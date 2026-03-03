# Argo CD + Helm + Kubernetes Example

A minimal Spring Boot API deployed with Helm and Argo CD, following patterns from the Platform Orchestration Service (POS).

**See [INTERFACES.md](./INTERFACES.md)** for where Kubernetes (kubectl) and Argo CD fit, and how to use both interfaces.

**See [STEPS.md](./STEPS.md)** for a step-by-step guide to the enhanced example (2 pods, 2 containers per pod: app + URL monitor sidecar).

**Important: This example uses an isolated kubeconfig. Your existing kubectl configuration for Adobe/orchestration clusters is never modified.**

---

## Prerequisites

- **Docker** (for building images and running kind)
- **kind** - `brew install kind`
- **kubectl** - `brew install kubectl`
- **Helm 3** - `brew install helm`
- **Maven** - `brew install maven` (or use SDKMAN)
- **Java 8** (or 11, 17)

---

## Quick Start (Helm - Recommended for Local)

```bash
# 1. Setup local cluster (creates .kube/config in project - isolated)
./scripts/setup-cluster.sh

# 2. Build app and load image into cluster
./scripts/build-and-push.sh

# 3. Deploy via Helm
./scripts/deploy-helm.sh

# 4. Test
export KUBECONFIG="$(pwd)/.kube/config"
kubectl port-forward svc/simple-api 8080:8080 -n simple-api &
curl http://localhost:8080/hello
```

Or run everything at once:

```bash
./scripts/run-all.sh
```

---

## Kubeconfig Isolation (Critical)

**Your default `~/.kube/config` is never modified.**

| Action | Kubeconfig Used |
|--------|-----------------|
| Running scripts | `./.kube/config` (project-local) |
| Your normal kubectl | `~/.kube/config` (unchanged) |

**To use this example's cluster:**
```bash
export KUBECONFIG="/Users/dascalu/kubernetes/argo-helm-example/.kube/config"
kubectl get pods -n simple-api
```

**To switch back to Adobe/orchestration:**
```bash
unset KUBECONFIG
# or: export KUBECONFIG=~/.kube/config
kubectl get pods -n 2  # Your orchestration namespace
```

---

## Project Structure

```
argo-helm-example/
├── simple-api/                 # Spring Boot application
│   ├── src/main/java/.../SimpleController.java
│   ├── Dockerfile
│   └── pom.xml
├── monitor/                    # URL monitor sidecar (curl loop)
│   ├── Dockerfile
│   └── monitor.sh
├── helm-chart/                 # Helm chart (POS-style)
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
│       ├── deployment.yaml
│       └── service.yaml
├── argo/                       # Argo CD Application manifest
│   └── application.yaml
├── scripts/
│   ├── setup-cluster.sh        # Create kind cluster
│   ├── build-and-push.sh       # Maven + Docker + kind load
│   ├── deploy-helm.sh         # Helm deploy
│   ├── install-argocd.sh       # Install Argo CD (optional)
│   ├── run-all.sh             # Full setup
│   └── teardown.sh            # Delete cluster
└── .kube/                      # Isolated kubeconfig (created by setup)
    └── config
```

---

## Component Mapping (POS Pattern)

| Component | This Example | POS Equivalent |
|-----------|--------------|----------------|
| API | simple-api (Spring Boot) | orchestration-server (Java API) |
| Deployment | 1 replica | 4 replicas (server), 1 (scheduler) |
| Service | ClusterIP | LoadBalancer |
| Config | values.yaml | namespace-values.yaml hierarchy |
| Health | /health | /airflow/health |

---

## Argo CD (Installed)

Argo CD is installed in the cluster. Use it to learn the GitOps workflow and the Argo CD UI.

**Access the Argo CD UI:**
```bash
export KUBECONFIG="$(pwd)/.kube/config"
kubectl port-forward svc/argocd-server 8443:443 -n argocd
# Open https://localhost:8443
# Username: admin
# Password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

**For full GitOps flow (Argo CD deploys from Git):**

1. Push this project to a Git repo (e.g., GitHub)
2. Update `argo/application.yaml`:
   ```yaml
   spec:
     source:
       repoURL: https://github.com/YOUR_USERNAME/argo-helm-example.git
       path: helm-chart
   ```
3. Install Argo CD: `./scripts/install-argocd.sh`
4. Apply the Application:
   ```bash
   kubectl apply -f argo/application.yaml
   ```

---

## Teardown

```bash
./scripts/teardown.sh
```

Deletes the kind cluster. Your `~/.kube/config` remains unchanged.

---

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| GET /hello | Returns message and environment |
| GET /health | Health check (used by K8s probes) |

---

## Troubleshooting

**"connection refused" when running kubectl**
- Ensure `export KUBECONFIG="$(pwd)/.kube/config"` is set
- Or run scripts from project root (they set it automatically)

**ImagePullBackOff**
- The image must be loaded into kind: `./scripts/build-and-push.sh`
- Helm deploy uses `image.pullPolicy=Never` for local images

**Port 8080 already in use**
- Use a different port: `kubectl port-forward svc/simple-api 9080:8080 -n simple-api`
- Then: `curl http://localhost:9080/hello`
