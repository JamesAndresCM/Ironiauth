# CLAUDE.md — Ironiauth

## Qué es este proyecto

Ironiauth es un Identity Provider (IdP) multi-tenant centralizado construido en Elixir/Phoenix. Permite que múltiples aplicaciones cliente (App A, App B, etc.) deleguen autenticación y autorización a un único servicio.

## Arquitectura del modelo de datos

```
Company (aplicación cliente)
  ├── api_key          → autentica llamadas desde el backend de cada app
  ├── uuid             → identifica la company en el JWT
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

## Flujo de integración con una app cliente

1. La app cliente (ej. open_car Rails) tiene `IRONIAUTH_API_KEY` en su `.env`
2. El backend de la app llama a `/api/v1/sign_up` o `/api/v1/sign_in` con `Authorization: Bearer <api_key>`
3. Ironiauth retorna un JWT firmado con **RS256** (asimétrico RSA)
4. El JWT incluye solo identidad: `company_uuid`, `user_uuid`
5. La app valida el JWT localmente con la **clave pública RSA** obtenida de `/.well-known/jwks.json`
6. Los permisos se consultan vía `GET /api/v1/users/permissions` y se cachean en sesión (5 min)

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

- **Sin auth (solo `:api`)**: `GET /`, `GET /.well-known/jwks.json`, `forgot_password`, `reset_password`
- **api_key_authenticated**: `sign_up`, `sign_in` — el backend de la app envía `Authorization: Bearer <api_key>`
- **jwt_authenticated**: todos los demás endpoints — `Authorization: Bearer <jwt>`

Cualquier ruta no definida devuelve `{"error": "Not found"}` con status 404 (catch-all al final del router).

## Variables de entorno requeridas

```bash
GUARDIAN_RSA_PRIVATE_KEY=  # contenido PEM de la clave privada RSA (requerida en producción)
DATABASE_URL=               # solo en producción
SECRET_KEY_BASE=            # solo en producción (mix phx.gen.secret)
```

En dev/test la clave se lee de `priv/keys/private.pem` (gitignoreada). Generarla con:
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
- **company_uuid nunca viaja desde el browser** — viene del `api_key` que identifica la company en el backend
- **Permisos fuera del JWT** — el JWT solo lleva identidad. Los permisos se consultan vía `GET /users/permissions` y se cachean en el cliente (ej. 5 min en sesión de Rails). Cambios de grupo son inmediatamente visibles sin esperar expiración del JWT.
- **Grupos** — un usuario puede pertenecer a N grupos, cada grupo tiene N permisos. Resuelve el problema de eficiencia con muchos usuarios
- **admin?/1 y superadmin?/1 son fail-closed** — retornan `false` en cualquier error, nunca permiten acceso por defecto
- **Roles y sus alcances:**
  - `superadmin` → dueño de Ironiauth. Único que puede crear/gestionar companies. Plug: `IsSuperAdmin`.
  - `admin` → dueño de una company. Gestiona grupos, permisos y usuarios dentro de su company. Plug: `IsAdmin`.
  - `user` → usuario final. Solo puede ver/editar su propio perfil y consultar sus propios permisos.
- **Memberships** — reemplaza la relación directa `user.company_id` para soportar usuarios en múltiples companies

## Dependencias clave

- `guardian ~> 2.0` — JWT con RS256. Requiere clave RSA en formato JWK mapa (via JOSE).
- `guardian_db ~> 3.0` — revocación de tokens en DB. El sweeper se llama `Guardian.DB.Sweeper` (en versiones anteriores era `Guardian.DB.Token.SweeperServer`). Está registrado en `IroniauthWeb.Telemetry`.

## Patrones de código

- Los contextos (`Accounts`, `Management`) son la única interfaz hacia la DB
- Los controllers no acceden a `Repo` directamente
- `conn.assigns.current_company` es cargado por el plug `CurrentUser` — los controllers no lo resuelven por su cuenta
- Formato de permisos: `"recurso#accion"` (mismo separador `#` que el sistema Rails de referencia)
