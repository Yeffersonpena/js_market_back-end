-- Sentencias DELETE e INSERT para BonoEscala - Febrero 2026
-- Bonos para PDV REGULAR y PDV PREMIUM - Todas las zonales
-- IMPORTANTE: En febrero 2026, ambos tipos de PDV usan las mismas reglas de bonificacion

-- Eliminar registros existentes de Febrero 2026 (si ya fueron insertados previamente)
DELETE FROM PORTAL_COMERCIAL.dbo.BonoEscala
WHERE fecha_inicio = '2026-02-01'
  AND fecha_fin = '2026-02-28'
  AND (tipo_pdv = 'PDV REGULAR' OR tipo_pdv = 'PDV PREMIUM')
  AND zonal_pattern = 'TODAS';

-- Datos para PDV REGULAR - Febrero 2026
INSERT INTO PORTAL_COMERCIAL.dbo.BonoEscala (tipo_pdv,zonal_pattern,fecha_inicio,fecha_fin,rango_min,rango_max,ratio_min,bono,created_at,updated_at,cantidad_calidad_min,nivel_rango) VALUES
	 (N'PDV REGULAR',N'TODAS','2026-02-01','2026-02-28',5,9,50.00,1.50,getdate(),NULL,0,1),
	 (N'PDV REGULAR',N'TODAS','2026-02-01','2026-02-28',5,9,30.00,0.50,getdate(),NULL,0,1),
	 (N'PDV REGULAR',N'TODAS','2026-02-01','2026-02-28',10,19,50.00,2.00,getdate(),NULL,0,2),
	 (N'PDV REGULAR',N'TODAS','2026-02-01','2026-02-28',10,19,30.00,1.00,getdate(),NULL,0,2),
	 (N'PDV REGULAR',N'TODAS','2026-02-01','2026-02-28',20,29,50.00,2.50,getdate(),NULL,0,3),
	 (N'PDV REGULAR',N'TODAS','2026-02-01','2026-02-28',20,29,30.00,1.50,getdate(),NULL,0,3),
	 (N'PDV REGULAR',N'TODAS','2026-02-01','2026-02-28',30,39,50.00,3.00,getdate(),NULL,0,4),
	 (N'PDV REGULAR',N'TODAS','2026-02-01','2026-02-28',30,39,30.00,2.00,getdate(),NULL,0,4),
	 (N'PDV REGULAR',N'TODAS','2026-02-01','2026-02-28',40,49,50.00,3.50,getdate(),NULL,0,5),
	 (N'PDV REGULAR',N'TODAS','2026-02-01','2026-02-28',40,49,30.00,2.50,getdate(),NULL,0,5),
	 (N'PDV REGULAR',N'TODAS','2026-02-01','2026-02-28',50,79,50.00,4.00,getdate(),NULL,0,6),
	 (N'PDV REGULAR',N'TODAS','2026-02-01','2026-02-28',50,79,30.00,3.00,getdate(),NULL,0,6),
	 (N'PDV REGULAR',N'TODAS','2026-02-01','2026-02-28',80,99,50.00,4.50,getdate(),NULL,0,7),
	 (N'PDV REGULAR',N'TODAS','2026-02-01','2026-02-28',80,99,30.00,3.50,getdate(),NULL,0,7),
	 (N'PDV REGULAR',N'TODAS','2026-02-01','2026-02-28',100,149,50.00,5.00,getdate(),NULL,0,8),
	 (N'PDV REGULAR',N'TODAS','2026-02-01','2026-02-28',100,149,30.00,4.00,getdate(),NULL,0,8),
	 (N'PDV REGULAR',N'TODAS','2026-02-01','2026-02-28',150,250,50.00,5.50,getdate(),NULL,0,9),
	 (N'PDV REGULAR',N'TODAS','2026-02-01','2026-02-28',150,250,30.00,4.50,getdate(),NULL,0,9);

-- Datos para PDV PREMIUM - Febrero 2026 (Mismas reglas que PDV REGULAR)
INSERT INTO PORTAL_COMERCIAL.dbo.BonoEscala (tipo_pdv,zonal_pattern,fecha_inicio,fecha_fin,rango_min,rango_max,ratio_min,bono,created_at,updated_at,cantidad_calidad_min,nivel_rango) VALUES
	 (N'PDV PREMIUM',N'TODAS','2026-02-01','2026-02-28',5,9,50.00,1.50,getdate(),NULL,0,1),
	 (N'PDV PREMIUM',N'TODAS','2026-02-01','2026-02-28',5,9,30.00,0.50,getdate(),NULL,0,1),
	 (N'PDV PREMIUM',N'TODAS','2026-02-01','2026-02-28',10,19,50.00,2.00,getdate(),NULL,0,2),
	 (N'PDV PREMIUM',N'TODAS','2026-02-01','2026-02-28',10,19,30.00,1.00,getdate(),NULL,0,2),
	 (N'PDV PREMIUM',N'TODAS','2026-02-01','2026-02-28',20,29,50.00,2.50,getdate(),NULL,0,3),
	 (N'PDV PREMIUM',N'TODAS','2026-02-01','2026-02-28',20,29,30.00,1.50,getdate(),NULL,0,3),
	 (N'PDV PREMIUM',N'TODAS','2026-02-01','2026-02-28',30,39,50.00,3.00,getdate(),NULL,0,4),
	 (N'PDV PREMIUM',N'TODAS','2026-02-01','2026-02-28',30,39,30.00,2.00,getdate(),NULL,0,4),
	 (N'PDV PREMIUM',N'TODAS','2026-02-01','2026-02-28',40,49,50.00,3.50,getdate(),NULL,0,5),
	 (N'PDV PREMIUM',N'TODAS','2026-02-01','2026-02-28',40,49,30.00,2.50,getdate(),NULL,0,5),
	 (N'PDV PREMIUM',N'TODAS','2026-02-01','2026-02-28',50,79,50.00,4.00,getdate(),NULL,0,6),
	 (N'PDV PREMIUM',N'TODAS','2026-02-01','2026-02-28',50,79,30.00,3.00,getdate(),NULL,0,6),
	 (N'PDV PREMIUM',N'TODAS','2026-02-01','2026-02-28',80,99,50.00,4.50,getdate(),NULL,0,7),
	 (N'PDV PREMIUM',N'TODAS','2026-02-01','2026-02-28',80,99,30.00,3.50,getdate(),NULL,0,7),
	 (N'PDV PREMIUM',N'TODAS','2026-02-01','2026-02-28',100,149,50.00,5.00,getdate(),NULL,0,8),
	 (N'PDV PREMIUM',N'TODAS','2026-02-01','2026-02-28',100,149,30.00,4.00,getdate(),NULL,0,8),
	 (N'PDV PREMIUM',N'TODAS','2026-02-01','2026-02-28',150,250,50.00,5.50,getdate(),NULL,0,9),
	 (N'PDV PREMIUM',N'TODAS','2026-02-01','2026-02-28',150,250,30.00,4.50,getdate(),NULL,0,9);

-- Notas sobre los datos:
-- PDV REGULAR - Febrero 2026:
-- 1. Rangos de ventas prepago: 5-9, 10-19, 20-29, 30-39, 40-49, 50-79, 80-99, 100-149, 150-250
-- 2. Bonos segun estructura de febrero 2026:
--    - 5-9: S/ 0.5 (>=30% recargadas) y S/ 1.5 (>=50% recargadas)
--    - 10-19: S/ 1.0 (>=30% recargadas) y S/ 2.0 (>=50% recargadas)
--    - 20-29: S/ 1.5 (>=30% recargadas) y S/ 2.5 (>=50% recargadas)
--    - 30-39: S/ 2.0 (>=30% recargadas) y S/ 3.0 (>=50% recargadas)
--    - 40-49: S/ 2.5 (>=30% recargadas) y S/ 3.5 (>=50% recargadas)
--    - 50-79: S/ 3.0 (>=30% recargadas) y S/ 4.0 (>=50% recargadas)
--    - 80-99: S/ 3.5 (>=30% recargadas) y S/ 4.5 (>=50% recargadas)
--    - 100-149: S/ 4.0 (>=30% recargadas) y S/ 5.0 (>=50% recargadas)
--    - 150-250: S/ 4.5 (>=30% recargadas) y S/ 5.5 (>=50% recargadas)
-- 3. Cantidad de calidad minima: 0 (sin minimo de buena calidad)
-- 4. Ratios: 30.00 (>=30% recargadas) y 50.00 (>=50% recargadas)
-- 5. Zona: "TODAS" (aplica para todas las zonales)
-- 6. El periodo es del 1 al 28 de febrero 2026
--
-- PDV PREMIUM - Febrero 2026:
-- IMPORTANTE: PDV PREMIUM usa EXACTAMENTE las mismas reglas que PDV REGULAR en febrero 2026
-- 1. Mismos rangos de ventas prepago: 5-9, 10-19, 20-29, 30-39, 40-49, 50-79, 80-99, 100-149, 150-250
-- 2. Mismos bonos que PDV REGULAR segun estructura de febrero 2026
-- 3. Misma cantidad de calidad minima: 0 (sin minimo de buena calidad)
-- 4. Mismos ratios: 30.00 (>=30% recargadas) y 50.00 (>=50% recargadas)
-- 5. Misma zona: "TODAS" (aplica para todas las zonales, sin separacion LIMA SUR/REGIONES)
--
-- NOTA: Bono adicional C1 + C2 (Aplica para AMBOS tipos de PDV):
--    - Para rangos 5-49: S/ 1.0 (si llega al 50% C1C2)
--    - Para rangos 50-149: S/ 1.5 (si llega al 50% C1C2)
--    Este bono adicional se debe calcular por separado en el sistema de bonificacion
--
-- NOTA ESPECIAL - Rango R9* (150-250):
--    - Los unitarios del R9 solo aplican en caso el PDV tenga como minimo 45% C1C2 (Buena calidad)
--    - De lo contrario, solo se pagara hasta la venta 149 (R8)
--    - Esta validacion debe implementarse en la logica de calculo de bonos
--    - En febrero 2026, el R9 mantiene bonos:
--      * >=30% recargadas: S/ 4.5
--      * >=50% recargadas: S/ 5.5
