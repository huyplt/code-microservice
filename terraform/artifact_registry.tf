# terraform/artifact_registry.tf

resource "google_project_service" "artifactregistry" {
  project = var.gcp_project_id
  service = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "docker_repo" {
  provider      = google-beta // Artifact Registry thường cần provider beta
  project       = var.gcp_project_id
  location      = var.artifact_registry_location // Phải là region
  repository_id = var.artifact_registry_repo_id
  description   = "Docker repository for microservices"
  format        = "DOCKER"

  depends_on = [
    google_project_service.artifactregistry,
  ]
}
