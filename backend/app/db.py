from contextlib import contextmanager
from datetime import timedelta

import mysql.connector

from app import config


def conectar(rol):
    """Abre una conexión con el usuario de MySQL que corresponde al rol."""
    usuario, contrasena = config.DB_USUARIOS[rol]
    cnx = mysql.connector.connect(
        host=config.DB_HOST,
        port=config.DB_PORT,
        database=config.DB_NAME,
        user=usuario,
        password=contrasena,
        charset="utf8mb4",
        autocommit=True,
    )
    return Db(cnx)


def _limpiar(fila):
    # MySQL devuelve las columnas TIME como timedelta: las pasamos a "HH:MM"
    for clave, valor in fila.items():
        if isinstance(valor, timedelta):
            minutos = int(valor.total_seconds()) // 60
            fila[clave] = f"{minutos // 60:02d}:{minutos % 60:02d}"
    return fila


class Db:
    """Envoltorio chico sobre la conexión. Siempre SQL a mano con parámetros %s, nunca concatenar texto."""

    def __init__(self, cnx):
        self.cnx = cnx

    def todos(self, sql, params=()):
        cursor = self.cnx.cursor(dictionary=True)
        try:
            cursor.execute(sql, params)
            return [_limpiar(fila) for fila in cursor.fetchall()]
        finally:
            cursor.close()

    def uno(self, sql, params=()):
        filas = self.todos(sql, params)
        return filas[0] if filas else None

    def ejecutar(self, sql, params=()):
        """Para INSERT, UPDATE y DELETE. Devuelve (id insertado, filas afectadas)."""
        cursor = self.cnx.cursor()
        try:
            cursor.execute(sql, params)
            return cursor.lastrowid, cursor.rowcount
        finally:
            cursor.close()

    @contextmanager
    def transaccion(self):
        """Para varias escrituras que tienen que quedar todas o ninguna (por ejemplo planilla + goles + tarjetas)."""
        self.cnx.start_transaction()
        try:
            yield
            self.cnx.commit()
        except Exception:
            self.cnx.rollback()
            raise

    def cerrar(self):
        self.cnx.close()
