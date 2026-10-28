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