#!/bin/bash
# Install ingress-nginx on Kind (for stage/prod host-based routing)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
KUBECONFIG_FILE="$PROJECT_ROOT/.kube/config"

export KUBECONFIG="${KUBECONFIG:-$KUBECONFIG_FILE}"

echo "=== Installing ingress-nginx on Kind ==="
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

echo "Waiting for ingress controller to be ready..."
kubectl wait -n ingress-nginx --for=condition=ready pod -l app.kubernetes.io/component=controller --timeout=120s

echo ""
echo "=== Ingress installed ==="
echo "Add to /etc/hosts:"
echo "  127.0.0.1 stage.simple-api.local"
echo "  127.0.0.1 prod.simple-api.local"
echo ""
echo "Then access: curl -H 'Host: stage.simple-api.local' http://localhost/hello"
echo ""
