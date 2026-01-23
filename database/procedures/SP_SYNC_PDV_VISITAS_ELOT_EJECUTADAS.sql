-- =============================================
-- Stored Procedure: SP_SYNC_PDV_VISITAS_ELOT_EJECUTADAS
-- Descripción: Sincroniza datos de visitas ejecutadas desde el linked query
--              hacia la tabla PDV_VISITAS_ELOT_EJECUTADAS
-- Parámetros:
--   @fecha DATE: Fecha de las visitas a sincronizar (filtra por FECHA_INI)
-- =============================================
CREATE PROCEDURE ELOT.dbo.SP_SYNC_PDV_VISITAS_ELOT_EJECUTADAS
    @fecha DATE
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Eliminar registros del día para evitar duplicados
        DELETE FROM ELOT.dbo.PDV_VISITAS_ELOT_EJECUTADAS
        WHERE FECHA_INI = @fecha;

        -- Insertar todos los registros del linked query para el día
        INSERT INTO ELOT.dbo.PDV_VISITAS_ELOT_EJECUTADAS (
            ID_CHECK,
            FECHA_INI,
            HORA_INI,
            FECHA_FIN,
            HORA_FIN,
            DURACION,
            OBJETIVO_VISITA,
            IDPDV,
            TIPO_VISITA,
            CLUSTER_PDV,
            CODIGO_ALTERNO,
            NOMBRE_PDV,
            ZONAL,
            RUTA,
            MODULO,
            NOMBRE_VENDEDOR,
            DNI_VENDEDOR,
            VISITA_EFECTIVA,
            MARCACION_EN_PUNTO,
            EXTRA_RUTA,
            POSICION_SIMULADA,
            CLIENTE_LATITUD,
            CLIENTE_LONGITUD,
            CHECKIN_LATITUD,
            CHEKIN_LONGITUD,
            CHECKOUT_LATITUD,
            CHECKOUT_LONGITUD,
            ENCUESTA,
            PREG_01,
            PREG_02,
            PREG_03,
            PREG_04,
            PREG_05,
            PREG_06,
            PREG_07,
            PREG_08,
            PREG_09,
            PREG_10,
            PREG_11,
            PREG_12,
            PREG_13,
            PREG_14,
            PREG_15,
            IMG_01,
            IMG_02,
            IMG_03,
            FECHA_SINCRONIZACION,
            USUARIO_SINCRONIZACION
        )
        SELECT
            ID_CHECK,
            FECHA_INI,
            HORA_INI,
            FECHA_FIN,
            HORA_FIN,
            DURACION,
            OBJETIVO_VISITA,
            IDPDV,
            TIPO_VISITA,
            CLUSTER_PDV,
            CODIGO_ALTERNO,
            NOMBRE_PDV,
            ZONAL,
            RUTA,
            MODULO,
            NOMBRE_VENDEDOR,
            DNI_VENDEDOR,
            CASE WHEN VISITA_EFECTIVA = 'SI' THEN 1 ELSE 0 END AS VISITA_EFECTIVA,
            CASE WHEN MARCACION_EN_PUNTO = 'SI' THEN 1 ELSE 0 END AS MARCACION_EN_PUNTO,
            CASE WHEN EXTRA_RUTA = 'SI' THEN 1 ELSE 0 END AS EXTRA_RUTA,
            CASE WHEN POSICION_SIMULADA = 'SI' THEN 1 ELSE 0 END AS POSICION_SIMULADA,
            CLIENTE_LATITUD,
            CLIENTE_LONGITUD,
            CHECKIN_LATITUD,
            CHEKIN_LONGITUD,
            CHECKOUT_LATITUD,
            CHECKOUT_LONGITUD,
            ENCUESTA,
            PREG_01,
            PREG_02,
            PREG_03,
            PREG_04,
            PREG_05,
            PREG_06,
            PREG_07,
            PREG_08,
            PREG_09,
            PREG_10,
            PREG_11,
            PREG_12,
            PREG_13,
            PREG_14,
            PREG_15,
            IMG_01,
            IMG_02,
            IMG_03,
            GETDATE(),
            'SISTEMA'
        FROM [192.168.3.101,1800\MSSQL_NEW].[DISTRIB_MOVIL2].[dbo].[WOLAP_OPERACIONES_MOVILES_FINAL]
        WHERE FECHA_INI = @fecha
            AND ZONAL LIKE '%ELOT%';

        -- Capturar cantidad de registros insertados
        DECLARE @RegistrosInsertados INT = @@ROWCOUNT;

        -- Actualizar programacion_id relacionando con PDV_VISITAS_ELOT_PROGRAMACION
        -- Primero intentar por CODIGO_ALTERNO = ID_ELOT (si existe en programación)
        UPDATE ejec
        SET ejec.programacion_id = prog.id
        FROM ELOT.dbo.PDV_VISITAS_ELOT_EJECUTADAS ejec
        INNER JOIN ELOT.dbo.PDV_VISITAS_ELOT_PROGRAMACION prog
            ON ejec.CODIGO_ALTERNO = prog.ID_ELOT
        WHERE ejec.FECHA_INI = @fecha
            AND ejec.programacion_id IS NULL
            AND ejec.CODIGO_ALTERNO IS NOT NULL
            AND prog.ID_ELOT IS NOT NULL;

        -- Si no hay match por ID_ELOT, intentar por IDPDV + FECHA (menos preciso)
        UPDATE ejec
        SET ejec.programacion_id = prog.id
        FROM ELOT.dbo.PDV_VISITAS_ELOT_EJECUTADAS ejec
        INNER JOIN ELOT.dbo.PDV_VISITAS_ELOT_PROGRAMACION prog
            ON ejec.IDPDV = CAST(prog.COD_CLIENTE AS CHAR(10))
            AND YEAR(ejec.FECHA_INI) = prog.AÑO
            AND MONTH(ejec.FECHA_INI) = prog.MES
        WHERE ejec.FECHA_INI = @fecha
            AND ejec.programacion_id IS NULL
            AND ejec.IDPDV IS NOT NULL;

        COMMIT TRANSACTION;

        -- Retornar resultado
        SELECT
            @RegistrosInsertados AS RegistrosInsertados,
            'Sincronización completada exitosamente' AS Mensaje;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorNumber INT = ERROR_NUMBER();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        DECLARE @ErrorProcedure NVARCHAR(128) = ERROR_PROCEDURE();
        DECLARE @ErrorLine INT = ERROR_LINE();
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();

        RAISERROR(
            'Error en %s (Línea %d): %s',
            @ErrorSeverity,
            @ErrorState,
            @ErrorProcedure,
            @ErrorLine,
            @ErrorMessage
        );
    END CATCH;
END;
GO

