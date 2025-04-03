CREATE TABLE [dbo].[parametros](
	[id] [int] PRIMARY KEY IDENTITY(1,1) NOT NULL,
	[tipo] [int] NOT NULL,
	[level] [int] not NULL,
	[fecha] date NULL,
	[valor] [varchar](255) NOT NULL,
	[comentario] [varchar](500) NULL,
)

INSERT INTO PORTAL_COMERCIAL.dbo.parametros_ (tipo, [level], fecha, valor, comentario) VALUES(1, 0, null, N'2025-03-31', N'fecha máxima del funnel');
INSERT INTO PORTAL_COMERCIAL.dbo.parametros_ (tipo, [level], fecha, valor, comentario) VALUES(2, 0, null, N'2025-03-16', N'fecha de inicio para los MM quincenal');
INSERT INTO PORTAL_COMERCIAL.dbo.parametros_ (tipo, [level], fecha, valor, comentario) VALUES(3, 0, null, N'2025-03-31', N'fecha de fin para los MM quincenal');
INSERT INTO PORTAL_COMERCIAL.dbo.parametros_ (tipo, [level], fecha, valor, comentario) VALUES(5, 1, N'2025-03-31', 9, N'Condición de fecha de ventas para MM');



-- 

INSERT INTO PORTAL_COMERCIAL.dbo.parametros
(id, tipo, valor, comentario, [level])
VALUES(1, 1, N'2025-03-31', N'fecha máxima del funnel', NULL);
INSERT INTO PORTAL_COMERCIAL.dbo.parametros
(id, tipo, valor, comentario, [level])
VALUES(2, 2, N'2025-03-16', N'fecha de inicio para los MM quincenal', NULL);
INSERT INTO PORTAL_COMERCIAL.dbo.parametros
(id, tipo, valor, comentario, [level])
VALUES(3, 3, N'2025-03-31', N'fecha de fin para los MM quincenal', NULL);
INSERT INTO PORTAL_COMERCIAL.dbo.parametros
(id, tipo, valor, comentario, [level])
VALUES(4, 4, N'9', N'Condición de fecha de ventas para MM', NULL);


-- 
CREATE TABLE [dbo].[parametros](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[tipo] [int] NOT NULL,
	[valor] [varchar](255) NOT NULL,
	[comentario] [varchar](500) NULL,
	[level] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

