# ABM de equipos y de sus planteles.
# Las reglas las controlan los triggers de sql/09_triggers_plantel.sql:
#   - equipos y planteles solo se modifican mientras el torneo está en inscripción
#   - el capitán y todos los jugadores tienen que ser de la facultad del equipo
#   - máximo 10 jugadores y máximo 2 docentes o funcionarios por plantel
#   - un equipo no cambia de facultad, y el capitán tiene que estar en el plantel
# Y las restricciones de la tabla: un jugador en un solo equipo por edición, camisetas sin repetir.
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, ConfigDict, Field

from app.auth import ADMIN, PLANILLERO, get_db, requiere_rol

router = APIRouter(prefix="/equipos", tags=["equipos"])
solo_admin = [Depends(requiere_rol(ADMIN))]
logueados = [Depends(requiere_rol(ADMIN, PLANILLERO))]

SELECT_EQUIPO = """SELECT e.id_equipo, e.nombre, e.id_torneo, t.nombre AS torneo,
                          e.id_facultad, f.nombre AS facultad,
                          e.ci_capitan, CONCAT(c.nombre, ' ', c.apellido) AS capitan,
                          (SELECT COUNT(*) FROM equipo_jugador_torneo ejt
                           WHERE ejt.id_equipo = e.id_equipo) AS cantidad_jugadores
                   FROM equipo e
                   JOIN torneo t   ON t.id_torneo = e.id_torneo
                   JOIN facultad f ON f.id_facultad = e.id_facultad
                   JOIN jugador c  ON c.ci = e.ci_capitan"""

CI = Field(pattern=r"^\d{7,8}$")


class EquipoIn(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    nombre: str = Field(min_length=1, max_length=100)
    id_torneo: int = Field(gt=0)
    id_facultad: int = Field(gt=0)
    ci_capitan: str = CI


class JugadorPlantelIn(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True)

    ci_jugador: str = CI
    numero_camiseta: int = Field(ge=1, le=99)


@router.get("", dependencies=logueados)
def listar(id_torneo: int | None = None, db=Depends(get_db)):
    if id_torneo is None:
        return db.todos(SELECT_EQUIPO + " ORDER BY e.id_torneo, e.nombre")
    return db.todos(SELECT_EQUIPO + " WHERE e.id_torneo = %s ORDER BY e.nombre", (id_torneo,))


@router.get("/{id_equipo}", dependencies=logueados)
def obtener(id_equipo: int, db=Depends(get_db)):
    equipo = db.uno(SELECT_EQUIPO + " WHERE e.id_equipo = %s", (id_equipo,))
    if equipo is None:
        raise HTTPException(404, "No existe ese equipo")
    return equipo


@router.post("", status_code=201, dependencies=solo_admin)
def crear(datos: EquipoIn, db=Depends(get_db)):
    # El capitán se elige al crear el equipo, pero después hay que agregarlo al plantel:
    # el torneo no puede cerrar la inscripción si algún capitán no está en su plantel
    id_nuevo, _ = db.ejecutar(
        "INSERT INTO equipo (nombre, id_torneo, id_facultad, ci_capitan) VALUES (%s, %s, %s, %s)",
        (datos.nombre, datos.id_torneo, datos.id_facultad, datos.ci_capitan),
    )
    return obtener(id_nuevo, db)


@router.put("/{id_equipo}", dependencies=solo_admin)
def modificar(id_equipo: int, datos: EquipoIn, db=Depends(get_db)):
    actual = obtener(id_equipo, db)
    if datos.id_torneo != actual["id_torneo"]:
        raise HTTPException(409, "Un equipo no puede pasar a otro torneo")
    db.ejecutar(
        "UPDATE equipo SET nombre = %s, id_facultad = %s, ci_capitan = %s WHERE id_equipo = %s",
        (datos.nombre, datos.id_facultad, datos.ci_capitan, id_equipo),
    )
    return obtener(id_equipo, db)


@router.delete("/{id_equipo}", status_code=204, dependencies=solo_admin)
def borrar(id_equipo: int, db=Depends(get_db)):
    # Si tiene plantel o partidos, la clave foránea no deja borrarlo (409)
    _, filas = db.ejecutar("DELETE FROM equipo WHERE id_equipo = %s", (id_equipo,))
    if filas == 0:
        raise HTTPException(404, "No existe ese equipo")


# ---------- Plantel ----------

@router.get("/{id_equipo}/plantel", dependencies=logueados)
def ver_plantel(id_equipo: int, db=Depends(get_db)):
    obtener(id_equipo, db)
    return db.todos(
        """SELECT j.ci, j.nombre, j.apellido, j.tipo, ejt.numero_camiseta
           FROM equipo_jugador_torneo ejt
           JOIN jugador j ON j.ci = ejt.ci_jugador
           WHERE ejt.id_equipo = %s
           ORDER BY ejt.numero_camiseta""",
        (id_equipo,),
    )


@router.post("/{id_equipo}/plantel", status_code=201, dependencies=solo_admin)
def agregar_al_plantel(id_equipo: int, datos: JugadorPlantelIn, db=Depends(get_db)):
    equipo = obtener(id_equipo, db)
    # id_torneo se copia del equipo: así el UNIQUE (id_torneo, ci_jugador) impide
    # que el jugador esté en dos equipos de la misma edición
    db.ejecutar(
        """INSERT INTO equipo_jugador_torneo (id_equipo, ci_jugador, id_torneo, numero_camiseta)
           VALUES (%s, %s, %s, %s)""",
        (id_equipo, datos.ci_jugador, equipo["id_torneo"], datos.numero_camiseta),
    )
    return ver_plantel(id_equipo, db)


@router.delete("/{id_equipo}/plantel/{ci}", status_code=204, dependencies=solo_admin)
def quitar_del_plantel(id_equipo: int, ci: str, db=Depends(get_db)):
    equipo = obtener(id_equipo, db)
    if equipo["ci_capitan"] == ci:
        raise HTTPException(409, "No se puede sacar al capitán: primero elegí otro capitán")
    _, filas = db.ejecutar(
        "DELETE FROM equipo_jugador_torneo WHERE id_equipo = %s AND ci_jugador = %s", (id_equipo, ci)
    )
    if filas == 0:
        raise HTTPException(404, "Ese jugador no está en el plantel")
