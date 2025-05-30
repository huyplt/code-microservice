# terraform/gke_cluster.tf

// Bật các API cần thiết
resource "google_project_service" "compute" {
  project = var.gcp_project_id
  service = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "container" {
  project = var.gcp_project_id
  service = "container.googleapis.com"
  disable_on_destroy = false
}


resource "google_container_cluster" "primary" {
  project                = var.gcp_project_id
  name                   = var.gke_cluster_name
  location               = var.gcp_region // Cho regional cluster
  node_locations         = var.gke_node_locations // Chỉ định các zone cho regional cluster

  remove_default_node_pool = true
  initial_node_count       = 1 // Sẽ bị ghi đè bởi node pool được định nghĩa riêng

//  min_master_version = var.gke_master_version

  // Bật Workload Identity cho Pods trong GKE (khác với WIF cho GitHub Actions)
  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }

  // Bật Cloud Logging và Monitoring
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  // (Tùy chọn) Cấu hình mạng nếu bạn có VPC tùy chỉnh
  // network    = google_compute_network.vpc_network.self_link
  // subnetwork = google_compute_subnetwork.vpc_subnetwork.self_link

  depends_on = [
    google_project_service.container,
  ]
}

resource "google_container_node_pool" "primary_nodes" {
  project    = var.gcp_project_id
  name       = "${google_container_cluster.primary.name}-default-pool"
  location   = google_container_cluster.primary.location // Hoặc var.gcp_region
  cluster    = google_container_cluster.primary.name
  node_count = 1 // Terraform sẽ nhân với số zone trong node_locations

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type = var.gke_node_machine_type
    disk_size_gb = 15          // <<< THÊM VÀ ĐẶT GIÁ TRỊ NHỎ ĐỂ TEST
    disk_type    = "pd-standard"
    // Service Account cho nodes. Mặc định là Compute Engine default SA.
    // SA này cần quyền đọc từ Artifact Registry (roles/artifactregistry.reader)
    // và các quyền khác cần thiết cho node hoạt động.
    // service_account = "your-custom-gke-node-sa@${var.gcp_project_id}.iam.gserviceaccount.com"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform" // Phạm vi rộng, bao gồm đọc GAR
    ]

    // (Tùy chọn) Metadata, labels, taints...
    // metadata = {
    //   disable-legacy-endpoints = "true"
    // }
  }

  // Đảm bảo node pool được tạo sau khi cluster được tạo
  depends_on = [
    google_container_cluster.primary,
  ]
}

