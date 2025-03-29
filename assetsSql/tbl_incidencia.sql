CREATE TABLE [dbo].[tbl_incidencia](
	[id] [int] PRIMARY KEY IDENTITY(1,1) NOT NULL,
	[dniIncidencia] int NULL,
	[fechaReporte] date NULL,
	[errorReportado] [varchar](200) NULL,
	[statusIncidencia] [varchar](200) NULL,
	[seSupero] [varchar](20) NULL,
	[tipoDni] [varchar](90) NULL,
	[dniResponsable] int NULL,
);