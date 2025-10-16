#!/bin/bash
#
# Script: deploy-k8s.sh
# Description: Deploy application to Kubernetes cluster
# Usage: ./scripts/deploy/deploy-k8s.sh [NAMESPACE] [IMAGE_TAG]
#

set -e

echo "========================================="
echo "Deploying to Kubernetes"
echo "========================================="

# Configuration
NAMESPACE="${1:-obo-ns}"
IMAGE_TAG="${2:-latest}"
HARBOR_REGISTRY="harbor.server.thweb.click"
HARBOR_PROJECT="tthau"
IMAGE_NAME="obo-app"
FULL_IMAGE="${HARBOR_REGISTRY}/${HARBOR_PROJECT}/${IMAGE_NAME}:${IMAGE_TAG}"

echo "Namespace: $NAMESPACE"
echo "Image: $FULL_IMAGE"
echo ""

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Error: kubectl is not configured or cluster is unreachable"
    exit 1
fi

echo "✅ Connected to cluster: $(kubectl config current-context)"
echo ""

# Check if namespace exists
if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
    echo "⚠️  Namespace '$NAMESPACE' does not exist!"
    read -p "Do you want to create it and apply all manifests? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Applying all Kubernetes manifests..."
        kubectl apply -f kubernetes/
        echo "✅ Manifests applied"
    else
        echo "Deployment cancelled"
        exit 1
    fi
fi

# Update deployment image
echo "Updating deployment image..."
kubectl set image deployment/obo-app \
    obo-app="$FULL_IMAGE" \
    -n "$NAMESPACE" \
    --record

echo "Waiting for rollout to complete (timeout: 5m)..."
if kubectl rollout status deployment/obo-app -n "$NAMESPACE" --timeout=5m; then
    echo ""
    echo "✅ Deployment successful!"
    echo ""

    # Show deployment status
    echo "--- Pod Status ---"
    kubectl get pods -n "$NAMESPACE" -l app=obo-app
    echo ""

    echo "--- Deployment Status ---"
    kubectl get deployment obo-app -n "$NAMESPACE"
    echo ""

    echo "--- Service Status ---"
    kubectl get svc -n "$NAMESPACE"
    echo ""

    echo "--- Ingress Status ---"
    kubectl get ingress -n "$NAMESPACE"
    echo ""

    echo "Application should be accessible at:"
    echo "  https://obo.app.thweb.click"
else
    echo ""
    echo "❌ Deployment failed or timed out!"
    echo ""
    echo "Check pods:"
    kubectl get pods -n "$NAMESPACE" -l app=obo-app
    echo ""
    echo "Check events:"
    kubectl get events -n "$NAMESPACE" --sort-by='.lastTimestamp' | tail -20
    exit 1
fi
