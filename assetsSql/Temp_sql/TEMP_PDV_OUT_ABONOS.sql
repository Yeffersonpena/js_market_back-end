CREATE TABLE [dbo].[TEMP_PDV_OUT_ABONOS](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[año] [int] NOT NULL,
	[mes] [int] NOT NULL,
	[DNI ] [varchar](50) NULL,
	[DETALLE] [nvarchar](255) NULL,
	[BONO TOTAL] [decimal](18, 4) NULL,
	[STATUS DEL ABONO] [nvarchar](255) NULL,
	[FECHAS_ABONO] [varchar](50) NULL
)