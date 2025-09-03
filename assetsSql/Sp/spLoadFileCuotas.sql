-- USE BD_PLANIFICACION_OUTLET_AD;
CREATE PROCEDURE dbo.spLoadFileFunnel
    -- @pathFile NVARCHAR(255) 
    @month INT
AS
BEGIN
    BEGIN TRY
        delete from dbo.PDV_OUT_FUNNEL  where YEAR(fecha)=YEAR(GETDATE()) and month(fecha) =@month;
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
            -- 'Excel 12.0; Database=' + @pathFile + ';',
            -- 'Excel 12.0; Database=D:\JS-MARKET\Proyecto\v2\js_market_back-end\storage\app\private\file_xlsx\Funnel.xlsm;',
            'Excel 12.0; Database=D:\OneDrive - J.S. Market Solutions SAC\PLANIFICACION\MAESTRAS\fuente_portal_AD\FUNNEL\Funnel.xlsm;',
            'SELECT * FROM [BASE$]'
        );

        insert into dbo.tbl_log_procedimientos values ('spLoadFileEntregable', GETDATE());
        RETURN 0; 
    END TRY
    BEGIN CATCH
        RETURN ERROR_MESSAGE();
    END CATCH
END

