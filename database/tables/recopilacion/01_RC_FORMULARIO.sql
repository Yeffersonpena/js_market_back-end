-- =============================================
-- Tabla: RC_FORMULARIO
-- Descripcion: Versiones del formulario de recopilacion
-- =============================================
CREATE TABLE dbo.RC_FORMULARIO (
    id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    codigo VARCHAR(50) COLLATE Modern_Spanish_CI_AS NOT NULL,
    nombre VARCHAR(200) COLLATE Modern_Spanish_CI_AS NOT NULL,
    version INT NOT NULL,
    descripcion VARCHAR(500) COLLATE Modern_Spanish_CI_AS NULL,
    activo BIT NOT NULL DEFAULT 1,
    fecha_inicio_vigencia DATE NULL,
    fecha_fin_vigencia DATE NULL,
    fecha_creacion DATETIME NOT NULL DEFAULT GETDATE(),
    usuario_creacion VARCHAR(100) COLLATE Modern_Spanish_CI_AS NULL,
    fecha_actualizacion DATETIME NULL,
    usuario_actualizacion VARCHAR(100) COLLATE Modern_Spanish_CI_AS NULL,
    CONSTRAINT UQ_RC_FORMULARIO_CODIGO_VERSION UNIQUE (codigo, version),
    CONSTRAINT CHK_RC_FORMULARIO_VERSION CHECK (version >= 1),
    CONSTRAINT CHK_RC_FORMULARIO_VIGENCIA CHECK (
        fecha_fin_vigencia IS NULL OR
        fecha_inicio_vigencia IS NULL OR
        fecha_fin_vigencia >= fecha_inicio_vigencia
    )
);

CREATE NONCLUSTERED INDEX IX_RC_FORMULARIO_ACTIVO
    ON dbo.RC_FORMULARIO (activo ASC, codigo ASC, version DESC)
    WITH (PAD_INDEX = OFF, FILLFACTOR = 100, SORT_IN_TEMPDB = OFF,
          IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF,
          ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
    ON [PRIMARY];
