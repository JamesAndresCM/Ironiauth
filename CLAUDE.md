# CLAUDE.md — Ironiauth

## Qué es este proyecto

Ironiauth es un Identity Provider (IdP) multi-tenant centralizado construido en Elixir/Phoenix. Permite que múltiples aplicaciones cliente (App A, App B, etc.) deleguen autenticación y autorización a un único servicio.

Ironiauth tiene **dos modos de integración**:

| Modo | Quién sirve la UI | Cómo funciona |
|------|-------------------|---------------|
| **API-only** | La app cliente | Backend llama directamente a `/api/v1/sign_in`, `/api/v1/sign_up` con `api_key` |
| **Hosted UI** | Ironiauth | La app redirige el browser a `/login?company_uuid=...&redirect_uri=...` |

## Convenciones de lenguaje

- **Código, comentarios, CLAUDE.md**: español
- **Templates HTML (Hosted UI)**: inglés — los formularios, mensajes de error y botones van en inglés ya que pueden ser usados por usuarios de cualquier app cliente

## Arquitectura del modelo de datos

```
Company (aplicación cliente)
  ├── api_key          → autentica llamadas desde el backend de cada app
  ├── uuid             → identifica la company en el JWT y en la Hosted UI
  ├── has_many :permissions
  ├── has_many :groups
  └── has_many :memberships

User
  ├── has_many :memberships  → relación N:N con companies
  ├── has_many :user_roles   → roles globales (admin, user, superadmin)
  └── has_many :user_groups  → grupos dentro de una company

Membership (User ↔ Company)
  └── status: "active" | "inactive"

Group (pertenece a una Company)
  ├── has_many :group_permissions
  └── has_many :user_groups

Permission (pertenece a una Company)
  └── formato: "recurso#accion"  ej: "car#create", "book#read"

GroupPermission  → join Group ↔ Permission
UserGroup        → join User ↔ Group
```

## Flujo de integración — Hosted UI (recomendado)

```
App cliente (Rails)                    Ironiauth                       Browser
      │                                     │                              │
      │  redirect_to hosted_login_url ──────►│                              │
      │  /login?company_uuid=<uuid>         │◄── GET /login ───────────────│
      │  &redirect_uri=<callback_url>       │──► render login form ────────►│
      │                                     │◄── POST /login (email+pass) ──│
      │                                     │──► redirect redirect_uri?jwt= ►│
      │◄── GET /auth/callback?jwt=<token> ──│                              │
      │  (guarda jwt en sesión)             │                              │
      │  window.location.replace('/')       │                              │
```

1. La app cliente construye la URL de Ironiauth en el backend: `hosted_login_url(callback_url:)` en `IroniauthClient`
2. El browser va a `/login?company_uuid=<uuid>&redirect_uri=<callback_url>` en Ironiauth
3. Ironiauth muestra el formulario de login (o register, forgot-password)
4. Al autenticar, Ironiauth redirige a `redirect_uri?jwt=<token>`
5. La app recibe el JWT en `/auth/callback`, lo guarda en sesión y limpia la URL con `window.location.replace('/')`

## Flujo de integración — API-only (modo headless)

1. La app cliente tiene `IRONIAUTH_API_KEY` en su `.env` del backend
2. El backend llama a `/api/v1/sign_in` con `Authorization: Bearer <api_key>`
3. Ironiauth retorna un JWT firmado con **RS256**
4. La app valida el JWT localmente con la clave pública de `/.well-known/jwks.json`
5. Los permisos se consultan vía `GET /api/v1/users/permissions` y se cachean en sesión (5 min)

## JWT Claims

El JWT usa RS256 y contiene solo identidad — sin permisos embebidos:

```json
{
  "alg": "RS256",
  "sub": "1",
  "user_uuid": "uuid-del-usuario",
  "company_uuid": "uuid-de-la-company",
  "exp": 1234567890
}
```

Los permisos se obtienen frescos vía `GET /api/v1/users/permissions` (autenticado con JWT). Esto permite que los cambios de grupos se reflejen inmediatamente sin esperar que expire el token.

## Hosted UI — rutas del browser

```
GET  /login               → formulario de login
POST /login               → procesa login, redirige con JWT
GET  /register            → formulario de registro
POST /register            → crea usuario, redirige con JWT
GET  /forgot-password     → formulario de forgot password
POST /forgot-password     → envía email de reset
GET  /reset-password      → formulario de nueva contraseña (token en query param)
POST /reset-password      → procesa reset, redirige a /login
```

Todos reciben `company_uuid` y `redirect_uri` como query params (GET) o hidden fields (POST). El `company_uuid` es construido por el backend de la app cliente — nunca lo ingresa el usuario.

Después del reset de contraseña, el browser es redirigido a `/login?company_uuid=<uuid>&redirect_uri=<url>` en Ironiauth — nunca directamente a la app externa, eliminando el riesgo de open redirect.

## Endpoint JWKS

`GET /.well-known/jwks.json` — expone la clave pública RSA en formato estándar JWKS. Las apps cliente la usan para verificar la firma del JWT sin compartir ningún secreto.

```json
{
  "keys": [{
    "kty": "RSA",
    "use": "sig",
    "alg": "RS256",
    "kid": "ironiauth-1",
    "n": "...",
    "e": "AQAB"
  }]
}
```

## Pipelines de autenticación en el router

- **`:browser`**: Hosted UI — login, register, forgot-password, reset-password. Incluye `put_root_layout`, CSRF, session.
- **Sin auth (`:api`)**: `GET /`, `GET /.well-known/jwks.json` — públicos
- **`api_key_authenticated`**: `sign_up`, `sign_in`, `forgot_password` (API-only) — el backend de la app envía `Authorization: Bearer <api_key>`
- **`jwt_authenticated`**: todos los demás endpoints — `Authorization: Bearer <jwt>`

Cualquier ruta no definida devuelve `{"error": "Not found"}` con status 404 (catch-all al final del router). Las rutas de dev (`/dev/mailbox`, `/dev/dashboard`) van ANTES del catch-all.

## Variables de entorno requeridas

```bash
GUARDIAN_RSA_PRIVATE_KEY=  # contenido PEM de la clave privada RSA (requerida en producción)
DATABASE_URL=               # solo en producción
SECRET_KEY_BASE=            # solo en producción (mix phx.gen.secret)
```

### Variables que necesita la app cliente (ej. open_car)

```bash
IRONIAUTH_API_KEY=          # api_key de la company en Ironiauth
IRONIAUTH_COMPANY_UUID=     # uuid de la company (para construir hosted_login_url)
IRONIAUTH_BASE_URL=         # ej: http://localhost:4000
```

En dev/test la clave RSA se lee de `priv/keys/private.pem` (gitignoreada). Generarla con:
```bash
openssl genrsa 2048 > priv/keys/private.pem
```

Las apps cliente NO necesitan ningún secreto compartido — solo usan `/.well-known/jwks.json`.

## Comandos útiles

```bash
mix ecto.reset          # borrar y recrear DB con seeds
mix ecto.migrate        # solo migrar
mix phx.server          # levantar servidor en puerto 4000
mix test                # correr tests
```

## Seeds

Los seeds crean:
- Roles: `user`, `admin`, `superadmin`
- Company `open_car` con `api_key` generado automáticamente
- Usuario admin `admin@opencar.com` / `admin1234` con membresía en open_car

## Decisiones de diseño importantes

- **RS256 en lugar de HS512** — firma asimétrica: Ironiauth firma con la clave privada (que solo conoce), las apps verifican con la clave pública del endpoint JWKS. Una app comprometida no puede forjar JWTs para otras companies.
- **Model B — email único por company, no global** — el mismo email puede existir en distintas companies como usuarios completamente independientes. `sign_in` y `forgot_password` siempre resuelven el usuario escopado a la company del api_key (modo API) o del company_uuid en la query param (Hosted UI).
- **company_uuid en Hosted UI** — viaja como query param en la URL que construye el backend de la app cliente. El usuario lo ve en la barra de dirección pero no puede cambiarlo por uno diferente porque Ironiauth verifica que exista en la DB. No es un secreto — es un identificador público.
- **Sin open redirect en reset password** — después de resetear la contraseña, el redirect va a `/login?company_uuid=...` dentro de Ironiauth, no directamente a la app externa. Esto evita que un atacante forje links de reset con `redirect_uri` malicioso.
- **Permisos fuera del JWT** — el JWT solo lleva identidad. Los permisos se consultan vía `GET /users/permissions` y se cachean en el cliente (ej. 5 min en sesión de Rails). Cambios de grupo son inmediatamente visibles sin esperar expiración del JWT.
- **Grupos** — un usuario puede pertenecer a N grupos, cada grupo tiene N permisos. Resuelve el problema de eficiencia con muchos usuarios
- **admin?/1 y superadmin?/1 son fail-closed** — retornan `false` en cualquier error, nunca permiten acceso por defecto
- **Roles y sus alcances:**
  - `superadmin` → dueño de Ironiauth. Único que puede crear/gestionar companies. Plug: `IsSuperAdmin`.
  - `admin` → dueño de una company. Gestiona grupos, permisos y usuarios dentro de su company. Plug: `IsAdmin`.
  - `user` → usuario final. Solo puede ver/editar su propio perfil y consultar sus propios permisos.
- **Memberships** — reemplaza la relación directa `user.company_id` para soportar usuarios en múltiples companies
- **active: true forzado** — `create_user_for_company/2` siempre crea usuarios con `active: true`. Los usuarios inactivos no pueden autenticarse.

## Dependencias clave

- `guardian ~> 2.0` — JWT con RS256. Requiere clave RSA en formato JWK mapa (via JOSE).
- `guardian_db ~> 3.0` — revocación de tokens en DB. El sweeper se llama `Guardian.DB.Sweeper` (en versiones anteriores era `Guardian.DB.Token.SweeperServer`). Está registrado en `IroniauthWeb.Telemetry`.
- `swoosh` — mailer. En dev usa `Adapters.Local` y el mailbox está en `/dev/mailbox`. El forgot_password email se envía con `Task.Supervisor` (asíncrono).

## Patrones de código

- Los contextos (`Accounts`, `Management`) son la única interfaz hacia la DB
- Los controllers no acceden a `Repo` directamente
- `conn.assigns.current_company` es cargado por el plug `CurrentUser` — los controllers no lo resuelven por su cuenta
- Formato de permisos: `"recurso#accion"` (mismo separador `#` que el sistema Rails de referencia)
- `AuthController` maneja toda la Hosted UI. `SessionsController` y `PasswordsController` manejan la API-only.
