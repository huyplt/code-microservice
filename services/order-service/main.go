package main

import (
        "context"
	"database/sql"
	"fmt"
	"log/slog" // Hoặc logrus đã cấu hình JSON
	"net/http"
	"os"
	"time"

	_ "github.com/lib/pq" // PostgreSQL driver (quan trọng dấu gạch dưới)
)

var db *sql.DB // Biến global cho DB connection

// Cấu hình DB sẽ được đọc từ biến môi trường
type DBConfig struct {
	Host     string
	Port     string
	User     string
	Password string
	DBName   string
}

func loadDBConfig() DBConfig {
	cfg := DBConfig{
		Host:     os.Getenv("DB_HOST"),
		Port:     os.Getenv("DB_PORT"),
		User:     os.Getenv("DB_USER"),
		Password: os.Getenv("DB_PASSWORD"), // Sẽ được inject từ K8s Secret
		DBName:   os.Getenv("DB_NAME"),
	}

	// Giá trị mặc định nếu dùng Cloud SQL Proxy sidecar
	if cfg.Host == "" {
		cfg.Host = "127.0.0.1" // Proxy lắng nghe trên localhost của Pod
	}
	if cfg.Port == "" {
		cfg.Port = "5432" // Port mặc định của PostgreSQL mà proxy thường expose
	}
	if cfg.DBName == "" {
		slog.Error("DB_NAME environment variable is not set.")
		os.Exit(1) // DBName là bắt buộc
	}
	if cfg.User == "" {
		slog.Error("DB_USER environment variable is not set.")
		os.Exit(1)
	}
	// Password có thể rỗng nếu DB không yêu cầu (không phải trường hợp này)
	// nhưng chúng ta sẽ inject nó từ secret nên không cần kiểm tra rỗng ở đây.

	return cfg
}

func initDB(cfg DBConfig) error {
	connStr := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		cfg.Host, cfg.Port, cfg.User, cfg.Password, cfg.DBName)
	// sslmode=disable là OK khi kết nối qua Cloud SQL Proxy vì proxy đã mã hóa
	// Nếu kết nối trực tiếp Public IP, nên dùng sslmode=require hoặc verify-full

	var err error
	db, err = sql.Open("postgres", connStr)
	if err != nil {
		return fmt.Errorf("error opening database connection: %w", err)
	}

	// Kiểm tra kết nối
	// Đặt timeout cho ping để tránh treo vô hạn nếu DB không sẵn sàng
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	err = db.PingContext(ctx)
	if err != nil {
		db.Close() // Đóng kết nối nếu ping lỗi
		return fmt.Errorf("error connecting to the database (ping failed): %w", err)
	}

	slog.Info("Successfully connected to the database", "dbName", cfg.DBName)
	return nil
}

func main() {
	// Cấu hình logger (slog JSON như ví dụ trước)
	jsonHandler := slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{ /* ... */ })
	logger := slog.New(jsonHandler)
	slog.SetDefault(logger)

	dbCfg := loadDBConfig()
	if err := initDB(dbCfg); err != nil {
		slog.Error("Failed to initialize database connection", "error", err.Error())
		os.Exit(1) // Thoát nếu không kết nối được DB (DB là critical)
	}
	defer db.Close() // Đảm bảo đóng kết nối DB khi main thoát

	// (Tùy chọn) Chạy database migrations ở đây nếu cần
	// runMigrations(db)

	slog.Info("User Service starting up", "service.name", "user-service", "version", "1.0.1")

	http.HandleFunc("/users", handleUsers)
	http.HandleFunc("/healthz", handleHealthz)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	slog.Info("Server listening", "port", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		slog.Error("Server failed to start", "error", err.Error())
		os.Exit(1)
	}
}

// Ví dụ handler (cần logic CRUD thực tế)
func handleUsers(w http.ResponseWriter, r *http.Request) {
	slog.Info("Request received for /users", "method", r.Method, "path", r.URL.Path)

	// Ví dụ: Thử query đơn giản
	rows, err := db.QueryContext(r.Context(), "SELECT version();") // Kiểm tra kết nối
	if err != nil {
		slog.Error("Failed to query database", "error", err.Error())
		http.Error(w, "Database query failed", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var version string
	if rows.Next() {
		rows.Scan(&version)
	}

	fmt.Fprintf(w, "Hello from User Service! DB Version: %s\n", version)
}

func handleHealthz(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	err := db.PingContext(ctx) // Kiểm tra kết nối DB
	if err != nil {
		slog.Error("Health check failed: DB ping error", "error", err.Error())
		http.Error(w, "Database not responding", http.StatusInternalServerError)
		return
	}
	slog.Debug("Health check successful")
	w.WriteHeader(http.StatusOK)
	fmt.Fprintln(w, "OK")
}

// (Tùy chọn) Hàm chạy migrations
// func runMigrations(db *sql.DB) {
//   driver, err := postgres.WithInstance(db, &postgres.Config{})
//   if err != nil {
//     slog.Error("Cannot create postgres driver for migration", "error", err)
//     os.Exit(1)
//   }
//   m, err := migrate.NewWithDatabaseInstance(
//     "file://./migrations", // Đường dẫn đến thư mục chứa file .sql migrations
//     "postgres", driver)
//   if err != nil {
//     slog.Error("Migration instance creation failed", "error", err)
//     os.Exit(1)
//   }
//   if err := m.Up(); err != nil && err != migrate.ErrNoChange {
//     slog.Error("An error occurred while syncing the database", "error", err)
//     os.Exit(1)
//   }
//   slog.Info("Database migrations applied successfully (if any).")
// }
