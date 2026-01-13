CREATE TABLE PORTAL_COMERCIAL.dbo.PDV_OUT_FLYERS (
	id int NOT NULL,
	año int NULL,
	mes int NULL,
	dni_responsable varchar(50) COLLATE Modern_Spanish_CI_AS NULL,
	zonal varchar(50) COLLATE Modern_Spanish_CI_AS NULL,
	foto_esquema varchar(200) COLLATE Modern_Spanish_CI_AS NULL,
	fecha_inicio date NULL,
	fecha_fin date NULL,
	tipoImg varchar(50) COLLATE Modern_Spanish_CI_AS NULL,
	CONSTRAINT PK_PDV_OUT_FLYERS_1 PRIMARY KEY (id)
);
CREATE NONCLUSTERED INDEX IX_FLYERS_FOTO_ESQUEMA_DNI ON PORTAL_COMERCIAL.dbo.PDV_OUT_FLYERS (foto_esquema, dni_responsable);
