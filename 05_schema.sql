CREATE TABLE planilla_partido (
    id_partido INT NOT NULL,
    ci_jugador VARCHAR(15) NOT NULL,
    id_equipo  INT NOT NULL,
    PRIMARY KEY (id_partido, ci_jugador),
    FOREIGN KEY (id_partido)            REFERENCES partido(id_partido),
    FOREIGN KEY (id_equipo, ci_jugador) REFERENCES equipo_jugador_torneo(id_equipo, ci_jugador)
);

CREATE TABLE gol (
    id_gol     INT AUTO_INCREMENT PRIMARY KEY,
    id_partido INT NOT NULL,
    ci_jugador VARCHAR(15) NOT NULL,
    minuto     TINYINT NOT NULL,
    autogol    BOOLEAN NOT NULL DEFAULT FALSE,
    CHECK (minuto BETWEEN 1 AND 60),
    FOREIGN KEY (id_partido, ci_jugador) REFERENCES planilla_partido(id_partido, ci_jugador)
);

CREATE TABLE tarjeta (
    id_tarjeta INT AUTO_INCREMENT PRIMARY KEY,
    id_partido INT NOT NULL,
    ci_jugador VARCHAR(15) NOT NULL,
    minuto     TINYINT NOT NULL,
    color      ENUM('amarilla', 'roja') NOT NULL,
    CHECK (minuto BETWEEN 1 AND 60),
    FOREIGN KEY (id_partido, ci_jugador) REFERENCES planilla_partido(id_partido, ci_jugador)
);

CREATE TABLE sancion_jugador (
    id_sancion          INT AUTO_INCREMENT PRIMARY KEY,
    ci_jugador          VARCHAR(15) NOT NULL,
    id_torneo           INT NOT NULL,
    motivo              ENUM('roja', 'acumulacion de amarillas', 'disciplinaria') NOT NULL,
    numero_fecha_inicio INT NOT NULL,
    cantidad_fechas     INT NOT NULL DEFAULT 1,
    id_tarjeta          INT,
    CHECK (numero_fecha_inicio >= 1),
    CHECK (cantidad_fechas >= 1),
    FOREIGN KEY (id_torneo, ci_jugador) REFERENCES equipo_jugador_torneo(id_torneo, ci_jugador),
    FOREIGN KEY (id_tarjeta)            REFERENCES tarjeta(id_tarjeta) ON DELETE CASCADE
);