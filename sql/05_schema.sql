CREATE TABLE partido (
    id_partido          INT AUTO_INCREMENT PRIMARY KEY,
    id_torneo           INT NOT NULL,
    numero_fecha        INT NOT NULL,
    id_equipo_local     INT NOT NULL,
    id_equipo_visitante INT NOT NULL,
    dia                 DATE NOT NULL,
    id_turno            INT NOT NULL,
    nombre_cancha       VARCHAR(50) NOT NULL,
    id_complejo         INT NOT NULL,
    estado              ENUM('programado', 'jugado', 'postergado', 'cancelado') NOT NULL DEFAULT 'programado',
    CHECK (numero_fecha >= 1),
    CHECK (id_equipo_local <> id_equipo_visitante),
    FOREIGN KEY (id_torneo)                      REFERENCES torneo(id_torneo),
    FOREIGN KEY (id_equipo_local, id_torneo)     REFERENCES equipo(id_equipo, id_torneo),
    FOREIGN KEY (id_equipo_visitante, id_torneo) REFERENCES equipo(id_equipo, id_torneo),
    FOREIGN KEY (id_turno)                       REFERENCES turno(id_turno),
    FOREIGN KEY (nombre_cancha, id_complejo)     REFERENCES cancha(nombre_cancha, id_complejo)
);