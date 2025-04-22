#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
# Default namespace and release name if not provided
DEFAULT_NAMESPACE="default"
DEFAULT_RELEASE_NAME="my-microservices"
# Path to the umbrella chart
CHART_DIR="helm/umbrella-chart"
# --- End Configuration ---

# Get parameters from command line arguments
NAMESPACE="${1:-$DEFAULT_NAMESPACE}"
RELEASE_NAME="${2:-$DEFAULT_RELEASE_NAME}"
IMAGE_TAG="${3:-latest}" # Use 'latest' if no tag is provided

echo "Starting deployment process..."
echo "Namespace:    ${NAMESPACE}"
echo "Release Name: ${RELEASE_NAME}"
echo "Image Tag:    ${IMAGE_TAG}"
echo "Chart Dir:    ${CHART_DIR}"
echo "-------------------------------------"

# Ensure Helm is available
if ! command -v helm &> /dev/null; then
    echo "Error: helm command not found. Please install Helm."
    exit 1
fi

# Ensure kubectl is available and configured
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl command not found. Please install kubectl."
    exit 1
fi
if ! kubectl cluster-info &> /dev/null; then
    echo "Error: Cannot connect to Kubernetes cluster. Check your kubectl configuration."
    exit 1
fi

echo "Updating Helm dependencies for umbrella chart..."
helm dependency update "${CHART_DIR}"

echo "Deploying/Upgrading release '${RELEASE_NAME}' in namespace '${NAMESPACE}'..."

# Use helm upgrade --install:
# - Installs if the release doesn't exist, upgrades if it does.
# - --namespace: Specifies the target namespace.
# - --create-namespace: Creates the namespace if it doesn't exist.
# - --set global.imageTag=...: Overrides the global image tag in the umbrella chart's values.
# - --wait: Waits until all resources are in a ready state (optional, but good practice).
# - --timeout: How long to wait for the deployment (optional).
helm upgrade --install "${RELEASE_NAME}" "${CHART_DIR}" \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  --set global.imageTag="${IMAGE_TAG}" \
  --wait \
  --timeout 10m # Adjust timeout as needed

echo "-------------------------------------"
echo "Deployment process initiated for release '${RELEASE_NAME}'."
echo "Run 'kubectl get pods -n ${NAMESPACE}' to check pod status."
echo "Run 'helm status ${RELEASE_NAME} -n ${NAMESPACE}' for release details."

# Try to get the Kong proxy IP (this might need adjustment based on your Kong setup)
echo "Attempting to find Kong proxy external IP..."
KONG_PROXY_IP=$(kubectl get service -n kong --selector=app.kubernetes.io/component=proxy -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' 2>/dev/null || \
                kubectl get service -n kong --selector=app.kubernetes.io/component=proxy -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}' 2>/dev/null || \
                kubectl get service -n kong kong-proxy -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || \
                kubectl get service -n kong kong-proxy -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || \
                echo "Could not automatically determine Kong IP.")

if [[ "$KONG_PROXY_IP" != "Could not automatically determine Kong IP." ]]; then
  echo "Kong proxy external IP/Hostname seems to be: ${KONG_PROXY_IP}"
  echo "Try accessing services:"
  echo " - User Service: curl http://${KONG_PROXY_IP}/users"
  echo " - Product Service: curl http://${KONG_PROXY_IP}/products"
  echo " - Order Service: curl http://${KONG_PROXY_IP}/orders"
else
  echo "Could not find Kong proxy IP automatically. Please find it manually:"
  echo "kubectl get service -n <your-kong-namespace>"
fi

echo "Deployment script finished."