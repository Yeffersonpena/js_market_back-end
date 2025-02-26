CREATE TABLE tbl_menu (
    idMenu INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(20) NULL,
    ruta NVARCHAR(100) NULL,
    icono NVARCHAR(20) NULL,
    estado BIT NULL,
    orden TINYINT NULL,
    componente NVARCHAR(100) NULL
);

INSERT INTO tbl_menu (nombre, ruta, icono, estado, orden, componente)
VALUES 
('Inicio', '/', 'MdHome', 1, 1, 'HomePage'),
('Usuarios', '/usuarios', 'FaUsers', 1, 2, 'UsuariosPage'),
('Perfiles', '/perfiles', 'FaBuilding', 1, 3, 'PerfilesPage'),
('Ventas PDV', '/ventas', 'FaChartLine', 1, 4, 'HistoricoVentasPage'),
('Abonos', '/abonos', 'MdAttachMoney', 1, 5, 'HistoricoAbonosPage'),
('Campañas', '/campañas', 'MdCampaign', 1, 6, 'FlyersPage'),
('Ventas M.M', '/avance-ventas', 'MdTrendingUp', 1, 7, 'HistoricoVentasMMPage'),
('Carga Imágenes', '/carga-imagenes', 'MdTrendingUp', 1, 8, 'ImagenesPage');