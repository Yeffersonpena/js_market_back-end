CREATE PROCEDURE dbo.spLoadFileIncidencia
@month INT
AS
BEGIN
    BEGIN TRY
		delete from dbo.tbl_incidencia;
	 -- delete from dbo.tbl_incidencia  where [año]=YEAR(GETDATE()) and mes=@month;
        INSERT INTO dbo.tbl_incidencia (
        [dni_incidencia], [dni_enrolado], [proyecto], [ORDEN], [FECHA ENVIO JEFE], [ERROR], [FECHA ENVIO], [Caso reiterado  Fecha], [Ultimo envio zonal],
        [Status de Incidencia],	[SE SUPERO SI/NO], [ULTIMA FECHA DE VALIDACION (ZONAL)], [OBSERVACION], [SE ENVIO A TDP]
            )
        SELECT 
            TRY_CONVERT(int, [Dni Valor]) AS DniValor,  
            TRY_CONVERT(int, [dni_enrolado]) AS [dni_enrolado],  
            TRY_CONVERT(varchar, [proyecto]) AS Proyecto,  
            TRY_CONVERT(int, [ORDEN]) AS Orden,  
            TRY_CONVERT(datetime, [FECHA ENVIO JEFE]) AS FechaEnvioJefe,  
            TRY_CONVERT(varchar, [ERROR]) AS Error,  
            TRY_CONVERT(datetime, [FECHA ENVIO]) AS FechaEnvio,  
            TRY_CONVERT(datetime, [Caso reiterado  Fecha]) AS CasoReiteradoFecha,  
            TRY_CONVERT(datetime, [Ultimo envio zonal]) AS UltimoEnvioZonal,  
            TRY_CONVERT(varchar, [Status de Incidencia]) AS StatusIncidencia,  
            TRY_CONVERT(varchar, [SE SUPERO SI/NO]) AS SeSupero,  
            TRY_CONVERT(datetime, [ULTIMA FECHA DE VALIDACION (ZONAL)]) AS UltimaFechaValidacionZonal,  
            TRY_CONVERT(varchar, [OBSERVACION]) AS Observacion,  
            TRY_CONVERT(varchar, [SE ENVIO A TDP]) AS SeEnvioATDP 
        FROM OPENROWSET(
            'Microsoft.ACE.OLEDB.12.0', 
            'Excel 12.0; Database=D:\OneDrive - J.S. Market Solutions SAC\PLANIFICACION\MAESTRAS\fuente_portal_AD\INCIDENCIA\Incidencia.xlsx;',
            'SELECT * FROM [BASE$]'
        );
        insert into dbo.tbl_log_procedimientos values ('spLoadFileEntregable', GETDATE());
		--  delete from dbo.PDV_OUT_ABONOS where [año]=YEAR(GETDATE()) and mes in (select mes from dbo.TEMP_PDV_OUT_ABONOS group by mes);
		--  insert into portal_comercial.dbo.tbl_incidencia( [año],[mes],[DNI],[DETALLE],[BONO TOTAL],[STATUS DEL ABONO],[FECHAS_ABONO])
			-- select [año],[mes],[DNI],[DETALLE],[BONO TOTAL],[STATUS DEL ABONO],[FECHAS_ABONO] from portal_comercial.dbo.TEMP_PDV_OUT_ABONOS
        RETURN 0; 
    END TRY
    BEGIN CATCH
        RETURN ERROR_MESSAGE();  
    END CATCH
END
GO