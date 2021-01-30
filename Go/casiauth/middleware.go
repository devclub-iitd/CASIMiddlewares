package casiauth

import (
	"crypto/rsa"
	"fmt"
	"io/ioutil"
	"net/http"
	"strings"
	"time"

	jwt "github.com/dgrijalva/jwt-go"
)

const (
	tokenName     = "token"
	rememberName  = "rememberme"
	authURL       = "http://localhost:8000/user/login"
	refreshURL    = "http://localhost:8000/auth/refresh-token"
	publicKeyPath = "public.pem"
	maxTTL        = 60 * 5
	queryParam    = "serviceURL"
	logoutPath    = "/logout"
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
	// TODO: Use a logging library instead of printing

	return http.HandlerFunc(func(rw http.ResponseWriter, r *http.Request) {
		defer func() {
			if rec := recover(); rec != nil {
				fmt.Println(rec)
				http.SetCookie(rw, &http.Cookie{
					Name:   tokenName,
					MaxAge: -1,
				})
				http.SetCookie(rw, &http.Cookie{
					Name:   rememberName,
					MaxAge: -1,
				})
				redirect(rw, r)
			}
		}()

		if r.URL.Path == logoutPath {
			panic("logout")
		}

		toRefresh := false
		tokenCookie, err := r.Cookie(tokenName)
		if err != nil {
			tokenCookie, err = r.Cookie(rememberName)
			if err != nil {
				panic("No token found")
			}
			toRefresh = true
		}

		token, err := jwt.ParseWithClaims(tokenCookie.Value, &CASIClaims{}, func(t *jwt.Token) (interface{}, error) {
			return key, nil
		})

		if claims, ok := token.Claims.(*CASIClaims); ok && token.Valid {
			printUser(claims)
			if tokenCookie.Name == tokenName {
				if claims.ExpiresAt-time.Now().Local().Unix() < maxTTL {
					toRefresh = true
				}
			}
			if toRefresh {
				refreshToken(rw, r, tokenCookie)
			}
			next.ServeHTTP(rw, r)

		} else {
			panic("Invalid Token")
		}

	})
}

func refreshToken(rw http.ResponseWriter, r *http.Request, token *http.Cookie) {
	reqBody := strings.NewReader(fmt.Sprintf(`
		{
			"%s" : "%s"
		}
	`, token.Name, token.Value))

	res, err := http.Post(refreshURL, "application/json", reqBody)
	if err != nil {
		panic(err)
	}
	cookies := res.Cookies()
	for _, c := range cookies {
		if c.Name == tokenName || c.Name == rememberName {
			http.SetCookie(rw, c)
		}
	}

}

func redirect(rw http.ResponseWriter, r *http.Request) {
	// BUG r.URL.RequestURI() gives only the request path and not the full url
	url := fmt.Sprintf("%s?%s=%s", authURL, queryParam, r.URL.RequestURI())
	redirectHandler := http.RedirectHandler(url, http.StatusTemporaryRedirect)
	redirectHandler.ServeHTTP(rw, r)
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
