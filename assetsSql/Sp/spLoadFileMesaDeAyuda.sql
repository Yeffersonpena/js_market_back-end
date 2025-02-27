-- USE BD_PLANIFICACION_OUTLET_AD;
CREATE PROCEDURE dbo.spLoadFileMesaAyuda
AS
BEGIN
    BEGIN TRY
        INSERT INTO dbo.PDV_OUT_MESA_DE_AYUDA (
           columan_name_tbl
        )
        SELECT columna_NAME_xlsx,
                --
        FROM OPENROWSET(
            'Microsoft.ACE.OLEDB.12.0', 
            'Excel 12.0; Database=D:\OneDrive - J.S. Market Solutions SAC\PLANIFICACION\MAESTRAS\fuente_portal_AD\MESA DE AYUDA\Mesa_de_ayuda.xlsx;',
            'SELECT * FROM [name_pestaña$]'
        );

        insert into dbo.tbl_log_procedimientos values ('spLoadFileEntregable', GETDATE());
        RETURN 0; 
    END TRY
    BEGIN CATCH
        RETURN ERROR_MESSAGE();  
    END CATCH
END

