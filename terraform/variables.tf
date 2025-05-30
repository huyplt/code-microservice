# terraform/variables.tf

variable "gcp_project_id" {
  description = "Google Cloud Project ID."
  type        = string
  # Không có default, sẽ yêu cầu khi chạy hoặc lấy từ terraform.tfvars
}

variable "gcp_region" {
  description = "Google Cloud Region for most resources."
  type        = string
  default     = "asia-southeast1"
}

variable "gke_cluster_name" {
  description = "Name of the GKE cluster."
  type        = string
  default     = "microservice-cluster"
}

variable "gke_node_machine_type" {
  description = "Machine type for GKE nodes."
  type        = string
  default     = "e2-medium"
}

variable "gke_initial_node_count_per_zone" {
  description = "Initial number of nodes per zone for GKE node pool."
  type        = number
  default     = 1 // Sẽ có tổng số node = số zone * giá trị này
}

variable "gke_node_locations" {
  description = "Zones for GKE node pools (for regional cluster). Should be within gcp_region."
  type        = list(string)
  default     = ["asia-southeast1-a", "asia-southeast1-b"] // Regional cluster
}

variable "gke_master_version" {
  description = "GKE master version. Check available versions for your region."
  type        = string
  default     = "1.27" // Ví dụ, kiểm tra phiên bản mới nhất/phù hợp
}


variable "artifact_registry_repo_id" {
  description = "ID for the Artifact Registry repository."
  type        = string
  default     = "docker-repo"
}

variable "artifact_registry_location" {
  description = "Location for the Artifact Registry repository (must be a region)."
  type        = string
  default     = "asia-southeast1" // Phải là region, không phải zone
}


variable "db_instance_name_suffix" {
  description = "Suffix for the Cloud SQL PostgreSQL instance name."
  type        = string
  default     = "pg-instance" // Tên đầy đủ sẽ là <gke_cluster_name>-<suffix>
}

variable "db_tier" {
  description = "Machine type for the Cloud SQL instance."
  type        = string
  default     = "db-f1-micro"
}

variable "db_version" {
  description = "PostgreSQL version for Cloud SQL."
  type        = string
  default     = "POSTGRES_15"
}

variable "db_user_name" {
  description = "Username for the database."
  type        = string
  default     = "app_user"
}

variable "db_password_secret_id" {
  description = "ID of the Secret Manager secret for DB password."
  type        = string
  default     = "db-app-password"
}

variable "db_names" {
  description = "A map of database names to create. Key is logical name, value is actual DB name."
  type        = map(string)
  default = {
    user_db    = "user_service_db"
    product_db = "product_service_db"
    order_db   = "order_service_db"
  }
}

// Biến cho WIF
variable "github_actions_sa_name" {
  description = "Name for the GitHub Actions Service Account (without project/domain)."
  type        = string
  default     = "github-actions-wif-sa"
}

variable "workload_identity_pool_id" {
  description = "ID for the Workload Identity Pool."
  type        = string
  default     = "github-pool"
}

variable "workload_identity_provider_id" {
  description = "ID for the Workload Identity Provider."
  type        = string
  default     = "github-provider"
}

variable "github_org_user" {
  description = "Your GitHub organization or username (e.g., huyplt)."
  type        = string
  # Không có default, sẽ yêu cầu khi chạy hoặc lấy từ terraform.tfvars
}

variable "github_repo_name" {
  description = "Your GitHub repository name (e.g., code-microservice)."
  type        = string
  # Không có default, sẽ yêu cầu khi chạy hoặc lấy từ terraform.tfvars
}
