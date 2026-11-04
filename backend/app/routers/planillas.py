from typing import Literal

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, ConfigDict, Field

from app.auth import ADMIN, PLANILLERO, get_db, requiere_rol
from app.routers.partidos import obtener

router = APIRouter(prefix="/partidos", tags=["planillas"])
logueados = [Depends(requiere_rol(ADMIN, PLANILLERO))]

# Las reglas (partido jugado, jugador suspendido, solo jugadores de la planilla, 48 horas) las revisan
# los triggers de la base; si alguna falla, errores.py devuelve el mensaje del trigger con un 400.


class PlanillaIn(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    ci_jugador: str = Field(min_length=1, max_length=15)


class GolIn(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    ci_jugador: str = Field(min_length=1, max_length=15)
    minuto: int = Field(ge=1, le=60)
    autogol: bool = False


class TarjetaIn(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    ci_jugador: str = Field(min_length=1, max_length=15)
    minuto: int = Field(ge=1, le=60)
    color: Literal["amarilla", "roja"]


@router.get("/{id_partido}/planilla", dependencies=logueados)
def ver_planilla(id_partido: int, db=Depends(get_db)):
    """Todo lo que necesita la pantalla del planillero: los dos planteles, quién está suspendido,
    quién ya está en la planilla y los goles y tarjetas cargados."""
    partido = obtener(id_partido, db)

    # Misma cuenta que usa el trigger de la base: suspendido si la fecha del partido cae dentro de una sanción
    jugadores = db.todos(
        """SELECT ejt.id_equipo, j.ci, j.nombre, j.apellido, ejt.numero_camiseta,
                  (e.ci_capitan = j.ci) AS es_capitan,
                  EXISTS (SELECT 1 FROM sancion_jugador s
                          WHERE s.ci_jugador = j.ci AND s.id_torneo = %s
                            AND %s BETWEEN s.numero_fecha_inicio AND s.numero_fecha_inicio + s.cantidad_fechas - 1) AS suspendido,
                  EXISTS (SELECT 1 FROM planilla_partido pp
                          WHERE pp.id_partido = %s AND pp.ci_jugador = j.ci) AS en_planilla
           FROM equipo_jugador_torneo ejt
           JOIN jugador j ON j.ci = ejt.ci_jugador
           JOIN equipo e ON e.id_equipo = ejt.id_equipo
           WHERE ejt.id_equipo IN (%s, %s)
           ORDER BY ejt.id_equipo, ejt.numero_camiseta""",
        (partido["id_torneo"], partido["numero_fecha"], id_partido,
         partido["id_equipo_local"], partido["id_equipo_visitante"]),
    )
    for jugador in jugadores:
        for campo in ("es_capitan", "suspendido", "en_planilla"):
            jugador[campo] = bool(jugador[campo])

    equipos = [
        {"id_equipo": partido["id_equipo_local"], "nombre": partido["equipo_local"], "jugadores": []},
        {"id_equipo": partido["id_equipo_visitante"], "nombre": partido["equipo_visitante"], "jugadores": []},
    ]
    for jugador in jugadores:
        for equipo in equipos:
            if equipo["id_equipo"] == jugador["id_equipo"]:
                equipo["jugadores"].append(jugador)

    goles = db.todos(
        """SELECT g.id_gol, g.ci_jugador, j.nombre, j.apellido, pp.id_equipo, g.minuto, g.autogol
           FROM gol g
           JOIN planilla_partido pp ON pp.id_partido = g.id_partido AND pp.ci_jugador = g.ci_jugador
           JOIN jugador j ON j.ci = g.ci_jugador
           WHERE g.id_partido = %s
           ORDER BY g.minuto""",
        (id_partido,),
    )
    for gol in goles:
        gol["autogol"] = bool(gol["autogol"])

    tarjetas = db.todos(
        """SELECT t.id_tarjeta, t.ci_jugador, j.nombre, j.apellido, pp.id_equipo, t.minuto, t.color
           FROM tarjeta t
           JOIN planilla_partido pp ON pp.id_partido = t.id_partido AND pp.ci_jugador = t.ci_jugador
           JOIN jugador j ON j.ci = t.ci_jugador
           WHERE t.id_partido = %s
           ORDER BY t.minuto""",
        (id_partido,),
    )

    # Solo se puede cargar o corregir la planilla de un partido jugado y hasta 48 horas después del turno
    dentro_de_48h = db.uno(
        """SELECT TIMESTAMP(p.dia, t.hora_fin) + INTERVAL 48 HOUR >= NOW() AS vigente
           FROM partido p JOIN turno t ON t.id_turno = p.id_turno
           WHERE p.id_partido = %s""",
        (id_partido,),
    )["vigente"]

    return {
        "partido": partido,
        "se_puede_editar": partido["estado"] == "jugado" and bool(dentro_de_48h),
        "equipos": equipos,
        "goles": goles,
        "tarjetas": tarjetas,
    }


@router.post("/{id_partido}/planilla", status_code=201, dependencies=logueados)
def cargar_planilla(id_partido: int, datos: PlanillaIn, db=Depends(get_db)):
    partido = obtener(id_partido, db)

    # El equipo del jugador sale de su plantel: tiene que ser el local o el visitante
    jugador = db.uno(
        "SELECT id_equipo FROM equipo_jugador_torneo WHERE ci_jugador = %s AND id_equipo IN (%s, %s)",
        (datos.ci_jugador, partido["id_equipo_local"], partido["id_equipo_visitante"]),
    )
    if jugador is None:
        raise HTTPException(400, "Ese jugador no es del plantel de ninguno de los dos equipos")

    db.ejecutar(
        "INSERT INTO planilla_partido (id_partido, ci_jugador, id_equipo) VALUES (%s, %s, %s)",
        (id_partido, datos.ci_jugador, jugador["id_equipo"]),
    )
    return {"id_partido": id_partido, "ci_jugador": datos.ci_jugador, "id_equipo": jugador["id_equipo"]}


@router.delete("/{id_partido}/planilla/{ci_jugador}", status_code=204, dependencies=logueados)
def quitar_de_planilla(id_partido: int, ci_jugador: str, db=Depends(get_db)):
    _, filas = db.ejecutar(
        "DELETE FROM planilla_partido WHERE id_partido = %s AND ci_jugador = %s",
        (id_partido, ci_jugador),
    )
    if filas == 0:
        raise HTTPException(404, "Ese jugador no está en la planilla de este partido")


@router.post("/{id_partido}/goles", status_code=201, dependencies=logueados)
def cargar_gol(id_partido: int, datos: GolIn, db=Depends(get_db)):
    id_gol, _ = db.ejecutar(
        "INSERT INTO gol (id_partido, ci_jugador, minuto, autogol) VALUES (%s, %s, %s, %s)",
        (id_partido, datos.ci_jugador, datos.minuto, datos.autogol),
    )
    return {"id_gol": id_gol, "id_partido": id_partido, **datos.model_dump()}


@router.delete("/{id_partido}/goles/{id_gol}", status_code=204, dependencies=logueados)
def borrar_gol(id_partido: int, id_gol: int, db=Depends(get_db)):
    _, filas = db.ejecutar("DELETE FROM gol WHERE id_gol = %s AND id_partido = %s", (id_gol, id_partido))
    if filas == 0:
        raise HTTPException(404, "No existe ese gol en este partido")


@router.post("/{id_partido}/tarjetas", status_code=201, dependencies=logueados)
def cargar_tarjeta(id_partido: int, datos: TarjetaIn, db=Depends(get_db)):
    # La sanción (roja o 3 amarillas) la crea sola un trigger de la base
    id_tarjeta, _ = db.ejecutar(
        "INSERT INTO tarjeta (id_partido, ci_jugador, minuto, color) VALUES (%s, %s, %s, %s)",
        (id_partido, datos.ci_jugador, datos.minuto, datos.color),
    )
    return {"id_tarjeta": id_tarjeta, "id_partido": id_partido, **datos.model_dump()}


@router.delete("/{id_partido}/tarjetas/{id_tarjeta}", status_code=204, dependencies=logueados)
def borrar_tarjeta(id_partido: int, id_tarjeta: int, db=Depends(get_db)):
    # Si la tarjeta generó una sanción, la base la borra junto con la tarjeta (ON DELETE CASCADE)
    _, filas = db.ejecutar(
        "DELETE FROM tarjeta WHERE id_tarjeta = %s AND id_partido = %s",
        (id_tarjeta, id_partido),
    )
    if filas == 0:
        raise HTTPException(404, "No existe esa tarjeta en este partido")
