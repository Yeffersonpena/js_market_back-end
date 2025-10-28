-- Script para eliminar registros del día 1 del mes anterior
-- que corresponden a productos 'PORT PREPAGO M7' y 'PORT M4 NO DIR'
-- Solo afecta al mes anterior, no al mes actual

DECLARE @añoAnterior INT, @mesAnterior INT;

-- Calcular el mes anterior
IF MONTH(GETDATE()) = 1
BEGIN
    SET @añoAnterior = YEAR(GETDATE()) - 1;
    SET @mesAnterior = 12;
END
ELSE
BEGIN
    SET @añoAnterior = YEAR(GETDATE());
    SET @mesAnterior = MONTH(GETDATE()) - 1;
END;

-- Mostrar información de lo que se va a eliminar
SELECT 
    COUNT(*) AS Registros_A_Eliminar,
    @añoAnterior AS Año,
    @mesAnterior AS Mes
FROM dbo.PDV_OUT_FUNNEL 
WHERE PRODUCTO_WEB IN ('PORT PREPAGO M7', 'PORT M4 NO DIR') 
  AND DAY(FECHA) = 1 
  AND YEAR(FECHA) = @añoAnterior 
  AND MONTH(FECHA) = @mesAnterior;

-- Eliminar los registros del día 1 del mes anterior para los productos específicos
DELETE FROM dbo.PDV_OUT_FUNNEL 
WHERE PRODUCTO_WEB IN ('PORT PREPAGO M7', 'PORT M4 NO DIR') 
  AND DAY(FECHA) = 1 
  AND YEAR(FECHA) = @añoAnterior 
  AND MONTH(FECHA) = @mesAnterior;

-- Mostrar resultado
PRINT 'Registros eliminados del día 1 del mes ' + CAST(@mesAnterior AS VARCHAR(2)) + '/' + CAST(@añoAnterior AS VARCHAR(4));
