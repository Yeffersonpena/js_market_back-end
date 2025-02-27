-- USE BD_PLANIFICACION_OUTLET_AD;
-- DROP PROCEDURE IF EXISTS dbo.spLoadFileEntregable;
CREATE PROCEDURE dbo.spLoadFileEntregable
AS
BEGIN
    BEGIN TRY
        INSERT INTO PDV_OUT_ENTREGABLE (
            AÑO,
            MES, 
            SOCIO,
            ZONAL,
            DNI_RESPONSABLE,
            [DNI/CE],
            DNI_VENDEDOR,
            NOMBRE_RESPONSABLE,
            NOMBRE_VENDEDOR,
            NOMBRE_SUPERVISOR,
            ESTADO,
            FECHA_INICIO,
            FECHA_FIN,
            ACCION_1,
            ACCION_2,
            DISTRITO,
            CONGLOMERADO,
            NUMERO_RECARGADOR,
            CHIP_MM,
            COORDENADA_X,
            COORDENADA_Y,
            CLUSTER_PDV_REGULAR,
            NOMBRE_VENDEDOR1,
            TEAM_LIDER,
            TEAM_LIDER_FECHA_INICIO,
            TEAM_LIDER_FECHA_FIN,
            CUOTA_PREPAGO, 
            CELULAR_VENDEDOR
            )
            SELECT 
                [Año],
                [Mes],
                [Socio],
                [Zonal],
                [DNI_Responsable],
                [DNI/CE],
                [DNI_Vendedor],
                [Nombre Responsable],
                [Nombre Vendedor],
                [Nombre de supervisor],
                [Estado],
                [Fecha de inicio],
                [Fecha de Cese],
                [Acción 1],
                [Acción 2],
                [Distrito],
                [Conglomerado],
                [Número recargador],
                [CHIPS MM],
                [Coordenada_X],
                [Coordenada_Y],
                [Cluster_Pdv_Regular],
                [Nombre Vendedor_1],
                [ES TEAM LEADER? SI/NO],
                [TEAM LIDER FECHA DE INICIO],
                [TEAM LIDER FECHA FINAL],
                [CUOTA_PREPAGO], 
                [CELULAR_VENDEDOR]
            FROM OPENROWSET(
                'Microsoft.ACE.OLEDB.12.0', 
                --'Excel 12.0; Database=' + @pathFile + ';',
                -- 'Excel 12.0; Database=D:\JS-MARKET\Proyecto\v2\js_market_back-end\storage\app\private\file_xlsx\Entregable.xlsx;',
                'Excel 12.0; Database=D:\OneDrive - J.S. Market Solutions SAC\PLANIFICACION\MAESTRAS\fuente_portal_AD\ENTREGABLE\Entregable.xlsx;',
                'SELECT * FROM [BASE JS$]'
            );
        -- PRINT 'El procedimiento se ejecutó correctamente.';
        RETURN 0; 
    END TRY
    BEGIN CATCH
        -- SELECT ERROR_MESSAGE() AS ErrorMessage;
        -- THROW;
        -- PRINT 'Ocurrió un error durante la ejecución del procedimiento.';
        -- RETURN 1;  
        RETURN ERROR_MESSAGE();  
    END CATCH
END
