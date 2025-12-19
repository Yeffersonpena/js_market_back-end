-- Tabla para almacenar cuotas e incentivos por zonal y categoría
-- Permite definir cuotas y bonos por zona geográfica para equipos y accesorios
-- con períodos de vigencia por fecha de inicio y fin

CREATE TABLE [dbo].[cuotas_incentivos_logistica] (
    id INT IDENTITY(1,1) NOT NULL,
    zonal VARCHAR(50) COLLATE Modern_Spanish_CI_AS NOT NULL,
    categoria VARCHAR(20) COLLATE Modern_Spanish_CI_AS NOT NULL,  -- EQUIPOS, ACCESORIOS
    cuota1 DECIMAL(18,2) NOT NULL,                                -- Primera cuota objetivo
    bono1 DECIMAL(18,2) NOT NULL,                                 -- Bono por alcanzar cuota1
    cuota2 DECIMAL(18,2) NOT NULL,                                -- Segunda cuota objetivo
    bono2 DECIMAL(18,2) NOT NULL,                                 -- Bono por alcanzar cuota2
    fecha_inicio DATE NOT NULL,                                    -- Fecha de inicio de vigencia
    fecha_fin DATE NOT NULL,                                       -- Fecha de fin de vigencia
    activo BIT DEFAULT 1 NOT NULL,                                 -- Indica si el registro está activo
    created_at DATETIME DEFAULT GETDATE() NOT NULL,
    updated_at DATETIME NULL,
    CONSTRAINT PK_cuotas_incentivos_logistica PRIMARY KEY (id)
);

-- Índices para optimizar consultas
CREATE INDEX IX_cuotas_incentivos_logistica_Zonal_Categoria
ON [dbo].[cuotas_incentivos_logistica] (zonal, categoria, activo);

CREATE INDEX IX_cuotas_incentivos_logistica_Fechas
ON [dbo].[cuotas_incentivos_logistica] (fecha_inicio, fecha_fin);

CREATE INDEX IX_cuotas_incentivos_logistica_Categoria_Fechas
ON [dbo].[cuotas_incentivos_logistica] (categoria, fecha_inicio, fecha_fin);

-- =============================================
-- DATOS INICIALES: Bonos por Zonal
-- Período: 06 de diciembre 2025 al 13 de diciembre 2025
-- =============================================

-- =============================================
-- EQUIPOS - Bonos por Zonal
-- =============================================
INSERT INTO [dbo].[cuotas_incentivos_logistica]
    (zonal, categoria, cuota1, bono1, cuota2, bono2, fecha_inicio, fecha_fin, activo)
VALUES
    ('AREQUIPA', 'EQUIPOS', 35000.00, 500.00, 40000.00, 800.00, '2025-12-06', '2025-12-13', 1),
    ('AYACUCHO', 'EQUIPOS', 65000.00, 800.00, 70000.00, 1100.00, '2025-12-06', '2025-12-13', 1),
    ('CUSCO', 'EQUIPOS', 75000.00, 800.00, 83000.00, 1100.00, '2025-12-06', '2025-12-13', 1),
    ('HUANCAYO', 'EQUIPOS', 70000.00, 800.00, 80000.00, 1100.00, '2025-12-06', '2025-12-13', 1),
    ('HUANUCO', 'EQUIPOS', 45000.00, 500.00, 55000.00, 1100.00, '2025-12-06', '2025-12-13', 1),
    ('ICA', 'EQUIPOS', 80000.00, 800.00, 90000.00, 1100.00, '2025-12-06', '2025-12-13', 1),
    ('LIMASUR', 'EQUIPOS', 30000.00, 500.00, 37000.00, 800.00, '2025-12-06', '2025-12-13', 1),
    ('PUCALLPA', 'EQUIPOS', 38000.00, 500.00, 45000.00, 800.00, '2025-12-06', '2025-12-13', 1),
    ('PUNO', 'EQUIPOS', 33000.00, 500.00, 40000.00, 800.00, '2025-12-06', '2025-12-13', 1);

-- =============================================
-- ACCESORIOS - Bonos por Zonal
-- =============================================
INSERT INTO [dbo].[cuotas_incentivos_logistica]
    (zonal, categoria, cuota1, bono1, cuota2, bono2, fecha_inicio, fecha_fin, activo)
VALUES
    ('AREQUIPA', 'ACCESORIOS', 3500.00, 400.00, 4500.00, 480.00, '2025-12-06', '2025-12-13', 1),
    ('AYACUCHO', 'ACCESORIOS', 3500.00, 400.00, 4500.00, 480.00, '2025-12-06', '2025-12-13', 1),
    ('CUSCO', 'ACCESORIOS', 4500.00, 500.00, 5500.00, 580.00, '2025-12-06', '2025-12-13', 1),
    ('HUANCAYO', 'ACCESORIOS', 4500.00, 500.00, 5500.00, 580.00, '2025-12-06', '2025-12-13', 1),
    ('HUANUCO', 'ACCESORIOS', 3000.00, 300.00, 4000.00, 380.00, '2025-12-06', '2025-12-13', 1),
    ('ICA', 'ACCESORIOS', 4000.00, 450.00, 5000.00, 530.00, '2025-12-06', '2025-12-13', 1),
    ('LIMASUR', 'ACCESORIOS', 3500.00, 400.00, 4500.00, 480.00, '2025-12-06', '2025-12-13', 1),
    ('PUCALLPA', 'ACCESORIOS', 3500.00, 400.00, 4500.00, 480.00, '2025-12-06', '2025-12-13', 1),
    ('PUNO', 'ACCESORIOS', 3000.00, 300.00, 4000.00, 380.00, '2025-12-06', '2025-12-13', 1);

-- =============================================
-- DATOS: Bonos por Zonal - EQUIPOS
-- Período: 15 de diciembre 2025 al 21 de diciembre 2025
-- =============================================

INSERT INTO [dbo].[cuotas_incentivos_logistica]
    (zonal, categoria, cuota1, bono1, cuota2, bono2, fecha_inicio, fecha_fin, activo)
VALUES
    ('AREQUIPA', 'EQUIPOS', 35000.00, 500.00, 40000.00, 800.00, '2025-12-15', '2025-12-21', 1),
    ('AYACUCHO', 'EQUIPOS', 65000.00, 800.00, 70000.00, 1100.00, '2025-12-15', '2025-12-21', 1),
    ('CUSCO', 'EQUIPOS', 75000.00, 800.00, 83000.00, 1100.00, '2025-12-15', '2025-12-21', 1),
    ('HUANCAYO', 'EQUIPOS', 70000.00, 800.00, 80000.00, 1100.00, '2025-12-15', '2025-12-21', 1),
    ('HUANUCO', 'EQUIPOS', 45000.00, 500.00, 55000.00, 1100.00, '2025-12-15', '2025-12-21', 1),
    ('ICA', 'EQUIPOS', 80000.00, 800.00, 90000.00, 1100.00, '2025-12-15', '2025-12-21', 1),
    ('LIMASUR', 'EQUIPOS', 58000.00, 800.00, 68000.00, 1100.00, '2025-12-15', '2025-12-21', 1),
    ('PUCALLPA', 'EQUIPOS', 38000.00, 500.00, 45000.00, 800.00, '2025-12-15', '2025-12-21', 1),
    ('PUNO', 'EQUIPOS', 33000.00, 500.00, 40000.00, 800.00, '2025-12-15', '2025-12-21', 1);

-- =============================================
-- DATOS: Bonos por Zonal - ACCESORIOS
-- Período: 15 de diciembre 2025 al 21 de diciembre 2025
-- =============================================

INSERT INTO [dbo].[cuotas_incentivos_logistica]
    (zonal, categoria, cuota1, bono1, cuota2, bono2, fecha_inicio, fecha_fin, activo)
VALUES
    ('AREQUIPA', 'ACCESORIOS', 3500.00, 400.00, 4500.00, 480.00, '2025-12-15', '2025-12-21', 1),
    ('AYACUCHO', 'ACCESORIOS', 3500.00, 400.00, 4500.00, 480.00, '2025-12-15', '2025-12-21', 1),
    ('CUSCO', 'ACCESORIOS', 4500.00, 500.00, 5500.00, 580.00, '2025-12-15', '2025-12-21', 1),
    ('HUANCAYO', 'ACCESORIOS', 4500.00, 500.00, 5500.00, 580.00, '2025-12-15', '2025-12-21', 1),
    ('HUANUCO', 'ACCESORIOS', 3000.00, 300.00, 4000.00, 380.00, '2025-12-15', '2025-12-21', 1),
    ('ICA', 'ACCESORIOS', 4000.00, 450.00, 5000.00, 530.00, '2025-12-15', '2025-12-21', 1),
    ('LIMASUR', 'ACCESORIOS', 3500.00, 400.00, 4500.00, 480.00, '2025-12-15', '2025-12-21', 1),
    ('PUCALLPA', 'ACCESORIOS', 3500.00, 400.00, 4500.00, 480.00, '2025-12-15', '2025-12-21', 1),
    ('PUNO', 'ACCESORIOS', 3000.00, 300.00, 4000.00, 380.00, '2025-12-15', '2025-12-21', 1);
