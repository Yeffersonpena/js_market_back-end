-- =============================================
-- Tabla: PDV_VISITAS_ELOT_DIAS_SEMANA
-- Descripción: Almacena los días de la semana programados para cada PDV ELOT
--              Una fila por cada día de semana programado (relación 1:N con PDV_VISITAS_ELOT_PROGRAMACION)
--              Programación por patrón semanal recurrente (todos los lunes, todos los martes, etc.)
-- Uso: Permite consultas eficientes por día de semana para calendario y comparación VS
-- =============================================
CREATE TABLE ELOT.dbo.PDV_VISITAS_ELOT_DIAS_SEMANA (
    id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,

    -- Relación con programación
    programacion_id INT NOT NULL,

    -- Información del día de semana
    DIA_SEMANA INT NOT NULL, -- 1=Lunes, 2=Martes, 3=Miércoles, 4=Jueves, 5=Viernes, 6=Sábado

    -- Estado de la visita programada
    PROGRAMADO BIT NOT NULL DEFAULT 1, -- 1 = programado, 0 = no programado

    -- Auditoría
    FECHA_CREACION DATETIME NULL DEFAULT GETDATE(),
    USUARIO_CREACION VARCHAR(100) COLLATE Modern_Spanish_CI_AS NULL,
    FECHA_ACTUALIZACION DATETIME NULL,
    USUARIO_ACTUALIZACION VARCHAR(100) COLLATE Modern_Spanish_CI_AS NULL,

    -- Constraints
    CONSTRAINT FK_PDV_VISITAS_ELOT_DIAS_PROGRAMACION
        FOREIGN KEY (programacion_id)
        REFERENCES ELOT.dbo.PDV_VISITAS_ELOT_PROGRAMACION(id)
        ON DELETE CASCADE,
    CONSTRAINT CHK_PDV_VISITAS_ELOT_DIAS_SEMANA
        CHECK (DIA_SEMANA >= 1 AND DIA_SEMANA <= 6), -- 1-6 (Lunes a Sábado)
    CONSTRAINT UQ_PDV_VISITAS_ELOT_DIAS_PROG_DIA
        UNIQUE (programacion_id, DIA_SEMANA)
);

-- Índices críticos para performance de consultas
-- Índice principal para consultas del calendario (por día de semana)
CREATE NONCLUSTERED INDEX IX_PDV_VISITAS_ELOT_DIAS_SEMANA
    ON ELOT.dbo.PDV_VISITAS_ELOT_DIAS_SEMANA (DIA_SEMANA ASC)
    INCLUDE (programacion_id, PROGRAMADO)
    WITH (PAD_INDEX = OFF, FILLFACTOR = 100, SORT_IN_TEMPDB = OFF,
          IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF,
          ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
    ON [PRIMARY];

-- Índice para consultas por programación específica
CREATE NONCLUSTERED INDEX IX_PDV_VISITAS_ELOT_DIAS_PROGRAMACION
    ON ELOT.dbo.PDV_VISITAS_ELOT_DIAS_SEMANA (programacion_id ASC, DIA_SEMANA ASC)
    INCLUDE (PROGRAMADO)
    WITH (PAD_INDEX = OFF, FILLFACTOR = 100, SORT_IN_TEMPDB = OFF,
          IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF,
          ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
    ON [PRIMARY];

-- Índice para consultas de días programados activos
CREATE NONCLUSTERED INDEX IX_PDV_VISITAS_ELOT_DIAS_PROGRAMADO
    ON ELOT.dbo.PDV_VISITAS_ELOT_DIAS_SEMANA (DIA_SEMANA ASC, PROGRAMADO ASC)
    INCLUDE (programacion_id)
    WHERE PROGRAMADO = 1
    WITH (PAD_INDEX = OFF, FILLFACTOR = 100, SORT_IN_TEMPDB = OFF,
          IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF,
          ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
    ON [PRIMARY];

