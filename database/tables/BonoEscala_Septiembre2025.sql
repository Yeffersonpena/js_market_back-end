-- Sentencias INSERT para BonoEscala - Septiembre 2025
-- Datos históricos para PDV REGULAR (ratio mínimo 20%, CON rango 101-149)
-- Introduce el nuevo rango 101-149 desde septiembre 2025

-- Datos para PDV REGULAR - Septiembre 2025 (Datos históricos - Sin separación de zonas)
INSERT INTO PORTAL_COMERCIAL.dbo.BonoEscala (tipo_pdv,zonal_pattern,fecha_inicio,fecha_fin,rango_min,rango_max,ratio_min,bono,created_at,updated_at,cantidad_calidad_min) VALUES
	 (N'PDV REGULAR',N'TODAS','2025-09-01','2025-09-30',5,10,50.00,1.50,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-09-01','2025-09-30',5,10,20.00,0.50,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-09-01','2025-09-30',11,20,50.00,2.50,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-09-01','2025-09-30',11,20,20.00,1.50,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-09-01','2025-09-30',21,40,50.00,3.00,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-09-01','2025-09-30',21,40,20.00,2.00,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-09-01','2025-09-30',41,80,50.00,3.50,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-09-01','2025-09-30',41,80,20.00,2.50,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-09-01','2025-09-30',81,100,50.00,4.00,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-09-01','2025-09-30',81,100,20.00,3.00,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-09-01','2025-09-30',101,149,50.00,4.50,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-09-01','2025-09-30',101,149,20.00,3.50,getdate(),NULL,0);

-- Notas sobre los datos:
-- 1. Septiembre 2025: Datos específicos para septiembre 2025
-- 2. Ratio mínimo: 20.00 (histórico)
-- 3. Rangos: 5-10, 11-20, 21-40, 41-80, 81-100, 101-149 (NUEVO RANGO desde septiembre)
-- 4. Bonos según estructura histórica:
--    - 5-10: S/ 0.5 (>=20%) y S/ 1.5 (>=50%)
--    - 11-20: S/ 1.5 (>=20%) y S/ 2.5 (>=50%)
--    - 21-40: S/ 2.0 (>=20%) y S/ 3.0 (>=50%)
--    - 41-80: S/ 2.5 (>=20%) y S/ 3.5 (>=50%)
--    - 81-100: S/ 3.0 (>=20%) y S/ 4.0 (>=50%)
--    - 101-149: S/ 3.5 (>=20%) y S/ 4.5 (>=50%) [NUEVO DESDE SEPTIEMBRE]
-- 5. Cantidad de calidad mínima: 0 (sin mínimo de buena calidad)
-- 6. Zona: "TODAS" (sin separación de zonas)
-- 7. Este mes introduce el rango 101-149 que estará disponible desde octubre 2025 en adelante
