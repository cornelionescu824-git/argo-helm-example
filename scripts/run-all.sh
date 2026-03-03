#!/bin/bash
# Complete setup: cluster + build + deploy
# Run this after cloning. Uses ISOLATED kubeconfig - safe for your existing clusters.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Step 1/3: Setup local Kubernetes cluster..."
"$SCRIPT_DIR/setup-cluster.sh"

echo ""
echo "Step 2/3: Build and load Docker image..."
"$SCRIPT_DIR/build-and-push.sh"

echo ""
echo "Step 3/3: Deploy via Helm..."
"$SCRIPT_DIR/deploy-helm.sh"

echo ""
echo "=== All done! ==="
echo ""
echo "Test the API:"
echo "  export KUBECONFIG=$(cd "$SCRIPT_DIR/.." && pwd)/.kube/config"
echo "  kubectl port-forward svc/simple-api 8080:8080 -n simple-api"
echo "  curl http://localhost:8080/hello"
echo ""
echo "To restore your normal kubectl: unset KUBECONFIG"
