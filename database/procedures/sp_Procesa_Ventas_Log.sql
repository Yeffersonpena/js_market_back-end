-- SP para procesar ventas de prepago desde VentasLog y cargar en tablas de resumen
-- Procesa todo el mes de una vez, usando VentasLog como fuente única
CREATE PROCEDURE [dbo].[sp_Procesa_Ventas_Log]
    @año INT,
    @mes INT
AS
BEGIN
    BEGIN TRY
        -- Variables de rango de fechas para el mes completo
        DECLARE @fechaInicioMes DATE = DATEFROMPARTS(@año, @mes, 1);
        DECLARE @fechaFinMes DATE = DATEADD(MONTH, 1, @fechaInicioMes);

        ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        -- Insert en la tabla resumen prepago (procesa todo el mes desde VentasLog)
        DELETE from dbo.tbl_ventas_prepago_new where year(fecha)=@año and month(fecha)=@mes;

        INSERT INTO dbo.tbl_ventas_prepago_new(DNI_RESPONSABLE, FECHA, ALTA_PREPAGO, PORTA_PREPAGO, DNI_VENDEDOR)
        SELECT
            VALOR_DNI_RESPONSABLE AS DNI_RESPONSABLE,
            FECHA,
            COUNT(CASE WHEN OPERATION_NAME = 'Alta' AND PRODUCT_NAME = 'Prepago' THEN 1 END) AS ALTA_PREPAGO,
            COUNT(CASE WHEN OPERATION_NAME = 'Portabilidad' AND PRODUCT_NAME = 'Prepago' THEN 1 END) AS PORTA_PREPAGO,
            VALOR_DNI_VENDEDOR AS DNI_VENDEDOR
        FROM PORTAL_COMERCIAL.dbo.VentasLog
        WHERE FECHA >= @fechaInicioMes AND FECHA < @fechaFinMes
          AND PRODUCT_NAME = 'Prepago'
          AND VALOR_DNI_RESPONSABLE IS NOT NULL
        GROUP BY VALOR_DNI_RESPONSABLE, VALOR_DNI_VENDEDOR, FECHA;
        ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

        insert into dbo.tbl_log_procedimientos values ('sp_Procesa_Ventas_Log', GETDATE());
        RETURN 0;
    END TRY
    BEGIN CATCH
        RETURN ERROR_MESSAGE();
    END CATCH
END

