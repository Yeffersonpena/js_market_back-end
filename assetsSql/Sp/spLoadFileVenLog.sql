-- USE PORTAL_COMERCIAL;
CREATE PROCEDURE dbo.spLoadFileVentaLog
    @month INT
AS
BEGIN
    BEGIN TRY
        INSERT INTO dbo.tbl_venta_log (
            [DNI_VENDEDOR], DNI_RESPONSABLE, [FECHA], OPERATION_NAME, PRODUCT_NAME,
            --  ACTIVITY_RESULT,
              CLIENT_DNI
            --   , LINE_NUMBER, ICCID, SALES_TYPE
            -- , SOCIO, ZONAL, ACCION, REGION, CLUSTERCALIDAD, MONTO_ACUMULADO_RECARGAS, MONTO_PRIMERA_RECARGA, MONTO_RECARGAS_DIA0
        )
        SELECT 
            -- CONVERT(VARCHAR(50), CAST([DNI_Responsable] AS BIGINT)) AS [DNI_Responsable],
            [DNI_VENDEDOR], DNI_RESPONSABLE, [FECHA], OPERATION_NAME, PRODUCT_NAME,
            --  ACTIVITY_RESULT, 
             CLIENT_DNI
            --  , LINE_NUMBER, ICCID, SALES_TYPE
            -- , SOCIO, ZONAL, ACCION, REGION, CLUSTERCALIDAD, MONTO_ACUMULADO_RECARGAS, MONTO_PRIMERA_RECARGA, MONTO_RECARGAS_DIA0

        FROM OPENROWSET(
            'Microsoft.ACE.OLEDB.12.0', 
            -- 'Excel 12.0; Database=D:\OneDrive - J.S. Market Solutions SAC\PLANIFICACION\MAESTRAS\fuente_portal_AD\ESQUEMAS\Esquemas.xlsx;',
            'Excel 12.0; Database=D:\OneDrive - J.S. Market Solutions SAC\PLANIFICACION\MAESTRAS\fuente_portal_AD\ENTREGABLE\VentasLog.xlsm;',
            'SELECT * FROM [BASE$]'
        );
        insert into dbo.tbl_log_procedimientos values ('spLoadFileVentaLog', GETDATE());
        RETURN 0; 
    END TRY
    BEGIN CATCH
        RETURN ERROR_MESSAGE();  
    END CATCH
END










