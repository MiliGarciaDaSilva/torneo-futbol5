# ABM de sanciones.
# Hay dos tipos:
#   - automáticas: las crea un trigger al cargar una roja o la tercera amarilla (tienen id_tarjeta).
#     No se borran desde acá: se van solas si se borra la tarjeta que las generó.
#   - manuales: las carga el administrador, por ejemplo una sanción disciplinaria (id_tarjeta es NULL).
# Mientras una sanción está vigente, el trigger de la planilla no deja que el jugador juegue.
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, ConfigDict, Field

from app.auth import ADMIN, PLANILLERO, get_db, requiere_rol

router = APIRouter(prefix="/sanciones", tags=["sanciones"])
solo_admin = [Depends(requiere_rol(ADMIN))]
logueados = [Depends(requiere_rol(ADMIN, PLANILLERO))]

Motivo = Literal["roja", "acumulacion de amarillas", "disciplinaria"]

SELECT_SANCION = """SELECT s.id_sancion, s.ci_jugador, j.nombre, j.apellido, e.nombre AS equipo,
                           s.id_torneo, s.motivo, s.numero_fecha_inicio, s.cantidad_fechas,
                           s.numero_fecha_inicio + s.cantidad_fechas - 1 AS numero_fecha_fin,
                           s.id_tarjeta
                    FROM sancion_jugador s
                    JOIN jugador j ON j.ci = s.ci_jugador
                    JOIN equipo_jugador_torneo ejt ON ejt.id_torneo = s.id_torneo AND ejt.ci_jugador = s.ci_jugador
                    JOIN equipo e ON e.id_equipo = ejt.id_equipo"""


class DatosSancion(BaseModel):
    """Lo que se puede cambiar de una sanción ya cargada."""
    motivo: Motivo = "disciplinaria"
    numero_fecha_inicio: int = Field(ge=1, le=99)
    cantidad_fechas: int = Field(ge=1, le=20)


class SancionIn(DatosSancion):
    model_config = ConfigDict(str_strip_whitespace=True)

    ci_jugador: str = Field(pattern=r"^\d{7,8}$")
    id_torneo: int = Field(gt=0)


@router.get("", dependencies=logueados)
def listar(id_torneo: int | None = None, db=Depends(get_db)):
    if id_torneo is None:
        return db.todos(SELECT_SANCION + " ORDER BY s.id_torneo, s.numero_fecha_inicio, j.apellido")
    return db.todos(SELECT_SANCION + " WHERE s.id_torneo = %s ORDER BY s.numero_fecha_inicio, j.apellido",
                    (id_torneo,))


@router.get("/{id_sancion}", dependencies=logueados)
def obtener(id_sancion: int, db=Depends(get_db)):
    sancion = db.uno(SELECT_SANCION + " WHERE s.id_sancion = %s", (id_sancion,))
    if sancion is None:
        raise HTTPException(404, "No existe esa sanción")
    return sancion


@router.post("", status_code=201, dependencies=solo_admin)
def crear(datos: SancionIn, db=Depends(get_db)):
    # Si el jugador no está en ningún plantel de ese torneo, la clave foránea no deja cargarla
    id_nuevo, _ = db.ejecutar(
        """INSERT INTO sancion_jugador (ci_jugador, id_torneo, motivo, numero_fecha_inicio, cantidad_fechas)
           VALUES (%s, %s, %s, %s, %s)""",
        (datos.ci_jugador, datos.id_torneo, datos.motivo, datos.numero_fecha_inicio, datos.cantidad_fechas),
    )
    return obtener(id_nuevo, db)


@router.put("/{id_sancion}", dependencies=solo_admin)
def modificar(id_sancion: int, datos: DatosSancion, db=Depends(get_db)):
    # Sirve, por ejemplo, para extender una sanción. El jugador y el torneo no se cambian.
    actual = obtener(id_sancion, db)
    if actual["id_tarjeta"] is not None and datos.motivo != actual["motivo"]:
        raise HTTPException(409, "El motivo de una sanción automática no se puede cambiar")
    db.ejecutar(
        "UPDATE sancion_jugador SET motivo = %s, numero_fecha_inicio = %s, cantidad_fechas = %s WHERE id_sancion = %s",
        (datos.motivo, datos.numero_fecha_inicio, datos.cantidad_fechas, id_sancion),
    )
    return obtener(id_sancion, db)


@router.delete("/{id_sancion}", status_code=204, dependencies=solo_admin)
def borrar(id_sancion: int, db=Depends(get_db)):
    sancion = obtener(id_sancion, db)
    if sancion["id_tarjeta"] is not None:
        raise HTTPException(409, "Es una sanción automática: se borra sola si se borra la tarjeta que la generó")
    db.ejecutar("DELETE FROM sancion_jugador WHERE id_sancion = %s", (id_sancion,))
