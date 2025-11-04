-- Sentencias INSERT para BonoEscala - Noviembre 2025
-- Bonos para PDV REGULAR y PDV PREMIUM - Todas las zonales
-- IMPORTANTE: En noviembre 2025, ambos tipos de PDV usan las mismas reglas de bonificación

-- Datos para PDV REGULAR - Noviembre 2025
INSERT INTO PORTAL_COMERCIAL.dbo.BonoEscala (tipo_pdv,zonal_pattern,fecha_inicio,fecha_fin,rango_min,rango_max,ratio_min,bono,created_at,updated_at,cantidad_calidad_min) VALUES
	 (N'PDV REGULAR',N'TODAS','2025-11-01','2025-11-30',5,9,50.00,1.50,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-11-01','2025-11-30',5,9,30.00,0.50,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-11-01','2025-11-30',10,19,50.00,2.00,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-11-01','2025-11-30',10,19,30.00,1.00,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-11-01','2025-11-30',20,29,50.00,2.50,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-11-01','2025-11-30',20,29,30.00,1.50,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-11-01','2025-11-30',30,39,50.00,3.00,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-11-01','2025-11-30',30,39,30.00,2.00,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-11-01','2025-11-30',40,49,50.00,3.50,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-11-01','2025-11-30',40,49,30.00,2.50,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-11-01','2025-11-30',50,79,50.00,4.00,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-11-01','2025-11-30',50,79,30.00,3.00,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-11-01','2025-11-30',80,99,50.00,4.50,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-11-01','2025-11-30',80,99,30.00,3.50,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-11-01','2025-11-30',100,150,50.00,5.00,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-11-01','2025-11-30',100,150,30.00,4.00,getdate(),NULL,0);

-- Datos para PDV PREMIUM - Noviembre 2025 (Mismas reglas que PDV REGULAR)
INSERT INTO PORTAL_COMERCIAL.dbo.BonoEscala (tipo_pdv,zonal_pattern,fecha_inicio,fecha_fin,rango_min,rango_max,ratio_min,bono,created_at,updated_at,cantidad_calidad_min) VALUES
	 (N'PDV PREMIUM',N'TODAS','2025-11-01','2025-11-30',5,9,50.00,1.50,getdate(),NULL,0),
	 (N'PDV PREMIUM',N'TODAS','2025-11-01','2025-11-30',5,9,30.00,0.50,getdate(),NULL,0),
	 (N'PDV PREMIUM',N'TODAS','2025-11-01','2025-11-30',10,19,50.00,2.00,getdate(),NULL,0),
	 (N'PDV PREMIUM',N'TODAS','2025-11-01','2025-11-30',10,19,30.00,1.00,getdate(),NULL,0),
	 (N'PDV PREMIUM',N'TODAS','2025-11-01','2025-11-30',20,29,50.00,2.50,getdate(),NULL,0),
	 (N'PDV PREMIUM',N'TODAS','2025-11-01','2025-11-30',20,29,30.00,1.50,getdate(),NULL,0),
	 (N'PDV PREMIUM',N'TODAS','2025-11-01','2025-11-30',30,39,50.00,3.00,getdate(),NULL,0),
	 (N'PDV PREMIUM',N'TODAS','2025-11-01','2025-11-30',30,39,30.00,2.00,getdate(),NULL,0),
	 (N'PDV PREMIUM',N'TODAS','2025-11-01','2025-11-30',40,49,50.00,3.50,getdate(),NULL,0),
	 (N'PDV PREMIUM',N'TODAS','2025-11-01','2025-11-30',40,49,30.00,2.50,getdate(),NULL,0),
	 (N'PDV PREMIUM',N'TODAS','2025-11-01','2025-11-30',50,79,50.00,4.00,getdate(),NULL,0),
	 (N'PDV PREMIUM',N'TODAS','2025-11-01','2025-11-30',50,79,30.00,3.00,getdate(),NULL,0),
	 (N'PDV PREMIUM',N'TODAS','2025-11-01','2025-11-30',80,99,50.00,4.50,getdate(),NULL,0),
	 (N'PDV PREMIUM',N'TODAS','2025-11-01','2025-11-30',80,99,30.00,3.50,getdate(),NULL,0),
	 (N'PDV PREMIUM',N'TODAS','2025-11-01','2025-11-30',100,150,50.00,5.00,getdate(),NULL,0),
	 (N'PDV PREMIUM',N'TODAS','2025-11-01','2025-11-30',100,150,30.00,4.00,getdate(),NULL,0);

-- Notas sobre los datos:
-- PDV REGULAR - Noviembre 2025:
-- 1. Rangos de ventas prepago: 5-9, 10-19, 20-29, 30-39, 40-49, 50-79, 80-99, 100-150
-- 2. Bonos según estructura de noviembre 2025:
--    - 5-9: S/ 0.5 (>=30% recargadas) y S/ 1.5 (>=50% recargadas)
--    - 10-19: S/ 1.0 (>=30% recargadas) y S/ 2.0 (>=50% recargadas)
--    - 20-29: S/ 1.5 (>=30% recargadas) y S/ 2.5 (>=50% recargadas)
--    - 30-39: S/ 2.0 (>=30% recargadas) y S/ 3.0 (>=50% recargadas)
--    - 40-49: S/ 2.5 (>=30% recargadas) y S/ 3.5 (>=50% recargadas)
--    - 50-79: S/ 3.0 (>=30% recargadas) y S/ 4.0 (>=50% recargadas)
--    - 80-99: S/ 3.5 (>=30% recargadas) y S/ 4.5 (>=50% recargadas)
--    - 100-150: S/ 4.0 (>=30% recargadas) y S/ 5.0 (>=50% recargadas)
-- 3. Cantidad de calidad mínima: 0 (sin mínimo de buena calidad)
-- 4. Ratios: 30.00 (>=30% recargadas) y 50.00 (>=50% recargadas)
-- 5. Zona: "TODAS" (aplica para todas las zonales)
-- 6. El período es del 1 al 30 de noviembre 2025
--
-- PDV PREMIUM - Noviembre 2025:
-- IMPORTANTE: PDV PREMIUM usa EXACTAMENTE las mismas reglas que PDV REGULAR en noviembre 2025
-- 1. Mismos rangos de ventas prepago: 5-9, 10-19, 20-29, 30-39, 40-49, 50-79, 80-99, 100-150
-- 2. Mismos bonos que PDV REGULAR según estructura de noviembre 2025
-- 3. Misma cantidad de calidad mínima: 0 (sin mínimo de buena calidad)
-- 4. Mismos ratios: 30.00 (>=30% recargadas) y 50.00 (>=50% recargadas)
-- 5. Misma zona: "TODAS" (aplica para todas las zonales, sin separación LIMA SUR/REGIONES)
--
-- NOTA: Bono adicional C1 + C2 (Aplica para AMBOS tipos de PDV):
--    - Para rangos 5-49: S/ 1.0 (si llega al 50% C1C2)
--    - Para rangos 50-150: S/ 1.5 (si llega al 50% C1C2)
--    Este bono adicional se debe calcular por separado en el sistema de bonificación

