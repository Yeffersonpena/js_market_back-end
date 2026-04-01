-- =============================================
-- Tabla: RC_CLIENTE_PDV
-- Descripcion: Maestra de clientes/PDV para recopilacion.
--              Identificador principal: nro_documento (DNI/RUC).
--              Campos adicionales se pueden agregar luego.
-- =============================================
CREATE TABLE dbo.RC_CLIENTE_PDV (
    -- Orden exacto solicitado por negocio
    zonal VARCHAR(100) COLLATE Modern_Spanish_CI_AS NOT NULL,
    nro_documento VARCHAR(20) COLLATE Modern_Spanish_CI_AS NOT NULL, -- CDOC_IDE
    departamento VARCHAR(100) COLLATE Modern_Spanish_CI_AS NULL,
    provincia VARCHAR(100) COLLATE Modern_Spanish_CI_AS NULL,
    distrito VARCHAR(100) COLLATE Modern_Spanish_CI_AS NULL,
    direccion VARCHAR(255) COLLATE Modern_Spanish_CI_AS NULL,
    vendedor VARCHAR(150) COLLATE Modern_Spanish_CI_AS NULL,
    es_pdv_movistar BIT NULL,
    total_q_ventas_equipo INT NULL,
    total_s_venta_equipo DECIMAL(18,2) NULL,
    promedio_equipo DECIMAL(18,2) NULL,
    total_q_venta_accesorio INT NULL,
    total_s_venta_accesorio DECIMAL(18,2) NULL,
    promedio_accesorio DECIMAL(18,2) NULL,
    vende_equipos BIT NULL,      -- EQUIPOS
    vende_accesorios BIT NULL,   -- ACC
    total_eq_mas_acc DECIMAL(18,2) NULL,
    grupo VARCHAR(10) COLLATE Modern_Spanish_CI_AS NULL,

    -- Campos técnicos adicionales (fuera del orden de negocio)
    id INT IDENTITY(1,1) NOT NULL,
    nombre_pdv VARCHAR(255) COLLATE Modern_Spanish_CI_AS NULL,
    fecha_carga_metricas DATE NULL,

    CONSTRAINT PK_RC_CLIENTE_PDV PRIMARY KEY (id),
    CONSTRAINT UQ_RC_CLIENTE_PDV_NRO_DOCUMENTO UNIQUE (nro_documento)
);

CREATE NONCLUSTERED INDEX IX_RC_CLIENTE_PDV_ZONAL
    ON dbo.RC_CLIENTE_PDV (zonal ASC)
    INCLUDE (nro_documento, nombre_pdv)
    WITH (PAD_INDEX = OFF, FILLFACTOR = 100, SORT_IN_TEMPDB = OFF,
          IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF,
          ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
    ON [PRIMARY];

CREATE NONCLUSTERED INDEX IX_RC_CLIENTE_PDV_NOMBRE
    ON dbo.RC_CLIENTE_PDV (nombre_pdv ASC)
    INCLUDE (nro_documento, zonal)
    WITH (PAD_INDEX = OFF, FILLFACTOR = 100, SORT_IN_TEMPDB = OFF,
          IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF,
          ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
    ON [PRIMARY];
