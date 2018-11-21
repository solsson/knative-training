package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
)

func handler(w http.ResponseWriter, r *http.Request) {
	reqID := r.Header.Get("x-request-id")
	log.Printf("Got request from %q id %q\n", r.RemoteAddr, reqID)

	dependOnService := os.Getenv("DEPEND_ON_SERVICE")
	if dependOnService == "" {
		dependOnService = "echo"
	}
	url := "http://" + dependOnService

	client := &http.Client{}

	get, err := http.NewRequest("GET", url, nil)
	resp, err := client.Do(get)
	if err != nil {
		log.Printf("GET failed for %q\n", url)
		panic(err)
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusOK {
		bodyBytes, err := ioutil.ReadAll(resp.Body)
		if err != nil {
			log.Println("Failed to read response body")
			panic(err)
		}
		bodyString := string(bodyBytes)
		fmt.Fprint(w, bodyString)
	} else {
		fmt.Fprintf(w, "Got status %q from backend", resp.StatusCode)
	}
}

func main() {
	log.Print("Frontend service started.")

	http.HandleFunc("/", handler)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Fatal(http.ListenAndServe(fmt.Sprintf(":%s", port), nil))
}
