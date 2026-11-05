# ABM de jugadores (solo el administrador los modifica; cualquier usuario logueado los puede ver).
from datetime import date
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.auth import ADMIN, PLANILLERO, get_db, requiere_rol

router = APIRouter(prefix="/jugadores", tags=["jugadores"])
solo_admin = [Depends(requiere_rol(ADMIN))]
logueados = [Depends(requiere_rol(ADMIN, PLANILLERO))]

SELECT_JUGADOR = """SELECT j.ci, j.nombre, j.apellido, j.email, j.fecha_nacimiento,
                           j.id_facultad, f.nombre AS facultad, j.tipo
                    FROM jugador j
                    JOIN facultad f ON f.id_facultad = j.id_facultad"""


class DatosJugador(BaseModel):
    """Lo que se puede cambiar de un jugador. La cédula no, porque es la clave primaria."""
    model_config = ConfigDict(str_strip_whitespace=True)

    nombre: str = Field(min_length=1, max_length=50)
    apellido: str = Field(min_length=1, max_length=50)
    email: str = Field(max_length=100, pattern=r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
    fecha_nacimiento: date
    id_facultad: int = Field(gt=0)
    tipo: Literal["grado", "posgrado", "docente", "funcionario"]

    @field_validator("fecha_nacimiento")
    @classmethod
    def no_en_el_futuro(cls, valor):
        if valor > date.today():
            raise ValueError("La fecha de nacimiento no puede ser futura")
        return valor


class JugadorIn(DatosJugador):
    # Cédula uruguaya sin puntos ni guion: 7 u 8 dígitos (la misma regla que el formulario del frontend)
    ci: str = Field(pattern=r"^\d{7,8}$")


@router.get("", dependencies=logueados)
def listar(id_facultad: int | None = None, db=Depends(get_db)):
    if id_facultad is None:
        return db.todos(SELECT_JUGADOR + " ORDER BY j.apellido, j.nombre")
    return db.todos(SELECT_JUGADOR + " WHERE j.id_facultad = %s ORDER BY j.apellido, j.nombre", (id_facultad,))


@router.get("/{ci}", dependencies=logueados)
def obtener(ci: str, db=Depends(get_db)):
    jugador = db.uno(SELECT_JUGADOR + " WHERE j.ci = %s", (ci,))
    if jugador is None:
        raise HTTPException(404, "No existe ese jugador")
    return jugador


@router.post("", status_code=201, dependencies=solo_admin)
def crear(datos: JugadorIn, db=Depends(get_db)):
    # Si la cédula o el correo ya existen, la clave primaria o el UNIQUE devuelven 409
    db.ejecutar(
        """INSERT INTO jugador (ci, nombre, apellido, email, fecha_nacimiento, id_facultad, tipo)
           VALUES (%s, %s, %s, %s, %s, %s, %s)""",
        (datos.ci, datos.nombre, datos.apellido, datos.email, datos.fecha_nacimiento,
         datos.id_facultad, datos.tipo),
    )
    return obtener(datos.ci, db)


@router.put("/{ci}", dependencies=solo_admin)
def modificar(ci: str, datos: DatosJugador, db=Depends(get_db)):
    actual = obtener(ci, db)

    # Si ya está en un plantel, no puede cambiar de facultad: el equipo representa a su facultad
    if datos.id_facultad != actual["id_facultad"]:
        en_plantel = db.uno("SELECT 1 AS si FROM equipo_jugador_torneo WHERE ci_jugador = %s LIMIT 1", (ci,))
        if en_plantel:
            raise HTTPException(409, "El jugador ya integra un plantel, no se puede cambiar su facultad")

    db.ejecutar(
        """UPDATE jugador SET nombre = %s, apellido = %s, email = %s, fecha_nacimiento = %s,
                              id_facultad = %s, tipo = %s
           WHERE ci = %s""",
        (datos.nombre, datos.apellido, datos.email, datos.fecha_nacimiento,
         datos.id_facultad, datos.tipo, ci),
    )
    return obtener(ci, db)


@router.delete("/{ci}", status_code=204, dependencies=solo_admin)
def borrar(ci: str, db=Depends(get_db)):
    # Si integra un plantel o es capitán, la clave foránea no deja borrarlo (409)
    _, filas = db.ejecutar("DELETE FROM jugador WHERE ci = %s", (ci,))
    if filas == 0:
        raise HTTPException(404, "No existe ese jugador")
