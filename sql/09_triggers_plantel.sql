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