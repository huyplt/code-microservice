# terraform/outputs.tf
output "user_db_name" {
  description = "Name of the user service database."
  value       = google_sql_database.user_db.name
}
output "product_db_name" {
  description = "Name of the product service database."
  value       = google_sql_database.product_db.name
}
output "order_db_name" {
  description = "Name of the order service database."
  value       = google_sql_database.order_db.name
}
output "gcp_project_id" {
  value = var.gcp_project_id
}

output "gcp_region" {
  value = var.gcp_region
}

output "gke_cluster_name" {
  value = google_container_cluster.primary.name
}

output "gke_cluster_endpoint" {
  description = "GKE cluster master endpoint."
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "gke_cluster_ca_certificate" {
  description = "Base64 encoded CA certificate for GKE cluster."
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "artifact_registry_repository_url" {
  description = "URL of the Artifact Registry Docker repository."
  value       = "${var.artifact_registry_location}-docker.pkg.dev/${var.gcp_project_id}/${var.artifact_registry_repo_id}"
}

output "db_instance_name" {
  description = "Name of the Cloud SQL PostgreSQL instance."
  value       = google_sql_database_instance.main_postgres.name
}

output "db_instance_connection_name" {
  description = "Connection name of the Cloud SQL instance (for Cloud SQL Proxy)."
  value       = google_sql_database_instance.main_postgres.connection_name
}

output "db_instance_public_ip_address" {
  description = "Public IP address of the Cloud SQL instance (if ipv4_enabled=true)."
  value       = length(google_sql_database_instance.main_postgres.ip_address) > 0 ? google_sql_database_instance.main_postgres.ip_address[0].ip_address : "N/A (Private IP or not configured for Public IP)"
}

output "db_user_name" {
  description = "Username for the application to connect to the database."
  value       = google_sql_user.db_user.name
}

output "db_password_secret_manager_id" {
  description = "ID of the Secret Manager secret storing the DB password (format: projects/PROJECT_NUMBER/secrets/SECRET_ID)."
  value       = google_secret_manager_secret.db_password_secret.id
}

output "db_names_created" {
  description = "A map of the database names created."
  value       = { // THAY THẾ VÒNG LẶP FOR BẰNG MAP THỦ CÔNG NÀY
    user_service_db    = google_sql_database.user_db.name
    product_service_db = google_sql_database.product_db.name
    order_service_db   = google_sql_database.order_db.name
  }
}


output "github_actions_sa_email" {
  description = "Email of the Service Account for GitHub Actions WIF."
  value       = google_service_account.github_actions_sa.email
}

output "workload_identity_pool_name" {
  description = "Full name of the Workload Identity Pool."
  value       = google_iam_workload_identity_pool.github_pool.name
}

output "workload_identity_provider_name" {
  description = "Full name of the Workload Identity Provider."
  value       = google_iam_workload_identity_pool_provider.github_provider.name
}
