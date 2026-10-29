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