#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
# CHANGE THIS to your container registry
REGISTRY="asia-southeast1-docker.pkg.dev/microservice-lab-457503/docker-repo"
# Default tag if none provided
DEFAULT_TAG="latest"
# --- End Configuration ---

# Get the tag from the first argument, or use the default
TAG="${1:-$DEFAULT_TAG}"

# Base directory where services are located
SERVICES_DIR="services"

echo "Starting image build and push process..."
echo "Registry: ${REGISTRY}"
echo "Tag:      ${TAG}"
echo "-------------------------------------"

# Find all directories within the services directory
# Assuming each directory is a service to be built
for service_dir in "${SERVICES_DIR}"/*; do
  if [ -d "${service_dir}" ]; then
    service_name=$(basename "${service_dir}")
    image_name="${REGISTRY}/${service_name}:${TAG}"

    echo "Processing service: ${service_name}"
    echo "Building image: ${image_name}"

    # Go to the service directory
    pushd "${service_dir}" > /dev/null

    # Build the Docker image
    docker build -t "${image_name}" .

    echo "Pushing image: ${image_name}"
    # Push the Docker image
    docker push "${image_name}"

    # Return to the original directory
    popd > /dev/null

    echo "Finished processing service: ${service_name}"
    echo "-------------------------------------"
  fi
done

echo "Build and push process completed successfully."
