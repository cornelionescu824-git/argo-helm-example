# Step-by-Step: See Helm and Argo CD in Action

This guide walks you through the enhanced example: **2 pods**, each with **2 containers** (app + URL monitor sidecar). For each step, you'll see what to run and what Helm, Argo CD, and Kubernetes are doing.

---

## What You'll Deploy

| Component | Description |
|-----------|-------------|
| **simple-api** | Spring Boot app (port 8080) |
| **url-monitor** | Sidecar that curls a configurable URL every N seconds |
| **Replicas** | 2 pods |
| **Containers per pod** | 2 (app + monitor) |

---

## Step 1: Build Both Images and Load into Kind

### What to run

```bash
cd /Users/dascalu/kubernetes/argo-helm-example
./scripts/build-and-push.sh
```

### What's happening

| Component | Role |
|-----------|------|
| **Helm** | Not involved. No chart rendering yet. |
| **Argo CD** | Not involved. No Git, no sync. |
| **Kubernetes** | Not involved. No API calls. |

**What the script does:**
- Maven builds the Spring Boot JAR
- Docker builds `simple-api:1.0.0` and `url-monitor:1.0.0`
- `kind load docker-image` loads both into the Kind cluster's nodes

**Why:** Argo CD will deploy pods that reference these images. With `pullPolicy: Never`, Kubernetes uses images already present on the node. If the images aren't loaded, you get `ImagePullBackOff`.

---

## Step 2: Push Changes to GitHub

### What to run

```bash
git add .
git status   # Review: monitor/, helm-chart/, argo/, scripts/
git commit -m "Add url-monitor sidecar, 2 replicas, 2 containers per pod"
git push
```

### What's happening

| Component | Role |
|-----------|------|
| **Helm** | Not involved. The chart files are just files in Git. |
| **Argo CD** | Will detect the new commit when it polls (or when you refresh). |
| **Kubernetes** | Not involved yet. |

**What Git stores:**
- `helm-chart/values.yaml` – replicaCount: 2, monitor.url, monitor.enabled, etc.
- `helm-chart/templates/deployment.yaml` – templates with `{{ .Values.xxx }}`
- `argo/application.yaml` – tells Argo CD which repo, path, and Helm params to use

**Why:** Argo CD uses Git as the source of truth. It will fetch this repo and render the Helm chart from it.

---

## Step 3: Argo CD Detects and Syncs (GitOps in Action)

### What to run

**Option A – Wait:** Argo CD polls Git every ~3 minutes. It will sync automatically.

**Option B – Force refresh:**
```bash
# Ensure port-forward is running (in another terminal):
# kubectl port-forward svc/argocd-server 8443:443 -n argocd

# Then in Argo CD UI: open simple-api → click REFRESH
# Or via CLI:
argocd app sync simple-api
```

### What's happening

| Component | Role |
|-----------|------|
| **Helm** | Used by Argo CD's repo server to render the chart (see below). |
| **Argo CD** | Fetches Git, renders the chart, compares with cluster, applies changes. |
| **Kubernetes** | Receives the applied manifests and creates/updates resources. |

**Argo CD flow (simplified):**

1. **Fetch** – Clones/pulls `https://github.com/cornelionescu824-git/argo-helm-example` and reads `helm-chart/`.

2. **Render (Helm)** – Argo CD's repo server runs the equivalent of:
   ```bash
   helm template simple-api helm-chart/ \
     -f helm-chart/values.yaml \
     --set image.pullPolicy=Never \
     --set monitor.image.pullPolicy=Never
   ```
   This turns templates like `{{ .Values.replicaCount }}` and `{{ .Values.monitor.url }}` into concrete YAML (e.g. `replicas: 2`, `value: "https://www.google.com"`).

3. **Compare** – Compares the rendered manifests with what's in the cluster (Deployments, Services, etc.).

4. **Apply** – Sends create/update/patch requests to the Kubernetes API so the cluster matches the rendered state.

**Kubernetes flow:**
- Receives the Deployment manifest (2 replicas, 2 containers per pod).
- Scheduler places pods on nodes.
- Kubelet pulls images (or uses cached ones with `pullPolicy: Never`) and starts containers.

---

## Step 4: Verify with kubectl

### What to run

```bash
export KUBECONFIG="/Users/dascalu/kubernetes/argo-helm-example/.kube/config"

# See 2 pods
kubectl get pods -n simple-api

# See 2 containers per pod
kubectl get pods -n simple-api -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].name}{"\n"}{end}'

# View monitor logs (sidecar curling the URL)
kubectl logs -n simple-api -l app=simple-api -c url-monitor -f
```

### What you see

Monitor logs look like:
```
Monitoring https://www.google.com every 10s
2026-03-03T16:30:00+00:00 - https://www.google.com -> HTTP 200
```

### What's happening

| Component | Role |
|-----------|------|
| **Helm** | Already done. Chart was rendered by Argo CD. |
| **Argo CD** | Idle. Cluster matches Git; app is Synced/Healthy. |
| **Kubernetes** | Running the pods. The url-monitor container runs the curl loop from the Helm-rendered env vars. |

---

## Step 5: Test the API

### What to run

```bash
kubectl port-forward svc/simple-api 8080:8080 -n simple-api
```

In another terminal:
```bash
curl http://localhost:8080/hello
```

### What's happening

- `kubectl port-forward` tunnels local port 8080 to the Service.
- The Service load-balances across the 2 pods.
- The simple-api container (from the Helm chart) serves the request.

---

## Step 6: Change the Monitor URL (See Helm + Argo CD Again)

### What to run

**1. Edit** `helm-chart/values.yaml`:

```yaml
monitor:
  url: "https://www.github.com"   # was https://www.google.com
  interval: 5                     # was 10
```

**2. Push:**
```bash
git add helm-chart/values.yaml
git commit -m "Change monitor URL to github.com, interval 5s"
git push
```

**3. Trigger sync** (or wait for Argo CD to poll):
```bash
argocd app sync simple-api
# Or click REFRESH in the Argo CD UI
```

**4. Watch the rollout:**
```bash
kubectl get pods -n simple-api -w
```

**5. Check new monitor behavior:**
```bash
kubectl logs -n simple-api -l app=simple-api -c url-monitor -f
```

You should see `https://www.github.com` and logs every 5 seconds.

### What's happening

| Component | Role |
|-----------|------|
| **Helm** | Argo CD re-renders the chart with the new `values.yaml`. The Deployment template gets new env vars: `MONITOR_URL=https://www.github.com`, `MONITOR_INTERVAL=5`. |
| **Argo CD** | Detects Git change → re-renders chart → sees Deployment diff → applies update to the cluster. |
| **Kubernetes** | Rolling update: new pods with new env vars replace old ones. Old pods terminate; new pods start with the updated config. |

**Flow:**
```
values.yaml (monitor.url, monitor.interval)
    → Helm template renders Deployment with new env
    → Argo CD applies updated Deployment
    → Kubernetes rolls out new pods
    → url-monitor reads MONITOR_URL and MONITOR_INTERVAL from env
```

---

## Step 7: Optional – Deploy via Helm Directly (No Argo CD)

### What to run

```bash
./scripts/deploy-helm.sh
```

### What's happening

| Component | Role |
|-----------|------|
| **Helm** | Runs on your machine. Reads `helm-chart/` from disk, renders with values (including `--set` overrides), and applies to the cluster via `kubectl`. |
| **Argo CD** | Will detect drift: cluster was changed by Helm, but Git still has the previous state. With `syncPolicy.automated`, Argo CD may sync back to match Git. |
| **Kubernetes** | Receives manifests from Helm and applies them. |

**Helm vs Argo CD:**

| | Helm (direct) | Argo CD (GitOps) |
|---|---------------|------------------|
| **Who renders** | `helm` CLI on your machine | Argo CD repo server in cluster |
| **Source** | Local `helm-chart/` directory | Git repo |
| **Who applies** | Helm (via kubectl) | Argo CD (via Kubernetes API) |
| **Trigger** | You run `helm upgrade` | You push to Git (or manual sync) |

---

## Architecture Summary

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  YOU                                                                         │
│  1. Edit helm-chart/values.yaml, templates/                                │
│  2. git push                                                                 │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  GIT (GitHub) – source of truth                                             │
│  helm-chart/, argo/application.yaml                                          │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ Argo CD fetches
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  ARGO CD REPO SERVER                                                         │
│  • Runs Helm template (values + templates → plain YAML)                      │
│  • Compares desired vs actual                                                │
│  • Applies via Kubernetes API                                                │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  KUBERNETES                                                                  │
│  Pod 1: [simple-api] [url-monitor]                                           │
│  Pod 2: [simple-api] [url-monitor]                                           │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Quick Reference: Who Does What

| Step | Helm | Argo CD | Kubernetes |
|------|------|---------|------------|
| 1. Build images | — | — | — |
| 2. Push to Git | — | Will poll | — |
| 3. Sync | Renders chart (inside Argo CD) | Fetches, renders, applies | Receives manifests |
| 4. Verify | — | — | Runs pods |
| 5. Test API | — | — | Serves traffic |
| 6. Change values | Re-renders with new values | Detects, syncs | Rolling update |
| 7. Helm deploy | Renders locally, applies | May detect drift | Receives manifests |

---

## Step 8: Stage and Production Environments

See **[ENVIRONMENTS.md](./ENVIRONMENTS.md)** for full details.

**Apply Argo CD Applications for stage and prod:**
```bash
kubectl apply -f argo/application-stage.yaml
kubectl apply -f argo/application-prod.yaml
```

**Or deploy via Helm:**
```bash
./scripts/deploy-helm-stage.sh
./scripts/deploy-helm-prod.sh
```

**What's happening:** Same Helm chart, different value files. Stage uses `values-stage.yaml` (1 replica, `/stage/config` ZK node, stage.simple-api.local). Prod uses `values-prod.yaml` (2 replicas, `/prod/config` ZK node, prod.simple-api.local). Each environment gets its own namespace and Zookeeper instance.

---

## Troubleshooting

**ImagePullBackOff for url-monitor**
- Run `./scripts/build-and-push.sh` to load both images into Kind
- Ensure `monitor.image.pullPolicy: Never` in Application or values

**Argo CD shows OutOfSync**
- Click **REFRESH** in the UI or run `argocd app sync simple-api`

**Monitor logs empty**
- Wait ~30s for the first curl
- Check: `kubectl logs <pod> -c url-monitor -n simple-api`
