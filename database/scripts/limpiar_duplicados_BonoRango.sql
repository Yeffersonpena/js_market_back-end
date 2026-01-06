-- Script para limpiar duplicados en BonoRango
-- Mantiene solo el registro más reciente (mayor id) para cada combinación de:
-- (nivel_rango, tipo_bono, fecha_inicio)

-- Verificar duplicados antes de eliminar
SELECT
    nivel_rango,
    tipo_bono,
    fecha_inicio,
    COUNT(*) AS cantidad_duplicados,
    MIN(id) AS id_mas_antiguo,
    MAX(id) AS id_mas_reciente
FROM PORTAL_COMERCIAL.dbo.BonoRango
GROUP BY nivel_rango, tipo_bono, fecha_inicio
HAVING COUNT(*) > 1
ORDER BY nivel_rango, tipo_bono, fecha_inicio;

-- Eliminar duplicados, manteniendo solo el registro con mayor id (más reciente)
WITH Duplicados AS (
    SELECT
        id,
        nivel_rango,
        tipo_bono,
        fecha_inicio,
        ROW_NUMBER() OVER (
            PARTITION BY nivel_rango, tipo_bono, fecha_inicio
            ORDER BY id DESC  -- Mantener el más reciente (mayor id)
        ) AS rn
    FROM PORTAL_COMERCIAL.dbo.BonoRango
)
DELETE FROM PORTAL_COMERCIAL.dbo.BonoRango
WHERE id IN (
    SELECT id
    FROM Duplicados
    WHERE rn > 1  -- Eliminar todos excepto el primero (más reciente)
);

-- Verificar que ya no hay duplicados
SELECT
    nivel_rango,
    tipo_bono,
    fecha_inicio,
    COUNT(*) AS cantidad
FROM PORTAL_COMERCIAL.dbo.BonoRango
GROUP BY nivel_rango, tipo_bono, fecha_inicio
HAVING COUNT(*) > 1;

-- Si la query anterior no devuelve filas, significa que ya no hay duplicados

