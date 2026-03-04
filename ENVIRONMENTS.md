# Stage and Production Environments

This project deploys the same Helm chart to **stage** and **prod** with different values. Each environment has its own namespace, Zookeeper node path, and endpoint.

---

## Environment Comparison

| Setting | Stage | Production |
|---------|-------|------------|
| **Namespace** | `simple-api-stage` | `simple-api-prod` |
| **Replicas** | 1 | 2 |
| **Zookeeper node** | `/stage/config` | `/prod/config` |
| **App message** | "Hello from Stage" | "Hello from Production" |
| **Monitor URL** | https://stage.example.com/health | https://prod.example.com/health |
| **Monitor interval** | 15s | 10s |
| **Ingress host** | stage.simple-api.local | prod.simple-api.local |
| **Resources** | 500m CPU, 512Mi RAM | 1000m CPU, 1Gi RAM |

---

## Value Files

| File | Purpose |
|------|---------|
| `values.yaml` | Base values (shared) |
| `values-stage.yaml` | Stage overrides |
| `values-prod.yaml` | Production overrides |

Helm merges them: `values.yaml` + `values-stage.yaml` for stage, `values.yaml` + `values-prod.yaml` for prod.

---

## Argo CD Applications

| Application | Namespace | Value files |
|-------------|-----------|-------------|
| `simple-api-stage` | simple-api-stage | values.yaml, values-stage.yaml |
| `simple-api-prod` | simple-api-prod | values.yaml, values-prod.yaml |

**Apply both:**
```bash
kubectl apply -f argo/application-stage.yaml
kubectl apply -f argo/application-prod.yaml
```

---

## Helm Deploy (Direct, No Argo CD)

```bash
# Stage
./scripts/deploy-helm-stage.sh

# Production
./scripts/deploy-helm-prod.sh
```

---

## Accessing Each Environment

### Port-forward (no Ingress)

```bash
# Stage
kubectl port-forward svc/simple-api 8080:8080 -n simple-api-stage
curl http://localhost:8080/hello
curl http://localhost:8080/config/zk

# Prod (different port)
kubectl port-forward svc/simple-api 8081:8080 -n simple-api-prod
curl http://localhost:8081/hello
curl http://localhost:8081/config/zk
```

### Ingress (requires ingress-nginx)

1. **Install ingress-nginx on Kind:**
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
   kubectl wait -n ingress-nginx --for=condition=ready pod -l app.kubernetes.io/component=controller --timeout=90s
   ```

2. **Add to /etc/hosts:**
   ```
   127.0.0.1 stage.simple-api.local
   127.0.0.1 prod.simple-api.local
   ```

3. **Access:**
   ```bash
   curl -H "Host: stage.simple-api.local" http://localhost/hello
   curl -H "Host: prod.simple-api.local" http://localhost/hello
   ```

---

## Zookeeper Nodes Per Environment

Each namespace has its own Zookeeper instance. The app reads from a different node path:

| Environment | Zookeeper node | Default value |
|-------------|----------------|---------------|
| Stage | `/stage/config` | stage-default-value |
| Prod | `/prod/config` | prod-default-value |

**Set a value in Zookeeper (stage):**
```bash
kubectl exec -it deployment/zookeeper -n simple-api-stage -- zkCli.sh -server localhost:2181
# In zkCli: set /stage/config "my-stage-value"
```

**Set a value in Zookeeper (prod):**
```bash
kubectl exec -it deployment/zookeeper -n simple-api-prod -- zkCli.sh -server localhost:2181
# In zkCli: set /prod/config "my-prod-value"
```

---

## Changing Environment Values

1. Edit `values-stage.yaml` or `values-prod.yaml`
2. Commit and push
3. Argo CD syncs automatically (or run `argocd app sync simple-api-stage` / `argocd app sync simple-api-prod`)

For Helm deploy: re-run `./scripts/deploy-helm-stage.sh` or `./scripts/deploy-helm-prod.sh`.
