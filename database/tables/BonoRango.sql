CREATE TABLE PORTAL_COMERCIAL.dbo.BonoRango (
	id int IDENTITY(1,1) NOT NULL,
	nivel_rango int NOT NULL,                    -- Nivel de rango (1-8)
	tipo_bono varchar(20) COLLATE Modern_Spanish_CI_AS NOT NULL,  -- 'sube' o 'mantiene'
	bono decimal(18,2) NOT NULL,                 -- Valor del bono
	fecha_inicio date NOT NULL,                  -- Inicio del período
	fecha_fin date NULL,                         -- Fin del período (NULL si vigente)
	created_at datetime DEFAULT getdate() NOT NULL,
	updated_at datetime NULL,
	CONSTRAINT PK_BonoRango PRIMARY KEY (id)
);

-- Sentencias INSERT para BonoRango - Noviembre 2025
-- Bonos por mantenimiento o subida de rango comparado con el mes anterior

-- Bonos "Mantienes Rango" (mantiene el mismo rango que el mes anterior)
INSERT INTO PORTAL_COMERCIAL.dbo.BonoRango (nivel_rango, tipo_bono, bono, fecha_inicio, fecha_fin, created_at, updated_at) VALUES
	(3, 'mantiene', 15.00, '2025-11-01', '2025-11-30', getdate(), NULL),  -- R3
	(4, 'mantiene', 20.00, '2025-11-01', '2025-11-30', getdate(), NULL),  -- R4
	(5, 'mantiene', 25.00, '2025-11-01', '2025-11-30', getdate(), NULL),  -- R5
	(6, 'mantiene', 30.00, '2025-11-01', '2025-11-30', getdate(), NULL),  -- R6
	(7, 'mantiene', 35.00, '2025-11-01', '2025-11-30', getdate(), NULL),  -- R7
	(8, 'mantiene', 40.00, '2025-11-01', '2025-11-30', getdate(), NULL);  -- R8

-- Bonos "Subes de Rango" (sube de rango comparado con el mes anterior)
INSERT INTO PORTAL_COMERCIAL.dbo.BonoRango (nivel_rango, tipo_bono, bono, fecha_inicio, fecha_fin, created_at, updated_at) VALUES
	(2, 'sube', 20.00, '2025-11-01', '2025-11-30', getdate(), NULL),  -- R2
	(3, 'sube', 25.00, '2025-11-01', '2025-11-30', getdate(), NULL),  -- R3
	(4, 'sube', 30.00, '2025-11-01', '2025-11-30', getdate(), NULL),  -- R4
	(5, 'sube', 35.00, '2025-11-01', '2025-11-30', getdate(), NULL),  -- R5
	(6, 'sube', 40.00, '2025-11-01', '2025-11-30', getdate(), NULL),  -- R6
	(7, 'sube', 45.00, '2025-11-01', '2025-11-30', getdate(), NULL);  -- R7

-- Notas sobre los datos:
-- 1. Mantienes Rango: Se otorga cuando el PDV mantiene el mismo nivel de rango del mes anterior
--    - R1 y R2: No tienen bono por mantener rango
--    - R3 a R8: Bonos de S/ 15 a S/ 40 según el nivel
--
-- 2. Subes de Rango: Se otorga cuando el PDV sube de nivel de rango comparado con el mes anterior
--    - R1: No tiene bono por subir (ya está en el nivel más bajo)
--    - R2 a R7: Bonos de S/ 20 a S/ 45 según el nivel alcanzado
--    - R8: No tiene bono por subir (ya está en el nivel más alto)
--
-- 3. El cálculo se realiza comparando:
--    - Rango actual (noviembre): Se calcula con las ventas de noviembre usando la escala de noviembre
--    - Rango anterior (octubre): Se calcula con las ventas de octubre pero usando la escala de noviembre
--
-- 4. Período: 1 al 30 de noviembre 2025

