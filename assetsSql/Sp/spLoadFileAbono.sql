CREATE PROCEDURE dbo.spLoadFileAbono
AS
BEGIN
    BEGIN TRY
        INSERT INTO dbo.PDV_OUT_ABONOS (
           [año],[mes],[DNI],[DETALLE],[BONO TOTAL],[STATUS DEL ABONO],[FECHAS_ABONO]
        )
        SELECT 
		[AÑO],[MES],[DNI],[DETALLE],[BONO TOTAL],[STATUS DEL ABONO],[FECHAS_ ABONO]
        FROM OPENROWSET(
            'Microsoft.ACE.OLEDB.12.0', 
            'Excel 12.0; Database=D:\OneDrive - J.S. Market Solutions SAC\PLANIFICACION\MAESTRAS\fuente_portal_AD\ABONOS\Abono.xlsx;',
            'SELECT * FROM [Hoja1$]'
        );

        insert into dbo.tbl_log_procedimientos values ('spLoadFileAbono', GETDATE());
        RETURN 0; 
    END TRY
    BEGIN CATCH
        RETURN ERROR_MESSAGE();  
    END CATCH
END