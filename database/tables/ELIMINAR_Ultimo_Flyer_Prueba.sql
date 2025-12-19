-- Elimina el último flyer registrado (asignaciones a usuarios y campaña)
DECLARE @nombreFlyer VARCHAR(200);

SELECT TOP 1 @nombreFlyer = foto_esquema
FROM PORTAL_COMERCIAL.dbo.PDV_OUT_CAMPAÑAS_FLYERS
ORDER BY fecha_creacion DESC, id DESC;

SELECT @nombreFlyer AS 'Flyer_a_Eliminar';

DELETE FROM PORTAL_COMERCIAL.dbo.PDV_OUT_FLYERS
WHERE foto_esquema = @nombreFlyer;

DELETE FROM PORTAL_COMERCIAL.dbo.PDV_OUT_CAMPAÑAS_FLYERS
WHERE foto_esquema = @nombreFlyer;

SELECT @nombreFlyer AS 'Flyer_Eliminado', 'Eliminación completada' AS 'Estado';
