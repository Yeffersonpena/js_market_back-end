CREATE FUNCTION dbo.fn_calcularBono (@dniResponsable VARCHAR(20), @mes INT, @anio INT)
RETURNS FLOAT
AS
BEGIN
    DECLARE @totalVenta INT
    DECLARE @totalRecargas INT
    DECLARE @tipoPDV VARCHAR(20)
    DECLARE @bonoPre FLOAT

    SELECT @totalVenta = COUNT(*) 
    FROM dbo.PDV_OUT_FUNNEL 
    WHERE DNI_RESPONSABLE = @dniResponsable
    AND YEAR(fecha) = @anio 
    AND MONTH(fecha) = @mes

    SELECT @totalRecargas = COUNT(*) 
    FROM dbo.PDV_OUT_FUNNEL 
    WHERE DNI_RESPONSABLE = @dniResponsable
    AND YEAR(fecha) = @anio 
    AND MONTH(fecha) = @mes
    AND [RECARGAS>5] = 1

    SELECT TOP 1 @tipoPDV = ACCION_2 
    FROM dbo.PDV_OUT_ENTREGABLE 
    WHERE AÑO = @anio 
    AND DNI_RESPONSABLE = @dniResponsable
    ORDER BY mes DESC

    IF @tipoPDV = 'PDV REGULAR'
    BEGIN
        IF @totalVenta BETWEEN 1 AND 10
        BEGIN
            IF CAST(@totalRecargas AS FLOAT) / @totalVenta >= 0.5
                SET @bonoPre = @totalVenta * 1.5
            ELSE
                SET @bonoPre = @totalVenta * 0.5
        END
        ELSE IF @totalVenta BETWEEN 11 AND 20
        BEGIN
            IF CAST(@totalRecargas AS FLOAT) / @totalVenta >= 0.5
                SET @bonoPre = @totalVenta * 2.5
            ELSE
                SET @bonoPre = @totalVenta * 1.5
        END
        ELSE IF @totalVenta BETWEEN 21 AND 40
        BEGIN
            IF CAST(@totalRecargas AS FLOAT) / @totalVenta >= 0.5
                SET @bonoPre = @totalVenta * 3
            ELSE
                SET @bonoPre = @totalVenta * 2
        END
        ELSE IF @totalVenta BETWEEN 41 AND 80
        BEGIN
            IF CAST(@totalRecargas AS FLOAT) / @totalVenta >= 0.5
                SET @bonoPre = @totalVenta * 3.5
            ELSE
                SET @bonoPre = @totalVenta * 2.5
        END
        ELSE IF @totalVenta >= 81
        BEGIN
            IF CAST(@totalRecargas AS FLOAT) / @totalVenta >= 0.5
                SET @bonoPre = @totalVenta * 4
            ELSE
                SET @bonoPre = @totalVenta * 3
        END
    END
    ELSE IF @tipoPDV = 'PDV PREMIUM'
    BEGIN
        IF @totalVenta >=80 AND @totalVenta < 150
        BEGIN
            SET @bonoPre = @totalVenta * 2.0
        END
        IF @totalVenta BETWEEN 150 AND 250
        BEGIN
            IF CAST(@totalRecargas AS FLOAT) / @totalVenta >= 0.5
                SET @bonoPre = @totalVenta * 5.0
            ELSE
                SET @bonoPre = @totalVenta * 4.0
        END
        ELSE IF @totalVenta >= 251
        BEGIN
            IF CAST(@totalRecargas AS FLOAT) / @totalVenta >= 0.5
                SET @bonoPre = @totalVenta * 6.0
            ELSE
                SET @bonoPre = @totalVenta * 5.0
        END
    END

    RETURN @bonoPre
END
