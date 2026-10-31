# Torneo Interfacultades de Fútbol 5

## Backend

Con Docker Desktop abierto, desde la raíz del repo levantar la base:

```bash
docker compose up -d db
```

Después, dentro de `backend/`:

```bash
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

API en http://localhost:8000 (documentación en `/docs`).

## Frontend

Dentro de `frontend/`:

```bash
npm install
npm run dev
```

App en http://localhost:5173. Usuarios: `admin@ucu.edu.uy` / `admin1234` y `planillero@ucu.edu.uy` / `planillero1234`.
