CREATE TABLE [dbo].[users](
	[id] [int] PRIMARY KEY IDENTITY(1,1) NOT NULL,
	[idPerfil] [int] NOT NULL,
	[user] [varchar](255) NOT NULL,
	[password] [varbinary](64) NULL,
	[zonal] [varchar](100) NOT NULL,
	[created_by] [varchar](255) NOT NULL,
	[created_at] [datetime] NOT NULL,
	[updated_by] [varchar](255) NULL,
	[updated_at] [datetime] NULL,
	[salt] [varchar](200) NULL,
)


PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[users] ADD  DEFAULT (getdate()) FOR [created_at]
GO