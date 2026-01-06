-- Tabla: Blacklist de Usuarios (Bloqueados por Ventas Inusuales Postpago)
-- Fuente: Excel con datos de usuarios bloqueados enviado por compañero
-- Propósito: Registrar usuarios que han sido bloqueados por malas prácticas (ventas inusuales reincidentes)

CREATE TABLE PORTAL_COMERCIAL.dbo.blacklist_usuarios (
	ID BIGINT IDENTITY(1,1) NOT NULL
		CONSTRAINT PK_BlacklistUsuarios PRIMARY KEY,

	ZONAL VARCHAR(100) COLLATE Modern_Spanish_CI_AS NULL,
	FECHA_DE_SOLICITUD DATE NOT NULL,
	DNI_RESPONSABLE INT NULL,
	USUARIO INT NOT NULL,
	TIPO_DE_DNI VARCHAR(50) COLLATE Modern_Spanish_CI_AS NULL,
	CASUISTICA VARCHAR(255) COLLATE Modern_Spanish_CI_AS NULL,
	FECHA_CARGA DATETIME DEFAULT GETDATE() NOT NULL
);

-- Índices para optimizar consultas habituales
-- Índice para filtros por usuario (DNI del usuario bloqueado)
CREATE INDEX IX_BlacklistUsuarios_Usuario
	ON PORTAL_COMERCIAL.dbo.blacklist_usuarios (USUARIO);

-- Índice para filtros por DNI responsable
CREATE INDEX IX_BlacklistUsuarios_DNI_Responsable
	ON PORTAL_COMERCIAL.dbo.blacklist_usuarios (DNI_RESPONSABLE);

-- Índice para filtros por fecha de solicitud
CREATE INDEX IX_BlacklistUsuarios_FechaSolicitud
	ON PORTAL_COMERCIAL.dbo.blacklist_usuarios (FECHA_DE_SOLICITUD);

-- Índice para filtros por zonal
CREATE INDEX IX_BlacklistUsuarios_Zonal
	ON PORTAL_COMERCIAL.dbo.blacklist_usuarios (ZONAL);

-- Índice compuesto para consultas por usuario y fecha
CREATE INDEX IX_BlacklistUsuarios_Usuario_Fecha
	ON PORTAL_COMERCIAL.dbo.blacklist_usuarios (USUARIO, FECHA_DE_SOLICITUD);

