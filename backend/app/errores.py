import mysql.connector
from fastapi import Request
from fastapi.responses import JSONResponse

# Errores de MySQL más comunes traducidos a algo que se pueda mostrar en la pantalla
MENSAJES = {
    1048: (400, "Falta un dato obligatorio"),
    1062: (409, "Ya existe un registro con esos datos"),
    1142: (403, "Tu usuario de base de datos no tiene permiso para esta operación"),
    # 1216 y 1217 son los mismos errores de clave foránea que 1452 y 1451, pero sin detalle:
    # MySQL los manda así cuando el usuario no tiene permisos sobre la tabla relacionada
    1216: (400, "Se hace referencia a un dato que no existe"),
    1217: (409, "No se puede borrar o cambiar: hay otros datos que dependen de este"),
    1265: (400, "Algún dato tiene un valor inválido"),
    1366: (400, "Algún dato tiene un formato inválido"),
    1406: (400, "Algún texto es demasiado largo"),
    1451: (409, "No se puede borrar o cambiar: hay otros datos que dependen de este"),
    1452: (400, "Se hace referencia a un dato que no existe"),
    2003: (503, "No se pudo conectar a la base de datos"),
    3819: (400, "Algún dato no cumple las reglas de la base"),
}


async def error_mysql(request: Request, exc: mysql.connector.Error):
    # 1644 = SIGNAL de un trigger: el mensaje ya lo escribimos nosotros en español
    if exc.errno == 1644:
        return JSONResponse(status_code=400, content={"detail": exc.msg})

    codigo_http, mensaje = MENSAJES.get(exc.errno, (500, "Error en la base de datos"))
    return JSONResponse(status_code=codigo_http, content={"detail": mensaje, "mysql": exc.msg})
