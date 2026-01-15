-- =============================================
-- Script de Migración: Agregar Columna CODIGO_CUM
-- Tabla: PDV_VISITAS_AD_PROGRAMACION
-- Fecha: 2025-01-XX
-- =============================================
-- Descripción: Agrega la columna CODIGO_CUM que viene en el Excel de programación
--              CODIGO_CUM es un identificador alternativo del PDV
-- =============================================

USE [tu_base_de_datos]; -- Cambiar por el nombre de tu base de datos
GO

BEGIN TRANSACTION;

BEGIN TRY
    -- Verificar si la columna ya existe
    IF NOT EXISTS (
        SELECT 1
        FROM sys.columns
        WHERE object_id = OBJECT_ID(N'dbo.PDV_VISITAS_AD_PROGRAMACION')
        AND name = 'CODIGO_CUM'
    )
    BEGIN
        -- Agregar la columna CODIGO_CUM
        ALTER TABLE dbo.PDV_VISITAS_AD_PROGRAMACION
        ADD CODIGO_CUM VARCHAR(50) COLLATE Modern_Spanish_CI_AS NULL;

        PRINT 'Columna CODIGO_CUM agregada correctamente.';

        -- Opcional: Crear índice si se va a usar frecuentemente para búsquedas
        -- CREATE NONCLUSTERED INDEX IX_PDV_VISITAS_AD_PROG_CODIGO_CUM
        --     ON dbo.PDV_VISITAS_AD_PROGRAMACION (CODIGO_CUM ASC)
        --     WHERE CODIGO_CUM IS NOT NULL;
    END
    ELSE
    BEGIN
        PRINT 'La columna CODIGO_CUM ya existe en la tabla.';

        -- Verificar el tipo de dato y tamaño
        DECLARE @currentType VARCHAR(50);
        DECLARE @currentSize INT;

        SELECT
            @currentType = TYPE_NAME(system_type_id),
            @currentSize = CHARACTER_MAXIMUM_LENGTH
        FROM sys.columns
        WHERE object_id = OBJECT_ID(N'dbo.PDV_VISITAS_AD_PROGRAMACION')
        AND name = 'CODIGO_CUM';

        PRINT 'Tipo actual: ' + @currentType;
        IF @currentSize IS NOT NULL
            PRINT 'Tamaño actual: ' + CAST(@currentSize AS VARCHAR);

        -- Si es necesario, ajustar el tamaño
        IF @currentType != 'varchar' OR (@currentSize IS NOT NULL AND @currentSize < 50)
        BEGIN
            ALTER TABLE dbo.PDV_VISITAS_AD_PROGRAMACION
            ALTER COLUMN CODIGO_CUM VARCHAR(50) COLLATE Modern_Spanish_CI_AS NULL;

            PRINT 'Tipo/tamaño de CODIGO_CUM actualizado a VARCHAR(50).';
        END
    END

    -- Mostrar estructura final
    SELECT
        COLUMN_NAME,
        DATA_TYPE,
        CHARACTER_MAXIMUM_LENGTH,
        IS_NULLABLE
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo'
    AND TABLE_NAME = 'PDV_VISITAS_AD_PROGRAMACION'
    AND COLUMN_NAME = 'CODIGO_CUM';

    COMMIT TRANSACTION;
    PRINT 'Migración completada exitosamente.';

END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'ERROR: La migración falló.';
    PRINT 'Mensaje: ' + ERROR_MESSAGE();
    PRINT 'Número: ' + CAST(ERROR_NUMBER() AS VARCHAR);
    PRINT 'Línea: ' + CAST(ERROR_LINE() AS VARCHAR);
    THROW;
END CATCH;
GO

