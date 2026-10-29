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