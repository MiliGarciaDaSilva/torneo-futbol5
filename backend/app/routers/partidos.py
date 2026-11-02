from typing import Literal

from fastapi import APIRouter, Depends, HTTPException

from app.auth import ADMIN, PLANILLERO, get_db, requiere_rol

router = APIRouter(prefix="/partidos", tags=["partidos"])
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


@router.get("/{id_partido}", dependencies=logueados)
def obtener(id_partido: int, db=Depends(get_db)):
  partido = db.uno(SELECT_PARTIDO + " WHERE p.id_partido = %s", (id_partido,))
  if partido is None:
    raise HTTPException(404, "No existe ese partido")
  return partido