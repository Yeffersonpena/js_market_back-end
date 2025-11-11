CREATE TABLE PORTAL_COMERCIAL.dbo.VentasLog (
	FECHA date NULL,
	DNI_VENDEDOR varchar(8) COLLATE Modern_Spanish_CI_AS NULL,
	DNI_RESPONSABLE varchar(8) COLLATE Modern_Spanish_CI_AS NULL,
	VALOR_DNI_RESPONSABLE int NULL,
	VALOR_DNI_VENDEDOR int NULL,
	SOCIO varchar(100) COLLATE Modern_Spanish_CI_AS NULL,
	ZONAL varchar(100) COLLATE Modern_Spanish_CI_AS NULL,
	ACCION varchar(100) COLLATE Modern_Spanish_CI_AS NULL,
	REGION varchar(50) COLLATE Modern_Spanish_CI_AS NULL,
	IDENTIFICADOR int NULL,
	HORA varchar(4) COLLATE Modern_Spanish_CI_AS NULL,
	OPERATION_NAME varchar(50) COLLATE Modern_Spanish_CI_AS NULL,
	PRODUCT_NAME varchar(50) COLLATE Modern_Spanish_CI_AS NULL,
	ACTIVITY_RESULT varchar(20) COLLATE Modern_Spanish_CI_AS NULL,
	CLIENT_DNI varchar(8) COLLATE Modern_Spanish_CI_AS NULL,
	LINE_NUMBER varchar(15) COLLATE Modern_Spanish_CI_AS NULL,
	ICCID varchar(25) COLLATE Modern_Spanish_CI_AS NULL,
	SALES_TYPE varchar(20) COLLATE Modern_Spanish_CI_AS NULL,
	CLUSTERCALIDAD varchar(100) COLLATE Modern_Spanish_CI_AS NULL,
	MONTO_ACUMULADO_RECARGAS decimal(18,2) NULL,
	MONTO_PRIMERA_RECARGA decimal(18,2) NULL,
	MONTO_RECARGAS_DIA0 decimal(18,2) NULL,
	PROVINCIA varchar(100) COLLATE Modern_Spanish_CI_AS NULL,
	DISTRITO varchar(100) COLLATE Modern_Spanish_CI_AS NULL,
	FECHA_PRIMERA_RECARGA date NULL,
	PRODUCTOORIGEN varchar(100) COLLATE Modern_Spanish_CI_AS NULL,
	SELLER_IMEI varchar(50) COLLATE Modern_Spanish_CI_AS NULL
);

-- Índices para optimizar consultas de análisis de ventas
-- Índice para filtros por fecha (muy común en consultas de ventas)
CREATE INDEX IX_VentasLog_FECHA ON PORTAL_COMERCIAL.dbo.VentasLog (FECHA);

-- Índice para filtros por DNI vendedor
CREATE INDEX IX_VentasLog_DNI_VENDEDOR ON PORTAL_COMERCIAL.dbo.VentasLog (DNI_VENDEDOR);

-- Índice para filtros por DNI responsable
CREATE INDEX IX_VentasLog_DNI_RESPONSABLE ON PORTAL_COMERCIAL.dbo.VentasLog (DNI_RESPONSABLE);

-- Índice para filtros por zonal
CREATE INDEX IX_VentasLog_ZONAL ON PORTAL_COMERCIAL.dbo.VentasLog (ZONAL);

-- Índice para filtros por socio
CREATE INDEX IX_VentasLog_SOCIO ON PORTAL_COMERCIAL.dbo.VentasLog (SOCIO);

-- Índices compuestos para consultas comunes que combinan múltiples filtros
-- Índice compuesto para consultas por fecha y vendedor (muy común en análisis de ventas)
CREATE INDEX IX_VentasLog_FECHA_DNI_VENDEDOR ON PORTAL_COMERCIAL.dbo.VentasLog (FECHA, DNI_VENDEDOR);

-- Índice compuesto para consultas por fecha y zonal
CREATE INDEX IX_VentasLog_FECHA_ZONAL ON PORTAL_COMERCIAL.dbo.VentasLog (FECHA, ZONAL);

-- Índice compuesto para consultas por fecha y socio
CREATE INDEX IX_VentasLog_FECHA_SOCIO ON PORTAL_COMERCIAL.dbo.VentasLog (FECHA, SOCIO);