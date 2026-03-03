-- DISTRIBUTOR_DATAMART.dbo.YALI_STOCK definition

-- Drop table

-- DROP TABLE DISTRIBUTOR_DATAMART.dbo.YALI_STOCK;

CREATE TABLE DISTRIBUTOR_DATAMART.dbo.YALI_STOCK (
	idMovil int NULL,
	Codigo int NULL,
	EAN varchar(50) COLLATE Modern_Spanish_CI_AS NULL,
	Modelo varchar(200) COLLATE Modern_Spanish_CI_AS NULL,
	ModeloPadre varchar(200) COLLATE Modern_Spanish_CI_AS NULL,
	Tipo varchar(50) COLLATE Modern_Spanish_CI_AS NULL,
	IMEI varchar(50) COLLATE Modern_Spanish_CI_AS NULL,
	ICC varchar(50) COLLATE Modern_Spanish_CI_AS NULL,
	Numero varchar(50) COLLATE Modern_Spanish_CI_AS NULL,
	NombrePV varchar(50) COLLATE Modern_Spanish_CI_AS NULL,
	idTipoStock int NULL,
	TipoStock varchar(50) COLLATE Modern_Spanish_CI_AS NULL,
	Almacen varchar(100) COLLATE Modern_Spanish_CI_AS NULL,
	Proveedor varchar(200) COLLATE Modern_Spanish_CI_AS NULL,
	FechaFactura datetime NULL,
	Factura varchar(50) COLLATE Modern_Spanish_CI_AS NULL,
	Cant int NULL,
	FechaRecibido datetime NULL,
	antiguedad int NULL,
	Precio decimal(18,4) NULL,
	CodigoSAP varchar(50) COLLATE Modern_Spanish_CI_AS NULL,
	CodigoLote varchar(50) COLLATE Modern_Spanish_CI_AS NULL,
	nombrefamilia varchar(50) COLLATE Modern_Spanish_CI_AS NULL,
	nombrecategoria varchar(50) COLLATE Modern_Spanish_CI_AS NULL,
	SFID varchar(50) COLLATE Modern_Spanish_CI_AS NULL,
	regionPeru varchar(50) COLLATE Modern_Spanish_CI_AS NULL,
	zonaPeru varchar(50) COLLATE Modern_Spanish_CI_AS NULL,
	nombreCCVV varchar(50) COLLATE Modern_Spanish_CI_AS NULL,
	PVPImp decimal(18,4) NULL,
	CosteTotal decimal(18,4) NULL
);
