-- Sentencias DELETE e INSERT para BonoRango - Abril 2026
-- Bonos por mantenimiento o subida de rango comparado con el mes anterior

-- Eliminar registros existentes de Abril 2026 (si ya fueron insertados previamente)
DELETE FROM PORTAL_COMERCIAL.dbo.BonoRango
WHERE fecha_inicio = '2026-04-01'
  AND fecha_fin = '2026-04-30';

-- Bonos "Mantienes Rango" (mantiene el mismo rango que el mes anterior)
INSERT INTO PORTAL_COMERCIAL.dbo.BonoRango (nivel_rango, tipo_bono, bono, fecha_inicio, fecha_fin, created_at, updated_at) VALUES
(3, 'mantiene', 15.00, '2026-04-01', '2026-04-30', getdate(), NULL),  -- R3
(4, 'mantiene', 20.00, '2026-04-01', '2026-04-30', getdate(), NULL),  -- R4
(5, 'mantiene', 25.00, '2026-04-01', '2026-04-30', getdate(), NULL),  -- R5
(6, 'mantiene', 30.00, '2026-04-01', '2026-04-30', getdate(), NULL),  -- R6
(7, 'mantiene', 35.00, '2026-04-01', '2026-04-30', getdate(), NULL),  -- R7
(8, 'mantiene', 40.00, '2026-04-01', '2026-04-30', getdate(), NULL);  -- R8

-- Bonos "Subes de Rango" (sube de rango comparado con el mes anterior)
INSERT INTO PORTAL_COMERCIAL.dbo.BonoRango (nivel_rango, tipo_bono, bono, fecha_inicio, fecha_fin, created_at, updated_at) VALUES
(1, 'sube', 10.00, '2026-04-01', '2026-04-30', getdate(), NULL),  -- R1
(2, 'sube', 20.00, '2026-04-01', '2026-04-30', getdate(), NULL),  -- R2
(3, 'sube', 25.00, '2026-04-01', '2026-04-30', getdate(), NULL),  -- R3
(4, 'sube', 30.00, '2026-04-01', '2026-04-30', getdate(), NULL),  -- R4
(5, 'sube', 35.00, '2026-04-01', '2026-04-30', getdate(), NULL),  -- R5
(6, 'sube', 40.00, '2026-04-01', '2026-04-30', getdate(), NULL),  -- R6
(7, 'sube', 45.00, '2026-04-01', '2026-04-30', getdate(), NULL),  -- R7
(8, 'sube', 50.00, '2026-04-01', '2026-04-30', getdate(), NULL);  -- R8

-- Notas sobre los datos para Abril 2026:
-- 1. Mantienes Rango: Se otorga cuando el PDV mantiene el mismo nivel de rango del mes anterior
--    - R1 y R2: No tienen bono por mantener rango
--    - R3 a R8: Bonos de S/ 15 a S/ 40 según el nivel
--    - R9*: No tiene bono por mantener rango
--
-- 2. Subes de Rango: Se otorga cuando el PDV sube de nivel de rango comparado con el mes anterior
--    - R1: S/ 10
--    - R2 a R8: Bonos de S/ 20 a S/ 50 según el nivel alcanzado
--    - R9*: No tiene bono por subir
--
-- 3. El cálculo se realiza comparando:
--    - Rango actual (abril): Se calcula con las ventas de abril usando la escala de abril
--    - Rango anterior (marzo): Se calcula con las ventas de marzo pero usando la escala de abril
--
-- 4. Período: 1 al 30 de abril 2026
