-- =============================================
-- Tabla: RC_PREGUNTA_OPCION
-- Descripcion: Opciones para preguntas cerradas
-- =============================================
CREATE TABLE dbo.RC_PREGUNTA_OPCION (
    id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    pregunta_id INT NOT NULL,
    codigo VARCHAR(50) COLLATE Modern_Spanish_CI_AS NOT NULL,
    etiqueta VARCHAR(200) COLLATE Modern_Spanish_CI_AS NOT NULL,
    valor VARCHAR(200) COLLATE Modern_Spanish_CI_AS NULL,
    orden INT NOT NULL,
    activo BIT NOT NULL DEFAULT 1,
    fecha_creacion DATETIME NOT NULL DEFAULT GETDATE(),
    usuario_creacion VARCHAR(100) COLLATE Modern_Spanish_CI_AS NULL,
    fecha_actualizacion DATETIME NULL,
    usuario_actualizacion VARCHAR(100) COLLATE Modern_Spanish_CI_AS NULL,
    CONSTRAINT FK_RC_PREGUNTA_OPCION_PREGUNTA
        FOREIGN KEY (pregunta_id) REFERENCES dbo.RC_PREGUNTA(id),
    CONSTRAINT UQ_RC_PREGUNTA_OPCION_CODIGO UNIQUE (pregunta_id, codigo),
    CONSTRAINT UQ_RC_PREGUNTA_OPCION_ORDEN UNIQUE (pregunta_id, orden),
    CONSTRAINT CHK_RC_PREGUNTA_OPCION_ORDEN CHECK (orden >= 1)
);

CREATE NONCLUSTERED INDEX IX_RC_PREGUNTA_OPCION_PREGUNTA
    ON dbo.RC_PREGUNTA_OPCION (pregunta_id ASC, orden ASC)
    INCLUDE (codigo, etiqueta, valor, activo)
    WITH (PAD_INDEX = OFF, FILLFACTOR = 100, SORT_IN_TEMPDB = OFF,
          IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF,
          ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
    ON [PRIMARY];
