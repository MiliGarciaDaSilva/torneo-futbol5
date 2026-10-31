import os

# Los valores por defecto sirven para correr el backend en la PC contra el MySQL de docker compose.
# Adentro de docker compose se pisan con las variables de entorno del servicio api.
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = int(os.getenv("DB_PORT", "3307"))
DB_NAME = os.getenv("DB_NAME", "torneo")

# Un usuario de MySQL por rol (ver sql/16_usuarios.sql): cada pedido usa el del usuario logueado
DB_USUARIOS = {
    "login": (os.getenv("DB_LOGIN_USER", "app_login"), os.getenv("DB_LOGIN_PASSWORD", "login1234")),
    "administrador": (os.getenv("DB_ADMIN_USER", "admin"), os.getenv("DB_ADMIN_PASSWORD", "admin1234")),
    "planillero": (os.getenv("DB_PLANILLERO_USER", "planillero"), os.getenv("DB_PLANILLERO_PASSWORD", "planillero1234")),
}

JWT_SECRET = os.getenv("JWT_SECRET", "clave-de-desarrollo-cambiar-en-produccion")
JWT_HORAS = int(os.getenv("JWT_HORAS", "8"))

CORS_ORIGINS = os.getenv("CORS_ORIGINS", "http://localhost:5173").split(",")
