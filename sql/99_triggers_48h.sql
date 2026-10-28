DELIMITER //

CREATE TRIGGER gol_48h_insert BEFORE INSERT ON gol
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT * FROM partido p
               JOIN turno t ON t.id_turno = p.id_turno
               WHERE p.id_partido = NEW.id_partido
                 AND TIMESTAMP(p.dia, t.hora_fin) + INTERVAL 48 HOUR < NOW()) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pasaron mas de 48 horas del partido';
    END IF;
END //

CREATE TRIGGER gol_48h_update BEFORE UPDATE ON gol
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT * FROM partido p
               JOIN turno t ON t.id_turno = p.id_turno
               WHERE p.id_partido = OLD.id_partido
                 AND TIMESTAMP(p.dia, t.hora_fin) + INTERVAL 48 HOUR < NOW()) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pasaron mas de 48 horas del partido';
    END IF;
END //

CREATE TRIGGER gol_48h_delete BEFORE DELETE ON gol
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT * FROM partido p
               JOIN turno t ON t.id_turno = p.id_turno
               WHERE p.id_partido = OLD.id_partido
                 AND TIMESTAMP(p.dia, t.hora_fin) + INTERVAL 48 HOUR < NOW()) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pasaron mas de 48 horas del partido';
    END IF;
END //

CREATE TRIGGER tarjeta_48h_insert BEFORE INSERT ON tarjeta
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT * FROM partido p
               JOIN turno t ON t.id_turno = p.id_turno
               WHERE p.id_partido = NEW.id_partido
                 AND TIMESTAMP(p.dia, t.hora_fin) + INTERVAL 48 HOUR < NOW()) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pasaron mas de 48 horas del partido';
    END IF;
END //

CREATE TRIGGER tarjeta_48h_update BEFORE UPDATE ON tarjeta
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT * FROM partido p
               JOIN turno t ON t.id_turno = p.id_turno
               WHERE p.id_partido = OLD.id_partido
                 AND TIMESTAMP(p.dia, t.hora_fin) + INTERVAL 48 HOUR < NOW()) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pasaron mas de 48 horas del partido';
    END IF;
END //

CREATE TRIGGER tarjeta_48h_delete BEFORE DELETE ON tarjeta
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT * FROM partido p
               JOIN turno t ON t.id_turno = p.id_turno
               WHERE p.id_partido = OLD.id_partido
                 AND TIMESTAMP(p.dia, t.hora_fin) + INTERVAL 48 HOUR < NOW()) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pasaron mas de 48 horas del partido';
    END IF;
END //

CREATE TRIGGER planilla_48h_insert BEFORE INSERT ON planilla_partido
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT * FROM partido p
               JOIN turno t ON t.id_turno = p.id_turno
               WHERE p.id_partido = NEW.id_partido
                 AND TIMESTAMP(p.dia, t.hora_fin) + INTERVAL 48 HOUR < NOW()) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pasaron mas de 48 horas del partido';
    END IF;
END //

CREATE TRIGGER planilla_48h_delete BEFORE DELETE ON planilla_partido
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT * FROM partido p
               JOIN turno t ON t.id_turno = p.id_turno
               WHERE p.id_partido = OLD.id_partido
                 AND TIMESTAMP(p.dia, t.hora_fin) + INTERVAL 48 HOUR < NOW()) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pasaron mas de 48 horas del partido';
    END IF;
END //

DELIMITER ;