CREATE TABLE PORTAL_COMERCIAL.dbo.parametros (
	id int IDENTITY(1,1) NOT NULL,
	tipo int NOT NULL,
	[level] int NOT NULL,
	fecha date NULL,
	valor varchar(255) COLLATE Modern_Spanish_CI_AS NOT NULL,
	comentario varchar(500) COLLATE Modern_Spanish_CI_AS NULL,
	CONSTRAINT PK__parametr__3213E83F7E265F03 PRIMARY KEY (id)
);

INSERT INTO PORTAL_COMERCIAL.dbo.parametros (tipo,[level],fecha,valor,comentario) VALUES
	 (1,0,NULL,N'2025-12-25',N'(para manejar la fecha de renderizado del portal principal ))fecha máxima del funnel (solo es informativo en el portal)'),
	 (2,0,NULL,N'2025-07-01',N'fecha de inicio para los MM quincenal'),
	 (3,0,NULL,N'2025-07-31',N'fecha de fin para los MM quincenal'),
	 (5,1,'2025-03-31',N'9',N'Condición de fecha de ventas para MM'),
	 (5,2,'2025-03-31',N'30',N'minRatio'),
	 (5,3,'2025-03-31',N'45',N'maxRatio'),
	 (5,4,'2025-03-31',N'0',N'--'),
	 (5,1,'2025-04-01',N'11',N'Condición de fecha de ventas para MM'),
	 (5,2,'2025-04-01',N'35',N'minRatio'),
	 (5,3,'2025-04-01',N'45',N'maxRatio');
INSERT INTO PORTAL_COMERCIAL.dbo.parametros (tipo,[level],fecha,valor,comentario) VALUES
	 (5,4,'2025-04-01',N'0',N'--'),
	 (5,1,'2025-04-16',N'11',N'Condición de fecha de ventas para MM'),
	 (5,2,'2025-04-16',N'35',N'minRatio'),
	 (5,3,'2025-04-16',N'45',N'maxRatio'),
	 (5,4,'2025-04-16',N'0',N'--'),
	 (5,1,'2025-05-01',N'10',N'Condición de fecha de ventas para MM'),
	 (5,2,'2025-05-01',N'35',N'minRatio'),
	 (5,3,'2025-05-01',N'45',N'maxRatio'),
	 (5,4,'2025-05-01',N'0',N'--'),
	 (4,0,NULL,N'2025-12-21',N'fecha de actualización de calidad funnel');
INSERT INTO PORTAL_COMERCIAL.dbo.parametros (tipo,[level],fecha,valor,comentario) VALUES
	 (6,0,NULL,N'2025-05-18',N'fecha de la quincena, especificar si es Q1 o Q2'),
	 (7,0,'2025-06-01',N'10',N'Precio de calidad cuando no hay valores en la fila'),
	 (7,0,'2025-07-01',N'8',N'Precio de calidad cuando no hay valores en la fila'),
	 (8,0,'2025-06-01',N'35',N'Variable minima de calidad'),
	 (8,0,'2025-07-01',N'45',N'Variable minima de calidad');
INSERT INTO PORTAL_COMERCIAL.dbo.parametros (tipo,[level],fecha,valor,comentario) VALUES
	 (9,0,NULL,N'2025-11-01',N'Fecha máxima común calculada por sp_ActualizarEsquemaPDV PARA ESQUEMA PDV');

