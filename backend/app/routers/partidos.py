<<<<<<< HEAD
from datetime import date
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, ConfigDict, Field
=======
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException
>>>>>>> 923de59

from app.auth import ADMIN, PLANILLERO, get_db, requiere_rol

router = APIRouter(prefix="/partidos", tags=["partidos"])
<<<<<<< HEAD
solo_admin = [Depends(requiere_rol(ADMIN))]
logueados = [Depends(requiere_rol(ADMIN, PLANILLERO))]

# Las reglas (5 jugadores, rival repetido, cancha ocupada, etc.) las revisan los triggers de la base;
# si alguna falla, errores.py devuelve el mensaje del trigger con un 400.

SELECT_PARTIDO = """SELECT p.id_partido, p.id_torneo, p.numero_fecha,
                           p.id_equipo_local, el.nombre AS equipo_local,
                           p.id_equipo_visitante, ev.nombre AS equipo_visitante,
                           p.dia, p.id_turno, t.hora_inicio, t.hora_fin,
                           p.nombre_cancha, p.id_complejo, c.nombre AS complejo, p.estado
                    FROM partido p
                    JOIN equipo el ON el.id_equipo = p.id_equipo_local
                    JOIN equipo ev ON ev.id_equipo = p.id_equipo_visitante
                    JOIN turno t ON t.id_turno = p.id_turno
                    JOIN complejo c ON c.id_complejo = p.id_complejo"""


class PartidoIn(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    id_torneo: int
    numero_fecha: int = Field(ge=1)
    id_equipo_local: int
    id_equipo_visitante: int
    dia: date
    id_turno: int
    nombre_cancha: str = Field(min_length=1, max_length=50)
    id_complejo: int


class EstadoIn(BaseModel):
    estado: Literal["programado", "jugado", "postergado", "cancelado"]


@router.get("", dependencies=logueados)
def listar(id_torneo: int | None = None, estado: str | None = None, numero_fecha: int | None = None,
           db=Depends(get_db)):
    # Los filtros son opcionales: solo se agregan al WHERE los que vienen en la URL
    condiciones = []
    params = []
    if id_torneo is not None:
        condiciones.append("p.id_torneo = %s")
        params.append(id_torneo)
    if estado is not None:
        condiciones.append("p.estado = %s")
        params.append(estado)
    if numero_fecha is not None:
        condiciones.append("p.numero_fecha = %s")
        params.append(numero_fecha)

    sql = SELECT_PARTIDO
    if condiciones:
        sql += " WHERE " + " AND ".join(condiciones)
    sql += " ORDER BY p.numero_fecha, p.dia, t.hora_inicio"
    return db.todos(sql, tuple(params))
=======
logueados = [Depends(requiere_rol(ADMIN, PLANILLERO))]

Estado = Literal["programado", "jugado", "postergado", "cancelado"]

SELECT_PARTIDO = """
SELECT p.id_partido, p.id_torneo, p.numero_fecha,
       p.id_equipo_local, el.nombre AS equipo_local,
       p.id_equipo_visitante, ev.nombre AS equipo_visitante,
       p.dia, p.id_turno, t.hora_inicio, t.hora_fin,
       p.nombre_cancha, p.id_complejo, c.nombre AS complejo,
       p.estado
FROM partido p
JOIN equipo el  ON el.id_equipo = p.id_equipo_local
JOIN equipo ev  ON ev.id_equipo = p.id_equipo_visitante
JOIN turno t    ON t.id_turno = p.id_turno
JOIN complejo c ON c.id_complejo = p.id_complejo
"""


@router.get("", dependencies=logueados)
def listar(
  id_torneo: int | None = None,
  numero_fecha: int | None = None,
  estado: Estado | None = None,
  db=Depends(get_db),
):
  condiciones = []
  params = []
  if id_torneo is not None:
    condiciones.append("p.id_torneo = %s")
    params.append(id_torneo)
  if numero_fecha is not None:
    condiciones.append("p.numero_fecha = %s")
    params.append(numero_fecha)
  if estado is not None:
    condiciones.append("p.estado = %s")
    params.append(estado)

  sql = SELECT_PARTIDO
  if condiciones:
    sql += " WHERE " + " AND ".join(condiciones)
  sql += " ORDER BY p.numero_fecha, p.dia, t.hora_inicio"
  return db.todos(sql, params)
>>>>>>> 923de59


@router.get("/{id_partido}", dependencies=logueados)
def obtener(id_partido: int, db=Depends(get_db)):
<<<<<<< HEAD
    partido = db.uno(SELECT_PARTIDO + " WHERE p.id_partido = %s", (id_partido,))
    if partido is None:
        raise HTTPException(404, "No existe ese partido")
    return partido


@router.post("", status_code=201, dependencies=solo_admin)
def crear(datos: PartidoIn, db=Depends(get_db)):
    # El estado arranca en 'programado' (es el DEFAULT de la tabla)
    id_nuevo, _ = db.ejecutar(
        """INSERT INTO partido (id_torneo, numero_fecha, id_equipo_local, id_equipo_visitante,
                                dia, id_turno, nombre_cancha, id_complejo)
           VALUES (%s, %s, %s, %s, %s, %s, %s, %s)""",
        (datos.id_torneo, datos.numero_fecha, datos.id_equipo_local, datos.id_equipo_visitante,
         datos.dia, datos.id_turno, datos.nombre_cancha, datos.id_complejo),
    )
    return obtener(id_nuevo, db)


@router.put("/{id_partido}", dependencies=solo_admin)
def modificar(id_partido: int, datos: PartidoIn, db=Depends(get_db)):
    obtener(id_partido, db)
    db.ejecutar(
        """UPDATE partido SET id_torneo = %s, numero_fecha = %s, id_equipo_local = %s, id_equipo_visitante = %s,
                              dia = %s, id_turno = %s, nombre_cancha = %s, id_complejo = %s
           WHERE id_partido = %s""",
        (datos.id_torneo, datos.numero_fecha, datos.id_equipo_local, datos.id_equipo_visitante,
         datos.dia, datos.id_turno, datos.nombre_cancha, datos.id_complejo, id_partido),
    )
    return obtener(id_partido, db)


@router.patch("/{id_partido}/estado", dependencies=solo_admin)
def cambiar_estado(id_partido: int, datos: EstadoIn, db=Depends(get_db)):
    obtener(id_partido, db)
    db.ejecutar("UPDATE partido SET estado = %s WHERE id_partido = %s", (datos.estado, id_partido))
    return obtener(id_partido, db)


@router.delete("/{id_partido}", status_code=204, dependencies=solo_admin)
def borrar(id_partido: int, db=Depends(get_db)):
    _, filas = db.ejecutar("DELETE FROM partido WHERE id_partido = %s", (id_partido,))
    if filas == 0:
        raise HTTPException(404, "No existe ese partido")
=======
  partido = db.uno(SELECT_PARTIDO + " WHERE p.id_partido = %s", (id_partido,))
  if partido is None:
    raise HTTPException(404, "No existe ese partido")
  return partido
>>>>>>> 923de59
