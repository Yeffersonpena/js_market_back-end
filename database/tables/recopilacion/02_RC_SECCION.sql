-- =============================================
-- Tabla: RC_SECCION
-- Descripcion: Segmentos/pasos del formulario
-- =============================================
CREATE TABLE dbo.RC_SECCION (
    id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    formulario_id INT NOT NULL,
    codigo VARCHAR(50) COLLATE Modern_Spanish_CI_AS NOT NULL,
    titulo VARCHAR(200) COLLATE Modern_Spanish_CI_AS NOT NULL,
    descripcion VARCHAR(500) COLLATE Modern_Spanish_CI_AS NULL,
    orden INT NOT NULL,
    activo BIT NOT NULL DEFAULT 1,
    fecha_creacion DATETIME NOT NULL DEFAULT GETDATE(),
    usuario_creacion VARCHAR(100) COLLATE Modern_Spanish_CI_AS NULL,
    fecha_actualizacion DATETIME NULL,
    usuario_actualizacion VARCHAR(100) COLLATE Modern_Spanish_CI_AS NULL,
    CONSTRAINT FK_RC_SECCION_FORMULARIO
        FOREIGN KEY (formulario_id) REFERENCES dbo.RC_FORMULARIO(id),
    CONSTRAINT UQ_RC_SECCION_FORMULARIO_CODIGO UNIQUE (formulario_id, codigo),
    CONSTRAINT UQ_RC_SECCION_FORMULARIO_ORDEN UNIQUE (formulario_id, orden),
    CONSTRAINT CHK_RC_SECCION_ORDEN CHECK (orden >= 1)
);

CREATE NONCLUSTERED INDEX IX_RC_SECCION_FORMULARIO
    ON dbo.RC_SECCION (formulario_id ASC, orden ASC)
    INCLUDE (codigo, titulo, activo)
    WITH (PAD_INDEX = OFF, FILLFACTOR = 100, SORT_IN_TEMPDB = OFF,
          IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF,
          ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
    ON [PRIMARY];
