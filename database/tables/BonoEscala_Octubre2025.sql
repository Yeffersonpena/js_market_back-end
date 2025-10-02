-- Sentencias INSERT para BonoEscala - Octubre 2025
-- Basado en los patrones de datos existentes para julio, agosto y septiembre 2025

-- Datos para LIMA SUR - Octubre 2025 (Valores actualizados según nueva estructura)
INSERT INTO PORTAL_COMERCIAL.dbo.BonoEscala (tipo_pdv,zonal_pattern,fecha_inicio,fecha_fin,rango_min,rango_max,ratio_min,bono,created_at,updated_at,cantidad_calidad_min) VALUES
	 (N'PDV PREMIUM',N'%LIMA SUR%','2025-10-01','2025-10-31',150,220,45.00,3.00,getdate(),NULL,50),
	 (N'PDV PREMIUM',N'%LIMA SUR%','2025-10-01','2025-10-31',150,220,0.00,2.00,getdate(),NULL,50),
	 (N'PDV PREMIUM',N'%LIMA SUR%','2025-10-01','2025-10-31',221,300,45.00,3.50,getdate(),NULL,50),
	 (N'PDV PREMIUM',N'%LIMA SUR%','2025-10-01','2025-10-31',221,300,0.00,2.50,getdate(),NULL,50),
	 (N'PDV PREMIUM',N'%LIMA SUR%','2025-10-01','2025-10-31',301,400,45.00,4.00,getdate(),NULL,50),
	 (N'PDV PREMIUM',N'%LIMA SUR%','2025-10-01','2025-10-31',301,400,0.00,3.00,getdate(),NULL,50);

-- Datos para REGIONES - Octubre 2025 (Valores actualizados según nueva estructura)
INSERT INTO PORTAL_COMERCIAL.dbo.BonoEscala (tipo_pdv,zonal_pattern,fecha_inicio,fecha_fin,rango_min,rango_max,ratio_min,bono,created_at,updated_at,cantidad_calidad_min) VALUES
	 (N'PDV PREMIUM',N'REGIONES','2025-10-01','2025-10-31',150,220,45.00,5.00,getdate(),NULL,55),
	 (N'PDV PREMIUM',N'REGIONES','2025-10-01','2025-10-31',150,220,0.00,3.50,getdate(),NULL,55),
	 (N'PDV PREMIUM',N'REGIONES','2025-10-01','2025-10-31',221,300,45.00,5.50,getdate(),NULL,75),
	 (N'PDV PREMIUM',N'REGIONES','2025-10-01','2025-10-31',221,300,0.00,4.00,getdate(),NULL,75),
	 (N'PDV PREMIUM',N'REGIONES','2025-10-01','2025-10-31',301,400,45.00,6.00,getdate(),NULL,100),
	 (N'PDV PREMIUM',N'REGIONES','2025-10-01','2025-10-31',301,400,0.00,4.50,getdate(),NULL,100);

-- Datos para PDV REGULAR - Octubre 2025 (Nueva estructura de bonos - Sin separación de zonas)
INSERT INTO PORTAL_COMERCIAL.dbo.BonoEscala (tipo_pdv,zonal_pattern,fecha_inicio,fecha_fin,rango_min,rango_max,ratio_min,bono,created_at,updated_at,cantidad_calidad_min) VALUES
	 (N'PDV REGULAR',N'TODAS','2025-10-01','2025-10-31',5,10,50.00,1.50,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-10-01','2025-10-31',5,10,30.00,0.50,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-10-01','2025-10-31',11,20,50.00,2.50,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-10-01','2025-10-31',11,20,30.00,1.50,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-10-01','2025-10-31',21,40,50.00,3.00,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-10-01','2025-10-31',21,40,30.00,2.00,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-10-01','2025-10-31',41,80,50.00,3.50,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-10-01','2025-10-31',41,80,30.00,2.50,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-10-01','2025-10-31',81,100,50.00,4.00,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-10-01','2025-10-31',81,100,30.00,3.00,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-10-01','2025-10-31',101,149,50.00,4.50,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-10-01','2025-10-31',101,149,30.00,3.50,getdate(),NULL,0);

-- Notas sobre los datos:
-- PDV PREMIUM:
-- 1. AMBAS ZONAS: Nuevos rangos de ventas: 150-220, 221-300, 301-400 (se eliminó 100-149)
-- 2. LIMA SUR: Nuevos bonos según estructura de octubre 2025:
--    - 150-220: S/ 2.0 (<45%) y S/ 3.0 (>=45%)
--    - 221-300: S/ 2.5 (<45%) y S/ 3.5 (>=45%)
--    - 301-400: S/ 3.0 (<45%) y S/ 4.0 (>=45%)
-- 3. REGIONES: Nuevos bonos según estructura de octubre 2025:
--    - 150-220: S/ 3.5 (<45%) y S/ 5.0 (>=45%)
--    - 221-300: S/ 4.0 (<45%) y S/ 5.5 (>=45%)
--    - 301-400: S/ 4.5 (<45%) y S/ 6.0 (>=45%)
-- 4. Cantidades de calidad mínima actualizadas:
--    - LIMA SUR: 50 para todos los rangos
--    - REGIONES: 55 (150-220), 75 (221-300), 100 (301-400)
-- 5. Ratios: 0.00 y 45.00
--
-- PDV REGULAR (NUEVO):
-- 6. Rangos de ventas: 5-10, 11-20, 21-40, 41-80, 81-100, 101-149
-- 7. Bonos según estructura de octubre 2025:
--    - 5-10: S/ 0.5 (>=30%) y S/ 1.5 (>=50%)
--    - 11-20: S/ 1.5 (>=30%) y S/ 2.5 (>=50%)
--    - 21-40: S/ 2.0 (>=30%) y S/ 3.0 (>=50%)
--    - 41-80: S/ 2.5 (>=30%) y S/ 3.5 (>=50%)
--    - 81-100: S/ 3.0 (>=30%) y S/ 4.0 (>=50%)
--    - 101-149: S/ 3.5 (>=30%) y S/ 4.5 (>=50%)
-- 8. Cantidad de calidad mínima: 0 (sin mínimo de buena calidad)
-- 9. Ratios: 30.00 y 50.00
-- 10. Zona: "TODAS" (sin separación de zonas)
--
-- 11. El período es del 1 al 31 de octubre 2025
