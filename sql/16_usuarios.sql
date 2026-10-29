CREATE USER 'admin'@'%' IDENTIFIED BY 'admin1234';
GRANT SELECT, INSERT, UPDATE, DELETE ON torneo.* TO 'admin'@'%';

CREATE USER 'planillero'@'%' IDENTIFIED BY 'planillero1234';
GRANT SELECT ON torneo.* TO 'planillero'@'%';
GRANT INSERT, DELETE ON torneo.planilla_partido TO 'planillero'@'%';
GRANT INSERT, UPDATE, DELETE ON torneo.gol TO 'planillero'@'%';
GRANT INSERT, UPDATE, DELETE ON torneo.tarjeta TO 'planillero'@'%';

INSERT INTO login (correo, contrasena, rol) VALUES
    ('admin@ucu.edu.uy',      SHA2('admin1234', 256),      'administrador'),
    ('planillero@ucu.edu.uy', SHA2('planillero1234', 256), 'planillero');