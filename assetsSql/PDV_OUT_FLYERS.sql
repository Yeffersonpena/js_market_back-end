CREATE TABLE [dbo].[PDV_OUT_FLYERS](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[año] [int] NULL,
	[mes] [int] NULL,
	[dni_responsable] [varchar](50) NULL,
	[zonal] [varchar](50) NULL,
	[foto_esquema] [varchar](200) NULL,
	[fecha_inicio] [date] NULL,
	[fecha_fin] [date] NULL,
 CONSTRAINT [PK_PDV_OUT_FLYERS_1] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]