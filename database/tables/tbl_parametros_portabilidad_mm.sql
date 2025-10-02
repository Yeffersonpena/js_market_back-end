-- Tabla para gestionar parámetros de portabilidad multimarca por mes/año
-- Permite configurar precios unitarios de portabilidad prepago y postpago por período
CREATE TABLE tbl_parametros_portabilidad_mm (
    id INT IDENTITY(1,1) PRIMARY KEY,
    año INT NOT NULL,
    mes INT NOT NULL,
    tipo_portabilidad VARCHAR(20) NOT NULL, -- 'PREPAGO', 'POSTPAGO'
    precio_unitario DECIMAL(10,2) NOT NULL,
    fecha_inicio DATE,
    fecha_fin DATE,
    fecha_creacion DATETIME DEFAULT GETDATE()
);

-- =============================================
-- INSERCIÓN DE DATOS PARA TODOS LOS CASOS
-- =============================================

-- Enero a Agosto 2025: Precios históricos
INSERT INTO tbl_parametros_portabilidad_mm (año, mes, tipo_portabilidad, precio_unitario, fecha_inicio, fecha_fin) VALUES
(2025, 1, 'PREPAGO', 20.00, '2025-01-01', '2025-01-31'),
(2025, 1, 'POSTPAGO', 35.00, '2025-01-01', '2025-01-31'),
(2025, 2, 'PREPAGO', 20.00, '2025-02-01', '2025-02-28'),
(2025, 2, 'POSTPAGO', 35.00, '2025-02-01', '2025-02-28'),
(2025, 3, 'PREPAGO', 20.00, '2025-03-01', '2025-03-31'),
(2025, 3, 'POSTPAGO', 35.00, '2025-03-01', '2025-03-31'),
(2025, 4, 'PREPAGO', 20.00, '2025-04-01', '2025-04-30'),
(2025, 4, 'POSTPAGO', 35.00, '2025-04-01', '2025-04-30'),
(2025, 5, 'PREPAGO', 20.00, '2025-05-01', '2025-05-31'),
(2025, 5, 'POSTPAGO', 35.00, '2025-05-01', '2025-05-31'),
(2025, 6, 'PREPAGO', 20.00, '2025-06-01', '2025-06-30'),
(2025, 6, 'POSTPAGO', 35.00, '2025-06-01', '2025-06-30'),
(2025, 7, 'PREPAGO', 20.00, '2025-07-01', '2025-07-31'),
(2025, 7, 'POSTPAGO', 35.00, '2025-07-01', '2025-07-31'),
(2025, 8, 'PREPAGO', 20.00, '2025-08-01', '2025-08-31'),
(2025, 8, 'POSTPAGO', 35.00, '2025-08-01', '2025-08-31');

-- Septiembre 2025: Nuevos precios unificados
INSERT INTO tbl_parametros_portabilidad_mm (año, mes, tipo_portabilidad, precio_unitario, fecha_inicio, fecha_fin) VALUES
(2025, 9, 'PREPAGO', 40.00, '2025-09-01', '2025-09-30'),
(2025, 9, 'POSTPAGO', 40.00, '2025-09-01', '2025-09-30');

-- Octubre 2025: Precios diferenciados por origen
INSERT INTO tbl_parametros_portabilidad_mm (año, mes, tipo_portabilidad, precio_unitario, fecha_inicio, fecha_fin) VALUES
(2025, 10, 'PREPAGO', 25.00, '2025-10-01', '2025-10-31'),
(2025, 10, 'POSTPAGO', 35.00, '2025-10-01', '2025-10-31');
