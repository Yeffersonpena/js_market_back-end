-- =============================================
-- Script de Migración: Corrección de Restricción UNIQUE
-- Tabla: PDV_VISITAS_AD_PROGRAMACION
-- Fecha: 2025-01-XX
-- =============================================
-- Problema: La restricción UNIQUE estaba sobre (DNI_RESPONSABLE, AÑO, MES)
--          pero un mismo responsable puede tener múltiples PDVs en el mismo mes.
-- Solución: Cambiar a (COD_CLIENTE, AÑO, MES) que es único por PDV.
-- =============================================

USE [tu_base_de_datos]; -- Cambiar por el nombre de tu base de datos
GO

BEGIN TRANSACTION;

BEGIN TRY
    -- 1. Eliminar la restricción UNIQUE incorrecta
    IF EXISTS (
        SELECT 1
        FROM sys.objects
        WHERE object_id = OBJECT_ID(N'dbo.UQ_PDV_VISITAS_AD_PROG_DNI_AÑO_MES')
        AND type = 'UQ'
    )
    BEGIN
        ALTER TABLE dbo.PDV_VISITAS_AD_PROGRAMACION
        DROP CONSTRAINT UQ_PDV_VISITAS_AD_PROG_DNI_AÑO_MES;

        PRINT 'Restricción UQ_PDV_VISITAS_AD_PROG_DNI_AÑO_MES eliminada correctamente.';
    END
    ELSE
    BEGIN
        PRINT 'La restricción UQ_PDV_VISITAS_AD_PROG_DNI_AÑO_MES no existe.';
    END

    -- 2. Eliminar el índice antiguo si existe (opcional, se recreará después)
    IF EXISTS (
        SELECT 1
        FROM sys.indexes
        WHERE name = 'IX_PDV_VISITAS_AD_PROG_DNI_AÑO_MES'
        AND object_id = OBJECT_ID(N'dbo.PDV_VISITAS_AD_PROGRAMACION')
    )
    BEGIN
        DROP INDEX IX_PDV_VISITAS_AD_PROG_DNI_AÑO_MES
        ON dbo.PDV_VISITAS_AD_PROGRAMACION;

        PRINT 'Índice IX_PDV_VISITAS_AD_PROG_DNI_AÑO_MES eliminado.';
    END

    -- 3. Verificar que no existan duplicados en COD_CLIENTE antes de crear la restricción
    IF EXISTS (
        SELECT COD_CLIENTE, AÑO, MES, COUNT(*) as cantidad
        FROM dbo.PDV_VISITAS_AD_PROGRAMACION
        WHERE COD_CLIENTE IS NOT NULL
        GROUP BY COD_CLIENTE, AÑO, MES
        HAVING COUNT(*) > 1
    )
    BEGIN
        PRINT 'ADVERTENCIA: Existen duplicados en (COD_CLIENTE, AÑO, MES).';
        PRINT 'Por favor, revisar y eliminar duplicados antes de continuar.';

        -- Mostrar duplicados
        SELECT COD_CLIENTE, AÑO, MES, COUNT(*) as cantidad
        FROM dbo.PDV_VISITAS_AD_PROGRAMACION
        WHERE COD_CLIENTE IS NOT NULL
        GROUP BY COD_CLIENTE, AÑO, MES
        HAVING COUNT(*) > 1;

        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- 4. Crear la nueva restricción UNIQUE sobre COD_CLIENTE
    IF NOT EXISTS (
        SELECT 1
        FROM sys.objects
        WHERE object_id = OBJECT_ID(N'dbo.UQ_PDV_VISITAS_AD_PROG_COD_CLIENTE_AÑO_MES')
        AND type = 'UQ'
    )
    BEGIN
        ALTER TABLE dbo.PDV_VISITAS_AD_PROGRAMACION
        ADD CONSTRAINT UQ_PDV_VISITAS_AD_PROG_COD_CLIENTE_AÑO_MES
        UNIQUE (COD_CLIENTE, AÑO, MES);

        PRINT 'Restricción UQ_PDV_VISITAS_AD_PROG_COD_CLIENTE_AÑO_MES creada correctamente.';
    END
    ELSE
    BEGIN
        PRINT 'La restricción UQ_PDV_VISITAS_AD_PROG_COD_CLIENTE_AÑO_MES ya existe.';
    END

    -- 5. Crear el nuevo índice sobre COD_CLIENTE
    IF NOT EXISTS (
        SELECT 1
        FROM sys.indexes
        WHERE name = 'IX_PDV_VISITAS_AD_PROG_COD_CLIENTE_AÑO_MES'
        AND object_id = OBJECT_ID(N'dbo.PDV_VISITAS_AD_PROGRAMACION')
    )
    BEGIN
        CREATE NONCLUSTERED INDEX IX_PDV_VISITAS_AD_PROG_COD_CLIENTE_AÑO_MES
        ON dbo.PDV_VISITAS_AD_PROGRAMACION (COD_CLIENTE ASC, AÑO ASC, MES ASC)
        WITH (PAD_INDEX = OFF, FILLFACTOR = 100, SORT_IN_TEMPDB = OFF,
              IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF,
              ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
        ON [PRIMARY];

        PRINT 'Índice IX_PDV_VISITAS_AD_PROG_COD_CLIENTE_AÑO_MES creado correctamente.';
    END
    ELSE
    BEGIN
        PRINT 'El índice IX_PDV_VISITAS_AD_PROG_COD_CLIENTE_AÑO_MES ya existe.';
    END

    -- 6. Recrear el índice sobre DNI_RESPONSABLE (sin restricción UNIQUE, solo para consultas)
    IF NOT EXISTS (
        SELECT 1
        FROM sys.indexes
        WHERE name = 'IX_PDV_VISITAS_AD_PROG_DNI_AÑO_MES'
        AND object_id = OBJECT_ID(N'dbo.PDV_VISITAS_AD_PROGRAMACION')
    )
    BEGIN
        CREATE NONCLUSTERED INDEX IX_PDV_VISITAS_AD_PROG_DNI_AÑO_MES
        ON dbo.PDV_VISITAS_AD_PROGRAMACION (DNI_RESPONSABLE ASC, AÑO ASC, MES ASC)
        WITH (PAD_INDEX = OFF, FILLFACTOR = 100, SORT_IN_TEMPDB = OFF,
              IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF,
              ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
        ON [PRIMARY];

        PRINT 'Índice IX_PDV_VISITAS_AD_PROG_DNI_AÑO_MES recreado (sin restricción UNIQUE).';
    END

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

