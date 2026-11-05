import mysql.connector
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app import auth, config
from app.errores import error_mysql
from app.routers import canchas, catalogos, complejos, equipos, jugadores, partidos, planillas, reportes, sanciones, torneos

app = FastAPI(title="Torneo Interfacultades de Fútbol 5")

app.add_middleware(
    CORSMiddleware,
    allow_origins=config.CORS_ORIGINS,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.add_exception_handler(mysql.connector.Error, error_mysql)

app.include_router(auth.router)
app.include_router(catalogos.router)
app.include_router(complejos.router)
app.include_router(partidos.router)
app.include_router(planillas.router)
app.include_router(torneos.router)
app.include_router(jugadores.router)
app.include_router(equipos.router)
app.include_router(canchas.router)
app.include_router(sanciones.router)
app.include_router(reportes.router)
# Cada router nuevo se agrega acá (jugadores, equipos, partidos, planillas, reportes, ...)


@app.get("/salud", tags=["salud"])
def salud():
    return {"ok": True}
