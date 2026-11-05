# Una ruta para todos los reportes: GET /reportes/{clave}?id_torneo=1
# Cada reporte es una vista de la base (sql/10, 14, 15 y 18). Acá solo se elige la vista,
# se filtra por torneo si corresponde y se ordena.
from fastapi import APIRouter, Depends, HTTPException

from app.auth import ADMIN, get_db, requiere_rol

router = APIRouter(prefix="/reportes", tags=["reportes"], dependencies=[Depends(requiere_rol(ADMIN))])

# clave de la URL: (vista, ¿se filtra por torneo?, orden, límite de filas)
# Los nombres de vista y el orden salen de esta lista fija, nunca de lo que manda el usuario,
# así que no hay forma de meter SQL por la URL.
REPORTES = {
    "posiciones":             ("reporte_posiciones",                True,  "puntos DESC, dg DESC, gf DESC, equipo", None),
    "goleadores":             ("reporte_goleadores",                True,  "goles DESC, apellido",                  10),
    "fair-play":              ("reporte_fair_play",                 True,  "puntos, equipo",                        None),
    "goles-por-fecha":        ("reporte_promedio_goles_por_fecha",  True,  "numero_fecha",                          None),
    "goles-por-edicion":      ("reporte_promedio_goles_por_edicion", False, "anio, semestre",                       None),
    "canchas":                ("reporte_canchas_mas_usadas",        False, "cantidad_partidos DESC, complejo",      None),
    "turnos":                 ("reporte_turnos_mas_usados",         False, "cantidad_partidos DESC, hora_inicio",   None),
    "jugadores-por-facultad": ("reporte_jugadores_por_facultad",    False, "cantidad_jugadores DESC, facultad",     None),
    "jugadores-por-tipo":     ("reporte_jugadores_por_tipo",        False, "cantidad_jugadores DESC",               None),
    "nunca-en-planilla":      ("reporte_nunca_en_planilla",         True,  "equipo, apellido",                      None),
    "sanciones-por-equipo":   ("reporte_sanciones_por_equipo",      True,  "cantidad_sanciones DESC, equipo",       None),
    "sanciones-por-motivo":   ("reporte_sanciones_por_motivo",      True,  "cantidad_sanciones DESC",               None),
    "estados":                ("reporte_porcentaje_estados",        True,  "cantidad DESC",                         None),
    # Las 3 consultas propias (sql/18_reportes_extra.sql)
    "suspendidos":            ("reporte_suspendidos",               True,  "equipo, apellido",                      None),
    "partidos-mas-goles":     ("reporte_partidos_mas_goles",        True,  "total_goles DESC, numero_fecha",        10),
    "local-vs-visitante":     ("reporte_local_vs_visitante",        True,  "condicion",                             None),
}


@router.get("")
def listar_reportes():
    """Las claves disponibles, y cuáles necesitan id_torneo."""
    return [{"clave": clave, "por_torneo": por_torneo} for clave, (_, por_torneo, _, _) in REPORTES.items()]


@router.get("/{clave}")
def ver_reporte(clave: str, id_torneo: int | None = None, db=Depends(get_db)):
    if clave not in REPORTES:
        raise HTTPException(404, "No existe ese reporte")
    vista, por_torneo, orden, limite = REPORTES[clave]

    sql = f"SELECT * FROM {vista}"
    params = []
    if por_torneo:
        if id_torneo is None:
            raise HTTPException(400, "Este reporte necesita el torneo: agregá ?id_torneo=")
        sql += " WHERE id_torneo = %s"
        params.append(id_torneo)
    sql += f" ORDER BY {orden}"
    if limite:
        sql += f" LIMIT {limite}"
    return db.todos(sql, params)
