-- Sentencias INSERT para BonoEscala - Agosto 2025
-- Datos históricos para PDV REGULAR (ratio mínimo 20%, sin rango 101-149)
-- Se usará como referencia para períodos menores a agosto 2025

-- Datos para PDV REGULAR - Enero a Agosto 2025 (Datos históricos - Sin separación de zonas)
INSERT INTO PORTAL_COMERCIAL.dbo.BonoEscala (tipo_pdv,zonal_pattern,fecha_inicio,fecha_fin,rango_min,rango_max,ratio_min,bono,created_at,updated_at,cantidad_calidad_min) VALUES
	 (N'PDV REGULAR',N'TODAS','2025-01-01','2025-08-31',5,10,50.00,1.50,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-01-01','2025-08-31',5,10,20.00,0.50,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-01-01','2025-08-31',11,20,50.00,2.50,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-01-01','2025-08-31',11,20,20.00,1.50,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-01-01','2025-08-31',21,40,50.00,3.00,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-01-01','2025-08-31',21,40,20.00,2.00,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-01-01','2025-08-31',41,80,50.00,3.50,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-01-01','2025-08-31',41,80,20.00,2.50,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-01-01','2025-08-31',81,100,50.00,4.00,getdate(),NULL,0),
	 (N'PDV REGULAR',N'TODAS','2025-01-01','2025-08-31',81,100,20.00,3.00,getdate(),NULL,0);

-- Notas sobre los datos:
-- 1. Período: Enero a Agosto 2025 (2025-01-01 a 2025-08-31)
-- 2. Ratio mínimo: 20.00 (histórico)
-- 3. Rangos: 5-10, 11-20, 21-40, 41-80, 81-100 (sin rango 101-149)
-- 4. Bonos según estructura histórica:
--    - 5-10: S/ 0.5 (>=20%) y S/ 1.5 (>=50%)
--    - 11-20: S/ 1.5 (>=20%) y S/ 2.5 (>=50%)
--    - 21-40: S/ 2.0 (>=20%) y S/ 3.0 (>=50%)
--    - 41-80: S/ 2.5 (>=20%) y S/ 3.5 (>=50%)
--    - 81-100: S/ 3.0 (>=20%) y S/ 4.0 (>=50%)
-- 5. Cantidad de calidad mínima: 0 (sin mínimo de buena calidad)
-- 6. Zona: "TODAS" (sin separación de zonas)
-- 7. Se aplicará para todos los meses de enero a agosto 2025
