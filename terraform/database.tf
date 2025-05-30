# terraform/database.tf
resource "google_sql_database_instance" "main_postgres" {
  name             = "microservices-db-instance"
  region           = var.gcp_region
  database_version = "POSTGRES_15" // Chọn phiên bản
  settings {
    tier = "db-f1-micro" // Chọn tier phù hợp (f1-micro cho test)
    // Cấu hình backup, IP, maintenance, flags...
    ip_configuration {
      ipv4_enabled = true
      // authorized_networks {
      //   name  = "allow-gke-nodes"
      //   value = "0.0.0.0/0" // CẢNH BÁO: Cho phép mọi IP, chỉ dùng cho test. Nên giới hạn!
      // }
    }
  }
  deletion_protection = false // Đặt là true cho production
}

resource "google_sql_database" "user_db" {
  instance = google_sql_database_instance.main_postgres.name
  name     = "user_service_db"
}

resource "google_sql_database" "product_db" {
  instance = google_sql_database_instance.main_postgres.name
  name     = "product_service_db"
}

resource "google_sql_database" "order_db" {
  instance = google_sql_database_instance.main_postgres.name
  name     = "order_service_db"
}

resource "google_sql_user" "db_user" {
  instance = google_sql_database_instance.main_postgres.name
  name     = "app_user"
  password = random_password.db_password.result // Tạo password ngẫu nhiên
}

resource "random_password" "db_password" {
  length  = 16
  special = true
}

// Lưu password vào Google Secret Manager
// Lưu password vào Google Secret Manager
resource "google_secret_manager_secret" "db_password_secret" {
  project   = var.gcp_project_id
  secret_id = "db-app-user-password"

  replication {
    user_managed {
      // THỬ ĐỊNH NGHĨA "replicas" (SỐ NHIỀU) NHƯ MỘT KHỐI
      replicas { // <--- KHỐI "replicas" (SỐ NHIỀU)
        location = var.gcp_region // Hoặc một region cụ thể
      }

      // Nếu bạn muốn nhiều replica với cấu trúc này, có thể bạn sẽ lặp lại khối "replicas"
      // HOẶC bên trong khối "replicas" có thể chứa nhiều "location"
      // Điều này cần được xác minh lại nếu cấu trúc cơ bản này không đúng.
    }
  }
}
resource "google_secret_manager_secret_version" "db_password_secret_version" {
  secret      = google_secret_manager_secret.db_password_secret.id
  secret_data = random_password.db_password.result
}

