ALTER TABLE equipo
    ADD UNIQUE (id_equipo, id_torneo);

ALTER TABLE equipo_jugador_torneo
    ADD FOREIGN KEY (id_equipo, id_torneo) REFERENCES equipo(id_equipo, id_torneo);

ALTER TABLE turno
    ADD CONSTRAINT chk_turno_horario CHECK (
        hora_inicio >= '18:00:00'
        AND hora_fin <= '23:00:00'
        AND TIMEDIFF(hora_fin, hora_inicio) = '01:00:00'
        );