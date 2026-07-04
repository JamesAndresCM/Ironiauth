# Ironiauth

IdP (Identity Provider) multi-tenant centralizado construido en Elixir/Phoenix. Permite que múltiples aplicaciones cliente deleguen autenticación y autorización a un único servicio, emitiendo JWTs firmados con RS256.

Tiene **dos modos de integración**:

| Modo | Quién sirve los formularios | Cuándo usarlo |
|------|-----------------------------|---------------|
| **Hosted UI** | Ironiauth | La app redirige el browser a Ironiauth, que devuelve un JWT via redirect. Sin formularios propios. |
| **API-only** | La app cliente | El backend llama directamente a la API con `api_key`. La app construye sus propios formularios. |

## Inicio rápido

```bash
# 1. Instalar dependencias
mix deps.get

# 2. Configurar variables de entorno
cp .env.example .env   # editar con tus valores

# 3. Crear y migrar la base de datos
mix ecto.setup         # equivalente a create + migrate + seed

# 4. Levantar el servidor
mix phx.server
```

El servidor queda disponible en `http://localhost:4000`.

## Variables de entorno

```bash
GUARDIAN_RSA_PRIVATE_KEY=<contenido PEM de la clave privada RSA>  # requerida en producción
DATABASE_URL=postgres://...                                         # solo en producción
SECRET_KEY_BASE=<mix phx.gen.secret>                               # solo en producción
```

En desarrollo y test se lee la clave desde `priv/keys/private.pem` (gitignoreada). Generarla la primera vez con:

```bash
openssl genrsa 2048 > priv/keys/private.pem
```

En producción setear `GUARDIAN_RSA_PRIVATE_KEY` con el contenido completo del archivo PEM.

## Arquitectura

```
App A (open_car)          App B (libros)          App N
     |                        |                     |
     | api_key (backend)      | api_key (backend)   |
     └────────────────────────┴─────────────────────┘
                              |
                         IRONIAUTH
                              |
                      JWT (solo identidad)
                              |
          ┌───────────────────┴──────────────────┐
       App A valida JWT                    App B valida JWT
       localmente                          localmente
       GET /users/permissions              GET /users/permissions
       (frescos, cacheados 5 min)          (frescos, cacheados 5 min)
```

Cada app cliente tiene un `api_key` único que identifica su `company` en Ironiauth. El `api_key` nunca sale del backend. En modo Hosted UI, el `company_uuid` viaja como query param en la URL que construye el backend — es un identificador público, no un secreto.

## Modelo de datos

| Tabla | Descripción |
|-------|-------------|
| `companies` | Cada app cliente es una company. Tiene `api_key` y `uuid`. |
| `users` | Usuarios globales. Sin `company_id` directo. |
| `memberships` | Relación N:N entre usuarios y companies (con `status`). |
| `roles` | `user`, `admin`, `superadmin` — roles globales. |
| `user_roles` | Asignación de roles a usuarios. |
| `groups` | Grupos dentro de una company. Un usuario puede estar en N grupos. |
| `group_permissions` | Qué permisos tiene cada grupo. |
| `user_groups` | A qué grupos pertenece cada usuario. |
| `permissions` | Permisos con formato `"recurso#accion"`. Pertenecen a una company. |

## Formato de permisos

Los permisos usan el formato `"recurso#accion"`:

```
"car#create"    "car#update"    "car#destroy"
"book#read"     "book#create"   "book#admin"
"admin#manage"
```

## JWT

El JWT usa algoritmo **RS256** (firma asimétrica RSA) e incluye solo identidad y contexto:

```json
{
  "alg": "RS256",
  "sub": "1",
  "user_uuid": "48de5033-6fcf-4801-abac-df1c3557bf1b",
  "company_uuid": "1bb9d88a-e1a1-4a7d-be62-4d26aac749ec",
  "exp": 1790375136
}
```

Las apps cliente validan el JWT **localmente** con la **clave pública RSA** (no hay secreto compartido). La clave pública se obtiene del endpoint estándar `GET /.well-known/jwks.json`. Los **permisos se consultan por separado** vía `GET /api/v1/users/permissions`.

### ¿Por qué RS256 y no HS512?

Con HS512 (simétrico), todas las apps cliente necesitan la misma clave secreta. Si una app es comprometida, el atacante puede **forjar JWTs para cualquier usuario en cualquier company**. Con RS256, Ironiauth firma con la clave privada (solo la conoce Ironiauth) y cada app cliente verifica con la clave pública. Una app comprometida no puede forjar tokens.

## API Endpoints

### Públicos (sin autenticación)

---

#### `POST /api/v1/forgot_password`
```json
// Request
{ "user": { "email": "juanito@opencar.com" } }

// Response 200
{ "message": "If the email exists, a reset link was sent" }
```

#### `PUT /api/v1/reset_password/:token`
```json
// Request
{
  "user": {
    "password": "nuevapass123",
    "password_confirmation": "nuevapass123"
  }
}

// Response 200
{ "message": "Password updated successfully" }

// Response 422 — token expirado
{ "error": "Reset token has expired" }
```

---

### Autenticados con api_key

Estos endpoints son llamados **desde el backend de la app cliente**, nunca desde el browser. El `api_key` se genera automáticamente al crear la company en Ironiauth y debe guardarse en las variables de entorno del backend (`IRONIAUTH_API_KEY`).

Header requerido: `Authorization: Bearer <api_key_de_la_company>`

---

#### `POST /api/v1/sign_up`
```json
// Request
{
  "user": {
    "username": "juanito",
    "email": "juanito@opencar.com",
    "password": "password123",
    "password_confirmation": "password123"
  }
}

// Response 201
{ "jwt": "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9..." }

// Response 422 — validación
{ "errors": { "email": ["has already been taken"] } }
```

#### `POST /api/v1/sign_in`
```json
// Request
{
  "email": "juanito@opencar.com",
  "password": "password123"
}

// Response 200
{ "jwt": "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9..." }

// Response 401 — credenciales inválidas
{ "error": "Login error" }
```

---

### Autenticados con JWT

Header requerido: `Authorization: Bearer <jwt>`

---

#### `DELETE /api/v1/sign_out`
```json
// Response 200
{ "msg": "logout successfully" }
```

#### `GET /api/v1/refresh_token`
```json
// Response 200
{ "jwt": "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9..." }
```

---

#### `GET /api/v1/users`
```json
// Response 200
{
  "data": [
    { "uuid": "48de5033-...", "username": "admin", "email": "admin@opencar.com" },
    { "uuid": "9f2c1a44-...", "username": "juanito", "email": "juanito@opencar.com" }
  ],
  "meta": {
    "page_number": 1,
    "per_page": 10,
    "total_pages": 1,
    "total_elements": 2
  }
}
```

#### `GET /api/v1/users/me` _(cualquier usuario autenticado)_
```json
// Response 200
{ "id": 1, "email": "admin@opencar.com", "roles": ["admin"] }
```

#### `GET /api/v1/users/permissions` _(cualquier usuario autenticado)_
Consulta la DB en tiempo real — retorna los permisos propios del usuario en la company.
```json
// Response 200
{ "data": ["car#create", "car#update", "car#destroy"] }
```

#### `GET /api/v1/users/:id` _(solo admin)_
```json
// Response 200
{ "data": { "uuid": "48de5033-...", "username": "admin", "email": "admin@opencar.com" } }

// Response 404
{ "error": "User not found" }
```

#### `PUT /api/v1/users/:id` _(solo el propio usuario)_
```json
// Request
{ "user": { "username": "nuevo_nombre" } }

// Response 200
{ "data": { "uuid": "48de5033-...", "username": "nuevo_nombre", "email": "admin@opencar.com" } }

// Response — intento de modificar otro usuario
{ "error": "Operation not permitted" }
```

#### `DELETE /api/v1/users/:id` _(solo admin)_
```
// Response 204 — sin cuerpo
```

---

---

#### `GET /api/v1/companies` _(solo superadmin)_
```json
// Response 200
{
  "data": [
    { "id": 1, "name": "open_car", "domain": "opencar.com" }
  ],
  "meta": { "page_number": 1, "per_page": 10, "total_pages": 1, "total_elements": 1 }
}
```

#### `POST /api/v1/companies` _(solo superadmin)_
El `api_key` se genera automáticamente al crear la company.
```json
// Request
{ "company": { "name": "libro_app", "domain": "libroapp.com" } }

// Response 201
{ "data": { "id": 2, "name": "libro_app", "domain": "libroapp.com" } }
```

#### `GET /api/v1/companies/:id` _(solo superadmin)_
```json
// Response 200
{ "data": { "id": 1, "name": "open_car", "domain": "opencar.com" } }
```

#### `PUT /api/v1/companies/:id` _(solo superadmin)_
```json
// Request
{ "company": { "name": "open_car_v2" } }

// Response 200
{ "data": { "id": 1, "name": "open_car_v2", "domain": "opencar.com" } }
```

#### `DELETE /api/v1/companies/:id` _(solo superadmin)_
```
// Response 204 — sin cuerpo
// Response 403 — si no es superadmin
{ "error": "Superadmin access required" }
```

---

#### `GET /api/v1/company_permissions` _(solo admin)_
```json
// Response 200
{
  "data": [
    { "id": 1, "name": "car#create", "description": "Crear autos" },
    { "id": 2, "name": "car#update", "description": "Editar autos" }
  ],
  "meta": { "page_number": 1, "per_page": 10, "total_pages": 1, "total_elements": 2 }
}
```

#### `POST /api/v1/company_permissions` _(solo admin)_
```json
// Request
{ "permission": { "name": "car#create", "description": "Crear autos" } }

// Response 201
{ "data": { "id": 1, "name": "car#create", "description": "Crear autos" } }

// Response 422 — nombre duplicado en la company
{ "errors": { "name": ["has already been taken"] } }
```

#### `PUT /api/v1/company_permissions/:id` _(solo admin)_
```json
// Request
{ "permission": { "description": "Permite crear un auto nuevo" } }

// Response 200
{ "data": { "id": 1, "name": "car#create", "description": "Permite crear un auto nuevo" } }
```

#### `DELETE /api/v1/company_permissions/:id` _(solo admin)_
```
// Response 204 — sin cuerpo
```

---

#### `GET /api/v1/groups` _(solo admin)_
```json
// Response 200
{
  "data": [
    { "id": 1, "uuid": "16373d9b-...", "name": "admins" }
  ]
}
```

#### `POST /api/v1/groups` _(solo admin)_
```json
// Request
{ "group": { "name": "editores" } }

// Response 201
{ "data": { "id": 2, "uuid": "abc123-...", "name": "editores" } }
```

#### `DELETE /api/v1/groups/:id` _(solo admin)_
```
// Response 204 — sin cuerpo
```

#### `POST /api/v1/groups/:group_id/permissions/:permission_id` _(solo admin)_
```
// Response 204 — sin cuerpo
// Response 422 — ya existe
{ "errors": { "group_id": ["has already been taken"] } }
```

#### `DELETE /api/v1/groups/:group_id/permissions/:permission_id` _(solo admin)_
```
// Response 204 — sin cuerpo
```

#### `POST /api/v1/groups/:group_id/users/:user_id` _(solo admin)_
```
// Response 204 — sin cuerpo
// Response 422 — ya existe
{ "errors": { "user_id": ["has already been taken"] } }
```

#### `DELETE /api/v1/groups/:group_id/users/:user_id` _(solo admin)_
```
// Response 204 — sin cuerpo
```

## Integración con una app Rails

### Modo Hosted UI (recomendado)

La app cliente no implementa formularios propios. Redirige el browser a Ironiauth y recibe el JWT en un callback.

#### 1. Configurar variables

```bash
# .env de tu app Rails
IRONIAUTH_URL=http://localhost:4000
IRONIAUTH_API_KEY=<api_key de tu company>
IRONIAUTH_COMPANY_UUID=<uuid de tu company>
```

#### 2. Cliente con helpers de URL

```ruby
# app/services/ironiauth_client.rb
class IroniauthClient
  BASE_URL     = ENV.fetch("IRONIAUTH_URL")
  API_KEY      = ENV.fetch("IRONIAUTH_API_KEY")
  COMPANY_UUID = ENV.fetch("IRONIAUTH_COMPANY_UUID")

  def self.hosted_login_url(callback_url:)
    "#{BASE_URL}/login?#{URI.encode_www_form(company_uuid: COMPANY_UUID, redirect_uri: callback_url)}"
  end

  def self.hosted_register_url(callback_url:)
    "#{BASE_URL}/register?#{URI.encode_www_form(company_uuid: COMPANY_UUID, redirect_uri: callback_url)}"
  end

  def self.fetch_user_info(jwt:)
    get("/api/v1/users/me", jwt: jwt)
  end
end
```

#### 3. SessionsController

```ruby
class SessionsController < ApplicationController
  def new
    return redirect_to root_path if logged_in?
    redirect_to IroniauthClient.hosted_login_url(callback_url: auth_callback_url), allow_other_host: true
  end

  def callback
    jwt = params[:jwt]
    session[:ironiauth_token] = jwt
    session.delete(:ironiauth_permissions)
    user_info = IroniauthClient.fetch_user_info(jwt: jwt)
    session[:current_user_email] = user_info.dig(:body, "email")
    # Limpiar el JWT de la URL del browser
    render html: "<script>window.location.replace('/');</script>".html_safe, layout: false
  end

  def destroy
    session.clear
    redirect_to login_path
  end
end
```

#### 4. Rutas

```ruby
get    "login",         to: "sessions#new"
get    "auth/callback", to: "sessions#callback", as: :auth_callback
delete "logout",        to: "sessions#destroy"
```

---

### Modo API-only

El backend llama directamente a la API de Ironiauth con el `api_key`. La app construye sus propios formularios.

#### 1. Configurar variables

```bash
# .env de tu app Rails
IRONIAUTH_URL=http://localhost:4000
IRONIAUTH_API_KEY=<api_key de tu company>
```

#### 2. Cliente HTTP

```ruby
# app/services/ironiauth_client.rb
class IroniauthClient
  BASE_URL = ENV.fetch("IRONIAUTH_URL")
  API_KEY  = ENV.fetch("IRONIAUTH_API_KEY")

  def self.sign_in(email:, password:)
    post("/api/v1/sign_in", { email: email, password: password })
  end

  def self.sign_up(username:, email:, password:, password_confirmation:)
    post("/api/v1/sign_up", {
      user: { username:, email:, password:, password_confirmation: }
    })
  end

  def self.post(path, body)
    uri = URI("#{BASE_URL}#{path}")
    req = Net::HTTP::Post.new(uri.path, {
      "Content-Type"  => "application/json",
      "Authorization" => "Bearer #{API_KEY}"
    })
    req.body = body.to_json
    res = Net::HTTP.new(uri.host, uri.port).request(req)
    { status: res.code.to_i, body: JSON.parse(res.body) }
  end
end
```

---

### Validar JWT y permisos (ambos modos)

La clave pública RSA se obtiene automáticamente desde `/.well-known/jwks.json`. No hay secreto compartido.

```ruby
def self.rsa_public_key
  @rsa_public_key ||= begin
    uri  = URI("#{BASE_URL}/.well-known/jwks.json")
    jwks = JSON.parse(Net::HTTP.get(uri))
    JWT::JWK.import(jwks["keys"].first).public_key
  end
end

# app/controllers/concerns/authenticatable.rb
def current_claims
  token = session[:ironiauth_token]
  return nil unless token

  payload, _ = JWT.decode(token, IroniauthClient.rsa_public_key, true, algorithms: ["RS256"])
  payload
rescue JWT::ExpiredSignature
  session.delete(:ironiauth_token)
  nil
rescue JWT::DecodeError
  nil
end
```

### Proteger acciones y condicionar vistas

```ruby
class CarsController < ApplicationController
  before_action :authenticate!
  before_action -> { require_permission!("car#create") }, only: %i[new create]
  before_action -> { require_permission!("car#update") }, only: %i[edit update]
  before_action -> { require_permission!("car#destroy") }, only: %i[destroy]
end
```

```erb
<% if can?("car#update") %>
  <%= link_to "Editar", edit_car_path(car) %>
<% end %>
```

## Seguridad

- Las contraseñas se hashean con bcrypt
- Los tokens JWT se revocan en logout (guardian_db)
- El reset de contraseña expira en 2 horas
- La contraseña mínima es 8 caracteres (en registro y en reset)
- `admin?/1` es fail-closed — retorna `false` en cualquier error
- El `api_key` se genera con `crypto.strong_rand_bytes(32)` al crear una company

## Testing

```bash
mix test
```
