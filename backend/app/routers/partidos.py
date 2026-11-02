from fastapi import APIRouter, Depends
from app.auth import ADMIN, PLANILLERO, get_db, requiere_rol

router = APIRouter(prefix="/partidos", tags=["partidos"]) #todas las rutas de este archivo empiezan con /partidos
logueados = [Depends(requiere_rol(ADMIN, PLANILLERO))]

@router.get("", dependencies=logueados) #cuando alguien pide GET /partidos se ejecuta la función listar
#solo entran el admin y el planillero o sea los dos que tienen que ver partidos
def listar(db=Depends(get_db)): #FastAPI le pasa a la función una conexión ya abierta y la cierra sola al terminar
  return db.todos(
    """SELECT p.id_partido, p.id_torneo, p.numero_fecha, p.id_equipo_local, el.nombre AS equipo_local,
              p.id_equipo_visitante, ev.nombre AS equipo_visitante,
              p.dia, p.id_turno, t.hora_inicio, t.hora_fin, 
              p.nombre_cancha, p.id_complejo, c.nombre AS complejo, p.estado
    FROM partido p
    JOIN equipo el ON el.id_equipo = p.id_equipo_local
    JOIN equipo ev ON ev.id_equipo = p.id_equipo_visitante
    JOIN turno t ON t.id_turno = p.id_turno
    JOIN complejo c ON c.id_complejo = p.id_complejo
    ORDER BY p.numero_fecha, p.dia, t.hora_inicio"""
  )