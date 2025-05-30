
# iam_wif.tf


resource "google_service_account" "github_actions_sa" {
  account_id   = var.github_actions_sa_name
  display_name = "GitHub Actions WIF Service Account"
  project      = var.gcp_project_id
}

// Quyền cho SA (ví dụ)
resource "google_project_iam_member" "gar_writer" {
  project = var.gcp_project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.github_actions_sa.email}"
}

resource "google_project_iam_member" "gke_developer" {
  project = var.gcp_project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.github_actions_sa.email}"
}

resource "google_iam_workload_identity_pool" "github_pool" {
  project                   = var.gcp_project_id
  workload_identity_pool_id = "github-pool" // Giữ tên này cho nhất quán với cicd.yaml
  display_name              = "GitHub Actions Pool"
  //  location                  = "global"
}

resource "google_iam_workload_identity_pool_provider" "github_provider" {
  project = var.gcp_project_id
  //location                           = "global"
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider" // Giữ tên này
  display_name                       = "GitHub Actions Provider"
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
  attribute_condition = "assertion.repository == '${var.github_org_user}/${var.github_repo_name}'"
}

resource "google_service_account_iam_member" "github_actions_sa_wif_user" {
  service_account_id = google_service_account.github_actions_sa.name // Sử dụng name (projects/.../serviceAccounts/...)
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/${var.github_org_user}/${var.github_repo_name}"
}
