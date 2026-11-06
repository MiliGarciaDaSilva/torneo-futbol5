# Torneo Interfacultades de Fútbol 5

Base de datos MySQL, API con FastAPI y pantallas en React (Vite).

## Levantar todo con Docker

Con Docker Desktop abierto, desde la raíz del repo:

```bash
docker compose up -d --build
```

| Servicio   | Dirección                                                       |
| ---------- | --------------------------------------------------------------- |
| Base MySQL | localhost:3307 (usuario root, contraseña root1234, base torneo) |
| API        | http://localhost:8000 (documentación en /docs)                  |
| Frontend   | http://localhost:5173                                           |

Si el puerto 3307 ya está ocupado, cambiar el primer número de "ports" del servicio "db" en "docker-compose.yml".

## Correr el backend o el frontend sin Docker

Levantar solo la base:

```bash
docker compose up -d db
```

Backend, dentro de "backend/":

```bash
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Frontend, dentro de "frontend/":

```bash
npm install
npm run dev
```

## Usuarios

Para entrar a la aplicación:

| Correo                  | Contraseña       | Rol           |
| ----------------------- | ---------------- | ------------- |
| `admin@ucu.edu.uy`      | `admin1234`      | administrador |
| `planillero@ucu.edu.uy` | `planillero1234` | planillero    |

La API se conecta a MySQL con un usuario distinto según el rol de quien inició sesión (sql/16_usuarios.sql):

| Usuario de MySQL | Qué puede hacer                                                                            |
| ---------------- | ------------------------------------------------------------------------------------------ |
| _admin_          | leer y escribir en todas las tablas                                                        |
| _planillero_     | leer todo menos "login"; cargar planillas, goles y tarjetas; marcar un partido como jugado |
| _app_login_      | solo leer la tabla "login", para validar el ingreso                                        |
