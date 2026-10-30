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
