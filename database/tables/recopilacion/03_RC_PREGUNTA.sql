-- =============================================
-- Tabla: RC_PREGUNTA
-- Descripcion: Catalogo de preguntas del formulario
-- =============================================
CREATE TABLE dbo.RC_PREGUNTA (
    id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    seccion_id INT NOT NULL,
    codigo VARCHAR(50) COLLATE Modern_Spanish_CI_AS NOT NULL,
    texto VARCHAR(1000) COLLATE Modern_Spanish_CI_AS NOT NULL,
    texto_ayuda VARCHAR(500) COLLATE Modern_Spanish_CI_AS NULL,
    tipo_respuesta VARCHAR(30) COLLATE Modern_Spanish_CI_AS NOT NULL,
    obligatoria BIT NOT NULL DEFAULT 0,
    permite_no_aplica BIT NOT NULL DEFAULT 0,
    requiere_foto BIT NOT NULL DEFAULT 0,
    min_fotos INT NOT NULL DEFAULT 0,
    max_fotos INT NOT NULL DEFAULT 0,
    orden INT NOT NULL,
    activo BIT NOT NULL DEFAULT 1,
    max_longitud INT NULL,
    valor_minimo DECIMAL(18,4) NULL,
    valor_maximo DECIMAL(18,4) NULL,
    fecha_creacion DATETIME NOT NULL DEFAULT GETDATE(),
    usuario_creacion VARCHAR(100) COLLATE Modern_Spanish_CI_AS NULL,
    fecha_actualizacion DATETIME NULL,
    usuario_actualizacion VARCHAR(100) COLLATE Modern_Spanish_CI_AS NULL,
    CONSTRAINT FK_RC_PREGUNTA_SECCION
        FOREIGN KEY (seccion_id) REFERENCES dbo.RC_SECCION(id),
    CONSTRAINT UQ_RC_PREGUNTA_SECCION_CODIGO UNIQUE (seccion_id, codigo),
    CONSTRAINT UQ_RC_PREGUNTA_SECCION_ORDEN UNIQUE (seccion_id, orden),
    CONSTRAINT CHK_RC_PREGUNTA_TIPO_RESPUESTA CHECK (
        tipo_respuesta IN (
            'texto_corto','texto_largo','numero','decimal','si_no',
            'opcion_unica','opcion_multiple','fecha','hora','audio'
        )
    ),
    CONSTRAINT CHK_RC_PREGUNTA_FOTOS CHECK (
        min_fotos >= 0 AND max_fotos >= 0 AND max_fotos >= min_fotos
    ),
    CONSTRAINT CHK_RC_PREGUNTA_ORDEN CHECK (orden >= 1),
    CONSTRAINT CHK_RC_PREGUNTA_MAX_LONGITUD CHECK (
        max_longitud IS NULL OR max_longitud >= 1
    ),
    CONSTRAINT CHK_RC_PREGUNTA_RANGO_NUMERICO CHECK (
        valor_minimo IS NULL OR valor_maximo IS NULL OR valor_maximo >= valor_minimo
    )
);

CREATE NONCLUSTERED INDEX IX_RC_PREGUNTA_SECCION
    ON dbo.RC_PREGUNTA (seccion_id ASC, orden ASC)
    INCLUDE (codigo, tipo_respuesta, obligatoria, requiere_foto, min_fotos, max_fotos, activo)
    WITH (PAD_INDEX = OFF, FILLFACTOR = 100, SORT_IN_TEMPDB = OFF,
          IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF,
          ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
    ON [PRIMARY];
