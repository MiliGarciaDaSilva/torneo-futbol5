CREATE USER 'admin'@'%' IDENTIFIED BY 'admin1234';
GRANT SELECT, INSERT, UPDATE, DELETE ON torneo.* TO 'admin'@'%';

-- El planillero lee tabla por tabla (todas menos login, para que no vea las contraseñas)
CREATE USER 'planillero'@'%' IDENTIFIED BY 'planillero1234';
GRANT SELECT ON torneo.facultad              TO 'planillero'@'%';
GRANT SELECT ON torneo.turno                 TO 'planillero'@'%';
GRANT SELECT ON torneo.complejo              TO 'planillero'@'%';
GRANT SELECT ON torneo.cancha                TO 'planillero'@'%';
GRANT SELECT ON torneo.torneo                TO 'planillero'@'%';
GRANT SELECT ON torneo.jugador               TO 'planillero'@'%';
GRANT SELECT ON torneo.equipo                TO 'planillero'@'%';
GRANT SELECT ON torneo.equipo_jugador_torneo TO 'planillero'@'%';
GRANT SELECT ON torneo.partido               TO 'planillero'@'%';
GRANT SELECT ON torneo.sancion_jugador       TO 'planillero'@'%';
GRANT SELECT, INSERT, DELETE         ON torneo.planilla_partido TO 'planillero'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON torneo.gol              TO 'planillero'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON torneo.tarjeta          TO 'planillero'@'%';

-- Usuario que usa el backend solo para el login: lee la tabla login y nada más
CREATE USER 'app_login'@'%' IDENTIFIED BY 'login1234';
GRANT SELECT ON torneo.login TO 'app_login'@'%';

INSERT INTO login (correo, contrasena, rol) VALUES
    ('admin@ucu.edu.uy',      SHA2('admin1234', 256),      'administrador'),
    ('planillero@ucu.edu.uy', SHA2('planillero1234', 256), 'planillero');
