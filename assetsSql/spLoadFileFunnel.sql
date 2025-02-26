CREATE PROCEDURE spLoadFileFunnel
AS
BEGIN
    BEGIN TRY
        INSERT INTO dbo.PDV_OUT_FUNNEL (
            ZONAL,
            REGION,
            SOCIO,
            DNI_RESPONSABLE,
            DNI_VENDEDOR,
            FECHA,
            PRODUCTO_WEB,
            PRODUCTOORIGEN,
            OPERADORCEDENTE,
            TELEFONO,
            TIPO_PREPAGO,
            CALIDAD_CLUSTER,
            FECHA_PRIMERA_RECARGA,
            DOCUMENTO_CLIENTE,
            VENTA_EXTRANJERO,
            MONTO_ACUMULADO_RECARGAS,
            PRODUCTO,
            RECARGA_SI_NO,
            MONTO_PRIMERA_RECARGA,
            [RECARGAS>5],
            ACCION,
            ACCION_INTERNA,
            VENTAS_REPETIDAS,
            TRIPLICADO_SI_NO
        )
        SELECT ZONAL,
            REGION,
            SOCIO,
            DNI_RESPONSABLE,
            DNI_VENDEDOR,
            FECHA,
            PRODUCTO_WEB,
            PRODUCTOORIGEN,
            OPERADORCEDENTE, 
            TELEFONO,
            TIPO_PREPAGO,
            CALIDAD_CLUSTER,
            FECHA_PRIMERA_RECARGA,
            DOCUMENTO_CLIENTE,
            VENTA_EXTRANJERO,
            MONTO_ACUMULADO_RECARGAS, 
            PRODUCTO,
            RECARGA_SI_NO,
            MONTO_PRIMERA_RECARGA,
            [RECARGAS>5],
            ACCION,
            ACCION_INTERNA,
            VENTAS_REPETIDAS,
            TRIPLICADO_SI_NO
        FROM OPENROWSET(
            'Microsoft.ACE.OLEDB.12.0', 
            'Excel 12.0; Database=D:\JS-MARKET\Proyecto\v2\js_market_back-end\storage\app\private\public\file_xlsx\Funnel.xlsm;',
            'SELECT * FROM [BASE$]'
        );
    END TRY
    BEGIN CATCH
        SELECT ERROR_MESSAGE() AS ErrorMessage;
        THROW;
    END CATCH
END

