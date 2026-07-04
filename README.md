# Ironiauth

IdP (Identity Provider) multi-tenant centralizado construido en Elixir/Phoenix. Permite que múltiples aplicaciones cliente deleguen autenticación y autorización a un único servicio, emitiendo JWTs firmados con RS256.

Tiene **dos modos de integración**:

| Modo | Quién sirve los formularios | Cuándo usarlo |
|------|-----------------------------|---------------|
| **Hosted UI** | Ironiauth | La app redirige el browser a Ironiauth, que devuelve un JWT via redirect. Sin formularios propios. |
| **API-only** | La app cliente | El backend llama directamente a la API con `api_key`. La app construye sus propios formularios. |

## Inicio rápido

```bash
mix deps.get
openssl genrsa 2048 > priv/keys/private.pem   # solo la primera vez
mix ecto.setup
mix phx.server
```

El servidor queda disponible en `http://localhost:4000`.

## Variables de entorno

```bash
GUARDIAN_RSA_PRIVATE_KEY=<contenido PEM de la clave privada RSA>  # requerida en producción
DATABASE_URL=postgres://...                                         # solo en producción
SECRET_KEY_BASE=<mix phx.gen.secret>                               # solo en producción
```

En desarrollo y test se lee la clave desde `priv/keys/private.pem` (gitignoreada).

## Arquitectura

```
App A (open_car)          App B (libros)          App N
     |                        |                     |
     | api_key (backend)      | api_key (backend)   |
     └────────────────────────┴─────────────────────┘
                              |
                         IRONIAUTH
                              |
                      JWT (solo identidad, RS256)
                              |
          ┌───────────────────┴──────────────────┐
       App A valida JWT                    App B valida JWT
       localmente con JWKS                localmente con JWKS
       GET /users/permissions              GET /users/permissions
       (frescos, cacheados 5 min)          (frescos, cacheados 5 min)
```

Cada app cliente tiene un `api_key` único que identifica su `company`. El `api_key` nunca sale del backend. En modo Hosted UI, el `company_uuid` viaja como query param en la URL que construye el backend — es un identificador público, no un secreto.

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

## JWT

Algoritmo **RS256**. Contiene solo identidad — los permisos se consultan por separado:

```json
{
  "alg": "RS256",
  "sub": "1",
  "user_uuid": "48de5033-...",
  "company_uuid": "1bb9d88a-...",
  "exp": 1790375136
}
```

La clave pública RSA se expone en `GET /.well-known/jwks.json`. Las apps cliente la usan para validar JWTs localmente sin secreto compartido.

## Seguridad

- Contraseñas hasheadas con bcrypt
- Tokens JWT revocados en logout (guardian_db)
- Reset de contraseña expira en 2 horas
- Contraseña mínima 8 caracteres
- `admin?/1` es fail-closed — retorna `false` en cualquier error
- `api_key` generado con `crypto.strong_rand_bytes(32)` al crear una company
- Reset password redirige a `/login` en Ironiauth, nunca a URL externa (sin open redirect)

## Testing

```bash
mix test
```

## Documentación

- [API Reference](docs/api.md) — todos los endpoints con ejemplos de request/response
- [Integración Rails](docs/integrations/rails.md) — Hosted UI y API-only
- [Integración Elixir](docs/integrations/elixir.md)
- [Integración Go](docs/integrations/go.md)
- [Integración Python](docs/integrations/python.md)
