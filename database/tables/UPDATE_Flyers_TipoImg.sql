-- =============================================
-- UPDATE: Asignar tipoImg 'ACELERADOR' a los flyers insertados
-- Fecha: Diciembre 2025
-- Descripción: Actualiza el campo tipoImg a 'ACELERADOR'
-- para los registros de las 3 imágenes insertadas
-- =============================================

-- Actualizar tipoImg para las 3 imágenes de RANGO
UPDATE PORTAL_COMERCIAL.dbo.PDV_OUT_FLYERS
SET tipoImg = 'ACELERADOR'
WHERE foto_esquema IN (
    'Acelerador_PDVRegular_ 05-9Diciembre1-2.jpg',
    'Acelerador_PDVRegular_ 05-9Diciembre_3-4.jpg',
    'Acelerador_PDVRegular_ 05-9Diciembre_5-8.jpg'
)
AND fecha_inicio = '2025-12-05'
AND fecha_fin = '2025-12-09'
AND (tipoImg IS NULL OR tipoImg = '');

-- Verificar el resultado
SELECT
    foto_esquema,
    tipoImg,
    COUNT(*) AS total_registros
FROM PORTAL_COMERCIAL.dbo.PDV_OUT_FLYERS
WHERE foto_esquema IN (
    'Acelerador_PDVRegular_ 05-9Diciembre1-2.jpg',
    'Acelerador_PDVRegular_ 05-9Diciembre_3-4.jpg',
    'Acelerador_PDVRegular_ 05-9Diciembre_5-8.jpg'
)
GROUP BY foto_esquema, tipoImg;

