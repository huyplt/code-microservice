
## Thiết lập Môi trường Cục bộ (Để build/deploy)

1.  **Clone Repository:**
    ```bash
    git clone https://github.com/huyplt/code-microservice.git # Thay bằng URL repo của bạn nếu khác
    cd code-microservice
    ```

2.  **Xác thực Google Cloud:**
    ```bash
    gcloud auth login
    gcloud config set project YOUR_GCP_PROJECT_ID # Thay bằng Project ID của bạn
    ```

3.  **Cấu hình Docker cho Artifact Registry:**
    ```bash
    # Thay YOUR_GAR_LOCATION bằng region của repo (ví dụ: asia-southeast1)
    gcloud auth configure-docker YOUR_GAR_LOCATION-docker.pkg.dev
    ```

4.  **Kết nối `kubectl` tới GKE Cluster:**
    ```bash
    # Thay YOUR_CLUSTER_NAME và YOUR_GKE_LOCATION (zone hoặc region)
    gcloud container clusters get-credentials YOUR_CLUSTER_NAME --location YOUR_GKE_LOCATION
    ```

5.  **Cấu hình Đường dẫn Artifact Registry:**
    *   Mở file `scripts/build_push.sh`.
    *   Chỉnh sửa biến `REGISTRY` thành đường dẫn đầy đủ đến GAR repository của bạn:
        ```sh
        REGISTRY="YOUR_GAR_LOCATION-docker.pkg.dev/YOUR_GCP_PROJECT_ID/YOUR_REPO_NAME"
        ```
    *   Mở các file `helm/<service-name>/values.yaml` (hoặc chỉ `helm/umbrella-chart/values.yaml` nếu bạn ghi đè tập trung).
    *   Đảm bảo giá trị `image.repository` trỏ đến đúng đường dẫn image trên GAR (ví dụ: `${REGISTRY}/user-service`). Đặt `image.tag: ""` để tag được quản lý bởi CI/CD hoặc lệnh deploy.

6.  **Cấu hình Kong Ingress Class:**
    *   Mở file `helm/kong-config/values.yaml`.
    *   Đảm bảo `ingress.ingressClassName` (hoặc `ingress.annotations` cho K8s cũ) được đặt đúng với tên Ingress Class của Kong trên cluster của bạn (thường là `kong`).

## Build và Push Images Thủ công

Script này sẽ build Docker image cho từng microservice và đẩy chúng lên Artifact Registry đã cấu hình.

```bash
# Cấp quyền thực thi (chỉ lần đầu)
chmod +x ./scripts/build_push.sh



# Chạy script với một tag cụ thể
./scripts/build_push.sh <YOUR_IMAGE_TAG>

# Ví dụ:
./scripts/build_push.sh latest
./scripts/build_push.sh v1.1.0
./scripts/build_push.sh $(git rev-parse --short HEAD) # Dùng git commit hash ngắn làm tag

Deploy Thủ công lên GKE
Script này sử dụng Helm umbrella chart để triển khai tất cả microservices và cấu hình Kong Ingress lên namespace chỉ định trên GKE cluster.

# Cấp quyền thực thi (chỉ lần đầu)
chmod +x ./scripts/deploy.sh

# Chạy script deploy
./scripts/deploy.sh <NAMESPACE> <RELEASE_NAME> <IMAGE_TAG>

# Ví dụ:
# Deploy vào namespace 'dev', release tên 'my-app', dùng tag 'latest'
./scripts/deploy.sh dev my-app latest

# Deploy vào namespace 'production', release tên 'prod-app', dùng tag 'v1.1.0'
./scripts/deploy.sh production prod-app v1.1.0
<NAMESPACE>: Namespace Kubernetes đích (sẽ được tạo nếu chưa có).

<RELEASE_NAME>: Tên định danh cho bản cài đặt Helm này.

<IMAGE_TAG>: Tag của Docker image cần deploy (phải khớp với tag đã được push lên GAR).
Quy trình CI/CD với GitHub Actions
Dự án này sử dụng GitHub Actions được định nghĩa trong file .github/workflows/cicd.yaml để tự động hóa quy trình build và deploy.

Trigger: Workflow được kích hoạt khi có push hoặc pull_request vào nhánh main (có thể tùy chỉnh).

Xác thực: Sử dụng Workload Identity Federation (WIF) để xác thực an toàn từ GitHub Actions đến Google Cloud mà không cần lưu trữ Service Account Key. Cần thiết lập WIF trong dự án GCP của bạn trước.

Các Job chính:

lint-and-test: (Có thể mở rộng) Chạy linting và unit tests. Kiểm tra cú pháp Helm charts.

build-and-push:

Xác thực với GCP qua WIF.

Cấu hình Docker để push lên GAR.

Build Docker images cho tất cả services.

Push images lên GAR với tag là Git commit hash ngắn.

Lưu tag image vào artifact image-tag để job sau sử dụng.

deploy-to-gke:

Chạy sau khi build-and-push thành công.

Xác thực với GCP qua WIF.

Cài đặt gke-gcloud-auth-plugin.

Lấy thông tin xác thực GKE cluster.

Tải artifact image-tag chứa tag image cần deploy.

Chạy script deploy.sh sử dụng Helm umbrella chart để deploy phiên bản mới nhất lên namespace và với release name đã cấu hình.

Cấu hình CI/CD:

Biến môi trường Workflow: Các giá trị như GCP_PROJECT_ID, GKE_CLUSTER_NAME, GKE_LOCATION, GAR_LOCATION, GAR_REPOSITORY, DEPLOY_NAMESPACE, HELM_RELEASE_NAME cần được cấu hình đúng trong khối env: của file cicd.yaml.

Workload Identity Federation: Thông tin workload_identity_provider và service_account trong các bước xác thực (google-github-actions/auth@v2) phải khớp với cấu hình WIF bạn đã thiết lập trên Google Cloud.

Quyền IAM: Service Account được WIF mạo danh (github-actions-wif-sa@...) cần có các vai trò IAM thích hợp (ví dụ: Artifact Registry Writer, Kubernetes Engine Developer).

Truy cập Ứng dụng
Sau khi deploy thành công (thủ công hoặc qua CI/CD):

Tìm Địa chỉ IP Public của Kong:

# Thay 'kong' bằng namespace bạn cài Kong nếu khác
kubectl get service -n kong -l app.kubernetes.io/component=proxy
Gửi Yêu cầu: Sử dụng IP bạn vừa tìm được:

export KONG_PROXY_IP=<EXTERNAL_IP_CỦA_KONG>

# Truy cập User Service
curl http://$KONG_PROXY_IP/users

# Truy cập Product Service
curl http://$KONG_PROXY_IP/products

# Truy cập Order Service
curl http://$KONG_PROXY_IP/orders
