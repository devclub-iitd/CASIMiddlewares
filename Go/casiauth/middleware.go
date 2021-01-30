package casiauth

import (
	"crypto/rsa"
	"fmt"
	"io/ioutil"
	"net/http"

	jwt "github.com/dgrijalva/jwt-go"
)

const (
	tokenName     = "token"
	rememberName  = "rememberme"
	authURL       = "https://auth.devclub.in/user/login"
	refreshURL    = "https://auth.devclub.in/auth/refresh-token"
	publicKeyPath = "public.pem"
	maxTTL        = 60 * 5
	queryParam    = "serviceURL"
)

var (
	key *rsa.PublicKey
)

// CASIClaims : CASI jwt payload
type CASIClaims struct {
	User map[string]interface{} `json:"user"`
	jwt.StandardClaims
}

// CASIMiddleware - Middleware to handle CASI authentication
func CASIMiddleware(next http.Handler) http.Handler {

	return http.HandlerFunc(func(rw http.ResponseWriter, r *http.Request) {
		tokenCookie, err := r.Cookie(tokenName)
		if err != nil {
			http.Error(rw, "No token found", http.StatusBadRequest)
			return
		}

		token, err := jwt.ParseWithClaims(tokenCookie.Value, &CASIClaims{}, func(t *jwt.Token) (interface{}, error) {
			return key, nil
		})

		if claims, ok := token.Claims.(*CASIClaims); ok && token.Valid {
			printUser(claims)
			next.ServeHTTP(rw, r)
		} else {
			http.Error(rw, "Invalid Token", http.StatusBadRequest)
		}

	})
}

func printUser(claims *CASIClaims) {
	for k, v := range claims.User {
		fmt.Printf("%s : %v\n", k, v)
	}
	fmt.Println("--------")
}

func init() {
	fmt.Println("Reading public key!")
	data, err := ioutil.ReadFile(publicKeyPath)
	if err != nil {
		panic(err)
	}
	key, err = jwt.ParseRSAPublicKeyFromPEM(data)
	if err != nil {
		panic(err)
	}
}
