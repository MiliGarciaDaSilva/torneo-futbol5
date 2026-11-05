# ABM de canchas. La clave primaria es compuesta (nombre_cancha + id_complejo),
# por eso en las rutas una cancha se identifica con las dos cosas: /canchas/{id_complejo}/{nombre_cancha}
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, ConfigDict, Field

from app.auth import ADMIN, PLANILLERO, get_db, requiere_rol

router = APIRouter(prefix="/canchas", tags=["canchas"])
solo_admin = [Depends(requiere_rol(ADMIN))]
logueados = [Depends(requiere_rol(ADMIN, PLANILLERO))]

SELECT_CANCHA = """SELECT ca.nombre_cancha, ca.id_complejo, co.nombre AS complejo, ca.superficie, ca.techada
                   FROM cancha ca
                   JOIN complejo co ON co.id_complejo = ca.id_complejo"""


class CanchaIn(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    nombre_cancha: str = Field(min_length=1, max_length=50)
    id_complejo: int = Field(gt=0)
    superficie: Literal["sintetico", "parquet"]
    techada: bool = False


def _a_bool(cancha):
    cancha["techada"] = bool(cancha["techada"])  # MySQL devuelve 0 o 1
    return cancha


@router.get("", dependencies=logueados)
def listar(id_complejo: int | None = None, db=Depends(get_db)):
    if id_complejo is None:
        filas = db.todos(SELECT_CANCHA + " ORDER BY co.nombre, ca.nombre_cancha")
    else:
        filas = db.todos(SELECT_CANCHA + " WHERE ca.id_complejo = %s ORDER BY ca.nombre_cancha", (id_complejo,))
    return [_a_bool(c) for c in filas]


@router.get("/{id_complejo}/{nombre_cancha}", dependencies=logueados)
def obtener(id_complejo: int, nombre_cancha: str, db=Depends(get_db)):
    cancha = db.uno(SELECT_CANCHA + " WHERE ca.id_complejo = %s AND ca.nombre_cancha = %s",
                    (id_complejo, nombre_cancha))
    if cancha is None:
        raise HTTPException(404, "No existe esa cancha")
    return _a_bool(cancha)


@router.post("", status_code=201, dependencies=solo_admin)
def crear(datos: CanchaIn, db=Depends(get_db)):
    # Si ya hay una cancha con ese nombre en ese complejo, la clave primaria devuelve 409
    db.ejecutar(
        "INSERT INTO cancha (nombre_cancha, id_complejo, superficie, techada) VALUES (%s, %s, %s, %s)",
        (datos.nombre_cancha, datos.id_complejo, datos.superficie, datos.techada),
    )
    return obtener(datos.id_complejo, datos.nombre_cancha, db)


@router.put("/{id_complejo}/{nombre_cancha}", dependencies=solo_admin)
def modificar(id_complejo: int, nombre_cancha: str, datos: CanchaIn, db=Depends(get_db)):
    obtener(id_complejo, nombre_cancha, db)
    # Cambiar el nombre o el complejo cambia la clave: si la cancha ya tiene partidos,
    # la clave foránea de partido no lo deja (409)
    db.ejecutar(
        """UPDATE cancha SET nombre_cancha = %s, id_complejo = %s, superficie = %s, techada = %s
           WHERE id_complejo = %s AND nombre_cancha = %s""",
        (datos.nombre_cancha, datos.id_complejo, datos.superficie, datos.techada, id_complejo, nombre_cancha),
    )
    return obtener(datos.id_complejo, datos.nombre_cancha, db)


@router.delete("/{id_complejo}/{nombre_cancha}", status_code=204, dependencies=solo_admin)
def borrar(id_complejo: int, nombre_cancha: str, db=Depends(get_db)):
    _, filas = db.ejecutar("DELETE FROM cancha WHERE id_complejo = %s AND nombre_cancha = %s",
                           (id_complejo, nombre_cancha))
    if filas == 0:
        raise HTTPException(404, "No existe esa cancha")
