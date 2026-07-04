# API Reference

Base URL: `http://localhost:4000` (dev) / tu dominio en producción.

Todos los endpoints JSON requieren `Content-Type: application/json`.

---

## Públicos (sin autenticación)

### `GET /`
```json
// Response 200
{ "message": "Ironiauth API" }
```

### `GET /.well-known/jwks.json`
Clave pública RSA para verificar JWTs localmente. Las apps cliente la cachean al inicio.
```json
// Response 200
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

### `PUT /api/v1/reset_password/:token`
```json
// Request
{ "user": { "password": "nueva123", "password_confirmation": "nueva123" } }

// Response 200
{ "message": "Password updated successfully" }

// Response 422 — token expirado
{ "error": "Reset token has expired" }
```

---

## Autenticados con api_key

Llamados **desde el backend de la app cliente**, nunca desde el browser.

Header requerido: `Authorization: Bearer <api_key>`

### `POST /api/v1/sign_up`
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
{ "jwt": "eyJhbGci..." }

// Response 422
{ "errors": { "email": ["has already been taken"] } }
```

### `POST /api/v1/sign_in`
```json
// Request
{ "email": "juanito@opencar.com", "password": "password123" }

// Response 200
{ "jwt": "eyJhbGci..." }

// Response 401
{ "error": "Login error" }
```

### `POST /api/v1/forgot_password`
```json
// Request
{ "user": { "email": "juanito@opencar.com" } }

// Response 200
{ "message": "If the email exists, a reset link was sent" }
```

---

## Autenticados con JWT

Header requerido: `Authorization: Bearer <jwt>`

### `DELETE /api/v1/sign_out`
```json
// Response 200
{ "msg": "logout successfully" }
```

### `GET /api/v1/refresh_token`
```json
// Response 200
{ "jwt": "eyJhbGci..." }
```

### `GET /api/v1/users/me`
```json
// Response 200
{ "id": 1, "email": "admin@opencar.com", "roles": ["admin"] }
```

### `GET /api/v1/users/permissions`
Consulta la DB en tiempo real — retorna los permisos del usuario en la company del JWT.
```json
// Response 200
{ "data": ["car#create", "car#update", "car#destroy"] }
```

### `GET /api/v1/users` _(solo admin)_
```json
// Response 200
{
  "data": [
    { "uuid": "48de5033-...", "username": "admin", "email": "admin@opencar.com" }
  ],
  "meta": { "page_number": 1, "per_page": 10, "total_pages": 1, "total_elements": 1 }
}
```

### `GET /api/v1/users/:id` _(solo admin)_
```json
// Response 200
{ "data": { "uuid": "48de5033-...", "username": "admin", "email": "admin@opencar.com" } }

// Response 404
{ "error": "User not found" }
```

### `PUT /api/v1/users/:id` _(solo el propio usuario)_
```json
// Request
{ "user": { "username": "nuevo_nombre" } }

// Response 200
{ "data": { "uuid": "48de5033-...", "username": "nuevo_nombre", "email": "admin@opencar.com" } }

// Response 403
{ "error": "Operation not permitted" }
```

### `DELETE /api/v1/users/:id` _(solo admin)_
```
// Response 204 — sin cuerpo
```

---

### `GET /api/v1/companies` _(solo superadmin)_
```json
// Response 200
{
  "data": [{ "id": 1, "name": "open_car", "domain": "opencar.com" }],
  "meta": { "page_number": 1, "per_page": 10, "total_pages": 1, "total_elements": 1 }
}
```

### `POST /api/v1/companies` _(solo superadmin)_
El `api_key` se genera automáticamente.
```json
// Request
{ "company": { "name": "libro_app", "domain": "libroapp.com" } }

// Response 201
{ "data": { "id": 2, "name": "libro_app", "domain": "libroapp.com" } }
```

### `GET /api/v1/companies/:id` _(solo superadmin)_
```json
// Response 200
{ "data": { "id": 1, "name": "open_car", "domain": "opencar.com" } }
```

### `PUT /api/v1/companies/:id` _(solo superadmin)_
```json
// Request
{ "company": { "name": "open_car_v2" } }

// Response 200
{ "data": { "id": 1, "name": "open_car_v2", "domain": "opencar.com" } }
```

### `DELETE /api/v1/companies/:id` _(solo superadmin)_
```
// Response 204 — sin cuerpo
// Response 403
{ "error": "Superadmin access required" }
```

---

### `GET /api/v1/company_permissions` _(solo admin)_
```json
// Response 200
{
  "data": [
    { "id": 1, "name": "car#create", "description": "Crear autos" }
  ],
  "meta": { "page_number": 1, "per_page": 10, "total_pages": 1, "total_elements": 1 }
}
```

### `POST /api/v1/company_permissions` _(solo admin)_
```json
// Request
{ "permission": { "name": "car#create", "description": "Crear autos" } }

// Response 201
{ "data": { "id": 1, "name": "car#create", "description": "Crear autos" } }

// Response 422
{ "errors": { "name": ["has already been taken"] } }
```

### `PUT /api/v1/company_permissions/:id` _(solo admin)_
```json
// Request
{ "permission": { "description": "Permite crear un auto nuevo" } }

// Response 200
{ "data": { "id": 1, "name": "car#create", "description": "Permite crear un auto nuevo" } }
```

### `DELETE /api/v1/company_permissions/:id` _(solo admin)_
```
// Response 204 — sin cuerpo
```

---

### `GET /api/v1/groups` _(solo admin)_
```json
// Response 200
{ "data": [{ "id": 1, "uuid": "16373d9b-...", "name": "admins" }] }
```

### `POST /api/v1/groups` _(solo admin)_
```json
// Request
{ "group": { "name": "editores" } }

// Response 201
{ "data": { "id": 2, "uuid": "abc123-...", "name": "editores" } }
```

### `DELETE /api/v1/groups/:id` _(solo admin)_
```
// Response 204 — sin cuerpo
```

### `POST /api/v1/groups/:group_id/permissions/:permission_id` _(solo admin)_
```
// Response 204 — sin cuerpo
// Response 422 — ya existe
{ "errors": { "group_id": ["has already been taken"] } }
```

### `DELETE /api/v1/groups/:group_id/permissions/:permission_id` _(solo admin)_
```
// Response 204 — sin cuerpo
```

### `POST /api/v1/groups/:group_id/users/:user_id` _(solo admin)_
```
// Response 204 — sin cuerpo
// Response 422 — ya existe
{ "errors": { "user_id": ["has already been taken"] } }
```

### `DELETE /api/v1/groups/:group_id/users/:user_id` _(solo admin)_
```
// Response 204 — sin cuerpo
```

---

## Errores globales

| Status | Cuándo ocurre |
|--------|---------------|
| `401`  | JWT inválido o expirado |
| `403`  | Sin permisos para la operación |
| `404`  | Recurso no encontrado o ruta no definida |
| `422`  | Validación fallida |
