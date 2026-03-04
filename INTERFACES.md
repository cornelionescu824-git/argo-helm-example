# Kubernetes & Argo CD Interfaces – Where Everything Fits

This guide explains the two main interfaces for managing your cluster and where Argo CD sits in the architecture.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         YOUR LOCAL MACHINE                                   │
│                                                                              │
│  ┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐    │
│  │ kubectl (CLI)    │    │ Argo CD UI       │    │ Argo CD CLI       │    │
│  │ Kubernetes API   │    │ (Web Browser)    │    │ (argocd)          │    │
│  └────────┬─────────┘    └────────┬─────────┘    └────────┬─────────┘    │
│           │                       │                       │              │
│           │    port-forward       │    port-forward       │              │
│           ▼                       ▼                       ▼              │
└───────────┼───────────────────────┼───────────────────────┼──────────────┘
            │                       │                       │
            │  KUBECONFIG           │                       │
            │  .kube/config         │                       │
            ▼                       ▼                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    KIND CLUSTER (argo-helm-example)                          │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ Kubernetes API Server (control plane)                                 │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐ │
│  │ namespace: argocd   │  │ namespace: simple-api│  │ namespace: kube-*   │ │
│  │                     │  │                     │  │                     │ │
│  │ • argocd-server     │  │ • simple-api pods   │  │ • CoreDNS, etc.     │ │
│  │ • argocd-repo-server│  │ • simple-api svc   │  │                     │ │
│  │ • argocd-application│  │                     │  │                     │ │
│  │   -controller       │  │                     │  │                     │ │
│  │ • argocd-redis      │  │                     │  │                     │ │
│  └─────────────────────┘  └─────────────────────┘  └─────────────────────┘ │
│           │                            ▲                                     │
│           │  Argo CD watches Git        │ Argo CD syncs manifests             │
│           │  and syncs to cluster      │ (when using GitOps flow)           │
│           ▼                            │                                     │
│  ┌─────────────────────┐               │                                     │
│  │ Git repo (optional) │───────────────┘                                     │
│  │ helm-chart/         │                                                     │
│  └─────────────────────┘                                                     │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 1. Kubernetes Interface: kubectl

**What it is:** The standard CLI for talking to the Kubernetes API. You use it to create/update/delete resources (pods, services, deployments, etc.).

**How to use it:**
```bash
export KUBECONFIG="/Users/dascalu/kubernetes/argo-helm-example/.kube/config"

# List namespaces
kubectl get ns

# List pods in simple-api
kubectl get pods -n simple-api

# List pods in argocd
kubectl get pods -n argocd

# Describe a resource
kubectl describe pod <pod-name> -n simple-api

# View logs
kubectl logs -f deployment/simple-api -n simple-api
```

**Where it fits:** Direct control over the cluster. You (or scripts like `deploy-helm.sh`) apply manifests and manage resources.

---

## 2. Argo CD Interface: Web UI

**What it is:** A web-based UI for GitOps. Argo CD watches a Git repository and keeps the cluster in sync with what’s in Git. You can see app status, sync state, and drift.

**How to access it:**

1. **Port-forward the Argo CD server:**
   ```bash
   export KUBECONFIG="/Users/dascalu/kubernetes/argo-helm-example/.kube/config"
   kubectl port-forward svc/argocd-server 8443:443 -n argocd
   ```

2. **Open in browser:** https://localhost:8443

3. **Login:**
   - Username: `admin`
   - Password: (run this to get it)
     ```bash
     kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
     ```

**Where Argo CD fits:** Argo CD runs *inside* the cluster. It:
- Watches a Git repo for changes
- Compares desired state (from Git) with actual state (in the cluster)
- Syncs the cluster when there is drift
- Provides a UI to see apps, sync status, and history

---

## 3. Argo CD Interface: argocd CLI (Optional)

**What it is:** CLI for Argo CD. Useful for scripting and automation.

**Install:**
```bash
brew install argocd
```

**Login (after port-forward is running):**
```bash
argocd login localhost:8443 --username admin --password <password> --insecure
```

**Useful commands:**
```bash
argocd app list
argocd app get simple-api
argocd app sync simple-api
```

---

## Where Is Argo CD in This Context?

| Layer | Tool | Role |
|-------|------|------|
| **You** | kubectl | Direct cluster management (deploy, inspect, debug) |
| **You** | Argo CD UI / CLI | GitOps: define apps from Git, view sync status |
| **Cluster** | Argo CD (argocd namespace) | Controller that watches Git and syncs to cluster |
| **Cluster** | Your app (simple-api namespace) | The workload Argo CD or Helm deploys |

**Two ways to deploy simple-api:**

1. **Helm (direct):** `./scripts/deploy-helm.sh` – you run it, Helm installs the chart.
2. **Argo CD (GitOps):** Argo CD watches a Git repo and deploys the Helm chart from there. For this to work, the project must be in a Git repo and `argo/application.yaml` must point to it.

---

## Current Setup: Argo CD + Helm

- **Argo CD is installed** in the `argocd` namespace.
- **simple-api** can be deployed either by Helm or by Argo CD.
- **Argo CD Application** (`argo/application.yaml`) is configured to pull from a Git repo. The placeholder `https://github.com/your-username/argo-helm-example.git` must be replaced with your real repo URL for Argo CD to sync.

**To use Argo CD with this project:**
1. Push the project to GitHub (or another Git host).
2. Edit `argo/application.yaml` and set `spec.source.repoURL` to your repo URL.
3. Apply the Application: `kubectl apply -f argo/application.yaml`
4. Argo CD will sync the Helm chart from Git into the cluster.

---

## Quick Reference: Access Both Interfaces

| Interface | Command | URL / Usage |
|-----------|---------|-------------|
| **kubectl** | `export KUBECONFIG=.../argo-helm-example/.kube/config` | `kubectl get pods -A` |
| **Argo CD UI** | `kubectl port-forward svc/argocd-server 8443:443 -n argocd` | https://localhost:8443 |
| **simple-api (stage)** | `kubectl port-forward svc/simple-api 8080:8080 -n simple-api-stage` | `curl http://localhost:8080/hello` |
| **simple-api (prod)** | `kubectl port-forward svc/simple-api 8081:8080 -n simple-api-prod` | `curl http://localhost:8081/hello` |

See **[ENVIRONMENTS.md](./ENVIRONMENTS.md)** for stage vs prod endpoints and Zookeeper nodes.
