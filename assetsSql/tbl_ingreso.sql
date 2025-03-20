CREATE TABLE [dbo].[tbl_ingreso](
    [id] [int] PRIMARY KEY IDENTITY(1,1) NOT NULL,
	[user] [int] NULL,
	[ip] [varchar](255) NOT NULL,
	[fecha] [date] NULL,
)