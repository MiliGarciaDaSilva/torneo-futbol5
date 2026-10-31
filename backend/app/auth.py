from datetime import datetime, timedelta, timezone

import jwt
from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel, ConfigDict, Field

from app import config
from app.db import conectar

router = APIRouter(prefix="/auth", tags=["auth"])
_bearer = HTTPBearer(auto_error=False)

ADMIN = "administrador"
PLANILLERO = "planillero"


class LoginIn(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    correo: str = Field(max_length=100, pattern=r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
    contrasena: str = Field(min_length=1, max_length=100)


@router.post("/login")
def login(datos: LoginIn):
    db = conectar("login")
    try:
        usuario = db.uno(
            "SELECT correo, rol FROM login WHERE correo = %s AND contrasena = SHA2(%s, 256)",
            (datos.correo, datos.contrasena),
        )
    finally:
        db.cerrar()

    if usuario is None:
        raise HTTPException(401, "Correo o contraseña incorrectos")

    vence = datetime.now(timezone.utc) + timedelta(hours=config.JWT_HORAS)
    token = jwt.encode({"sub": usuario["correo"], "rol": usuario["rol"], "exp": vence}, config.JWT_SECRET, algorithm="HS256")
    return {"token": token, "correo": usuario["correo"], "rol": usuario["rol"]}


def usuario_actual(credenciales: HTTPAuthorizationCredentials | None = Depends(_bearer)):
    if credenciales is None:
        raise HTTPException(401, "Falta iniciar sesión")
    try:
        datos = jwt.decode(credenciales.credentials, config.JWT_SECRET, algorithms=["HS256"])
    except jwt.PyJWTError:
        raise HTTPException(401, "La sesión venció o no es válida")
    return {"correo": datos["sub"], "rol": datos["rol"]}


def requiere_rol(*roles):
    """Uso: dependencies=[Depends(requiere_rol(ADMIN))] en la ruta o en el router."""

    def verificar(usuario=Depends(usuario_actual)):
        if usuario["rol"] not in roles:
            raise HTTPException(403, "Tu usuario no tiene permiso para esto")
        return usuario

    return verificar


def get_db(usuario=Depends(usuario_actual)):
    """Conexión a la base con el usuario de MySQL del rol logueado. Se cierra sola al terminar el pedido."""
    db = conectar(usuario["rol"])
    try:
        yield db
    finally:
        db.cerrar()


@router.get("/yo")
def yo(usuario=Depends(usuario_actual)):
    return usuario
