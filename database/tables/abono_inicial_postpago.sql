-- Tabla: Abono Inicial (Postpago)
-- Fuente inicial: registro manual (Excel) de recargas/abonos iniciales

CREATE TABLE PORTAL_COMERCIAL.dbo.abono_inicial_postpago (
	ID BIGINT IDENTITY(1,1) NOT NULL
		CONSTRAINT PK_AbonoInicialPostpago PRIMARY KEY,

	FECHA_HORA_RECARGA DATETIME2(0) NOT NULL,
	ZONAL VARCHAR(100) COLLATE Modern_Spanish_CI_AS NULL,
	ACCION VARCHAR(50) COLLATE Modern_Spanish_CI_AS NULL,
	DNI INT NOT NULL,
	RECARGADOR_CELULAR CHAR(9) COLLATE Modern_Spanish_CI_AS NOT NULL,
	MONTO DECIMAL(10,2) NOT NULL,
	SE_ABONO BIT DEFAULT 0 NOT NULL,
	FECHA_CARGA DATETIME DEFAULT GETDATE() NOT NULL
);

-- Índices para optimizar consultas habituales
CREATE INDEX IX_AbonoInicialPostpago_FechaHora
	ON PORTAL_COMERCIAL.dbo.abono_inicial_postpago (FECHA_HORA_RECARGA);

CREATE INDEX IX_AbonoInicialPostpago_DNI_FechaHora
	ON PORTAL_COMERCIAL.dbo.abono_inicial_postpago (DNI, FECHA_HORA_RECARGA);

CREATE INDEX IX_AbonoInicialPostpago_Recargador_FechaHora
	ON PORTAL_COMERCIAL.dbo.abono_inicial_postpago (RECARGADOR_CELULAR, FECHA_HORA_RECARGA);

CREATE INDEX IX_AbonoInicialPostpago_SeAbono_FechaHora
	ON PORTAL_COMERCIAL.dbo.abono_inicial_postpago (SE_ABONO, FECHA_HORA_RECARGA);


