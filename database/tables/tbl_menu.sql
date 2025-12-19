CREATE TABLE PORTAL_COMERCIAL.dbo.tbl_menu (
	idMenu int IDENTITY(1,1) NOT NULL,
	nombre nvarchar(20) COLLATE Modern_Spanish_CI_AS NULL,
	ruta nvarchar(100) COLLATE Modern_Spanish_CI_AS NULL,
	icono nvarchar(20) COLLATE Modern_Spanish_CI_AS NULL,
	estado bit NULL,
	orden tinyint NULL,
	componente nvarchar(100) COLLATE Modern_Spanish_CI_AS NULL,
	CONSTRAINT PK__tbl_menu__C26AF48309BC5D39 PRIMARY KEY (idMenu)
);

INSERT INTO PORTAL_COMERCIAL.dbo.tbl_menu (nombre,ruta,icono,estado,orden,componente) VALUES
	 (N'Inicio',N'/',N'MdHome',1,1,N'HomePage'),
	 (N'Usuarios',N'/usuarios',N'FaUsers',1,2,N'UsuariosPage'),
	 (N'Perfiles',N'/perfiles',N'FaBuilding',1,3,N'PerfilesPage'),
	 (N'Ventas PDV',N'/ventas',N'FaChartLine',1,4,N'HistoricoVentasPage'),
	 (N'Abonos',N'/abonos',N'MdAttachMoney',1,5,N'HistoricoAbonosPage'),
	 (N'Campañas',N'/campañas',N'MdCampaign',1,6,N'FlyersPage'),
	 (N'Ventas M.M',N'/avance-ventas',N'MdTrendingUp',1,7,N'HistoricoVentasMMPage'),
	 (N'Carga Imágenes',N'/carga-imagenes',N'MdTrendingUp',1,8,N'ImagenesPage'),
	 (N'Importar Data',N'/importar-data',N'FaFileExcel',1,9,N'ImportarDataPage'),
	 (N'Historial Log',N'/historial-log',N'FaHistory',1,10,N'HistorialLogPage');
INSERT INTO PORTAL_COMERCIAL.dbo.tbl_menu (nombre,ruta,icono,estado,orden,componente) VALUES
	 (N'Incidencias',N'/incidencias',N'MdReportProblem',1,11,N'IncidenciasPage'),
	 (N'Cierre Esquemas',N'/bonos',N'TbPigMoney',1,12,N'BonosPage'),
	 (N'Exportar Data',N'/exportar',N'FiDownload',1,13,N'ExportacionesPage'),
	 (N'Usuario Zonal',N'/zonal',N'FaUsers',1,14,N'ZonalUserPage'),
	 (N'Gestor Incidencia ',N'/incidencia-gestor',N'FaUsers',1,15,N'HomeIncidenciaPage'),
	 (N'Recargas Acumuladas',N'/recargas-acumuladas',N'MdPhoneIphone ',1,16,N'RecargasAcumuladasPage'),
	 (N'Calendario-Flyers',N'/calendario-aceleradores',N'FaCalendarAlt',1,17,N'CalendarioAceleradoresPage');
INSERT INTO PORTAL_COMERCIAL.dbo.tbl_menu (nombre,ruta,icono,estado,orden,componente) VALUES
	 (N'Ventas Postpago',N'/ventas-postpago',N'MdPayments',1,18,N'AbonoInicialPostpagoPage');
