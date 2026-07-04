# Integración con Go

## Dependencias

```bash
go get github.com/golang-jwt/jwt/v5
go get github.com/MicahParks/keyfunc/v3
```

```go
// go.mod
require (
    github.com/golang-jwt/jwt/v5 v5.2.1
    github.com/MicahParks/keyfunc/v3 v3.3.5
)
```

## Variables de entorno

```bash
IRONIAUTH_URL=https://tu-ironiauth.com
IRONIAUTH_API_KEY=<api_key de tu company>
```

## Cliente HTTP

```go
// internal/ironiauth/client.go
package ironiauth

import (
    "bytes"
    "encoding/json"
    "fmt"
    "io"
    "net/http"
    "os"
    "sync"
    "time"

    "github.com/MicahParks/keyfunc/v3"
    "github.com/golang-jwt/jwt/v5"
)

var (
    baseURL = os.Getenv("IRONIAUTH_URL")
    apiKey  = os.Getenv("IRONIAUTH_API_KEY")

    jwksOnce sync.Once
    jwkSet   keyfunc.Keyfunc
)

// GetJWKS obtiene el conjunto de claves públicas RSA y lo cachea.
func GetJWKS() (keyfunc.Keyfunc, error) {
    var err error
    jwksOnce.Do(func() {
        jwkSet, err = keyfunc.NewDefault([]string{baseURL + "/.well-known/jwks.json"})
    })
    return jwkSet, err
}

// SignIn llama al endpoint de login y retorna el JWT.
func SignIn(email, password string) (string, error) {
    body, _ := json.Marshal(map[string]string{"email": email, "password": password})
    resp, err := apiPost("/api/v1/sign_in", body)
    if err != nil {
        return "", err
    }
    return resp["jwt"].(string), nil
}

// SignUp registra un usuario nuevo y retorna el JWT.
func SignUp(username, email, password, passwordConfirmation string) (string, error) {
    payload := map[string]any{
        "user": map[string]string{
            "username":              username,
            "email":                 email,
            "password":             password,
            "password_confirmation": passwordConfirmation,
        },
    }
    body, _ := json.Marshal(payload)
    resp, err := apiPost("/api/v1/sign_up", body)
    if err != nil {
        return "", err
    }
    return resp["jwt"].(string), nil
}

// FetchPermissions consulta los permisos del usuario autenticado.
func FetchPermissions(jwtToken string) ([]string, error) {
    req, _ := http.NewRequest("GET", baseURL+"/api/v1/users/permissions", nil)
    req.Header.Set("Authorization", "Bearer "+jwtToken)

    client := &http.Client{Timeout: 5 * time.Second}
    res, err := client.Do(req)
    if err != nil {
        return nil, err
    }
    defer res.Body.Close()

    var result struct {
        Permissions []string `json:"permissions"`
    }
    json.NewDecoder(res.Body).Decode(&result)
    return result.Permissions, nil
}

func apiPost(path string, body []byte) (map[string]any, error) {
    req, _ := http.NewRequest("POST", baseURL+path, bytes.NewReader(body))
    req.Header.Set("Content-Type", "application/json")
    req.Header.Set("Authorization", "Bearer "+apiKey)

    client := &http.Client{Timeout: 5 * time.Second}
    res, err := client.Do(req)
    if err != nil {
        return nil, err
    }
    defer res.Body.Close()

    data, _ := io.ReadAll(res.Body)
    var result map[string]any
    json.Unmarshal(data, &result)
    return result, nil
}
```

## Validación del JWT

```go
// internal/ironiauth/auth.go
package ironiauth

import (
    "errors"
    "github.com/golang-jwt/jwt/v5"
)

type Claims struct {
    UserUUID    string `json:"user_uuid"`
    CompanyUUID string `json:"company_uuid"`
    jwt.RegisteredClaims
}

// DecodeJWT valida el JWT con la clave pública RSA del JWKS.
func DecodeJWT(tokenString string) (*Claims, error) {
    jwks, err := GetJWKS()
    if err != nil {
        return nil, fmt.Errorf("error obteniendo JWKS: %w", err)
    }

    token, err := jwt.ParseWithClaims(tokenString, &Claims{}, jwks.Keyfunc,
        jwt.WithValidMethods([]string{"RS256"}),
    )
    if err != nil {
        return nil, err
    }

    claims, ok := token.Claims.(*Claims)
    if !ok || !token.Valid {
        return nil, errors.New("token inválido")
    }
    return claims, nil
}
```

## Middleware de autenticación

```go
// middleware/auth.go
package middleware

import (
    "context"
    "encoding/json"
    "net/http"
    "strings"

    "mi_app/internal/ironiauth"
)

type contextKey string

const ClaimsKey contextKey = "claims"

func Authenticate(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        header := r.Header.Get("Authorization")
        if !strings.HasPrefix(header, "Bearer ") {
            writeError(w, 401, "No autenticado")
            return
        }

        token := strings.TrimPrefix(header, "Bearer ")
        claims, err := ironiauth.DecodeJWT(token)
        if err != nil {
            writeError(w, 401, "Token inválido")
            return
        }

        ctx := context.WithValue(r.Context(), ClaimsKey, claims)
        next.ServeHTTP(w, r.WithContext(ctx))
    })
}

func RequirePermission(permission string) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            // Obtener el token original del header (ya validado por Authenticate)
            token := strings.TrimPrefix(r.Header.Get("Authorization"), "Bearer ")

            perms, err := ironiauth.FetchPermissions(token)
            if err != nil {
                writeError(w, 503, "Error consultando permisos")
                return
            }

            for _, p := range perms {
                if p == permission {
                    next.ServeHTTP(w, r)
                    return
                }
            }

            writeError(w, 403, "Permiso requerido: "+permission)
        })
    }
}

func writeError(w http.ResponseWriter, status int, msg string) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)
    json.NewEncoder(w).Encode(map[string]string{"error": msg})
}
```

## Registro de rutas

```go
// main.go
package main

import (
    "net/http"
    "mi_app/middleware"
)

func main() {
    mux := http.NewServeMux()

    // Rutas protegidas
    mux.Handle("POST /cars",
        middleware.Authenticate(
            middleware.RequirePermission("car#create")(
                http.HandlerFunc(createCar),
            ),
        ),
    )

    mux.Handle("PUT /cars/{id}",
        middleware.Authenticate(
            middleware.RequirePermission("car#update")(
                http.HandlerFunc(updateCar),
            ),
        ),
    )

    mux.Handle("DELETE /cars/{id}",
        middleware.Authenticate(
            middleware.RequirePermission("car#destroy")(
                http.HandlerFunc(deleteCar),
            ),
        ),
    )

    http.ListenAndServe(":8080", mux)
}
```

## Nota sobre caché de permisos

En el ejemplo de arriba `FetchPermissions` llama a Ironiauth en cada request. Para cachear los permisos 5 minutos (igual que en los otros lenguajes), usar un mapa en memoria con TTL:

```go
import "sync"

type permCache struct {
    mu    sync.RWMutex
    store map[string]permEntry
}

type permEntry struct {
    perms     []string
    cachedAt  int64
}

var cache = &permCache{store: make(map[string]permEntry)}

func (c *permCache) get(userUUID string) ([]string, bool) {
    c.mu.RLock()
    defer c.mu.RUnlock()
    entry, ok := c.store[userUUID]
    if !ok || time.Now().Unix()-entry.cachedAt > 300 {
        return nil, false
    }
    return entry.perms, true
}

func (c *permCache) set(userUUID string, perms []string) {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.store[userUUID] = permEntry{perms: perms, cachedAt: time.Now().Unix()}
}
```
