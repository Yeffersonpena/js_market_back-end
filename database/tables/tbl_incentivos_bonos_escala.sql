-- Tabla para mapear la escala de bonos de incentivos por venta de equipos y accesorios
-- Permite definir diferentes niveles (TOP, ORO, PLATA, BRONCE) con sus rangos de montos y bonos correspondientes

CREATE TABLE [dbo].[tbl_incentivos_bonos_escala] (
    id INT IDENTITY(1,1) NOT NULL,
    cluster VARCHAR(50) NOT NULL,                    -- TOP, ORO, PLATA, BRONCE
    tipo_producto VARCHAR(20) NOT NULL,              -- EQUIPOS, ACCESORIOS
    monto_minimo DECIMAL(18,2) NOT NULL,             -- Monto mínimo de ventas para calificar
    bono DECIMAL(18,2) NOT NULL,                    -- Monto del bono correspondiente
    fecha_inicio DATE NOT NULL,                      -- Fecha de inicio de vigencia
    fecha_fin DATE NULL,                             -- Fecha de fin de vigencia (NULL si está vigente)
    activo BIT DEFAULT 1 NOT NULL,                   -- Indica si el registro está activo
    created_at DATETIME DEFAULT GETDATE() NOT NULL,
    updated_at DATETIME NULL,
    CONSTRAINT PK_tbl_incentivos_bonos_escala PRIMARY KEY (id)
);

-- Índices para optimizar consultas
CREATE INDEX IX_tbl_incentivos_bonos_escala_Cluster_Tipo 
ON [dbo].[tbl_incentivos_bonos_escala] (cluster, tipo_producto, activo);

CREATE INDEX IX_tbl_incentivos_bonos_escala_Fechas 
ON [dbo].[tbl_incentivos_bonos_escala] (fecha_inicio, fecha_fin);

CREATE INDEX IX_tbl_incentivos_bonos_escala_Monto 
ON [dbo].[tbl_incentivos_bonos_escala] (monto_minimo DESC, cluster, tipo_producto);

GO

-- =============================================
-- DATOS INICIALES: Bonos de Noviembre 2025
-- Período: 07 al 15 de noviembre 2025
-- =============================================

-- =============================================
-- EQUIPOS - TOP
-- =============================================
INSERT INTO [dbo].[tbl_incentivos_bonos_escala] (cluster, tipo_producto, monto_minimo, bono, fecha_inicio, fecha_fin, activo)
VALUES 
    ('TOP', 'EQUIPOS', 28000.00, 220.00, '2025-11-07', '2025-11-15', 1),
    ('TOP', 'EQUIPOS', 24000.00, 180.00, '2025-11-07', '2025-11-15', 1),
    ('TOP', 'EQUIPOS', 20000.00, 140.00, '2025-11-07', '2025-11-15', 1),
    ('TOP', 'EQUIPOS', 18000.00, 100.00, '2025-11-07', '2025-11-15', 1);

-- =============================================
-- EQUIPOS - ORO
-- =============================================
INSERT INTO [dbo].[tbl_incentivos_bonos_escala] (cluster, tipo_producto, monto_minimo, bono, fecha_inicio, fecha_fin, activo)
VALUES 
    ('ORO', 'EQUIPOS', 15500.00, 155.00, '2025-11-07', '2025-11-15', 1),
    ('ORO', 'EQUIPOS', 13500.00, 125.00, '2025-11-07', '2025-11-15', 1),
    ('ORO', 'EQUIPOS', 11500.00, 95.00, '2025-11-07', '2025-11-15', 1),
    ('ORO', 'EQUIPOS', 9500.00, 65.00, '2025-11-07', '2025-11-15', 1);

-- =============================================
-- EQUIPOS - PLATA
-- =============================================
INSERT INTO [dbo].[tbl_incentivos_bonos_escala] (cluster, tipo_producto, monto_minimo, bono, fecha_inicio, fecha_fin, activo)
VALUES 
    ('PLATA', 'EQUIPOS', 11500.00, 100.00, '2025-11-07', '2025-11-15', 1),
    ('PLATA', 'EQUIPOS', 10000.00, 80.00, '2025-11-07', '2025-11-15', 1),
    ('PLATA', 'EQUIPOS', 8500.00, 60.00, '2025-11-07', '2025-11-15', 1),
    ('PLATA', 'EQUIPOS', 7000.00, 40.00, '2025-11-07', '2025-11-15', 1);

-- =============================================
-- EQUIPOS - BRONCE
-- =============================================
INSERT INTO [dbo].[tbl_incentivos_bonos_escala] (cluster, tipo_producto, monto_minimo, bono, fecha_inicio, fecha_fin, activo)
VALUES 
    ('BRONCE', 'EQUIPOS', 5500.00, 90.00, '2025-11-07', '2025-11-15', 1),
    ('BRONCE', 'EQUIPOS', 4500.00, 70.00, '2025-11-07', '2025-11-15', 1),
    ('BRONCE', 'EQUIPOS', 3500.00, 50.00, '2025-11-07', '2025-11-15', 1),
    ('BRONCE', 'EQUIPOS', 2500.00, 30.00, '2025-11-07', '2025-11-15', 1);

-- =============================================
-- ACCESORIOS - TOP
-- =============================================
INSERT INTO [dbo].[tbl_incentivos_bonos_escala] (cluster, tipo_producto, monto_minimo, bono, fecha_inicio, fecha_fin, activo)
VALUES 
    ('TOP', 'ACCESORIOS', 2300.00, 200.00, '2025-11-07', '2025-11-15', 1),
    ('TOP', 'ACCESORIOS', 1950.00, 170.00, '2025-11-07', '2025-11-15', 1),
    ('TOP', 'ACCESORIOS', 1600.00, 155.00, '2025-11-07', '2025-11-15', 1),
    ('TOP', 'ACCESORIOS', 1250.00, 140.00, '2025-11-07', '2025-11-15', 1);

-- =============================================
-- ACCESORIOS - ORO
-- =============================================
INSERT INTO [dbo].[tbl_incentivos_bonos_escala] (cluster, tipo_producto, monto_minimo, bono, fecha_inicio, fecha_fin, activo)
VALUES 
    ('ORO', 'ACCESORIOS', 1400.00, 180.00, '2025-11-07', '2025-11-15', 1),
    ('ORO', 'ACCESORIOS', 1200.00, 140.00, '2025-11-07', '2025-11-15', 1),
    ('ORO', 'ACCESORIOS', 1000.00, 120.00, '2025-11-07', '2025-11-15', 1),
    ('ORO', 'ACCESORIOS', 800.00, 100.00, '2025-11-07', '2025-11-15', 1);

-- =============================================
-- ACCESORIOS - PLATA
-- =============================================
INSERT INTO [dbo].[tbl_incentivos_bonos_escala] (cluster, tipo_producto, monto_minimo, bono, fecha_inicio, fecha_fin, activo)
VALUES 
    ('PLATA', 'ACCESORIOS', 800.00, 100.00, '2025-11-07', '2025-11-15', 1),
    ('PLATA', 'ACCESORIOS', 650.00, 70.00, '2025-11-07', '2025-11-15', 1),
    ('PLATA', 'ACCESORIOS', 500.00, 50.00, '2025-11-07', '2025-11-15', 1),
    ('PLATA', 'ACCESORIOS', 350.00, 30.00, '2025-11-07', '2025-11-15', 1);

GO

-- =============================================
-- COMENTARIOS Y NOTAS
-- =============================================
/*
NOTAS IMPORTANTES:

1. BONO ADICIONAL:
   - Si el vendedor vende 15+ equipos Smart 10 de 64GB, gana un bono adicional de S/ 20
   - Este bono adicional NO está en esta tabla, se calcula en el SP según MARCA_CANDADO

2. CONDICIONES PARA CALIFICAR:
   - Sin deuda pendiente (DEUDA = 0 o NULL)
   - Debe vender mínimo 7 equipos Smart 10 de 64GB (candado mínimo)
   - Debe alcanzar el monto mínimo según su CLUSTER

3. CÁLCULO DEL BONO:
   - Se busca el BONO máximo donde PRECIO_VTA >= MONTO_MINIMO
   - Se filtra por CLUSTER y TIPO_PRODUCTO
   - Se considera la fecha de vigencia (fecha_inicio y fecha_fin)

4. MANTENIMIENTO:
   - Para nuevos períodos, insertar nuevos registros con nuevas fechas
   - Para desactivar rangos antiguos, actualizar activo = 0
   - Los rangos están ordenados de mayor a menor monto (para usar MAX en la consulta)

5. ESTRUCTURA:
   - Cada fila representa un rango de bono
   - Si un vendedor tiene PRECIO_VTA = 25000 y CLUSTER = 'TOP' y TIPO_PRODUCTO = 'EQUIPOS'
     → Califica para el bono de 180.00 (porque 25000 >= 24000)
*/

