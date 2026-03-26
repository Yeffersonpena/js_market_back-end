-- Tabla maestra de incentivos de logistica
-- Base de datos: DISTRIBUTOR_DATAMART
-- Define el incentivo, periodo, reglas generales y estado operativo

CREATE TABLE [DISTRIBUTOR_DATAMART].[dbo].[incentivo_cabecera] (
    id INT IDENTITY(1,1) NOT NULL,
    nombre_incentivo VARCHAR(150) COLLATE Modern_Spanish_CI_AS NOT NULL,
    tipo_incentivo VARCHAR(20) COLLATE Modern_Spanish_CI_AS NOT NULL,   -- BONO_EFECTIVO, SORTEO, MIXTO
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    descripcion VARCHAR(1000) COLLATE Modern_Spanish_CI_AS NULL,
    detalle_premios VARCHAR(1000) COLLATE Modern_Spanish_CI_AS NULL,    -- Texto libre para premios
    consideraciones VARCHAR(2000) COLLATE Modern_Spanish_CI_AS NULL,     -- Reglas del incentivo
    estado VARCHAR(20) COLLATE Modern_Spanish_CI_AS NOT NULL DEFAULT 'BORRADOR', -- BORRADOR, ACTIVO, CERRADO, LIQUIDADO
    activo BIT NOT NULL DEFAULT 1,
    created_by VARCHAR(100) COLLATE Modern_Spanish_CI_AS NULL,
    created_at DATETIME NOT NULL DEFAULT GETDATE(),
    updated_at DATETIME NULL,
    CONSTRAINT PK_incentivo_cabecera PRIMARY KEY (id),
    CONSTRAINT CK_incentivo_cabecera_tipo CHECK (tipo_incentivo IN ('BONO_EFECTIVO', 'SORTEO', 'MIXTO')),
    CONSTRAINT CK_incentivo_cabecera_estado CHECK (estado IN ('BORRADOR', 'ACTIVO', 'CERRADO', 'LIQUIDADO')),
    CONSTRAINT CK_incentivo_cabecera_periodo CHECK (fecha_inicio <= fecha_fin)
);

CREATE INDEX IX_incentivo_cabecera_periodo
ON [DISTRIBUTOR_DATAMART].[dbo].[incentivo_cabecera] (fecha_inicio, fecha_fin, activo);

CREATE INDEX IX_incentivo_cabecera_estado
ON [DISTRIBUTOR_DATAMART].[dbo].[incentivo_cabecera] (estado, activo);

