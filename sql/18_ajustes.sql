-- Validaciones de formato en la base (las mismas que hacen el backend y el formulario)
ALTER TABLE jugador
    ADD CONSTRAINT chk_jugador_ci CHECK (ci REGEXP '^[0-9]{7,8}$'),
    ADD CONSTRAINT chk_jugador_email CHECK (email REGEXP '^[^@ ]+@[^@ ]+[.][^@ ]+$');

ALTER TABLE login
    ADD CONSTRAINT chk_login_correo CHECK (correo REGEXP '^[^@ ]+@[^@ ]+[.][^@ ]+$');

-- El planillero marca el partido como jugado (solo puede tocar la columna estado;
-- el trigger de partido sigue exigiendo que el día y el turno ya hayan pasado)
GRANT UPDATE (estado) ON torneo.partido TO 'planillero'@'%';
