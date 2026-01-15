-- =============================================
-- Script de Migración: Cambio de Tipo de Columnas de Coordenadas
-- Tabla: PDV_VISITAS_AD_PROGRAMACION
-- Fecha: 2025-01-XX
-- =============================================
-- Problema: Las columnas LATITUD y LONGITUD están definidas como DECIMAL(10,8) y DECIMAL(11,8)
--          pero los datos del Excel tienen más decimales, causando "Numeric value out of range".
-- Solución: Cambiar a VARCHAR(50) para preservar la precisión exacta de los datos.
-- =============================================

USE [tu_base_de_datos]; -- Cambiar por el nombre de tu base de datos
GO

BEGIN TRANSACTION;

BEGIN TRY
    -- 1. Cambiar LATITUD de DECIMAL(10,8) a VARCHAR(50)
    IF EXISTS (
        SELECT 1
        FROM sys.columns
        WHERE object_id = OBJECT_ID(N'dbo.PDV_VISITAS_AD_PROGRAMACION')
        AND name = 'LATITUD'
        AND system_type_id = 106 -- DECIMAL
    )
    BEGIN
        -- Convertir datos existentes a VARCHAR preservando el valor
        ALTER TABLE dbo.PDV_VISITAS_AD_PROGRAMACION
        ALTER COLUMN LATITUD VARCHAR(50) COLLATE Modern_Spanish_CI_AS NULL;

        PRINT 'Columna LATITUD cambiada de DECIMAL a VARCHAR(50) correctamente.';
    END
    ELSE IF EXISTS (
        SELECT 1
        FROM sys.columns
        WHERE object_id = OBJECT_ID(N'dbo.PDV_VISITAS_AD_PROGRAMACION')
        AND name = 'LATITUD'
        AND system_type_id = 167 -- VARCHAR
    )
    BEGIN
        PRINT 'La columna LATITUD ya es VARCHAR. Verificando tamaño...';

        -- Verificar si necesita ampliar el tamaño
        DECLARE @currentSize INT;
        SELECT @currentSize = CHARACTER_MAXIMUM_LENGTH
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = 'dbo'
        AND TABLE_NAME = 'PDV_VISITAS_AD_PROGRAMACION'
        AND COLUMN_NAME = 'LATITUD';

        IF @currentSize < 50
        BEGIN
            ALTER TABLE dbo.PDV_VISITAS_AD_PROGRAMACION
            ALTER COLUMN LATITUD VARCHAR(50) COLLATE Modern_Spanish_CI_AS NULL;

            PRINT 'Tamaño de LATITUD actualizado a VARCHAR(50).';
        END
        ELSE
        BEGIN
            PRINT 'LATITUD ya tiene tamaño suficiente (' + CAST(@currentSize AS VARCHAR) + ').';
        END
    END
    ELSE
    BEGIN
        PRINT 'ADVERTENCIA: La columna LATITUD no existe en la tabla.';
    END

    -- 2. Cambiar LONGITUD de DECIMAL(11,8) a VARCHAR(50)
    IF EXISTS (
        SELECT 1
        FROM sys.columns
        WHERE object_id = OBJECT_ID(N'dbo.PDV_VISITAS_AD_PROGRAMACION')
        AND name = 'LONGITUD'
        AND system_type_id = 106 -- DECIMAL
    )
    BEGIN
        -- Convertir datos existentes a VARCHAR preservando el valor
        ALTER TABLE dbo.PDV_VISITAS_AD_PROGRAMACION
        ALTER COLUMN LONGITUD VARCHAR(50) COLLATE Modern_Spanish_CI_AS NULL;

        PRINT 'Columna LONGITUD cambiada de DECIMAL a VARCHAR(50) correctamente.';
    END
    ELSE IF EXISTS (
        SELECT 1
        FROM sys.columns
        WHERE object_id = OBJECT_ID(N'dbo.PDV_VISITAS_AD_PROGRAMACION')
        AND name = 'LONGITUD'
        AND system_type_id = 167 -- VARCHAR
    )
    BEGIN
        PRINT 'La columna LONGITUD ya es VARCHAR. Verificando tamaño...';

        -- Verificar si necesita ampliar el tamaño
        DECLARE @currentSizeLng INT;
        SELECT @currentSizeLng = CHARACTER_MAXIMUM_LENGTH
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = 'dbo'
        AND TABLE_NAME = 'PDV_VISITAS_AD_PROGRAMACION'
        AND COLUMN_NAME = 'LONGITUD';

        IF @currentSizeLng < 50
        BEGIN
            ALTER TABLE dbo.PDV_VISITAS_AD_PROGRAMACION
            ALTER COLUMN LONGITUD VARCHAR(50) COLLATE Modern_Spanish_CI_AS NULL;

            PRINT 'Tamaño de LONGITUD actualizado a VARCHAR(50).';
        END
        ELSE
        BEGIN
            PRINT 'LONGITUD ya tiene tamaño suficiente (' + CAST(@currentSizeLng AS VARCHAR) + ').';
        END
    END
    ELSE
    BEGIN
        PRINT 'ADVERTENCIA: La columna LONGITUD no existe en la tabla.';
    END

    -- 3. Verificar que la conversión fue exitosa
    SELECT
        COLUMN_NAME,
        DATA_TYPE,
        CHARACTER_MAXIMUM_LENGTH,
        NUMERIC_PRECISION,
        NUMERIC_SCALE
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo'
    AND TABLE_NAME = 'PDV_VISITAS_AD_PROGRAMACION'
    AND COLUMN_NAME IN ('LATITUD', 'LONGITUD');

    COMMIT TRANSACTION;
    PRINT 'Migración de coordenadas completada exitosamente.';
    PRINT 'Las coordenadas ahora se guardan como VARCHAR preservando la precisión exacta.';

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

