CREATE TABLE PORTAL_COMERCIAL.dbo.tbl_incentivos_diarios (
    id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    zonal VARCHAR(50) COLLATE Modern_Spanish_CI_AS NOT NULL,
    grupos VARCHAR(50) COLLATE Modern_Spanish_CI_AS NOT NULL,
    requisito_altas_pre TINYINT NULL,
    requisito_porta_pre TINYINT NULL,
    requisito_postpago TINYINT NULL,
    requisito_recargas TINYINT NULL,
    premio VARCHAR(120) COLLATE Modern_Spanish_CI_AS NOT NULL,
    prioridad TINYINT NOT NULL, -- Mayor número = prioridad más alta para premios excluyentes
    es_exclusivo BIT NOT NULL DEFAULT 1, -- 1 = solo puede ganar el de mayor prioridad dentro del mismo bloque
    frecuencia VARCHAR(20) COLLATE Modern_Spanish_CI_AS NOT NULL DEFAULT 'Diario',
    descripcion_detalle VARCHAR(200) COLLATE Modern_Spanish_CI_AS NULL,
    activo BIT NOT NULL DEFAULT 1
);

-- Reglas Huánuco (premio exclusivo: solo gana el de mayor prioridad que cumpla)
INSERT INTO PORTAL_COMERCIAL.dbo.tbl_incentivos_diarios
    (zonal, grupos, requisito_altas_pre, requisito_recargas, premio, prioridad, es_exclusivo, descripcion_detalle)
VALUES
    ('HUANUCO', 'G1,G2', 2, NULL, '1 TOMATODO O 1 AUDIFONO', 1, 1, '2 ALTAS PRE = 1 TOMATODO Ó 1 AUDIFONO'),
    ('HUANUCO', 'G1,G2', 2, 1, '1 TOMATODO + 1 AUDIFONO', 2, 1, '2 ALTAS PRE + 1 RECARGA = 1 TOMATODO + 1 AUDIFONO'),
    ('HUANUCO', 'G3,G4', 3, NULL, '1 TOMATODO O 1 AUDIFONO', 1, 1, '3 ALTAS PRE = 1 TOMATODO Ó 1 AUDIFONO'),
    ('HUANUCO', 'G3,G4', 3, 1, '1 TOMATODO + 1 AUDIFONO', 2, 1, '3 ALTAS PRE + 1 RECARGA = 1 TOMATODO + 1 AUDIFONO');

INSERT INTO PORTAL_COMERCIAL.dbo.tbl_incentivos_diarios
    (zonal, grupos, requisito_porta_pre, premio, prioridad, es_exclusivo, descripcion_detalle)
VALUES
    ('HUANUCO', 'G1,G2,G3,G4', 2, '1 CARGADOR', 1, 0, '2 PORTA PRE = 1 CARGADOR');

INSERT INTO PORTAL_COMERCIAL.dbo.tbl_incentivos_diarios
    (zonal, grupos, requisito_postpago, premio, prioridad, es_exclusivo, descripcion_detalle)
VALUES
    ('HUANUCO', 'G1,G2,G3,G4', 1, '1 CARGADOR', 1, 0, '1 POSTPAGO (ALTA O PORTA) = 1 CARGADOR');

-- Reglas Huancayo grupos G1 y G2
INSERT INTO PORTAL_COMERCIAL.dbo.tbl_incentivos_diarios
    (zonal, grupos, requisito_altas_pre, premio, prioridad, es_exclusivo, descripcion_detalle)
VALUES
    ('HUANCAYO', 'G1,G2', 2, '1 AUDIFONO', 1, 1, '2 ALTAS PRE = 1 AUDIFONO'),
    ('HUANCAYO', 'G1,G2', 3, '1 TOMATODO', 2, 1, '3 ALTAS PRE = 1 TOMATODO');

INSERT INTO PORTAL_COMERCIAL.dbo.tbl_incentivos_diarios
    (zonal, grupos, requisito_porta_pre, premio, prioridad, es_exclusivo, descripcion_detalle)
VALUES
    ('HUANCAYO', 'G1,G2', 2, '1 CARGADOR', 1, 0, '2 PORTA PRE = 1 CARGADOR');

-- Reglas Huancayo grupos G3 y G4
INSERT INTO PORTAL_COMERCIAL.dbo.tbl_incentivos_diarios
    (zonal, grupos, requisito_altas_pre, premio, prioridad, es_exclusivo, descripcion_detalle)
VALUES
    ('HUANCAYO', 'G3,G4', 2, '1 AUDIFONO', 1, 1, '2 ALTAS PRE = 1 AUDIFONO'),
    ('HUANCAYO', 'G3,G4', 3, '1 TOMATODO', 2, 1, '3 ALTAS PRE = 1 TOMATODO'),
    ('HUANCAYO', 'G3,G4', 4, '1 TOMATODO + 1 AUDIFONO', 3, 1, '4 ALTAS PRE = 1 TOMATODO + 1 AUDIFONO');

INSERT INTO PORTAL_COMERCIAL.dbo.tbl_incentivos_diarios
    (zonal, grupos, requisito_porta_pre, premio, prioridad, es_exclusivo, descripcion_detalle)
VALUES
    ('HUANCAYO', 'G3,G4', 2, '1 CARGADOR', 1, 0, '2 PORTA PRE = 1 CARGADOR');

