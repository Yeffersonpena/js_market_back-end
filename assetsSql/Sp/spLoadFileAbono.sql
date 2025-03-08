CREATE PROCEDURE dbo.spLoadFileAbono
@month INT
AS
BEGIN
    BEGIN TRY
		delete from dbo.TEMP_PDV_OUT_ABONOS;
	 -- delete from dbo.TEMP_PDV_OUT_ABONOS  where [año]=YEAR(GETDATE()) and mes=@month;
        INSERT INTO dbo.TEMP_PDV_OUT_ABONOS (
              [año],[mes],[DNI],[DETALLE],[BONO TOTAL],[STATUS DEL ABONO],[FECHAS_ABONO]
            )
        SELECT 
         [AÑO],[MES],CONVERT(VARCHAR(50), CAST([DNI] AS BIGINT)) AS DNI,[DETALLE],[BONO TOTAL],[STATUS DEL ABONO],[FECHAS_ ABONO]
            --    [AÑO],[MES],cast([DNI] as varchar),[DETALLE],[BONO TOTAL],[STATUS DEL ABONO],[FECHAS_ ABONO]
        FROM OPENROWSET(
            'Microsoft.ACE.OLEDB.12.0', 
            'Excel 12.0; Database=D:\OneDrive - J.S. Market Solutions SAC\PLANIFICACION\MAESTRAS\fuente_portal_AD\ABONOS\Abonos.xlsx;',
            'SELECT * FROM [Hoja1$]'
        );

        insert into dbo.tbl_log_procedimientos values ('spLoadFileEntregable', GETDATE());
		 delete from dbo.PDV_OUT_ABONOS where [año]=YEAR(GETDATE()) and mes in (select mes from dbo.TEMP_PDV_OUT_ABONOS group by mes);
		 insert into portal_comercial.dbo.PDV_OUT_ABONOS( [año],[mes],[DNI],[DETALLE],[BONO TOTAL],[STATUS DEL ABONO],[FECHAS_ABONO])
			select [año],[mes],[DNI],[DETALLE],[BONO TOTAL],[STATUS DEL ABONO],[FECHAS_ABONO] from portal_comercial.dbo.TEMP_PDV_OUT_ABONOS
        RETURN 0; 
    END TRY
    BEGIN CATCH
        RETURN ERROR_MESSAGE();  
    END CATCH
END
GO