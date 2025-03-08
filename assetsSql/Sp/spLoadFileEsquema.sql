-- USE BD_PLANIFICACION_OUTLET_AD;
CREATE PROCEDURE dbo.spLoadFileEsquema
    @month INT
AS
BEGIN
    BEGIN TRY
        delete from dbo.PDV_OUT_FLYERS where año=YEAR(GETDATE())  and mes=@month;
        INSERT INTO dbo.PDV_OUT_FLYERS (
            año,
            mes,
            dni_responsable,
            zonal,
            foto_esquema,
            fecha_inicio,
            fecha_fin
        )
        SELECT 
            [Año],
            [Mes],
            CONVERT(VARCHAR(50), CAST([DNI_Responsable] AS BIGINT)) AS [DNI_Responsable],
            -- CONVERT(VARCHAR(50), CAST([DNI] AS BIGINT)) AS DNI
            [Zonal],
            [Esquema],
            [Fecha Inicio],
            [Fecha Fin]
        FROM OPENROWSET(
            'Microsoft.ACE.OLEDB.12.0', 
            -- 'Excel 12.0; Database=D:\OneDrive - J.S. Market Solutions SAC\PLANIFICACION\MAESTRAS\fuente_portal_AD\ESQUEMAS\Esquemas.xlsx;',
            'Excel 12.0; Database=D:\OneDrive - J.S. Market Solutions SAC\PLANIFICACION\MAESTRAS\fuente_portal_AD\ESQUEMAS\Listado de incentivos.xlsx;',
            'SELECT * FROM [DETALLE$]'
        );
        insert into dbo.tbl_log_procedimientos values ('spLoadFileEntregable', GETDATE());
        RETURN 0; 
    END TRY
    BEGIN CATCH
        RETURN ERROR_MESSAGE();  
    END CATCH
END

