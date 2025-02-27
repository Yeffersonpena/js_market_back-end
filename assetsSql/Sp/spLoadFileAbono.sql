-- USE BD_PLANIFICACION_OUTLET_AD;
CREATE PROCEDURE dbo.spLoadFileAbono
AS
BEGIN
    BEGIN TRY
        INSERT INTO dbo.PDV_OUT_ABONOS (
           columan_name_tbl
        )
        SELECT columna_NAME_xlsx,
                --
        FROM OPENROWSET(
            'Microsoft.ACE.OLEDB.12.0', 
            'Excel 12.0; Database=D:\OneDrive - J.S. Market Solutions SAC\PLANIFICACION\MAESTRAS\fuente_portal_AD\ABONOS\Abono.xlsx;',
            'SELECT * FROM [name_pestaña$]'
        );
        RETURN 0; 
    END TRY
    BEGIN CATCH
        RETURN ERROR_MESSAGE();  
    END CATCH
END

