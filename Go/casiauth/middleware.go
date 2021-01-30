package casiauth

import (
	"crypto/rsa"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"regexp"
	"strings"
	"time"

	jwt "github.com/dgrijalva/jwt-go"
	funk "github.com/thoas/go-funk"
)

const (
	tokenName     = "token"
	rememberName  = "rememberme"
	publicKeyPath = "public.pem"
	maxTTL        = 60 * 5
	queryParam    = "serviceURL"
	logoutPath    = "/logout"
)

var (
	key          *rsa.PublicKey
	defaultRoles = []string{"external_user"}
	roles        = map[string][]string{
		"^/admin": {"admin"},
	}
	unauthorizedHandler = http.HandlerFunc(func(rw http.ResponseWriter, r *http.Request) {
		rw.WriteHeader(http.StatusUnauthorized)
		rw.Write([]byte("Alas you are out of scope! Get some more permissions dude"))
	})
	serverURL  = "http://localhost:8000"
	authURL    = serverURL + "/user/login"
	refreshURL = serverURL + "/auth/refresh-token"
	domain     = ""
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
					Domain: domain,
				})
				http.SetCookie(rw, &http.Cookie{
					Name:   rememberName,
					MaxAge: -1,
					Domain: domain,
				})
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
				redirect(rw, r)
				panic("No token found")
			}
			toRefresh = true
		}

		token, err := jwt.ParseWithClaims(tokenCookie.Value, &CASIClaims{}, func(t *jwt.Token) (interface{}, error) {
			return key, nil
		})

		if claims, ok := token.Claims.(*CASIClaims); ok && token.Valid {

			if !claims.areAuthorized(r) {
				unauthorizedHandler.ServeHTTP(rw, r)
				panic("Unauthorized!")
			}

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
			redirect(rw, r)
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

func (claims *CASIClaims) areAuthorized(req *http.Request) bool {
	userRoles, exists := claims.User["roles"]
	if !exists {
		return false
	}
	checkRolesIn := func(desiredRoles []string) bool {
		for _, r := range desiredRoles {
			if !funk.Contains(userRoles, r) {
				return false
			}
		}
		return true
	}
	if !checkRolesIn(defaultRoles) {
		return false
	}

	for regexPath, allowedRoles := range roles {
		match, _ := regexp.MatchString(regexPath, req.URL.Path)
		if !match {
			continue
		}

		if !checkRolesIn(allowedRoles) {
			return false
		}
	}
	return true
}

func redirect(rw http.ResponseWriter, r *http.Request) {
	// BUG r.URL.RequestURI() gives only the request path and not the full url
	url := fmt.Sprintf("%s?%s=%s", authURL, queryParam, r.URL.RequestURI())
	redirectHandler := http.RedirectHandler(url, http.StatusTemporaryRedirect)
	redirectHandler.ServeHTTP(rw, r)
}

func init() {

	if os.Getenv("APP_ENV") != "DEV" {
		serverURL = "https://auth.devclub.in"
		domain = "devclub.in"
	}
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
