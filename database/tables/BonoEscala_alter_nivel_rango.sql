-- ALTER TABLE para agregar campo nivel_rango a BonoEscala
-- Este campo almacenará el nivel de rango (1-8) según la tabla de bonificación

ALTER TABLE PORTAL_COMERCIAL.dbo.BonoEscala
ADD nivel_rango int NULL;

-- UPDATE para establecer nivel_rango para los registros de Noviembre 2025
-- Los niveles de rango se asignan según los rangos de ventas prepago:
-- R1 (nivel_rango = 1): 5-9
-- R2 (nivel_rango = 2): 10-19
-- R3 (nivel_rango = 3): 20-29
-- R4 (nivel_rango = 4): 30-39
-- R5 (nivel_rango = 5): 40-49
-- R6 (nivel_rango = 6): 50-79
-- R7 (nivel_rango = 7): 80-99
-- R8 (nivel_rango = 8): 100-150

UPDATE PORTAL_COMERCIAL.dbo.BonoEscala
SET nivel_rango = CASE
    WHEN rango_min = 5 AND rango_max = 9 THEN 1      -- R1
    WHEN rango_min = 10 AND rango_max = 19 THEN 2    -- R2
    WHEN rango_min = 20 AND rango_max = 29 THEN 3    -- R3
    WHEN rango_min = 30 AND rango_max = 39 THEN 4    -- R4
    WHEN rango_min = 40 AND rango_max = 49 THEN 5    -- R5
    WHEN rango_min = 50 AND rango_max = 79 THEN 6    -- R6
    WHEN rango_min = 80 AND rango_max = 99 THEN 7   -- R7
    WHEN rango_min = 100 AND rango_max = 150 THEN 8 -- R8
    ELSE NULL
END
WHERE fecha_inicio = '2025-11-01' 
  AND fecha_fin = '2025-11-30'
  AND (tipo_pdv = 'PDV REGULAR' OR tipo_pdv = 'PDV PREMIUM')
  AND zonal_pattern = 'TODAS';

