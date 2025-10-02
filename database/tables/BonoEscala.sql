CREATE TABLE PORTAL_COMERCIAL.dbo.BonoEscala (
	id int IDENTITY(1,1) NOT NULL,
	tipo_pdv varchar(30) COLLATE Modern_Spanish_CI_AS NOT NULL,
	zonal_pattern varchar(50) COLLATE Modern_Spanish_CI_AS NULL,
	fecha_inicio date NOT NULL,
	fecha_fin date NULL,
	rango_min int NOT NULL,
	rango_max int NOT NULL,
	ratio_min decimal(5,2) NOT NULL,
	bono decimal(18,2) NOT NULL,
	created_at datetime DEFAULT getdate() NOT NULL,
	updated_at datetime NULL,
	cantidad_calidad_min int NULL,
	min_dias_ventas int NULL,
	CONSTRAINT PK__BonoEsca__3213E83F7C14AEE4 PRIMARY KEY (id)
);