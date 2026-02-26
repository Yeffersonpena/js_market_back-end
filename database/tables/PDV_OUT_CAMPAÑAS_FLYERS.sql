-- PORTAL_COMERCIAL.dbo.PDV_OUT_CAMPAÑAS_FLYERS definition

-- Drop table

-- DROP TABLE PORTAL_COMERCIAL.dbo.PDV_OUT_CAMPAÑAS_FLYERS;

CREATE TABLE PORTAL_COMERCIAL.dbo.PDV_OUT_CAMPAÑAS_FLYERS (
	id int IDENTITY(1,1) NOT NULL,
	nombre_campaña varchar(150) COLLATE Modern_Spanish_CI_AS NOT NULL,
	foto_esquema varchar(200) COLLATE Modern_Spanish_CI_AS NOT NULL,
	fecha_inicio date NULL,
	fecha_fin date NULL,
	tipoImg varchar(50) COLLATE Modern_Spanish_CI_AS NOT NULL,
	modo varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,
	criterio_filtro varchar(500) COLLATE Modern_Spanish_CI_AS NULL,
	zonales varchar(500) COLLATE Modern_Spanish_CI_AS NULL,
	activa bit DEFAULT 1 NOT NULL,
	fecha_creacion datetime DEFAULT getdate() NULL,
	todos tinyint NULL,
	comunicado tinyint NULL,
	archivo_comunicacion varchar(200) COLLATE Modern_Spanish_CI_AS NULL,
	fecha_comunicacion date NULL,
	hora_inicio time NULL,
	hora_fin time NULL,
	CONSTRAINT PK__PDV_OUT___3213E83F021ED16C PRIMARY KEY (id)
);
ALTER TABLE PORTAL_COMERCIAL.dbo.PDV_OUT_CAMPAÑAS_FLYERS WITH NOCHECK ADD CONSTRAINT CK_modo_values CHECK (([modo]='TODOS' OR [modo]='MULTIMARCA' OR [modo]='PDV' OR [modo] IS NULL));

-- Vigencia por horas: NULL = todo el día; con valor = ventana horaria (ej. 11:00–14:00)
-- Solo para bases existentes creadas sin estas columnas:
IF COL_LENGTH('PORTAL_COMERCIAL.dbo.PDV_OUT_CAMPAÑAS_FLYERS', 'hora_inicio') IS NULL
	ALTER TABLE PORTAL_COMERCIAL.dbo.PDV_OUT_CAMPAÑAS_FLYERS ADD hora_inicio time NULL;
IF COL_LENGTH('PORTAL_COMERCIAL.dbo.PDV_OUT_CAMPAÑAS_FLYERS', 'hora_fin') IS NULL
	ALTER TABLE PORTAL_COMERCIAL.dbo.PDV_OUT_CAMPAÑAS_FLYERS ADD hora_fin time NULL;
