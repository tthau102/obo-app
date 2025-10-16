#!/bin/bash
#
# Script: tail-logs-k8s.sh
# Description: Tail logs from Kubernetes deployment
# Usage: ./scripts/monitoring/tail-logs-k8s.sh [NAMESPACE]
#

set -e

NAMESPACE="${1:-obo-ns}"

echo "========================================="
echo "Tailing Logs from Kubernetes"
echo "========================================="
echo "Namespace: $NAMESPACE"
echo ""

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Error: kubectl is not configured"
    exit 1
fi

# Check if deployment exists
if ! kubectl get deployment obo-app -n "$NAMESPACE" &> /dev/null; then
    echo "❌ Error: Deployment 'obo-app' not found in namespace '$NAMESPACE'"
    exit 1
fi

# Show pod status first
echo "--- Pod Status ---"
kubectl get pods -n "$NAMESPACE" -l app=obo-app
echo ""
echo "--- Streaming Logs (Ctrl+C to stop) ---"
echo ""

# Tail logs from all pods
kubectl logs -f deployment/obo-app -n "$NAMESPACE" --all-containers=true --timestamps=true
