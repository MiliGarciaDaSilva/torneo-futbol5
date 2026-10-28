CREATE TABLE equipo (
    id_equipo   INT AUTO_INCREMENT PRIMARY KEY,
    nombre      VARCHAR(100) NOT NULL,
    id_torneo   INT NOT NULL,
    id_facultad INT NOT NULL,
    ci_capitan  VARCHAR(15) NOT NULL,
    UNIQUE (id_torneo, nombre),
    UNIQUE (id_torneo, id_facultad),
    FOREIGN KEY (id_torneo)   REFERENCES torneo(id_torneo),
    FOREIGN KEY (id_facultad) REFERENCES facultad(id_facultad),
    FOREIGN KEY (ci_capitan)  REFERENCES jugador(ci)
);

CREATE TABLE equipo_jugador_torneo (
    id_equipo      INT NOT NULL,
    ci_jugador     VARCHAR(15) NOT NULL,
    id_torneo      INT NOT NULL,
    numero_camiseta TINYINT NOT NULL,
    PRIMARY KEY (id_equipo, ci_jugador),
    UNIQUE (id_torneo, ci_jugador),
    UNIQUE (id_equipo, numero_camiseta),
    CHECK (numero_camiseta BETWEEN 1 AND 99),
    FOREIGN KEY (id_equipo)  REFERENCES equipo(id_equipo),
    FOREIGN KEY (ci_jugador) REFERENCES jugador(ci),
    FOREIGN KEY (id_torneo)  REFERENCES torneo(id_torneo)
);