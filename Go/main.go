package main

import (
	"casi-go/casiauth"
	"fmt"
	"log"
	"net/http"
)

func ok(rw http.ResponseWriter, r *http.Request) {
	rw.WriteHeader(http.StatusOK)
	rw.Write([]byte("OK!"))
}

func main() {
	fmt.Println("Hello World!")

	mux := http.NewServeMux()
	okHandler := http.HandlerFunc(ok)

	mux.Handle("/", casiauth.CASIMiddleware(okHandler))

	err := http.ListenAndServe(":3000", mux)
	log.Fatal(err)

}
