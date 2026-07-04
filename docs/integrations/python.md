# Integración con Python (FastAPI)

## Dependencias

```bash
pip install PyJWT[crypto] requests fastapi
```

```toml
# pyproject.toml
[tool.poetry.dependencies]
PyJWT = {version = "^2.8", extras = ["crypto"]}
requests = "^2.31"
fastapi = "^0.111"
```

## Variables de entorno

```bash
IRONIAUTH_URL=https://tu-ironiauth.com
IRONIAUTH_API_KEY=<api_key de tu company>
```

## Cliente HTTP

```python
# services/ironiauth_client.py
import os
import time
import requests
from jwt.algorithms import RSAAlgorithm

IRONIAUTH_URL = os.environ["IRONIAUTH_URL"]
API_KEY = os.environ["IRONIAUTH_API_KEY"]

_rsa_public_key = None  # caché por proceso


def get_rsa_public_key():
    """Obtiene la clave pública RSA desde JWKS y la cachea."""
    global _rsa_public_key
    if _rsa_public_key is None:
        resp = requests.get(f"{IRONIAUTH_URL}/.well-known/jwks.json")
        resp.raise_for_status()
        jwk = resp.json()["keys"][0]
        _rsa_public_key = RSAAlgorithm.from_jwk(jwk)
    return _rsa_public_key


def sign_in(email: str, password: str) -> dict:
    resp = requests.post(
        f"{IRONIAUTH_URL}/api/v1/sign_in",
        json={"email": email, "password": password},
        headers={"Authorization": f"Bearer {API_KEY}"},
    )
    return resp.json()


def sign_up(username: str, email: str, password: str, password_confirmation: str) -> dict:
    resp = requests.post(
        f"{IRONIAUTH_URL}/api/v1/sign_up",
        json={"user": {
            "username": username,
            "email": email,
            "password": password,
            "password_confirmation": password_confirmation,
        }},
        headers={"Authorization": f"Bearer {API_KEY}"},
    )
    return resp.json()


def fetch_permissions(jwt: str) -> list[str]:
    resp = requests.get(
        f"{IRONIAUTH_URL}/api/v1/users/permissions",
        headers={"Authorization": f"Bearer {jwt}"},
    )
    return resp.json().get("permissions", [])
```

## Dependencias FastAPI

```python
# dependencies/auth.py
import jwt
import time
from fastapi import Depends, HTTPException, Request
from services.ironiauth_client import get_rsa_public_key, fetch_permissions

PERMISSIONS_TTL = 300  # 5 minutos


def decode_jwt(token: str) -> dict:
    """Valida el JWT con la clave pública RS256."""
    try:
        return jwt.decode(token, get_rsa_public_key(), algorithms=["RS256"])
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expirado")
    except jwt.DecodeError:
        raise HTTPException(status_code=401, detail="Token inválido")


def get_current_user(request: Request) -> dict:
    """Extrae y valida el JWT del header Authorization."""
    auth = request.headers.get("Authorization", "")
    if not auth.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="No autenticado")
    token = auth.removeprefix("Bearer ")
    return {"token": token, "claims": decode_jwt(token)}


def get_permissions(current_user: dict = Depends(get_current_user)) -> list[str]:
    """
    Obtiene los permisos del usuario. En producción cachear en Redis o en la sesión.
    """
    return fetch_permissions(current_user["token"])
```

## Uso en endpoints

```python
# routers/cars.py
from fastapi import APIRouter, Depends, HTTPException
from dependencies.auth import get_current_user, get_permissions

router = APIRouter(prefix="/cars")


def require(permission: str):
    """Guard de permiso como dependencia de FastAPI."""
    def _check(permissions: list[str] = Depends(get_permissions)):
        if permission not in permissions:
            raise HTTPException(status_code=403, detail=f"Permiso requerido: {permission}")
    return Depends(_check)


@router.post("/", dependencies=[require("car#create")])
def create_car(current_user: dict = Depends(get_current_user)):
    return {"msg": "auto creado"}


@router.put("/{car_id}", dependencies=[require("car#update")])
def update_car(car_id: int):
    return {"msg": f"auto {car_id} actualizado"}


@router.delete("/{car_id}", dependencies=[require("car#destroy")])
def delete_car(car_id: int):
    return {"msg": f"auto {car_id} eliminado"}
```

## Registro e inicio de sesión

```python
# routers/sessions.py
from fastapi import APIRouter, Response
from services.ironiauth_client import sign_in, sign_up

router = APIRouter()


@router.post("/sign_in")
def login(email: str, password: str, response: Response):
    result = sign_in(email=email, password=password)
    if "jwt" not in result:
        response.status_code = 401
        return {"error": "Credenciales inválidas"}
    return {"jwt": result["jwt"]}


@router.post("/sign_up")
def register(username: str, email: str, password: str, password_confirmation: str):
    result = sign_up(
        username=username,
        email=email,
        password=password,
        password_confirmation=password_confirmation,
    )
    return result
```
