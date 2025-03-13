CREATE PROCEDURE spCheckFileExists
    @typeSpName INT
AS
BEGIN
    BEGIN TRY
        DECLARE @FilePath VARCHAR(255)
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
            SELECT 'Invalid typeSpName' AS Error
            RETURN
        END

        -- DECLARE @FileExists INT
        -- EXEC xp_fileexist @FilePath, @FileExists OUTPUT
        -- IF @FileExists = 1
        --     SELECT 'True' AS FileExists
        -- ELSE
        --     SELECT 'False' AS FileExists
          DECLARE @FileExists INT
        EXEC xp_fileexist @FilePath, @FileExists OUTPUT

        SELECT CAST(@FileExists AS BIT) AS FileExists
    -- 
    END TRY
    BEGIN CATCH
        RETURN ERROR_MESSAGE();  
    END CATCH
END
