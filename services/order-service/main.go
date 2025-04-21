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

	http.HandleFunc("/orders", handleOrders)
	http.HandleFunc("/healthz", handleHealthz)

	log.Printf("Order service starting on port %s\n", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}

func handleOrders(w http.ResponseWriter, r *http.Request) {
	log.Printf("Received request on %s from %s", r.URL.Path, r.RemoteAddr)
	fmt.Fprintf(w, "Order Service reporting in! Path: %s\n", r.URL.Path)
}

func handleHealthz(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprintln(w, "OK")
}
