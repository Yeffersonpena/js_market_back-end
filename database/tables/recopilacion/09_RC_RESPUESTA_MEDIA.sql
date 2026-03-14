-- =============================================
-- Tabla: RC_RESPUESTA_MEDIA
-- Descripcion: Evidencias de respuesta (fotos/audio)
-- =============================================
CREATE TABLE dbo.RC_RESPUESTA_MEDIA (
    id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    respuesta_id BIGINT NOT NULL,
    tipo_media VARCHAR(20) COLLATE Modern_Spanish_CI_AS NOT NULL DEFAULT 'foto',
    ruta_archivo VARCHAR(500) COLLATE Modern_Spanish_CI_AS NOT NULL,
    nombre_archivo VARCHAR(255) COLLATE Modern_Spanish_CI_AS NULL,
    mime_type VARCHAR(100) COLLATE Modern_Spanish_CI_AS NULL,
    tamano_bytes BIGINT NULL,
    orden INT NOT NULL DEFAULT 1,
    fecha_subida DATETIME NOT NULL DEFAULT GETDATE(),
    usuario_subida VARCHAR(100) COLLATE Modern_Spanish_CI_AS NULL,
    CONSTRAINT FK_RC_RESPUESTA_MEDIA_RESPUESTA
        FOREIGN KEY (respuesta_id) REFERENCES dbo.RC_RESPUESTA(id) ON DELETE CASCADE,
    CONSTRAINT CHK_RC_RESPUESTA_MEDIA_TIPO CHECK (tipo_media IN ('foto','audio')),
    CONSTRAINT CHK_RC_RESPUESTA_MEDIA_ORDEN CHECK (orden >= 1)
);

CREATE NONCLUSTERED INDEX IX_RC_RESPUESTA_MEDIA_RESPUESTA
    ON dbo.RC_RESPUESTA_MEDIA (respuesta_id ASC, tipo_media ASC, orden ASC)
    INCLUDE (ruta_archivo, nombre_archivo, fecha_subida)
    WITH (PAD_INDEX = OFF, FILLFACTOR = 100, SORT_IN_TEMPDB = OFF,
          IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF,
          ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
    ON [PRIMARY];
