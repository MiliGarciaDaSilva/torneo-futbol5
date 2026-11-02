from datetime import date
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, ConfigDict, Field, model_validator

from app.auth import ADMIN, PLANILLERO, get_db, requiere_rol

router = APIRouter(prefix="/torneos", tags=["torneos"])
solo_admin = [Depends(requiere_rol(ADMIN))]
logueados = [Depends(requiere_rol(ADMIN, PLANILLERO))]

SELECT_TORNEO = """SELECT id_torneo, nombre, anio, semestre, fecha_inicio, fecha_fin, estado
                   FROM torneo"""


class TorneoIn(BaseModel):
  model_config = ConfigDict(str_strip_whitespace=True)

  nombre: str = Field(min_length=1, max_length=100)
  anio: int = Field(ge=2000, le=2100)
  semestre: int = Field(ge=1, le=2)
  fecha_inicio: date
  fecha_fin: date

  @model_validator(mode="after")
  def fechas_en_orden(self):
    if self.fecha_fin < self.fecha_inicio:
      raise ValueError("La fecha de fin no puede ser anterior a la de inicio")
    return self


class EstadoTorneoIn(BaseModel):
  estado: Literal["inscripcion", "en curso", "finalizado"]


@router.get("", dependencies=logueados)
def listar(db=Depends(get_db)):
  return db.todos(SELECT_TORNEO + " ORDER BY anio DESC, semestre DESC")


@router.get("/{id_torneo}", dependencies=logueados)
def obtener(id_torneo: int, db=Depends(get_db)):
  torneo = db.uno(SELECT_TORNEO + " WHERE id_torneo = %s", (id_torneo,))
  if torneo is None:
    raise HTTPException(404, "No existe ese torneo")
  return torneo


@router.post("", status_code=201, dependencies=solo_admin)
def crear(datos: TorneoIn, db=Depends(get_db)):
  id_nuevo, _ = db.ejecutar(
    """INSERT INTO torneo (nombre, anio, semestre, fecha_inicio, fecha_fin)
    VALUES (%s, %s, %s, %s, %s)""",
    (datos.nombre, datos.anio, datos.semestre, datos.fecha_inicio, datos.fecha_fin),
  )
  return obtener(id_nuevo, db)


@router.put("/{id_torneo}", dependencies=solo_admin)
def modificar(id_torneo: int, datos: TorneoIn, db=Depends(get_db)):
  obtener(id_torneo, db)
  db.ejecutar(
    """UPDATE torneo SET nombre = %s, anio = %s, semestre = %s, fecha_inicio = %s, fecha_fin = %s
    WHERE id_torneo = %s""",
    (datos.nombre, datos.anio, datos.semestre, datos.fecha_inicio, datos.fecha_fin, id_torneo),
  )
  return obtener(id_torneo, db)


@router.patch("/{id_torneo}/estado", dependencies=solo_admin)
def cambiar_estado(id_torneo: int, datos: EstadoTorneoIn, db=Depends(get_db)):
  obtener(id_torneo, db)
  db.ejecutar("UPDATE torneo SET estado = %s WHERE id_torneo = %s", (datos.estado, id_torneo))
  return obtener(id_torneo, db)


@router.delete("/{id_torneo}", status_code=204, dependencies=solo_admin)
def borrar(id_torneo: int, db=Depends(get_db)):
  _, filas = db.ejecutar("DELETE FROM torneo WHERE id_torneo = %s", (id_torneo,))
  if filas == 0:
    raise HTTPException(404, "No existe ese torneo")