# terraform/versions.tf
terraform {
  required_version = ">= 1.2" // Nên dùng phiên bản Terraform gần đây

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.10" # Sử dụng phiên bản provider google mới
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  // Backend GCS (Rất khuyến nghị cho làm việc nhóm và CI/CD)
   backend "gcs" {
     bucket  = "back-end-bucket-huy" // <-- THAY THẾ: TẠO BUCKET NÀY TRÊN GCS TRƯỚC
     prefix  = "gke-microservices/state"
   }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

// Provider google-beta có thể cần cho một số tài nguyên mới
provider "google-beta" {
  project = var.gcp_project_id
  region  = var.gcp_region
}
