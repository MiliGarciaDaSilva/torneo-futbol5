from fastapi import APIRouter, Depends

from app.auth import get_db

# Listas fijas para llenar los desplegables del frontend (cualquier usuario logueado)
router = APIRouter(tags=["catalogos"])


@router.get("/facultades")
def listar_facultades(db=Depends(get_db)):
    return db.todos("SELECT id_facultad, nombre FROM facultad ORDER BY nombre")


@router.get("/turnos")
def listar_turnos(db=Depends(get_db)):
    return db.todos("SELECT id_turno, hora_inicio, hora_fin FROM turno ORDER BY hora_inicio")
