from fastapi import APIRouter, Depends

from app.auth import ADMIN, PLANILLERO, get_db, requiere_rol
from app.routers.partidos import obtener

router = APIRouter(prefix="/partidos", tags=["planillas"])
logueados = [Depends(requiere_rol(ADMIN, PLANILLERO))]


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
