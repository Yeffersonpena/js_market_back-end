CREATE TABLE [dbo].[tbl_ingreso](
    [id] [int] PRIMARY KEY IDENTITY(1,1) NOT NULL,
	[user]  [varchar](90) NULL,
	[ip] [varchar](255) NOT NULL,
	[fecha] [DATETIME] NULL,
)