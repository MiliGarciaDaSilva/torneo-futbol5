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
