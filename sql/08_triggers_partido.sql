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
