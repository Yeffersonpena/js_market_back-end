-- =============================================
-- Tabla: PDV_VISITAS_AD_DIAS
-- Descripción: Almacena los días específicos programados para cada PDV AD (Tecnología y Telecom)
--              Una fila por cada día programado (relación 1:N con PDV_VISITAS_AD_PROGRAMACION)
-- Uso: Permite consultas eficientes por fecha para calendario y comparación VS
-- =============================================
CREATE TABLE dbo.PDV_VISITAS_AD_DIAS (
    id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,

    -- Relación con programación
    programacion_id INT NOT NULL,

    -- Información del día
    DIA_MES INT NOT NULL, -- 1-31
    FECHA_COMPLETA DATE NOT NULL, -- Fecha completa: debe calcularse en el proceso de registro (AÑO-MES-DIA_MES)

    -- Estado de la visita programada
    PROGRAMADO BIT NOT NULL DEFAULT 1, -- 1 = programado, 0 = no programado (para casos extraordinarios)
    es_extraordinario BIT NOT NULL DEFAULT 0, -- 1 = fuera de la frecuencia normal (modificación manual)

    -- Auditoría
    FECHA_CREACION DATETIME NULL DEFAULT GETDATE(),
    USUARIO_CREACION VARCHAR(100) COLLATE Modern_Spanish_CI_AS NULL,
    FECHA_ACTUALIZACION DATETIME NULL,
    USUARIO_ACTUALIZACION VARCHAR(100) COLLATE Modern_Spanish_CI_AS NULL,

    -- Constraints
    CONSTRAINT FK_PDV_VISITAS_AD_DIAS_PROGRAMACION
        FOREIGN KEY (programacion_id)
        REFERENCES dbo.PDV_VISITAS_AD_PROGRAMACION(id)
        ON DELETE CASCADE,
    CONSTRAINT CHK_PDV_VISITAS_AD_DIAS_DIA_MES
        CHECK (DIA_MES >= 1 AND DIA_MES <= 31),
    CONSTRAINT UQ_PDV_VISITAS_AD_DIAS_PROG_DIA
        UNIQUE (programacion_id, DIA_MES)
);

-- Índices críticos para performance de consultas
-- Índice principal para consultas del calendario (por fecha)
CREATE NONCLUSTERED INDEX IX_PDV_VISITAS_AD_DIAS_FECHA
    ON dbo.PDV_VISITAS_AD_DIAS (FECHA_COMPLETA ASC)
    INCLUDE (programacion_id, PROGRAMADO, es_extraordinario)
    WITH (PAD_INDEX = OFF, FILLFACTOR = 100, SORT_IN_TEMPDB = OFF,
          IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF,
          ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
    ON [PRIMARY];

-- Índice para consultas por programación específica
CREATE NONCLUSTERED INDEX IX_PDV_VISITAS_AD_DIAS_PROGRAMACION
    ON dbo.PDV_VISITAS_AD_DIAS (programacion_id ASC, FECHA_COMPLETA ASC)
    INCLUDE (DIA_MES, PROGRAMADO)
    WITH (PAD_INDEX = OFF, FILLFACTOR = 100, SORT_IN_TEMPDB = OFF,
          IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF,
          ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
    ON [PRIMARY];

-- Índice para consultas de días programados activos
CREATE NONCLUSTERED INDEX IX_PDV_VISITAS_AD_DIAS_PROGRAMADO
    ON dbo.PDV_VISITAS_AD_DIAS (FECHA_COMPLETA ASC, PROGRAMADO ASC)
    INCLUDE (programacion_id)
    WHERE PROGRAMADO = 1
    WITH (PAD_INDEX = OFF, FILLFACTOR = 100, SORT_IN_TEMPDB = OFF,
          IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF,
          ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
    ON [PRIMARY];

