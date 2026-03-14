-- =============================================
-- Tabla: RC_CLIENTE_PDV
-- Descripcion: Maestra de clientes/PDV para recopilacion.
--              Identificador principal: nro_documento (DNI/RUC).
--              Campos adicionales se pueden agregar luego.
-- =============================================
CREATE TABLE dbo.RC_CLIENTE_PDV (
    id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    nro_documento VARCHAR(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
    nombre_pdv VARCHAR(255) COLLATE Modern_Spanish_CI_AS NOT NULL,
    zonal VARCHAR(100) COLLATE Modern_Spanish_CI_AS NOT NULL,
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
