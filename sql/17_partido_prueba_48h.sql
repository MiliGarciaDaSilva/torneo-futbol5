-- Partido de prueba para cargar planillas, goles y tarjetas: se pasa un partido programado
-- al día de ayer y se marca jugado, así queda dentro de las 48 horas y sin planilla.
UPDATE partido
SET dia = CURDATE() - INTERVAL 1 DAY, estado = 'jugado'
WHERE id_torneo = 1 AND numero_fecha = 4 AND id_equipo_local = 1 AND id_equipo_visitante = 5;
