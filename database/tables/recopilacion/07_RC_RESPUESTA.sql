-- =============================================
-- Tabla: RC_RESPUESTA
-- Descripcion: Respuestas por pregunta (guardado parcial)
-- =============================================
CREATE TABLE dbo.RC_RESPUESTA (
    id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    visita_id BIGINT NOT NULL,
    pregunta_id INT NOT NULL,
    valor_texto VARCHAR(MAX) COLLATE Modern_Spanish_CI_AS NULL,
    valor_numero INT NULL,
    valor_decimal DECIMAL(18,4) NULL,
    valor_booleano BIT NULL,
    valor_fecha DATE NULL,
    valor_hora TIME NULL,
    observacion VARCHAR(1000) COLLATE Modern_Spanish_CI_AS NULL,
    no_aplica BIT NOT NULL DEFAULT 0,
    fecha_guardado DATETIME NOT NULL DEFAULT GETDATE(),
    usuario_guardado VARCHAR(100) COLLATE Modern_Spanish_CI_AS NULL,
    CONSTRAINT FK_RC_RESPUESTA_VISITA
        FOREIGN KEY (visita_id) REFERENCES dbo.RC_VISITA_FORMULARIO(id) ON DELETE CASCADE,
    CONSTRAINT FK_RC_RESPUESTA_PREGUNTA
        FOREIGN KEY (pregunta_id) REFERENCES dbo.RC_PREGUNTA(id),
    CONSTRAINT UQ_RC_RESPUESTA_VISITA_PREGUNTA UNIQUE (visita_id, pregunta_id)
);

CREATE NONCLUSTERED INDEX IX_RC_RESPUESTA_VISITA
    ON dbo.RC_RESPUESTA (visita_id ASC)
    INCLUDE (pregunta_id, no_aplica, fecha_guardado)
    WITH (PAD_INDEX = OFF, FILLFACTOR = 100, SORT_IN_TEMPDB = OFF,
          IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF,
          ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
    ON [PRIMARY];

CREATE NONCLUSTERED INDEX IX_RC_RESPUESTA_PREGUNTA
    ON dbo.RC_RESPUESTA (pregunta_id ASC)
    INCLUDE (visita_id, fecha_guardado)
    WITH (PAD_INDEX = OFF, FILLFACTOR = 100, SORT_IN_TEMPDB = OFF,
          IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF,
          ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
    ON [PRIMARY];
