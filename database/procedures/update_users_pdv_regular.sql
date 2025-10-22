-- Desactivar todos los usuarios
UPDATE PORTAL_COMERCIAL.dbo.users 
SET estado = 0
WHERE estado IS NULL OR estado != 0;

-- Activar responsables PDV REGULAR (Octubre 2025)
UPDATE u 
SET estado = 1
FROM PORTAL_COMERCIAL.dbo.users u
INNER JOIN PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE p 
    ON TRY_CAST(u.[user] AS INT) = p.DNI_RESPONSABLE
WHERE p.ACCION_1 = 'PDV REGULAR'
    AND p.AÑO = 2025 
    AND p.MES = 10
    AND TRY_CAST(u.[user] AS INT) IS NOT NULL;

-- Activar vendedores PDV REGULAR (Octubre 2025)
UPDATE u 
SET estado = 1
FROM PORTAL_COMERCIAL.dbo.users u
INNER JOIN PORTAL_COMERCIAL.dbo.PDV_OUT_FUNNEL f 
    ON TRY_CAST(u.[user] AS INT) = f.DNI_VENDEDOR
WHERE f.ACCION = 'PDV REGULAR'
    AND YEAR(f.FECHA) = 2025 
    AND MONTH(f.FECHA) = 10
    AND TRY_CAST(u.[user] AS INT) IS NOT NULL;
