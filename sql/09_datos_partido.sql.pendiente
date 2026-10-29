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
