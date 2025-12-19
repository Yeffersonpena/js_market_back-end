CREATE TABLE PORTAL_COMERCIAL.dbo.abonos_postpago_log (
	FECHA date NOT NULL,
	ZONAL_JS varchar(100) COLLATE Modern_Spanish_CI_AS NULL,
	ACCION_JS varchar(50) COLLATE Modern_Spanish_CI_AS NULL,
	CANAL varchar(20) COLLATE Modern_Spanish_CI_AS NULL,
	DNI_RESPONSABLE varchar(8) COLLATE Modern_Spanish_CI_AS NOT NULL,
	NOMBRE_PDV varchar(255) COLLATE Modern_Spanish_CI_AS NULL,
	DNI_VENDEDOR varchar(8) COLLATE Modern_Spanish_CI_AS NOT NULL,
	NOMBRE_VVDD varchar(255) COLLATE Modern_Spanish_CI_AS NULL,
	RECARGADOR varchar(50) COLLATE Modern_Spanish_CI_AS NULL,
	Alta int NULL,
	Portabilidad int NULL,
	TOTAL int NULL,
	BONO decimal(10,2) NULL,
	ESTADO_ABONO varchar(20) COLLATE Modern_Spanish_CI_AS NULL,
	OBS varchar(50) COLLATE Modern_Spanish_CI_AS NULL,
	ESTADO_RECARGA bit DEFAULT 0 NOT NULL,
	FECHA_CARGA datetime DEFAULT GETDATE() NOT NULL,

	-- Clave única para evitar duplicados del mismo día
	CONSTRAINT PK_AbonosPostpagoLog PRIMARY KEY (FECHA, DNI_RESPONSABLE, DNI_VENDEDOR)
);

-- Índices para optimizar consultas
-- Índice para filtros por fecha (muy común en consultas)
CREATE INDEX IX_AbonosPostpagoLog_Fecha ON PORTAL_COMERCIAL.dbo.abonos_postpago_log (FECHA);

-- Índice para filtros por DNI vendedor
CREATE INDEX IX_AbonosPostpagoLog_DNI_Vendedor ON PORTAL_COMERCIAL.dbo.abonos_postpago_log (DNI_VENDEDOR);

-- Índice para filtros por DNI responsable
CREATE INDEX IX_AbonosPostpagoLog_DNI_Responsable ON PORTAL_COMERCIAL.dbo.abonos_postpago_log (DNI_RESPONSABLE);

-- Índice para filtros por estado de abono
CREATE INDEX IX_AbonosPostpagoLog_EstadoAbono ON PORTAL_COMERCIAL.dbo.abonos_postpago_log (ESTADO_ABONO);

-- Índice compuesto para consultas por fecha y estado
CREATE INDEX IX_AbonosPostpagoLog_Fecha_Estado ON PORTAL_COMERCIAL.dbo.abonos_postpago_log (FECHA, ESTADO_ABONO);

