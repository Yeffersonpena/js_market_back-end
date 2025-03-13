CREATE PROCEDURE [dbo].[spCheckFileExists]
(
    @typeSpName INT
)
-- RETURNS VARCHAR(5)
RETURNS BIT
AS
BEGIN
    DECLARE @FilePath VARCHAR(255)
    DECLARE @FileExists INT
    DECLARE @Result VARCHAR(5)

    IF @typeSpName = 1
    BEGIN
        SET @FilePath = 'D:\OneDrive - J.S. Market Solutions SAC\PLANIFICACION\MAESTRAS\fuente_portal_AD\ENTREGABLE\Entregable.xlsx'
    END
    ELSE IF @typeSpName = 2
    BEGIN
        SET @FilePath = 'D:\OneDrive - J.S. Market Solutions SAC\PLANIFICACION\MAESTRAS\fuente_portal_AD\FUNNEL\Funnel.xlsm'
    END
    ELSE IF @typeSpName = 3
    BEGIN
        SET @FilePath = 'D:\OneDrive - J.S. Market Solutions SAC\PLANIFICACION\MAESTRAS\fuente_portal_AD\ABONOS\Abonos.xlsx'
    END
    ELSE IF @typeSpName = 4
    BEGIN
        SET @FilePath = 'D:\OneDrive - J.S. Market Solutions SAC\PLANIFICACION\MAESTRAS\fuente_portal_AD\AVANCE_DIARIO\carga_avance_multimarca.xlsx'
    END
    ELSE IF @typeSpName = 5
    BEGIN
        SET @FilePath = 'D:\OneDrive - J.S. Market Solutions SAC\PLANIFICACION\MAESTRAS\fuente_portal_AD\ESQUEMAS\Listado de incentivos.xlsx'
    END
    ELSE IF @typeSpName = 6
    BEGIN
        SET @FilePath = 'D:\OneDrive - J.S. Market Solutions SAC\PLANIFICACION\MAESTRAS\fuente_portal_AD\MESA DE AYUDA\Mesa_de_ayuda.xlsx'
    END
    ELSE
    BEGIN
        RETURN 'Invalid'
    END

    EXEC xp_fileexist @FilePath, @FileExists OUTPUT
    RETURN CASE WHEN @FileExists = 1 THEN 1 ELSE 0 END
END
GO