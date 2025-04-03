CREATE PROCEDURE [dbo].[spCalculoPaymentAll]
    @dni INT,
    @año INT,
    @mes INT,
    @tipoQuincena INT,
    @tipoUser INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @procName NVARCHAR(255);
    DECLARE @sql NVARCHAR(MAX);

    IF @mes IN (2, 3, 4, 5)
    BEGIN
        IF @tipoUser = 2
        BEGIN
            SET @procName = 'dbo.spCalculoPayment_' + CAST(@mes AS NVARCHAR(2));
        END
        ELSE IF @tipoUser = 3
        BEGIN
            SET @procName = 'dbo.spCalculoPaymentMM_' + CAST(@mes AS NVARCHAR(2));
        END
        
        SET @sql = N'EXEC ' + @procName + N' @dni, @año, @mes;';
        EXEC sp_executesql @sql, N'@dni INT, @año INT, @mes INT, @tipoQuincena INT', @dni, @año, @mes, @tipoQuincena;
    END
    ELSE
    BEGIN
        PRINT 'Mes no válido.';
    END
END;