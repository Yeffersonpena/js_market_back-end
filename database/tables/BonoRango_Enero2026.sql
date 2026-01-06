-- Sentencias DELETE e INSERT para BonoRango - Enero 2026
-- Bonos por mantenimiento o subida de rango comparado con el mes anterior

-- Eliminar registros existentes de Enero 2026 (si ya fueron insertados previamente)
DELETE FROM PORTAL_COMERCIAL.dbo.BonoRango
WHERE fecha_inicio = '2026-01-01'
  AND fecha_fin = '2026-01-31';

-- Bonos "Mantienes Rango" (mantiene el mismo rango que el mes anterior)
INSERT INTO PORTAL_COMERCIAL.dbo.BonoRango (nivel_rango, tipo_bono, bono, fecha_inicio, fecha_fin, created_at, updated_at) VALUES
	(3, 'mantiene', 15.00, '2026-01-01', '2026-01-31', getdate(), NULL),  -- R3
	(4, 'mantiene', 20.00, '2026-01-01', '2026-01-31', getdate(), NULL),  -- R4
	(5, 'mantiene', 25.00, '2026-01-01', '2026-01-31', getdate(), NULL),  -- R5
	(6, 'mantiene', 30.00, '2026-01-01', '2026-01-31', getdate(), NULL),  -- R6
	(7, 'mantiene', 35.00, '2026-01-01', '2026-01-31', getdate(), NULL),  -- R7
	(8, 'mantiene', 40.00, '2026-01-01', '2026-01-31', getdate(), NULL);  -- R8

-- Bonos "Subes de Rango" (sube de rango comparado con el mes anterior)
INSERT INTO PORTAL_COMERCIAL.dbo.BonoRango (nivel_rango, tipo_bono, bono, fecha_inicio, fecha_fin, created_at, updated_at) VALUES
	(1, 'sube', 10.00, '2026-01-01', '2026-01-31', getdate(), NULL),  -- R1
	(2, 'sube', 20.00, '2026-01-01', '2026-01-31', getdate(), NULL),  -- R2
	(3, 'sube', 25.00, '2026-01-01', '2026-01-31', getdate(), NULL),  -- R3
	(4, 'sube', 30.00, '2026-01-01', '2026-01-31', getdate(), NULL),  -- R4
	(5, 'sube', 35.00, '2026-01-01', '2026-01-31', getdate(), NULL),  -- R5
	(6, 'sube', 40.00, '2026-01-01', '2026-01-31', getdate(), NULL),  -- R6
	(7, 'sube', 45.00, '2026-01-01', '2026-01-31', getdate(), NULL),  -- R7
	(8, 'sube', 50.00, '2026-01-01', '2026-01-31', getdate(), NULL);  -- R8

-- Notas sobre los datos para Enero 2026:
-- 1. Mantienes Rango: Se otorga cuando el PDV mantiene el mismo nivel de rango del mes anterior
--    - R1 y R2: No tienen bono por mantener rango
--    - R3 a R8: Bonos de S/ 15 a S/ 40 según el nivel
--    - R9*: No tiene bono por mantener rango
--
-- 2. Subes de Rango: Se otorga cuando el PDV sube de nivel de rango comparado con el mes anterior
--    - R1: S/ 10 (NUEVO: En diciembre 2025 no tenía bono por subir)
--    - R2 a R8: Bonos de S/ 20 a S/ 50 según el nivel alcanzado
--    - R9*: No tiene bono por subir
--    - CAMBIO PRINCIPAL: R1 ahora tiene bono de S/ 10 al subir de rango (antes no existía)
--
-- 3. El cálculo se realiza comparando:
--    - Rango actual (enero): Se calcula con las ventas de enero usando la escala de enero
--    - Rango anterior (diciembre): Se calcula con las ventas de diciembre pero usando la escala de enero
--
-- 4. Período: 1 al 31 de enero 2026
--
-- 5. Comparación con Diciembre 2025:
--    - Mantienes Rango: Mismos valores (R3-R8: 15, 20, 25, 30, 35, 40)
--    - Subes de Rango: R1 ahora tiene S/ 10 (antes no tenía), R2-R8 mantienen los mismos valores


