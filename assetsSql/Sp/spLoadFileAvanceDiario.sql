-- USE BD_PLANIFICACION_OUTLET_AD;
CREATE PROCEDURE dbo.spLoadFileAvanceDiario
AS
BEGIN
    BEGIN TRY
        INSERT INTO dbo.PDV_OUT_AVANCES_DIARIOS_MM (
           columan_name_tbl
        )
        SELECT columna_NAME_xlsx,
                --
        FROM OPENROWSET(
            'Microsoft.ACE.OLEDB.12.0', 
            'Excel 12.0; Database=D:\OneDrive - J.S. Market Solutions SAC\PLANIFICACION\MAESTRAS\fuente_portal_AD\AVANCE_DIARIO\Avance_diario.xlsx;',
            'SELECT * FROM [name_pestaña$]'
        );
        RETURN 0; 
    END TRY
    BEGIN CATCH
        RETURN ERROR_MESSAGE();  
    END CATCH
END

