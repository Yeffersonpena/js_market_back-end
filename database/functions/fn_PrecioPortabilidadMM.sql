CREATE FUNCTION [dbo].[fn_PrecioPortabilidadMM](
    @año INT,
    @mes INT,
    @tipoPortabilidad VARCHAR(20) -- 'PREPAGO' o 'POSTPAGO'
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @precio DECIMAL(10,2) = 0;
    
    SELECT @precio = precio_unitario
    FROM tbl_parametros_portabilidad_mm
    WHERE año = @año 
      AND mes = @mes 
      AND tipo_portabilidad = @tipoPortabilidad;
    
    RETURN ISNULL(@precio, 0);
END;
