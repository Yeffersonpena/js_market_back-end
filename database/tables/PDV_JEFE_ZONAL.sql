-- =============================================
-- Tabla: PDV_JEFE_ZONAL
-- Descripcion: Maestra de jefes zonales de PDV.
-- Nota: Todas las variantes de zonal Lima se normalizan como LIMA SUR.
-- =============================================

CREATE TABLE dbo.PDV_JEFE_ZONAL (
    id INT IDENTITY(1,1) NOT NULL,
    zonal VARCHAR(100) COLLATE Modern_Spanish_CI_AS NOT NULL,
    nombre_jefe_zonal VARCHAR(150) COLLATE Modern_Spanish_CI_AS NOT NULL,
    dni_jefe_zonal VARCHAR(12) COLLATE Modern_Spanish_CI_AS NOT NULL,
    num_jefe_zonal VARCHAR(20) COLLATE Modern_Spanish_CI_AS NOT NULL,

    CONSTRAINT PK_PDV_JEFE_ZONAL PRIMARY KEY (id),
    CONSTRAINT UQ_PDV_JEFE_ZONAL_ZONAL UNIQUE (zonal)
);

INSERT INTO dbo.PDV_JEFE_ZONAL (
    zonal,
    nombre_jefe_zonal,
    dni_jefe_zonal,
    num_jefe_zonal
)
VALUES
    ('AYACUCHO', 'ANTHONY CANGANA PALOMINO', '47066592', '923004483'),
    ('CUSCO', 'MARTIN PAUCAR CCORAHUA', '46284947', '938224073'),
    ('H. CENTRO', 'LUIS MIGUEL ALVINO CALZADA', '43373925', '977259253'),
    ('H. SELVA', 'ALAN VALENCIA LLAJARUNA', '42942175', '958629051'),
    ('HUANUCO', 'MIGUEL ANGEL PICO VEGA', '001524263', '963365358'),
    ('ICA', 'ROBERTO FIDEL CHANG SALAS', '21526748', '956665310'),
    ('LIMA SUR', 'LUIS ENRRIQUE HERNANDEZ BARDALES', '45139383', '935726713'),
    ('PUCALLPA', 'JUAN DIEGO NUÑEZ AHUMADA', '72618955', '935766103'),
    ('PUNO', 'CARLA CONDORI ZAVALETA', '70405427', '978120820');
