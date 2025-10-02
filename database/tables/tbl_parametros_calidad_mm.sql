-- Tabla para gestionar parámetros de calidad multimarca por mes/año
-- Permite configurar valores unitarios fijos, escalas por ventas y lógica especial por período
CREATE TABLE tbl_parametros_calidad_mm (
    id INT IDENTITY(1,1) PRIMARY KEY,
    año INT NOT NULL,
    mes INT NOT NULL,
    tipo_calculo VARCHAR(20) NOT NULL, -- 'FIJO', 'ESCALA_VENTAS', 'ANTIGUO_NUEVO'
    valor_unitario DECIMAL(10,2), -- Para tipo FIJO
    ventas_minimas INT, -- Para escalas (ej: 5, 15, 20, 30)
    ventas_maximas INT, -- Para escalas (ej: 14, 19, 29, 999)
    cantidad_calidad_minima INT DEFAULT 15, -- Mínimo de ventas de calidad requeridas
    fecha_inicio DATE,
    fecha_fin DATE,
    fecha_creacion DATETIME DEFAULT GETDATE()
);

-- =============================================
-- INSERCIÓN DE DATOS PARA TODOS LOS CASOS
-- =============================================

-- Enero a Agosto 2025: Valores fijos
INSERT INTO tbl_parametros_calidad_mm (año, mes, tipo_calculo, valor_unitario, ventas_minimas, ventas_maximas, cantidad_calidad_minima, fecha_inicio, fecha_fin) VALUES
(2025, 1, 'FIJO', 10.00, NULL, NULL, 15, '2025-01-01', '2025-01-31'),
(2025, 2, 'FIJO', 10.00, NULL, NULL, 15, '2025-02-01', '2025-02-28'),
(2025, 3, 'FIJO', 10.00, NULL, NULL, 15, '2025-03-01', '2025-03-31'),
(2025, 4, 'FIJO', 10.00, NULL, NULL, 15, '2025-04-01', '2025-04-30'),
(2025, 5, 'FIJO', 10.00, NULL, NULL, 15, '2025-05-01', '2025-05-31'),
(2025, 6, 'FIJO', 10.00, NULL, NULL, 15, '2025-06-01', '2025-06-30'),
(2025, 7, 'FIJO', 8.00, NULL, NULL, 15, '2025-07-01', '2025-07-31'),
(2025, 8, 'FIJO', 5.00, NULL, NULL, 15, '2025-08-01', '2025-08-31');

-- Septiembre 2025: Lógica antiguos vs nuevos (mantener función actual)
INSERT INTO tbl_parametros_calidad_mm (año, mes, tipo_calculo, valor_unitario, ventas_minimas, ventas_maximas, cantidad_calidad_minima, fecha_inicio, fecha_fin) VALUES
(2025, 9, 'ANTIGUO_NUEVO', 5.00, NULL, NULL, 15, '2025-09-01', '2025-09-30'), -- Antiguos
(2025, 9, 'ANTIGUO_NUEVO', 8.00, NULL, NULL, 15, '2025-09-01', '2025-09-30'); -- Nuevos

-- Octubre 2025: Escala por ventas según tabla proporcionada
INSERT INTO tbl_parametros_calidad_mm (año, mes, tipo_calculo, valor_unitario, ventas_minimas, ventas_maximas, cantidad_calidad_minima, fecha_inicio, fecha_fin) VALUES
(2025, 10, 'ESCALA_VENTAS', 2.00, 5, 14, 15, '2025-10-01', '2025-10-31'),   -- 5 a 14 ventas = S/ 2
(2025, 10, 'ESCALA_VENTAS', 5.00, 15, 19, 15, '2025-10-01', '2025-10-31'), -- 15 a 19 ventas = S/ 5
(2025, 10, 'ESCALA_VENTAS', 6.00, 20, 29, 15, '2025-10-01', '2025-10-31'), -- 20 a 29 ventas = S/ 6
(2025, 10, 'ESCALA_VENTAS', 8.00, 30, 999, 15, '2025-10-01', '2025-10-31'); -- 30 a más ventas = S/ 8
