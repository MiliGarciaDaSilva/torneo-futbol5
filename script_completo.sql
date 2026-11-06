-- Script completo de la base torneo: tablas, triggers, vistas, usuarios de MySQL y datos de prueba.
-- Es la suma de los archivos de sql/ en el orden en que los carga docker compose (orden alfabetico).
-- Pensado para una base nueva. Correr con: mysql -u root -p < script_completo.sql
SET NAMES utf8mb4;
CREATE DATABASE IF NOT EXISTS torneo;
USE torneo;

-- 01_schema.sql
CREATE TABLE login (
    correo VARCHAR(100) PRIMARY KEY,
    contrasena VARCHAR(255) NOT NULL,
    rol ENUM('administrador', 'planillero') NOT NULL
);

CREATE TABLE facultad (
    id_facultad INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE turno (
    id_turno INT AUTO_INCREMENT PRIMARY KEY,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    CHECK (hora_fin > hora_inicio)
);

CREATE TABLE complejo (
    id_complejo INT AUTO_INCREMENT PRIMARY KEY ,
    nombre VARCHAR(100) NOT NULL,
    direccion VARCHAR(200) NOT NULL,
    departamento VARCHAR(50) NOT NULL
);

-- 02_schema.sql
CREATE TABLE torneo (
    id_torneo INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    anio INT NOT NULL,
    semestre TINYINT NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    estado ENUM('inscripcion', 'en curso', 'finalizado') NOT NULL DEFAULT 'inscripcion',
    CHECK (semestre IN (1, 2)),
    CHECK (fecha_fin >= fecha_inicio),
    UNIQUE (anio, semestre)
);

CREATE TABLE jugador (
    ci               VARCHAR(15) PRIMARY KEY,
    nombre           VARCHAR(50)  NOT NULL,
    apellido         VARCHAR(50)  NOT NULL,
    email            VARCHAR(100) NOT NULL UNIQUE,
    fecha_nacimiento DATE NOT NULL,
    id_facultad      INT NOT NULL,
    tipo             ENUM('grado', 'posgrado', 'docente', 'funcionario') NOT NULL,
    FOREIGN KEY (id_facultad) REFERENCES facultad(id_facultad)
);

CREATE TABLE cancha (
    nombre_cancha VARCHAR(50) NOT NULL,
    id_complejo   INT NOT NULL,
    superficie    ENUM('sintetico', 'parquet') NOT NULL,
    techada       BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (nombre_cancha, id_complejo),
    FOREIGN KEY (id_complejo) REFERENCES complejo(id_complejo)
);

-- 03_schema.sql
CREATE TABLE equipo (
    id_equipo   INT AUTO_INCREMENT PRIMARY KEY,
    nombre      VARCHAR(100) NOT NULL,
    id_torneo   INT NOT NULL,
    id_facultad INT NOT NULL,
    ci_capitan  VARCHAR(15) NOT NULL,
    UNIQUE (id_torneo, nombre),
    UNIQUE (id_torneo, id_facultad),
    FOREIGN KEY (id_torneo)   REFERENCES torneo(id_torneo),
    FOREIGN KEY (id_facultad) REFERENCES facultad(id_facultad),
    FOREIGN KEY (ci_capitan)  REFERENCES jugador(ci)
);

CREATE TABLE equipo_jugador_torneo (
    id_equipo      INT NOT NULL,
    ci_jugador     VARCHAR(15) NOT NULL,
    id_torneo      INT NOT NULL,
    numero_camiseta TINYINT NOT NULL,
    PRIMARY KEY (id_equipo, ci_jugador),
    UNIQUE (id_torneo, ci_jugador),
    UNIQUE (id_equipo, numero_camiseta),
    CHECK (numero_camiseta BETWEEN 1 AND 99),
    FOREIGN KEY (id_equipo)  REFERENCES equipo(id_equipo),
    FOREIGN KEY (ci_jugador) REFERENCES jugador(ci),
    FOREIGN KEY (id_torneo)  REFERENCES torneo(id_torneo)
);

-- 04_ajustes.sql
ALTER TABLE equipo
    ADD UNIQUE (id_equipo, id_torneo);

ALTER TABLE equipo_jugador_torneo
    ADD FOREIGN KEY (id_equipo, id_torneo) REFERENCES equipo(id_equipo, id_torneo);

ALTER TABLE turno
    ADD CONSTRAINT chk_turno_horario CHECK (
        hora_inicio >= '18:00:00'
        AND hora_fin <= '23:00:00'
        AND TIMEDIFF(hora_fin, hora_inicio) = '01:00:00'
        );

-- 05_schema.sql
CREATE TABLE partido (
    id_partido          INT AUTO_INCREMENT PRIMARY KEY,
    id_torneo           INT NOT NULL,
    numero_fecha        INT NOT NULL,
    id_equipo_local     INT NOT NULL,
    id_equipo_visitante INT NOT NULL,
    dia                 DATE NOT NULL,
    id_turno            INT NOT NULL,
    nombre_cancha       VARCHAR(50) NOT NULL,
    id_complejo         INT NOT NULL,
    estado              ENUM('programado', 'jugado', 'postergado', 'cancelado') NOT NULL DEFAULT 'programado',
    CHECK (numero_fecha >= 1),
    CHECK (id_equipo_local <> id_equipo_visitante),
    FOREIGN KEY (id_torneo)                      REFERENCES torneo(id_torneo),
    FOREIGN KEY (id_equipo_local, id_torneo)     REFERENCES equipo(id_equipo, id_torneo),
    FOREIGN KEY (id_equipo_visitante, id_torneo) REFERENCES equipo(id_equipo, id_torneo),
    FOREIGN KEY (id_turno)                       REFERENCES turno(id_turno),
    FOREIGN KEY (nombre_cancha, id_complejo)     REFERENCES cancha(nombre_cancha, id_complejo)
);

-- 06_schema.sql
CREATE TABLE planilla_partido (
    id_partido INT NOT NULL,
    ci_jugador VARCHAR(15) NOT NULL,
    id_equipo  INT NOT NULL,
    PRIMARY KEY (id_partido, ci_jugador),
    FOREIGN KEY (id_partido)            REFERENCES partido(id_partido),
    FOREIGN KEY (id_equipo, ci_jugador) REFERENCES equipo_jugador_torneo(id_equipo, ci_jugador)
);

CREATE TABLE gol (
    id_gol     INT AUTO_INCREMENT PRIMARY KEY,
    id_partido INT NOT NULL,
    ci_jugador VARCHAR(15) NOT NULL,
    minuto     TINYINT NOT NULL,
    autogol    BOOLEAN NOT NULL DEFAULT FALSE,
    CHECK (minuto BETWEEN 1 AND 60),
    FOREIGN KEY (id_partido, ci_jugador) REFERENCES planilla_partido(id_partido, ci_jugador)
);

CREATE TABLE tarjeta (
    id_tarjeta INT AUTO_INCREMENT PRIMARY KEY,
    id_partido INT NOT NULL,
    ci_jugador VARCHAR(15) NOT NULL,
    minuto     TINYINT NOT NULL,
    color      ENUM('amarilla', 'roja') NOT NULL,
    CHECK (minuto BETWEEN 1 AND 60),
    FOREIGN KEY (id_partido, ci_jugador) REFERENCES planilla_partido(id_partido, ci_jugador)
);

CREATE TABLE sancion_jugador (
    id_sancion          INT AUTO_INCREMENT PRIMARY KEY,
    ci_jugador          VARCHAR(15) NOT NULL,
    id_torneo           INT NOT NULL,
    motivo              ENUM('roja', 'acumulacion de amarillas', 'disciplinaria') NOT NULL,
    numero_fecha_inicio INT NOT NULL,
    cantidad_fechas     INT NOT NULL DEFAULT 1,
    id_tarjeta          INT,
    CHECK (numero_fecha_inicio >= 1),
    CHECK (cantidad_fechas >= 1),
    FOREIGN KEY (id_torneo, ci_jugador) REFERENCES equipo_jugador_torneo(id_torneo, ci_jugador),
    FOREIGN KEY (id_tarjeta)            REFERENCES tarjeta(id_tarjeta) ON DELETE CASCADE
);

-- 07_triggers.sql
DELIMITER //

CREATE TRIGGER validar_planilla BEFORE INSERT ON planilla_partido
FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT * FROM partido WHERE id_partido = NEW.id_partido AND estado = 'jugado') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo se puede cargar la planilla de un partido jugado';
    END IF;

    IF NOT EXISTS (SELECT * FROM partido
                   WHERE id_partido = NEW.id_partido
                     AND (id_equipo_local = NEW.id_equipo OR id_equipo_visitante = NEW.id_equipo)) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El equipo no juega este partido';
    END IF;

    IF EXISTS (SELECT * FROM sancion_jugador s
               JOIN partido p ON p.id_torneo = s.id_torneo
               WHERE p.id_partido = NEW.id_partido
                 AND s.ci_jugador = NEW.ci_jugador
                 AND p.numero_fecha BETWEEN s.numero_fecha_inicio AND s.numero_fecha_inicio + s.cantidad_fechas - 1) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El jugador esta suspendido para esta fecha';
    END IF;
END //

DELIMITER ;

CREATE TRIGGER sancion_por_roja AFTER INSERT ON tarjeta
FOR EACH ROW
INSERT INTO sancion_jugador (ci_jugador, id_torneo, motivo, numero_fecha_inicio, cantidad_fechas, id_tarjeta)
SELECT NEW.ci_jugador, p.id_torneo, 'roja', p.numero_fecha + 1, 1, NEW.id_tarjeta
FROM partido p
WHERE p.id_partido = NEW.id_partido
  AND NEW.color = 'roja';

CREATE TRIGGER sancion_por_amarillas AFTER INSERT ON tarjeta
FOR EACH ROW
INSERT INTO sancion_jugador (ci_jugador, id_torneo, motivo, numero_fecha_inicio, cantidad_fechas, id_tarjeta)
SELECT NEW.ci_jugador, p.id_torneo, 'acumulacion de amarillas', p.numero_fecha + 1, 1, NEW.id_tarjeta
FROM partido p
WHERE p.id_partido = NEW.id_partido
  AND NEW.color = 'amarilla'
  AND (SELECT COUNT(*) FROM tarjeta t
       JOIN partido p2 ON p2.id_partido = t.id_partido
       WHERE t.ci_jugador = NEW.ci_jugador
         AND t.color = 'amarilla'
         AND p2.id_torneo = p.id_torneo) % 3 = 0;

-- 08_triggers_partido.sql
DELIMITER //

CREATE PROCEDURE validar_partido(
    IN p_id_partido INT,
    IN p_id_torneo INT,
    IN p_numero_fecha INT,
    IN p_local INT,
    IN p_visitante INT,
    IN p_dia DATE,
    IN p_id_turno INT,
    IN p_nombre_cancha VARCHAR(50),
    IN p_id_complejo INT,
    IN p_estado VARCHAR(20)
)
BEGIN
    IF p_estado <> 'cancelado' THEN

        IF (SELECT COUNT(*) FROM equipo_jugador_torneo WHERE id_equipo = p_local) < 5 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El equipo local tiene menos de 5 jugadores';
        END IF;

        IF (SELECT COUNT(*) FROM equipo_jugador_torneo WHERE id_equipo = p_visitante) < 5 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El equipo visitante tiene menos de 5 jugadores';
        END IF;

        -- no repetir rival
        IF EXISTS (SELECT * FROM partido
                   WHERE id_partido <> p_id_partido
                     AND id_torneo = p_id_torneo
                     AND estado <> 'cancelado'
                     AND ((id_equipo_local = p_local AND id_equipo_visitante = p_visitante)
                       OR (id_equipo_local = p_visitante AND id_equipo_visitante = p_local))) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Estos equipos ya se enfrentaron en este torneo';
        END IF;

        -- un partido por equipo en cada fecha
        IF EXISTS (SELECT * FROM partido
                   WHERE id_partido <> p_id_partido
                     AND id_torneo = p_id_torneo
                     AND numero_fecha = p_numero_fecha
                     AND estado <> 'cancelado'
                     AND (id_equipo_local IN (p_local, p_visitante)
                       OR id_equipo_visitante IN (p_local, p_visitante))) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Un equipo ya tiene partido en esa fecha';
        END IF;

        -- cancha ocupada
        IF EXISTS (SELECT * FROM partido
                   WHERE id_partido <> p_id_partido
                     AND dia = p_dia
                     AND id_turno = p_id_turno
                     AND nombre_cancha = p_nombre_cancha
                     AND id_complejo = p_id_complejo
                     AND estado <> 'cancelado') THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La cancha ya esta ocupada en ese dia y turno';
        END IF;

        -- jugado solo si ya paso el turno
        IF p_estado = 'jugado' THEN
            IF NOT EXISTS (SELECT * FROM turno
                           WHERE id_turno = p_id_turno
                             AND TIMESTAMP(p_dia, hora_fin) <= NOW()) THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El partido todavia no se jugo, no se puede marcar como jugado';
            END IF;
        END IF;

    END IF;
END //

CREATE TRIGGER partido_validar_insert BEFORE INSERT ON partido
FOR EACH ROW
BEGIN
    CALL validar_partido(0, NEW.id_torneo, NEW.numero_fecha, NEW.id_equipo_local, NEW.id_equipo_visitante,
                         NEW.dia, NEW.id_turno, NEW.nombre_cancha, NEW.id_complejo, NEW.estado);
END //

CREATE TRIGGER partido_validar_update BEFORE UPDATE ON partido
FOR EACH ROW
BEGIN
    CALL validar_partido(OLD.id_partido, NEW.id_torneo, NEW.numero_fecha, NEW.id_equipo_local, NEW.id_equipo_visitante,
                         NEW.dia, NEW.id_turno, NEW.nombre_cancha, NEW.id_complejo, NEW.estado);
END //

CREATE TRIGGER partido_no_borrar_jugado BEFORE DELETE ON partido
FOR EACH ROW
BEGIN
    IF OLD.estado = 'jugado' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede borrar un partido jugado';
    END IF;
END //

DELIMITER ;

-- 09_triggers_plantel.sql
DELIMITER //

CREATE TRIGGER validar_plantel_insert BEFORE INSERT ON equipo_jugador_torneo
FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT * FROM torneo WHERE id_torneo = NEW.id_torneo AND estado = 'inscripcion') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Los planteles solo se modifican durante la inscripcion';
    END IF;

    IF NOT EXISTS (SELECT * FROM jugador j
                   JOIN equipo e ON e.id_facultad = j.id_facultad
                   WHERE j.ci = NEW.ci_jugador
                     AND e.id_equipo = NEW.id_equipo) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El jugador no es de la facultad del equipo';
    END IF;

    IF (SELECT COUNT(*) FROM equipo_jugador_torneo WHERE id_equipo = NEW.id_equipo) >= 10 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El plantel ya tiene 10 jugadores';
    END IF;

    IF EXISTS (SELECT * FROM jugador WHERE ci = NEW.ci_jugador AND tipo IN ('docente', 'funcionario'))
       AND (SELECT COUNT(*) FROM equipo_jugador_torneo ej
            JOIN jugador j ON j.ci = ej.ci_jugador
            WHERE ej.id_equipo = NEW.id_equipo
              AND j.tipo IN ('docente', 'funcionario')) >= 2 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El plantel ya tiene 2 docentes o funcionarios';
    END IF;
END //

CREATE TRIGGER validar_plantel_update BEFORE UPDATE ON equipo_jugador_torneo
FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT * FROM torneo WHERE id_torneo = OLD.id_torneo AND estado = 'inscripcion') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Los planteles solo se modifican durante la inscripcion';
    END IF;

    IF NEW.ci_jugador <> OLD.ci_jugador OR NEW.id_equipo <> OLD.id_equipo THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Para cambiar el jugador o el equipo hay que borrarlo y cargarlo de nuevo';
    END IF;
END //

CREATE TRIGGER validar_plantel_delete BEFORE DELETE ON equipo_jugador_torneo
FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT * FROM torneo WHERE id_torneo = OLD.id_torneo AND estado = 'inscripcion') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Los planteles solo se modifican durante la inscripcion';
    END IF;
END //

CREATE TRIGGER validar_equipo_insert BEFORE INSERT ON equipo
FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT * FROM torneo WHERE id_torneo = NEW.id_torneo AND estado = 'inscripcion') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Los equipos solo se inscriben durante la inscripcion';
    END IF;

    IF NOT EXISTS (SELECT * FROM jugador WHERE ci = NEW.ci_capitan AND id_facultad = NEW.id_facultad) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El capitan no es de la facultad del equipo';
    END IF;
END //

CREATE TRIGGER validar_equipo_update BEFORE UPDATE ON equipo
FOR EACH ROW
BEGIN
    IF NEW.id_facultad <> OLD.id_facultad THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede cambiar la facultad de un equipo';
    END IF;

    IF NEW.ci_capitan <> OLD.ci_capitan
       AND NOT EXISTS (SELECT * FROM equipo_jugador_torneo
                       WHERE id_equipo = NEW.id_equipo
                         AND ci_jugador = NEW.ci_capitan) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El capitan tiene que estar en el plantel del equipo';
    END IF;
END //

CREATE TRIGGER validar_torneo_estado BEFORE UPDATE ON torneo
FOR EACH ROW
BEGIN
    IF (OLD.estado = 'en curso' AND NEW.estado = 'inscripcion')
       OR (OLD.estado = 'finalizado' AND NEW.estado <> 'finalizado') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El torneo no puede volver a una etapa anterior';
    END IF;

    IF OLD.estado = 'inscripcion' AND NEW.estado <> 'inscripcion'
       AND EXISTS (SELECT * FROM equipo e
                   WHERE e.id_torneo = NEW.id_torneo
                     AND (SELECT COUNT(*) FROM equipo_jugador_torneo ej WHERE ej.id_equipo = e.id_equipo) < 5) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hay equipos con menos de 5 jugadores';
    END IF;

    IF OLD.estado = 'inscripcion' AND NEW.estado <> 'inscripcion'
       AND EXISTS (SELECT * FROM equipo e
                   WHERE e.id_torneo = NEW.id_torneo
                     AND NOT EXISTS (SELECT * FROM equipo_jugador_torneo ej
                                     WHERE ej.id_equipo = e.id_equipo
                                       AND ej.ci_jugador = e.ci_capitan)) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hay equipos cuyo capitan no esta en el plantel';
    END IF;
END //

DELIMITER ;

-- 10_reportes_partido.sql
-- Canchas mas usadas
CREATE VIEW reporte_canchas_mas_usadas AS
SELECT c.nombre AS complejo, p.nombre_cancha, COUNT(*) AS cantidad_partidos
FROM partido p
JOIN complejo c ON c.id_complejo = p.id_complejo
WHERE p.estado IN ('programado', 'jugado')
GROUP BY c.nombre, p.nombre_cancha, p.id_complejo
ORDER BY cantidad_partidos DESC;

-- Turnos mas usados
CREATE VIEW reporte_turnos_mas_usados AS
SELECT t.hora_inicio, t.hora_fin, COUNT(*) AS cantidad_partidos
FROM partido p
JOIN turno t ON t.id_turno = p.id_turno
WHERE p.estado IN ('programado', 'jugado')
GROUP BY t.id_turno, t.hora_inicio, t.hora_fin
ORDER BY cantidad_partidos DESC;

-- Porcentaje de partidos por estado, dentro de cada torneo
-- (el porcentaje se calcula sobre el total de partidos de ese torneo, no de todos los torneos)
CREATE VIEW reporte_porcentaje_estados AS
SELECT t.id_torneo, t.nombre AS torneo, p.estado,
       COUNT(*) AS cantidad,
       ROUND(COUNT(*) * 100 / (SELECT COUNT(*) FROM partido p2 WHERE p2.id_torneo = t.id_torneo), 2) AS porcentaje
FROM partido p
JOIN torneo t ON t.id_torneo = p.id_torneo
GROUP BY t.id_torneo, t.nombre, p.estado
ORDER BY t.id_torneo, cantidad DESC;

-- Promedio de goles por fecha
CREATE VIEW reporte_promedio_goles_por_fecha AS
SELECT t.id_torneo, t.nombre AS torneo, p.numero_fecha,
       COUNT(DISTINCT p.id_partido) AS partidos_jugados,
       COUNT(g.id_gol) AS goles,
       ROUND(COUNT(g.id_gol) / COUNT(DISTINCT p.id_partido), 2) AS promedio_goles
FROM partido p
JOIN torneo t ON t.id_torneo = p.id_torneo
LEFT JOIN gol g ON g.id_partido = p.id_partido
WHERE p.estado = 'jugado'
GROUP BY t.id_torneo, t.nombre, p.numero_fecha
ORDER BY t.id_torneo, p.numero_fecha;

-- Promedio de goles por edicion
CREATE VIEW reporte_promedio_goles_por_edicion AS
SELECT t.nombre AS torneo, t.anio, t.semestre,
       COUNT(DISTINCT p.id_partido) AS partidos_jugados,
       COUNT(g.id_gol) AS goles,
       ROUND(COUNT(g.id_gol) / COUNT(DISTINCT p.id_partido), 2) AS promedio_goles
FROM partido p
JOIN torneo t ON t.id_torneo = p.id_torneo
LEFT JOIN gol g ON g.id_partido = p.id_partido
WHERE p.estado = 'jugado'
GROUP BY t.id_torneo, t.nombre, t.anio, t.semestre
ORDER BY t.anio, t.semestre;

-- 11_inserts.sql
-- Datos de prueba: facultades, turnos, complejos, canchas, torneo, jugadores, equipos y planteles
-- Debe ejecutarse ANTES de 99_triggers_48h.sql

SET NAMES utf8mb4;

-- Facultades
INSERT INTO facultad (id_facultad, nombre) VALUES
    (1, 'Ingeniería y Tecnologías'),
    (2, 'Ciencias Empresariales'),
    (3, 'Derecho'),
    (4, 'Psicología'),
    (5, 'Ciencias de la Salud'),
    (6, 'Ciencias Humanas');

-- Turnos de una hora entre las 18:00 y las 23:00
INSERT INTO turno (id_turno, hora_inicio, hora_fin) VALUES
    (1, '18:00:00', '19:00:00'),
    (2, '19:00:00', '20:00:00'),
    (3, '20:00:00', '21:00:00'),
    (4, '21:00:00', '22:00:00'),
    (5, '22:00:00', '23:00:00');

-- Complejos deportivos
INSERT INTO complejo (id_complejo, nombre, direccion, departamento) VALUES
    (1, 'Malvín 5', 'Alejandro Gallinal 2111', 'Montevideo'),
    (2, 'El Clásico Fútbol 5', 'Alejandro Gallinal 2014', 'Montevideo');

-- Canchas (la clave es nombre_cancha + id_complejo: los dos complejos tienen una 'Camp Nou' y una 'Gran Parque Central')
INSERT INTO cancha (nombre_cancha, id_complejo, superficie, techada) VALUES
    ('Camp Nou', 1, 'sintetico', TRUE),
    ('Gran Parque Central', 1, 'sintetico', FALSE),
    ('Camp Nou', 2, 'parquet',   TRUE),
    ('Gran Parque Central', 2, 'sintetico', TRUE);

-- Torneo: se crea en 'inscripcion' para poder cargar los planteles,
-- y al final del script pasa a 'en curso'
INSERT INTO torneo (id_torneo, nombre, anio, semestre, fecha_inicio, fecha_fin, estado) VALUES
    (1, 'Torneo Interfacultades de Fútbol 5', 2026, 2, '2026-09-07', '2026-11-27', 'inscripcion');

-- Jugadores: 7 por facultad, con como máximo 2 docentes o funcionarios por facultad
INSERT INTO jugador (ci, nombre, apellido, email, fecha_nacimiento, id_facultad, tipo) VALUES
    ('45000001', 'Cristiano', 'Ronaldo', 'cristiano.ronaldo1@ucu.edu.uy', '2003-03-13', 1, 'grado'),
    ('45000038', 'Luka', 'Modric', 'luka.modric2@ucu.edu.uy', '1998-02-27', 1, 'grado'),
    ('45000075', 'Vinicius', 'Junior', 'vinicius.junior3@ucu.edu.uy', '1999-06-19', 1, 'grado'),
    ('45000112', 'Toni', 'Kroos', 'toni.kroos4@ucu.edu.uy', '1998-09-07', 1, 'grado'),
    ('45000149', 'Sergio', 'Ramos', 'sergio.ramos5@ucu.edu.uy', '1993-02-14', 1, 'posgrado'),
    ('45000186', 'Zinedine', 'Zidane', 'zinedine.zidane6@ucu.edu.uy', '1986-02-08', 1, 'docente'),
    ('45000223', 'Iker', 'Casillas', 'iker.casillas7@ucu.edu.uy', '1981-09-14', 1, 'funcionario'),

    ('45001260', 'Lionel', 'Messi', 'lionel.messi8@ucu.edu.uy', '1998-10-04', 2, 'grado'),
    ('45001297', 'Andrés', 'Iniesta', 'andres.iniesta9@ucu.edu.uy', '2001-11-21', 2, 'grado'),
    ('45001334', 'Xavi', 'Hernández', 'xavi.hernandez10@ucu.edu.uy', '1998-10-19', 2, 'grado'),
    ('45001371', 'Carles', 'Puyol', 'carles.puyol11@ucu.edu.uy', '2004-01-08', 2, 'grado'),
    ('45001408', 'Gerard', 'Piqué', 'gerard.pique12@ucu.edu.uy', '1998-09-28', 2, 'grado'),
    ('45001445', 'Sergio', 'Busquets', 'sergio.busquets13@ucu.edu.uy', '1994-05-14', 2, 'posgrado'),
    ('45001482', 'Pep', 'Guardiola', 'pep.guardiola14@ucu.edu.uy', '1982-09-04', 2, 'docente'),

    ('45002519', 'Diego', 'Forlán', 'diego.forlan15@ucu.edu.uy', '2002-09-27', 3, 'grado'),
    ('45002556', 'Pedro', 'Rocha', 'pedro.rocha16@ucu.edu.uy', '2000-02-19', 3, 'grado'),
    ('45002593', 'Fernando', 'Morena', 'fernando.morena17@ucu.edu.uy', '2001-06-04', 3, 'grado'),
    ('45002630', 'Alberto', 'Spencer', 'alberto.spencer18@ucu.edu.uy', '1999-10-02', 3, 'grado'),
    ('45002667', 'Antonio', 'Alzamendi', 'antonio.alzamendi19@ucu.edu.uy', '2001-08-22', 3, 'grado'),
    ('45002704', 'Diego', 'Aguirre', 'diego.aguirre20@ucu.edu.uy', '2004-06-15', 3, 'grado'),
    ('45002741', 'Pablo', 'Bengoechea', 'pablo.bengoechea21@ucu.edu.uy', '2005-06-10', 3, 'grado'),

    ('45003778', 'Luis', 'Suárez', 'luis.suarez22@ucu.edu.uy', '2001-03-23', 4, 'grado'),
    ('45003815', 'Sebastián', 'Abreu', 'sebastian.abreu23@ucu.edu.uy', '2001-02-19', 4, 'grado'),
    ('45003852', 'Álvaro', 'Recoba', 'alvaro.recoba24@ucu.edu.uy', '2002-09-16', 4, 'grado'),
    ('45003889', 'Rubén', 'Sosa', 'ruben.sosa25@ucu.edu.uy', '2003-12-15', 4, 'grado'),
    ('45003926', 'Hugo', 'de León', 'hugo.deleon26@ucu.edu.uy', '1995-10-03', 4, 'posgrado'),
    ('45003963', 'Julio', 'Montero', 'julio.montero27@ucu.edu.uy', '1993-09-14', 4, 'posgrado'),
    ('45004000', 'Tabaré', 'Vázquez', 'tabare.vazquez28@ucu.edu.uy', '1982-06-05', 4, 'funcionario'),

    ('45005037', 'Wayne', 'Rooney', 'wayne.rooney29@ucu.edu.uy', '2005-07-02', 5, 'grado'),
    ('45005074', 'Steven', 'Gerrard', 'steven.gerrard30@ucu.edu.uy', '1999-09-19', 5, 'grado'),
    ('45005111', 'Frank', 'Lampard', 'frank.lampard31@ucu.edu.uy', '2003-06-23', 5, 'grado'),
    ('45005148', 'David', 'Beckham', 'david.beckham32@ucu.edu.uy', '2003-10-16', 5, 'grado'),
    ('45005185', 'Paul', 'Scholes', 'paul.scholes33@ucu.edu.uy', '2005-02-27', 5, 'grado'),
    ('45005222', 'Ryan', 'Giggs', 'ryan.giggs34@ucu.edu.uy', '1981-05-16', 5, 'docente'),
    ('45005259', 'Alex', 'Ferguson', 'alex.ferguson35@ucu.edu.uy', '1991-11-03', 5, 'docente'),

    ('45006296', 'Diego', 'Maradona', 'diego.maradona36@ucu.edu.uy', '1998-12-23', 6, 'grado'),
    ('45006333', 'Ronaldinho', 'Gaúcho', 'ronaldinho.gaucho37@ucu.edu.uy', '2002-11-19', 6, 'grado'),
    ('45006370', 'Neymar', 'Junior', 'neymar.junior38@ucu.edu.uy', '2005-05-23', 6, 'grado'),
    ('45006407', 'Juan Román', 'Riquelme', 'juanroman.riquelme39@ucu.edu.uy', '2004-11-12', 6, 'grado'),
    ('45006444', 'Gabriel', 'Batistuta', 'gabriel.batistuta40@ucu.edu.uy', '1998-08-12', 6, 'grado'),
    ('45006481', 'Lionel', 'Scaloni', 'lionel.scaloni41@ucu.edu.uy', '1994-10-04', 6, 'posgrado'),
    ('45006518', 'Carlos', 'Bilardo', 'carlos.bilardo42@ucu.edu.uy', '1987-01-07', 6, 'funcionario');

-- Equipos: uno por facultad; el capitán es el primer jugador de cada plantel
INSERT INTO equipo (id_equipo, nombre, id_torneo, id_facultad, ci_capitan) VALUES
    (1, 'Ingecapos', 1, 1, '45000001'),
    (2, 'Barsa Sin Plata', 1, 2, '45001260'),
    (3, 'Peñarol Penal', 1, 3, '45002519'),
    (4, 'Nacional Campeón', 1, 4, '45003778'),
    (5, 'Manchester Perifar', 1, 5, '45005037'),
    (6, 'Dream Team Humanista', 1, 6, '45006296');

-- Planteles (equipo_jugador_torneo)
INSERT INTO equipo_jugador_torneo (id_equipo, ci_jugador, id_torneo, numero_camiseta) VALUES
    (1, '45000001', 1, 1),
    (1, '45000038', 1, 2),
    (1, '45000075', 1, 3),
    (1, '45000112', 1, 5),
    (1, '45000149', 1, 7),
    (1, '45000186', 1, 9),
    (1, '45000223', 1, 10),

    (2, '45001260', 1, 1),
    (2, '45001297', 1, 2),
    (2, '45001334', 1, 3),
    (2, '45001371', 1, 5),
    (2, '45001408', 1, 7),
    (2, '45001445', 1, 9),
    (2, '45001482', 1, 10),

    (3, '45002519', 1, 1),
    (3, '45002556', 1, 2),
    (3, '45002593', 1, 3),
    (3, '45002630', 1, 5),
    (3, '45002667', 1, 7),
    (3, '45002704', 1, 9),
    (3, '45002741', 1, 10),

    (4, '45003778', 1, 1),
    (4, '45003815', 1, 2),
    (4, '45003852', 1, 3),
    (4, '45003889', 1, 5),
    (4, '45003926', 1, 7),
    (4, '45003963', 1, 9),
    (4, '45004000', 1, 10),

    (5, '45005037', 1, 1),
    (5, '45005074', 1, 2),
    (5, '45005111', 1, 3),
    (5, '45005148', 1, 5),
    (5, '45005185', 1, 7),
    (5, '45005222', 1, 9),
    (5, '45005259', 1, 10),

    (6, '45006296', 1, 1),
    (6, '45006333', 1, 2),
    (6, '45006370', 1, 3),
    (6, '45006407', 1, 5),
    (6, '45006444', 1, 7),
    (6, '45006481', 1, 9),
    (6, '45006518', 1, 10);

-- Cerrada la inscripción, el torneo pasa a estar en curso
UPDATE torneo SET estado = 'en curso' WHERE id_torneo = 1;

-- 12_datos_partido.sql
-- Usa el torneo 1, los equipos 1 a 6 y las dos primeras canchas

SET @c1 = (SELECT nombre_cancha FROM cancha ORDER BY id_complejo, nombre_cancha LIMIT 1);
SET @k1 = (SELECT id_complejo   FROM cancha ORDER BY id_complejo, nombre_cancha LIMIT 1);
SET @c2 = (SELECT nombre_cancha FROM cancha ORDER BY id_complejo, nombre_cancha LIMIT 1 OFFSET 1);
SET @k2 = (SELECT id_complejo   FROM cancha ORDER BY id_complejo, nombre_cancha LIMIT 1 OFFSET 1);

-- Fecha 1 (jugada)
INSERT INTO partido (id_torneo, numero_fecha, id_equipo_local, id_equipo_visitante, dia, id_turno, nombre_cancha, id_complejo, estado) VALUES
(1, 1, 1, 2, '2026-10-07', 1, @c1, @k1, 'jugado'),
(1, 1, 3, 4, '2026-10-07', 1, @c2, @k2, 'jugado'),
(1, 1, 5, 6, '2026-10-07', 2, @c1, @k1, 'jugado');

-- Fecha 2 (jugada)
INSERT INTO partido (id_torneo, numero_fecha, id_equipo_local, id_equipo_visitante, dia, id_turno, nombre_cancha, id_complejo, estado) VALUES
(1, 2, 1, 3, '2026-10-14', 1, @c1, @k1, 'jugado'),
(1, 2, 2, 5, '2026-10-14', 1, @c2, @k2, 'jugado'),
(1, 2, 4, 6, '2026-10-14', 2, @c1, @k1, 'jugado');

-- Fecha 3 (jugada)
INSERT INTO partido (id_torneo, numero_fecha, id_equipo_local, id_equipo_visitante, dia, id_turno, nombre_cancha, id_complejo, estado) VALUES
(1, 3, 1, 4, '2026-10-21', 1, @c1, @k1, 'jugado'),
(1, 3, 2, 6, '2026-10-21', 1, @c2, @k2, 'jugado'),
(1, 3, 3, 5, '2026-10-21', 2, @c1, @k1, 'jugado');

-- Fecha 4
INSERT INTO partido (id_torneo, numero_fecha, id_equipo_local, id_equipo_visitante, dia, id_turno, nombre_cancha, id_complejo, estado) VALUES
(1, 4, 1, 5, '2026-11-04', 1, @c1, @k1, 'programado'),
(1, 4, 2, 4, '2026-11-04', 1, @c2, @k2, 'postergado'),
(1, 4, 3, 6, '2026-11-04', 2, @c1, @k1, 'cancelado');

-- Fecha 5 (programada)
INSERT INTO partido (id_torneo, numero_fecha, id_equipo_local, id_equipo_visitante, dia, id_turno, nombre_cancha, id_complejo, estado) VALUES
(1, 5, 1, 6, '2026-11-11', 1, @c1, @k1, 'programado'),
(1, 5, 2, 3, '2026-11-11', 1, @c2, @k2, 'programado'),
(1, 5, 4, 5, '2026-11-11', 2, @c1, @k1, 'programado');

-- Fecha 6 (3 vs 6 de nuevo, el anterior se cancelo)
INSERT INTO partido (id_torneo, numero_fecha, id_equipo_local, id_equipo_visitante, dia, id_turno, nombre_cancha, id_complejo, estado) VALUES
(1, 6, 3, 6, '2026-11-18', 1, @c1, @k1, 'programado');

-- 13_datos_planillas.sql
INSERT INTO planilla_partido (id_partido, ci_jugador, id_equipo) VALUES
    (1, '45000001', 1),
    (1, '45000038', 1),
    (1, '45000075', 1),
    (1, '45000112', 1),
    (1, '45000149', 1),
    (1, '45000186', 1),
    (1, '45001260', 2),
    (1, '45001297', 2),
    (1, '45001334', 2),
    (1, '45001371', 2),
    (1, '45001408', 2),
    (1, '45001445', 2),
    (1, '45001482', 2),

    (2, '45002519', 3),
    (2, '45002556', 3),
    (2, '45002593', 3),
    (2, '45002630', 3),
    (2, '45002667', 3),
    (2, '45002704', 3),
    (2, '45002741', 3),
    (2, '45003778', 4),
    (2, '45003815', 4),
    (2, '45003852', 4),
    (2, '45003889', 4),
    (2, '45003926', 4),
    (2, '45003963', 4),

    (3, '45005037', 5),
    (3, '45005074', 5),
    (3, '45005111', 5),
    (3, '45005148', 5),
    (3, '45005185', 5),
    (3, '45005222', 5),
    (3, '45005259', 5),
    (3, '45006296', 6),
    (3, '45006333', 6),
    (3, '45006370', 6),
    (3, '45006407', 6),
    (3, '45006444', 6),
    (3, '45006481', 6);

INSERT INTO gol (id_partido, ci_jugador, minuto, autogol) VALUES
    (1, '45000001', 12, FALSE),
    (1, '45000075', 33, FALSE),
    (1, '45001260', 50, FALSE),
    (2, '45002519', 20, FALSE),
    (2, '45003778', 45, FALSE),
    (3, '45005037', 5,  FALSE),
    (3, '45005037', 28, FALSE),
    (3, '45005074', 51, FALSE);

INSERT INTO tarjeta (id_partido, ci_jugador, minuto, color) VALUES
    (1, '45000038', 25, 'amarilla'),
    (1, '45001297', 40, 'roja'),
    (2, '45003815', 30, 'amarilla'),
    (2, '45002630', 55, 'amarilla'),
    (3, '45006333', 44, 'amarilla');

INSERT INTO planilla_partido (id_partido, ci_jugador, id_equipo) VALUES
    (4, '45000001', 1),
    (4, '45000038', 1),
    (4, '45000075', 1),
    (4, '45000112', 1),
    (4, '45000149', 1),
    (4, '45002519', 3),
    (4, '45002556', 3),
    (4, '45002593', 3),
    (4, '45002630', 3),
    (4, '45002667', 3),
    (4, '45002704', 3),

    (5, '45001260', 2),
    (5, '45001334', 2),
    (5, '45001371', 2),
    (5, '45001408', 2),
    (5, '45001445', 2),
    (5, '45001482', 2),
    (5, '45005037', 5),
    (5, '45005074', 5),
    (5, '45005111', 5),
    (5, '45005148', 5),
    (5, '45005185', 5),
    (5, '45005222', 5),

    (6, '45003778', 4),
    (6, '45003815', 4),
    (6, '45003852', 4),
    (6, '45003889', 4),
    (6, '45003926', 4),
    (6, '45003963', 4),
    (6, '45004000', 4),
    (6, '45006296', 6),
    (6, '45006333', 6),
    (6, '45006370', 6),
    (6, '45006407', 6),
    (6, '45006444', 6);

INSERT INTO gol (id_partido, ci_jugador, minuto, autogol) VALUES
    (4, '45000001', 8,  FALSE),
    (4, '45002519', 15, FALSE),
    (4, '45002593', 35, TRUE),
    (4, '45002667', 58, FALSE),
    (5, '45005111', 22, FALSE),
    (5, '45005037', 47, FALSE),
    (6, '45003889', 10, FALSE),
    (6, '45006296', 18, FALSE),
    (6, '45006370', 39, FALSE),
    (6, '45006296', 52, FALSE);

INSERT INTO tarjeta (id_partido, ci_jugador, minuto, color) VALUES
    (4, '45000149', 40, 'amarilla'),
    (5, '45005185', 33, 'amarilla'),
    (5, '45001371', 60, 'amarilla'),
    (6, '45003815', 27, 'amarilla');

INSERT INTO sancion_jugador (ci_jugador, id_torneo, motivo, numero_fecha_inicio, cantidad_fechas) VALUES
    ('45005111', 1, 'disciplinaria', 3, 2);

INSERT INTO planilla_partido (id_partido, ci_jugador, id_equipo) VALUES
    (7, '45000001', 1),
    (7, '45000038', 1),
    (7, '45000075', 1),
    (7, '45000112', 1),
    (7, '45000149', 1),
    (7, '45000186', 1),
    (7, '45003778', 4),
    (7, '45003815', 4),
    (7, '45003852', 4),
    (7, '45003889', 4),
    (7, '45003926', 4),

    (8, '45001260', 2),
    (8, '45001297', 2),
    (8, '45001334', 2),
    (8, '45001371', 2),
    (8, '45001408', 2),
    (8, '45006296', 6),
    (8, '45006333', 6),
    (8, '45006370', 6),
    (8, '45006407', 6),
    (8, '45006444', 6),
    (8, '45006481', 6),

    (9, '45002519', 3),
    (9, '45002556', 3),
    (9, '45002593', 3),
    (9, '45002630', 3),
    (9, '45002667', 3),
    (9, '45002704', 3),
    (9, '45002741', 3),
    (9, '45005037', 5),
    (9, '45005074', 5),
    (9, '45005148', 5),
    (9, '45005185', 5),
    (9, '45005222', 5),
    (9, '45005259', 5);

INSERT INTO gol (id_partido, ci_jugador, minuto, autogol) VALUES
    (7, '45000075', 41, FALSE),
    (8, '45001297', 14, FALSE),
    (8, '45006407', 25, FALSE),
    (8, '45001260', 36, FALSE),
    (8, '45006444', 57, FALSE),
    (9, '45005037', 31, FALSE);

INSERT INTO tarjeta (id_partido, ci_jugador, minuto, color) VALUES
    (7, '45003815', 15, 'amarilla'),
    (7, '45000112', 50, 'roja'),
    (9, '45002556', 48, 'amarilla');

-- 14_reportes_planilla.sql
CREATE VIEW resultado_partido AS
SELECT p.id_partido, p.id_torneo, p.numero_fecha, p.id_equipo_local, p.id_equipo_visitante,
       SUM(CASE WHEN (pl.id_equipo = p.id_equipo_local AND g.autogol = FALSE)
                  OR (pl.id_equipo = p.id_equipo_visitante AND g.autogol = TRUE) THEN 1 ELSE 0 END) AS goles_local,
       SUM(CASE WHEN (pl.id_equipo = p.id_equipo_visitante AND g.autogol = FALSE)
                  OR (pl.id_equipo = p.id_equipo_local AND g.autogol = TRUE) THEN 1 ELSE 0 END) AS goles_visitante
FROM partido p
LEFT JOIN gol g ON g.id_partido = p.id_partido
LEFT JOIN planilla_partido pl ON pl.id_partido = g.id_partido AND pl.ci_jugador = g.ci_jugador
WHERE p.estado = 'jugado'
GROUP BY p.id_partido, p.id_torneo, p.numero_fecha, p.id_equipo_local, p.id_equipo_visitante;

CREATE VIEW reporte_posiciones AS
SELECT t.id_torneo, t.nombre AS torneo, e.nombre AS equipo,
       COUNT(r.id_equipo) AS pj,
       SUM(CASE WHEN r.gf > r.gc THEN 1 ELSE 0 END) AS pg,
       SUM(CASE WHEN r.gf = r.gc THEN 1 ELSE 0 END) AS pe,
       SUM(CASE WHEN r.gf < r.gc THEN 1 ELSE 0 END) AS pp,
       COALESCE(SUM(r.gf), 0) AS gf,
       COALESCE(SUM(r.gc), 0) AS gc,
       COALESCE(SUM(r.gf), 0) - COALESCE(SUM(r.gc), 0) AS dg,
       SUM(CASE WHEN r.gf > r.gc THEN 3 WHEN r.gf = r.gc THEN 1 ELSE 0 END) AS puntos
FROM equipo e
JOIN torneo t ON t.id_torneo = e.id_torneo
LEFT JOIN (SELECT id_equipo_local AS id_equipo, goles_local AS gf, goles_visitante AS gc FROM resultado_partido
           UNION ALL
           SELECT id_equipo_visitante, goles_visitante, goles_local FROM resultado_partido) r ON r.id_equipo = e.id_equipo
GROUP BY t.id_torneo, t.nombre, e.id_equipo, e.nombre
ORDER BY t.id_torneo, puntos DESC, dg DESC, gf DESC;

CREATE VIEW reporte_goleadores AS
SELECT t.id_torneo, t.nombre AS torneo, j.nombre, j.apellido, e.nombre AS equipo, COUNT(*) AS goles
FROM gol g
JOIN planilla_partido pl ON pl.id_partido = g.id_partido AND pl.ci_jugador = g.ci_jugador
JOIN equipo e ON e.id_equipo = pl.id_equipo
JOIN torneo t ON t.id_torneo = e.id_torneo
JOIN jugador j ON j.ci = g.ci_jugador
WHERE g.autogol = FALSE
GROUP BY t.id_torneo, t.nombre, j.ci, j.nombre, j.apellido, e.nombre
ORDER BY t.id_torneo, goles DESC, j.apellido;

CREATE VIEW reporte_fair_play AS
SELECT t.id_torneo, t.nombre AS torneo, e.nombre AS equipo,
       SUM(CASE WHEN ta.color = 'amarilla' THEN 1 ELSE 0 END) AS amarillas,
       SUM(CASE WHEN ta.color = 'roja' THEN 1 ELSE 0 END) AS rojas,
       SUM(CASE WHEN ta.color = 'amarilla' THEN 1 WHEN ta.color = 'roja' THEN 3 ELSE 0 END) AS puntos
FROM equipo e
JOIN torneo t ON t.id_torneo = e.id_torneo
LEFT JOIN planilla_partido pl ON pl.id_equipo = e.id_equipo
LEFT JOIN tarjeta ta ON ta.id_partido = pl.id_partido AND ta.ci_jugador = pl.ci_jugador
GROUP BY t.id_torneo, t.nombre, e.id_equipo, e.nombre
ORDER BY t.id_torneo, puntos, e.nombre;

-- 15_reportes_jugadores.sql
CREATE VIEW reporte_jugadores_por_facultad AS
SELECT f.nombre AS facultad, COUNT(j.ci) AS cantidad_jugadores
FROM facultad f
LEFT JOIN jugador j ON j.id_facultad = f.id_facultad
GROUP BY f.id_facultad, f.nombre
ORDER BY cantidad_jugadores DESC, f.nombre;

CREATE VIEW reporte_jugadores_por_tipo AS
SELECT tipo, COUNT(*) AS cantidad_jugadores
FROM jugador
GROUP BY tipo
ORDER BY cantidad_jugadores DESC;

CREATE VIEW reporte_jugadores_por_facultad_y_tipo AS
SELECT f.nombre AS facultad,
       COUNT(CASE WHEN j.tipo = 'grado' THEN 1 END) AS grado,
       COUNT(CASE WHEN j.tipo = 'posgrado' THEN 1 END) AS posgrado,
       COUNT(CASE WHEN j.tipo = 'docente' THEN 1 END) AS docente,
       COUNT(CASE WHEN j.tipo = 'funcionario' THEN 1 END) AS funcionario,
       COUNT(j.ci) AS total
FROM facultad f
LEFT JOIN jugador j ON j.id_facultad = f.id_facultad
GROUP BY f.id_facultad, f.nombre
ORDER BY total DESC, f.nombre;

CREATE VIEW reporte_nunca_en_planilla AS
SELECT t.id_torneo, t.nombre AS torneo, e.nombre AS equipo, j.ci, j.nombre, j.apellido, j.tipo
FROM equipo_jugador_torneo ej
JOIN equipo e ON e.id_equipo = ej.id_equipo
JOIN torneo t ON t.id_torneo = ej.id_torneo
JOIN jugador j ON j.ci = ej.ci_jugador
WHERE NOT EXISTS (SELECT * FROM planilla_partido pl
                  WHERE pl.id_equipo = ej.id_equipo
                    AND pl.ci_jugador = ej.ci_jugador)
ORDER BY t.id_torneo, e.nombre, j.apellido;

CREATE VIEW reporte_sanciones_por_equipo AS
SELECT t.id_torneo, t.nombre AS torneo, e.nombre AS equipo, COUNT(s.id_sancion) AS cantidad_sanciones
FROM equipo e
JOIN torneo t ON t.id_torneo = e.id_torneo
LEFT JOIN equipo_jugador_torneo ej ON ej.id_equipo = e.id_equipo
LEFT JOIN sancion_jugador s ON s.id_torneo = ej.id_torneo AND s.ci_jugador = ej.ci_jugador
GROUP BY t.id_torneo, t.nombre, e.id_equipo, e.nombre
ORDER BY t.id_torneo, cantidad_sanciones DESC, e.nombre;

CREATE VIEW reporte_sanciones_por_motivo AS
SELECT t.id_torneo, t.nombre AS torneo, s.motivo, COUNT(*) AS cantidad_sanciones
FROM sancion_jugador s
JOIN torneo t ON t.id_torneo = s.id_torneo
GROUP BY t.id_torneo, t.nombre, s.motivo
ORDER BY t.id_torneo, cantidad_sanciones DESC;

-- 16_usuarios.sql
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

-- 17_partido_prueba_48h.sql
-- Partido de prueba para cargar planillas, goles y tarjetas: se pasa un partido programado
-- al día de ayer y se marca jugado, así queda dentro de las 48 horas y sin planilla.
UPDATE partido
SET dia = CURDATE() - INTERVAL 1 DAY, estado = 'jugado'
WHERE id_torneo = 1 AND numero_fecha = 4 AND id_equipo_local = 1 AND id_equipo_visitante = 5;

-- 18_ajustes.sql
-- Validaciones de formato en la base (las mismas que hacen el backend y el formulario)
ALTER TABLE jugador
    ADD CONSTRAINT chk_jugador_ci CHECK (ci REGEXP '^[0-9]{7,8}$'),
    ADD CONSTRAINT chk_jugador_email CHECK (email REGEXP '^[^@ ]+@[^@ ]+[.][^@ ]+$');

ALTER TABLE login
    ADD CONSTRAINT chk_login_correo CHECK (correo REGEXP '^[^@ ]+@[^@ ]+[.][^@ ]+$');

-- El planillero marca el partido como jugado (solo puede tocar la columna estado;
-- el trigger de partido sigue exigiendo que el día y el turno ya hayan pasado)
GRANT UPDATE (estado) ON torneo.partido TO 'planillero'@'%';

-- 18_reportes_extra.sql
-- Las 3 consultas que propusimos nosotros (además de los reportes que pide la letra).
-- Usan la vista resultado_partido de 14_reportes_planilla.sql, por eso van después.

-- 1. Suspendidos para la próxima fecha.
-- Sirve para que los equipos sepan con quién no cuentan antes de armar el equipo.
-- La "próxima fecha" de cada torneo es la fecha más baja que todavía tiene partidos sin jugar
-- (programados o postergados). Se usa la misma cuenta que el trigger de la planilla:
-- un jugador está suspendido si esa fecha cae entre el inicio y el fin de su sanción.
CREATE VIEW reporte_suspendidos AS
SELECT t.id_torneo, t.nombre AS torneo, prox.numero_fecha AS proxima_fecha,
       e.nombre AS equipo, j.ci, j.nombre, j.apellido, s.motivo,
       s.numero_fecha_inicio + s.cantidad_fechas - 1 AS suspendido_hasta_fecha
FROM (SELECT id_torneo, MIN(numero_fecha) AS numero_fecha
      FROM partido
      WHERE estado IN ('programado', 'postergado')
      GROUP BY id_torneo) prox
JOIN torneo t ON t.id_torneo = prox.id_torneo
JOIN sancion_jugador s ON s.id_torneo = prox.id_torneo
                      AND prox.numero_fecha BETWEEN s.numero_fecha_inicio
                                                AND s.numero_fecha_inicio + s.cantidad_fechas - 1
JOIN jugador j ON j.ci = s.ci_jugador
JOIN equipo_jugador_torneo ejt ON ejt.id_torneo = s.id_torneo AND ejt.ci_jugador = s.ci_jugador
JOIN equipo e ON e.id_equipo = ejt.id_equipo
ORDER BY t.id_torneo, e.nombre, j.apellido;

-- 2. Partidos con más goles.
-- Los partidos jugados ordenados por la cantidad total de goles (los más "vistosos" del torneo).
CREATE VIEW reporte_partidos_mas_goles AS
SELECT r.id_torneo, t.nombre AS torneo, r.numero_fecha,
       el.nombre AS equipo_local, ev.nombre AS equipo_visitante,
       CONCAT(r.goles_local, ' - ', r.goles_visitante) AS resultado,
       r.goles_local + r.goles_visitante AS total_goles
FROM resultado_partido r
JOIN torneo t  ON t.id_torneo = r.id_torneo
JOIN equipo el ON el.id_equipo = r.id_equipo_local
JOIN equipo ev ON ev.id_equipo = r.id_equipo_visitante
ORDER BY r.id_torneo, total_goles DESC, r.numero_fecha;

-- 3. Rendimiento de local y de visitante.
-- Compara cómo les va a los equipos jugando de local contra jugando de visitante:
-- partidos ganados, empatados y perdidos, goles y promedio de puntos por partido.
CREATE VIEW reporte_local_vs_visitante AS
SELECT x.id_torneo, t.nombre AS torneo, x.condicion,
       COUNT(*) AS partidos,
       SUM(x.gf > x.gc) AS ganados,
       SUM(x.gf = x.gc) AS empatados,
       SUM(x.gf < x.gc) AS perdidos,
       SUM(x.gf) AS goles_a_favor,
       SUM(x.gc) AS goles_en_contra,
       ROUND(SUM(CASE WHEN x.gf > x.gc THEN 3 WHEN x.gf = x.gc THEN 1 ELSE 0 END) / COUNT(*), 2) AS puntos_por_partido
FROM (SELECT id_torneo, 'local' AS condicion, goles_local AS gf, goles_visitante AS gc FROM resultado_partido
      UNION ALL
      SELECT id_torneo, 'visitante', goles_visitante, goles_local FROM resultado_partido) x
JOIN torneo t ON t.id_torneo = x.id_torneo
GROUP BY x.id_torneo, t.nombre, x.condicion
ORDER BY x.id_torneo, x.condicion;

-- 99_triggers_48h.sql
DELIMITER //

CREATE TRIGGER gol_48h_insert BEFORE INSERT ON gol
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT * FROM partido p
               JOIN turno t ON t.id_turno = p.id_turno
               WHERE p.id_partido = NEW.id_partido
                 AND TIMESTAMP(p.dia, t.hora_fin) + INTERVAL 48 HOUR < NOW()) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pasaron mas de 48 horas del partido';
    END IF;
END //

CREATE TRIGGER gol_48h_update BEFORE UPDATE ON gol
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT * FROM partido p
               JOIN turno t ON t.id_turno = p.id_turno
               WHERE p.id_partido = OLD.id_partido
                 AND TIMESTAMP(p.dia, t.hora_fin) + INTERVAL 48 HOUR < NOW()) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pasaron mas de 48 horas del partido';
    END IF;
END //

CREATE TRIGGER gol_48h_delete BEFORE DELETE ON gol
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT * FROM partido p
               JOIN turno t ON t.id_turno = p.id_turno
               WHERE p.id_partido = OLD.id_partido
                 AND TIMESTAMP(p.dia, t.hora_fin) + INTERVAL 48 HOUR < NOW()) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pasaron mas de 48 horas del partido';
    END IF;
END //

CREATE TRIGGER tarjeta_48h_insert BEFORE INSERT ON tarjeta
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT * FROM partido p
               JOIN turno t ON t.id_turno = p.id_turno
               WHERE p.id_partido = NEW.id_partido
                 AND TIMESTAMP(p.dia, t.hora_fin) + INTERVAL 48 HOUR < NOW()) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pasaron mas de 48 horas del partido';
    END IF;
END //

CREATE TRIGGER tarjeta_48h_update BEFORE UPDATE ON tarjeta
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT * FROM partido p
               JOIN turno t ON t.id_turno = p.id_turno
               WHERE p.id_partido = OLD.id_partido
                 AND TIMESTAMP(p.dia, t.hora_fin) + INTERVAL 48 HOUR < NOW()) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pasaron mas de 48 horas del partido';
    END IF;
END //

CREATE TRIGGER tarjeta_48h_delete BEFORE DELETE ON tarjeta
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT * FROM partido p
               JOIN turno t ON t.id_turno = p.id_turno
               WHERE p.id_partido = OLD.id_partido
                 AND TIMESTAMP(p.dia, t.hora_fin) + INTERVAL 48 HOUR < NOW()) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pasaron mas de 48 horas del partido';
    END IF;
END //

CREATE TRIGGER planilla_48h_insert BEFORE INSERT ON planilla_partido
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT * FROM partido p
               JOIN turno t ON t.id_turno = p.id_turno
               WHERE p.id_partido = NEW.id_partido
                 AND TIMESTAMP(p.dia, t.hora_fin) + INTERVAL 48 HOUR < NOW()) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pasaron mas de 48 horas del partido';
    END IF;
END //

CREATE TRIGGER planilla_48h_delete BEFORE DELETE ON planilla_partido
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT * FROM partido p
               JOIN turno t ON t.id_turno = p.id_turno
               WHERE p.id_partido = OLD.id_partido
                 AND TIMESTAMP(p.dia, t.hora_fin) + INTERVAL 48 HOUR < NOW()) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pasaron mas de 48 horas del partido';
    END IF;
END //

DELIMITER ;