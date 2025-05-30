FROM golang:1.21-alpine AS builder

WORKDIR /app

# Optional: Copy go.mod and go.sum if they exist and download dependencies
COPY go.mod go.sum ./
RUN go mod download 

# Copy the source code
COPY main.go .

# Build the Go application
# CGO_ENABLED=0 disables CGO for static linking (good for alpine)
# -ldflags="-s -w" strips debugging information, making the binary smaller
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o app main.go

# --- Final Stage ---
FROM alpine:latest

WORKDIR /app

# Copy the compiled binary from the builder stage
COPY --from=builder /app/app .

# Expose the port the application runs on
EXPOSE 8080

# Set the entrypoint for the container
# Run the binary when the container starts
CMD ["./app"]
