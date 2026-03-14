-- =============================================
-- Tabla: RC_VISITA_FORMULARIO
-- Descripcion: Instancia de formulario por punto (cliente o programacion AD)
-- =============================================
CREATE TABLE dbo.RC_VISITA_FORMULARIO (
    id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    cliente_id INT NULL,
    programacion_id INT NULL,
    formulario_id INT NOT NULL,
    anio INT NOT NULL,
    mes INT NOT NULL,
    dni_usuario INT NOT NULL,
    zonal_usuario VARCHAR(70) COLLATE Modern_Spanish_CI_AS NULL,
    estado VARCHAR(20) COLLATE Modern_Spanish_CI_AS NOT NULL DEFAULT 'borrador',
    porcentaje_avance DECIMAL(5,2) NOT NULL DEFAULT 0,
    cod_cliente VARCHAR(50) COLLATE Modern_Spanish_CI_AS NULL,
    nombre_punto VARCHAR(255) COLLATE Modern_Spanish_CI_AS NULL,
    direccion VARCHAR(500) COLLATE Modern_Spanish_CI_AS NULL,
    fecha_inicio DATETIME NOT NULL DEFAULT GETDATE(),
    fecha_ultima_edicion DATETIME NOT NULL DEFAULT GETDATE(),
    fecha_finalizacion DATETIME NULL,
    usuario_actualizacion VARCHAR(100) COLLATE Modern_Spanish_CI_AS NULL,
    CONSTRAINT FK_RC_VISITA_FORMULARIO_CLIENTE
        FOREIGN KEY (cliente_id) REFERENCES dbo.RC_CLIENTE_PDV(id),
    CONSTRAINT FK_RC_VISITA_FORMULARIO_PROGRAMACION
        FOREIGN KEY (programacion_id) REFERENCES dbo.PDV_VISITAS_AD_PROGRAMACION(id),
    CONSTRAINT FK_RC_VISITA_FORMULARIO_FORMULARIO
        FOREIGN KEY (formulario_id) REFERENCES dbo.RC_FORMULARIO(id),
    CONSTRAINT CHK_RC_VISITA_CLIENTE_O_PROGRAMACION
        CHECK (programacion_id IS NOT NULL OR cliente_id IS NOT NULL),
    CONSTRAINT CHK_RC_VISITA_ESTADO CHECK (estado IN ('borrador','en_progreso','finalizado')),
    CONSTRAINT CHK_RC_VISITA_PERIODO_ANIO CHECK (anio >= 2020 AND anio <= 2100),
    CONSTRAINT CHK_RC_VISITA_PERIODO_MES CHECK (mes >= 1 AND mes <= 12),
    CONSTRAINT CHK_RC_VISITA_AVANCE CHECK (porcentaje_avance >= 0 AND porcentaje_avance <= 100)
);

CREATE UNIQUE NONCLUSTERED INDEX UQ_RC_VISITA_PROGRAMACION_FORMULARIO_PERIODO
    ON dbo.RC_VISITA_FORMULARIO (programacion_id ASC, formulario_id ASC, anio ASC, mes ASC)
    WHERE programacion_id IS NOT NULL
    WITH (PAD_INDEX = OFF, FILLFACTOR = 100, SORT_IN_TEMPDB = OFF,
          IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF,
          ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
    ON [PRIMARY];

CREATE UNIQUE NONCLUSTERED INDEX UQ_RC_VISITA_CLIENTE_FORMULARIO_PERIODO
    ON dbo.RC_VISITA_FORMULARIO (cliente_id ASC, formulario_id ASC, anio ASC, mes ASC)
    WHERE cliente_id IS NOT NULL
    WITH (PAD_INDEX = OFF, FILLFACTOR = 100, SORT_IN_TEMPDB = OFF,
          IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF,
          ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
    ON [PRIMARY];

CREATE NONCLUSTERED INDEX IX_RC_VISITA_ZONAL_PERIODO
    ON dbo.RC_VISITA_FORMULARIO (zonal_usuario ASC, anio ASC, mes ASC, estado ASC)
    INCLUDE (cliente_id, programacion_id, dni_usuario, porcentaje_avance, fecha_ultima_edicion)
    WITH (PAD_INDEX = OFF, FILLFACTOR = 100, SORT_IN_TEMPDB = OFF,
          IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF,
          ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
    ON [PRIMARY];

CREATE NONCLUSTERED INDEX IX_RC_VISITA_USUARIO
    ON dbo.RC_VISITA_FORMULARIO (dni_usuario ASC, anio ASC, mes ASC)
    INCLUDE (cliente_id, programacion_id, estado, porcentaje_avance, fecha_ultima_edicion)
    WITH (PAD_INDEX = OFF, FILLFACTOR = 100, SORT_IN_TEMPDB = OFF,
          IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF,
          ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
    ON [PRIMARY];
