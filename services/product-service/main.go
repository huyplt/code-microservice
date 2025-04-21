package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080" // Default port
	}

	http.HandleFunc("/products", handleProducts)
	http.HandleFunc("/healthz", handleHealthz)

	log.Printf("Product service starting on port %s\n", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}

func handleProducts(w http.ResponseWriter, r *http.Request) {
	log.Printf("Received request on %s from %s", r.URL.Path, r.RemoteAddr)
	fmt.Fprintf(w, "Greetings from the Product Service! You asked for: %s\n", r.URL.Path)
}

func handleHealthz(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprintln(w, "OK")
}
