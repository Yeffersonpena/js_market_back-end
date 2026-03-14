-- =============================================
-- Tabla: RC_RESPUESTA_OPCION
-- Descripcion: Opciones seleccionadas para preguntas de opcion multiple
-- =============================================
CREATE TABLE dbo.RC_RESPUESTA_OPCION (
    id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    respuesta_id BIGINT NOT NULL,
    opcion_id INT NOT NULL,
    fecha_guardado DATETIME NOT NULL DEFAULT GETDATE(),
    usuario_guardado VARCHAR(100) COLLATE Modern_Spanish_CI_AS NULL,
    CONSTRAINT FK_RC_RESPUESTA_OPCION_RESPUESTA
        FOREIGN KEY (respuesta_id) REFERENCES dbo.RC_RESPUESTA(id) ON DELETE CASCADE,
    CONSTRAINT FK_RC_RESPUESTA_OPCION_OPCION
        FOREIGN KEY (opcion_id) REFERENCES dbo.RC_PREGUNTA_OPCION(id),
    CONSTRAINT UQ_RC_RESPUESTA_OPCION UNIQUE (respuesta_id, opcion_id)
);

CREATE NONCLUSTERED INDEX IX_RC_RESPUESTA_OPCION_RESPUESTA
    ON dbo.RC_RESPUESTA_OPCION (respuesta_id ASC)
    INCLUDE (opcion_id, fecha_guardado)
    WITH (PAD_INDEX = OFF, FILLFACTOR = 100, SORT_IN_TEMPDB = OFF,
          IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF,
          ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
    ON [PRIMARY];
