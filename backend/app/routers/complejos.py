# ABM de ejemplo: los demás ABM se arman copiando este archivo.
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, ConfigDict, Field

from app.auth import ADMIN, get_db, requiere_rol

router = APIRouter(prefix="/complejos", tags=["complejos"])
solo_admin = [Depends(requiere_rol(ADMIN))]


class ComplejoIn(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    nombre: str = Field(min_length=1, max_length=100)
    direccion: str = Field(min_length=1, max_length=200)
    departamento: str = Field(min_length=1, max_length=50)


@router.get("")
def listar(db=Depends(get_db)):
    return db.todos("SELECT id_complejo, nombre, direccion, departamento FROM complejo ORDER BY nombre")


@router.get("/{id_complejo}")
def obtener(id_complejo: int, db=Depends(get_db)):
    complejo = db.uno(
        "SELECT id_complejo, nombre, direccion, departamento FROM complejo WHERE id_complejo = %s",
        (id_complejo,),
    )
    if complejo is None:
        raise HTTPException(404, "No existe ese complejo")
    return complejo


@router.post("", status_code=201, dependencies=solo_admin)
def crear(datos: ComplejoIn, db=Depends(get_db)):
    id_nuevo, _ = db.ejecutar(
        "INSERT INTO complejo (nombre, direccion, departamento) VALUES (%s, %s, %s)",
        (datos.nombre, datos.direccion, datos.departamento),
    )
    return {"id_complejo": id_nuevo, **datos.model_dump()}


@router.put("/{id_complejo}", dependencies=solo_admin)
def modificar(id_complejo: int, datos: ComplejoIn, db=Depends(get_db)):
    obtener(id_complejo, db)
    db.ejecutar(
        "UPDATE complejo SET nombre = %s, direccion = %s, departamento = %s WHERE id_complejo = %s",
        (datos.nombre, datos.direccion, datos.departamento, id_complejo),
    )
    return {"id_complejo": id_complejo, **datos.model_dump()}


@router.delete("/{id_complejo}", status_code=204, dependencies=solo_admin)
def borrar(id_complejo: int, db=Depends(get_db)):
    _, filas = db.ejecutar("DELETE FROM complejo WHERE id_complejo = %s", (id_complejo,))
    if filas == 0:
        raise HTTPException(404, "No existe ese complejo")
