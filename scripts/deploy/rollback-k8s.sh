#!/bin/bash
#
# Script: rollback-k8s.sh
# Description: Rollback Kubernetes deployment to previous version
# Usage: ./scripts/deploy/rollback-k8s.sh [NAMESPACE] [REVISION]
#

set -e

echo "========================================="
echo "Kubernetes Deployment Rollback"
echo "========================================="

NAMESPACE="${1:-obo-ns}"
REVISION="$2"

echo "Namespace: $NAMESPACE"
echo ""

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Error: kubectl is not configured"
    exit 1
fi

# Show rollout history
echo "--- Rollout History ---"
kubectl rollout history deployment/obo-app -n "$NAMESPACE"
echo ""

# Confirm rollback
if [ -z "$REVISION" ]; then
    echo "⚠️  You are about to rollback to the PREVIOUS revision"
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Rollback cancelled"
        exit 0
    fi

    echo "Rolling back to previous revision..."
    kubectl rollout undo deployment/obo-app -n "$NAMESPACE"
else
    echo "⚠️  You are about to rollback to revision $REVISION"
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Rollback cancelled"
        exit 0
    fi

    echo "Rolling back to revision $REVISION..."
    kubectl rollout undo deployment/obo-app --to-revision="$REVISION" -n "$NAMESPACE"
fi

echo "Waiting for rollback to complete..."
kubectl rollout status deployment/obo-app -n "$NAMESPACE" --timeout=5m

echo ""
echo "✅ Rollback completed successfully!"
echo ""
kubectl get pods -n "$NAMESPACE" -l app=obo-app
