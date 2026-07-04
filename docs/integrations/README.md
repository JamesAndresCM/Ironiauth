# Guías de integración con Ironiauth

Ironiauth usa **RS256** (firma asimétrica RSA). Cada app cliente:

1. Llama a `sign_in` / `sign_up` desde su **backend** con `Authorization: Bearer <api_key>`
2. Recibe un JWT firmado con la clave privada de Ironiauth
3. Valida el JWT localmente usando la **clave pública** de `/.well-known/jwks.json`
4. Consulta permisos vía `GET /api/v1/users/permissions` (autenticado con el JWT)

No hay secreto compartido. La `api_key` identifica la company y nunca viaja al browser.

## Variables de entorno requeridas en tu app

```bash
IRONIAUTH_URL=https://tu-ironiauth.com
IRONIAUTH_API_KEY=<api_key de tu company>
```

## Guías por lenguaje

| Lenguaje / Framework | Archivo |
|----------------------|---------|
| Ruby on Rails        | [rails.md](rails.md) |
| Python (FastAPI)     | [python.md](python.md) |
| Elixir / Phoenix     | [elixir.md](elixir.md) |
| Go                   | [go.md](go.md) |

## Flujo de una request autenticada

```
Browser → App (tu backend)
              ↓
         Valida JWT con clave pública JWKS (local, sin red)
              ↓
         Si necesita permisos frescos → GET /api/v1/users/permissions
              ↓ (cachear 5 min en sesión)
         Ejecuta lógica de negocio
```
