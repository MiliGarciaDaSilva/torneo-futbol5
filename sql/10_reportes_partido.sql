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

-- Porcentaje de partidos por estado
CREATE VIEW reporte_porcentaje_estados AS
SELECT estado,
       COUNT(*) AS cantidad,
       ROUND(COUNT(*) * 100 / (SELECT COUNT(*) FROM partido), 2) AS porcentaje
FROM partido
GROUP BY estado;

-- Promedio de goles por fecha
CREATE VIEW reporte_promedio_goles_por_fecha AS
SELECT t.nombre AS torneo, p.numero_fecha,
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
