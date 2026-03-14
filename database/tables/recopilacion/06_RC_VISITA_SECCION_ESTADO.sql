-- =============================================
-- Tabla: RC_VISITA_SECCION_ESTADO
-- Descripcion: Estado/avance por cada seccion del formulario
-- =============================================
CREATE TABLE dbo.RC_VISITA_SECCION_ESTADO (
    id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    visita_id BIGINT NOT NULL,
    seccion_id INT NOT NULL,
    estado VARCHAR(20) COLLATE Modern_Spanish_CI_AS NOT NULL DEFAULT 'pendiente',
    porcentaje_avance DECIMAL(5,2) NOT NULL DEFAULT 0,
    fecha_guardado DATETIME NOT NULL DEFAULT GETDATE(),
    usuario_guardado VARCHAR(100) COLLATE Modern_Spanish_CI_AS NULL,
    CONSTRAINT FK_RC_VISITA_SECCION_ESTADO_VISITA
        FOREIGN KEY (visita_id) REFERENCES dbo.RC_VISITA_FORMULARIO(id) ON DELETE CASCADE,
    CONSTRAINT FK_RC_VISITA_SECCION_ESTADO_SECCION
        FOREIGN KEY (seccion_id) REFERENCES dbo.RC_SECCION(id),
    CONSTRAINT UQ_RC_VISITA_SECCION UNIQUE (visita_id, seccion_id),
    CONSTRAINT CHK_RC_VISITA_SECCION_ESTADO CHECK (estado IN ('pendiente','en_progreso','completa')),
    CONSTRAINT CHK_RC_VISITA_SECCION_AVANCE CHECK (porcentaje_avance >= 0 AND porcentaje_avance <= 100)
);

CREATE NONCLUSTERED INDEX IX_RC_VISITA_SECCION_ESTADO_VISITA
    ON dbo.RC_VISITA_SECCION_ESTADO (visita_id ASC, estado ASC)
    INCLUDE (seccion_id, porcentaje_avance, fecha_guardado)
    WITH (PAD_INDEX = OFF, FILLFACTOR = 100, SORT_IN_TEMPDB = OFF,
          IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF,
          ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
    ON [PRIMARY];
