-- PORTAL_COMERCIAL.dbo.users definition

-- Drop table

-- DROP TABLE PORTAL_COMERCIAL.dbo.users;

CREATE TABLE PORTAL_COMERCIAL.dbo.users (
	id int IDENTITY(1,1) NOT NULL,
	idPerfil int NOT NULL,
	[user] varchar(255) COLLATE Modern_Spanish_CI_AS NOT NULL,
	password varbinary(64) NULL,
	zonal varchar(100) COLLATE Modern_Spanish_CI_AS NOT NULL,
	created_by varchar(255) COLLATE Modern_Spanish_CI_AS NOT NULL,
	created_at datetime NOT NULL,
	updated_by varchar(255) COLLATE Modern_Spanish_CI_AS NULL,
	updated_at datetime NULL,
	salt varchar(200) COLLATE Modern_Spanish_CI_AS NULL,
	estado tinyint NULL,
	CONSTRAINT PK__users__3213E83FA2D77C1B PRIMARY KEY (id)
);