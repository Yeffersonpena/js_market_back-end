-- =============================================
-- Stored Procedure: SP_SYNC_PDV_VISITAS_AD_EJECUTADAS
-- Descripción: Sincroniza datos de visitas ejecutadas desde el linked query
--              hacia la tabla PDV_VISITAS_AD_EJECUTADAS
--              Incluye cálculo de campos formulados y deduplicación
-- Parámetros:
--   @fecha DATE: Fecha de las visitas a sincronizar (filtra por FECHA_INI)
-- =============================================
CREATE PROCEDURE dbo.SP_SYNC_PDV_VISITAS_AD_EJECUTADAS
    @fecha DATE
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Eliminar registros del día para evitar duplicados
        DELETE FROM dbo.PDV_VISITAS_AD_EJECUTADAS
        WHERE FECHA_INI = @fecha;

        -- CTE 1: Datos fuente del linked query con JOIN a programación
        WITH DatosFuente AS (
            SELECT
                src.ID_CHECK,
                src.FECHA_INI,
                src.HORA_INI,
                src.FECHA_FIN,
                src.HORA_FIN,
                src.DURACION,
                src.OBJETIVO_VISITA,
                src.IDPDV,
                src.TIPO_VISITA,
                src.CLUSTER_PDV,
                src.CODIGO_ALTERNO,
                src.NOMBRE_PDV,
                src.ZONAL,
                src.RUTA,
                src.MODULO,
                src.NOMBRE_VENDEDOR,
                src.DNI_VENDEDOR,
                src.VISITA_EFECTIVA,
                src.MARCACION_EN_PUNTO AS MARCACION_EN_PUNTO_ORIG,
                src.EXTRA_RUTA,
                src.POSICION_SIMULADA,
                src.CLIENTE_LATITUD,
                src.CLIENTE_LONGITUD,
                src.CHECKIN_LATITUD,
                src.CHEKIN_LONGITUD,
                src.CHECKOUT_LATITUD,
                src.CHECKOUT_LONGITUD,
                src.ENCUESTA,
                src.PREG_01,
                src.PREG_02,
                src.PREG_03,
                src.PREG_04,
                src.PREG_05,
                src.PREG_06,
                src.PREG_07,
                src.PREG_08,
                src.PREG_09,
                src.PREG_10,
                src.PREG_11,
                src.PREG_12,
                src.PREG_13,
                src.PREG_14,
                src.PREG_15,
                src.IMG_01,
                src.IMG_02,
                src.IMG_03,
                prog.TIPO_VISITA AS TIPO_VISITA_PROGRAMACION,
                prog.id AS programacion_id
            FROM [192.168.3.101,1800\MSSQL_NEW].[DISTRIB_MOVIL2].[dbo].[WOLAP_OPERACIONES_MOVILES_FINAL] src
            LEFT JOIN dbo.PDV_VISITAS_AD_PROGRAMACION prog
                ON src.CODIGO_ALTERNO = prog.CODIGO_CUM
            WHERE src.FECHA_INI = @fecha
                AND src.ZONAL LIKE '%MOVISTAR%'
        ),
        -- CTE 2: Calcular DIF_METROS con fórmula Haversine
        DatosConDistancia AS (
            SELECT
                *,
                -- Fórmula Haversine: distancia en metros
                CASE
                    WHEN CLIENTE_LATITUD IS NOT NULL
                        AND CLIENTE_LONGITUD IS NOT NULL
                        AND CHECKIN_LATITUD IS NOT NULL
                        AND CHEKIN_LONGITUD IS NOT NULL
                    THEN CAST(
                        (6371 * ACOS(
                            COS(RADIANS(90 - CLIENTE_LATITUD)) *
                            COS(RADIANS(90 - CHECKIN_LATITUD)) +
                            SIN(RADIANS(90 - CLIENTE_LATITUD)) *
                            SIN(RADIANS(90 - CHECKIN_LATITUD)) *
                            COS(RADIANS(CLIENTE_LONGITUD - CHEKIN_LONGITUD))
                        )) * 1000 AS DECIMAL(10,2)
                    )
                    ELSE NULL
                END AS DIF_METROS
            FROM DatosFuente
        ),
        -- CTE 3: Calcular MARCACION_EN_PUNTO_FORMULADO
        DatosConMarcacion AS (
            SELECT
                *,
                -- Lógica: Si TIPO_VISITA='PRESENCIAL' AND (MARCACION_ORIG='SI' OR DIF_METROS<=50) THEN 1 ELSE 0
                CASE
                    WHEN TIPO_VISITA_PROGRAMACION = 'PRESENCIAL' THEN
                        CASE
                            WHEN MARCACION_EN_PUNTO_ORIG = 'SI' THEN 1
                            WHEN DIF_METROS IS NOT NULL AND DIF_METROS <= 50 THEN 1
                            ELSE 0
                        END
                    ELSE 0
                END AS MARCACION_EN_PUNTO_FORMULADO
            FROM DatosConDistancia
        ),
        -- CTE 4: Generar CU_ELIMINAR para deduplicación
        DatosConCU AS (
            SELECT
                *,
                -- CU_ELIMINAR = MODULO + IDPDV + ID_CHECK + MARCACION_EN_PUNTO_FORMULADO
                CONCAT(
                    ISNULL(MODULO, ''),
                    ISNULL(IDPDV, ''),
                    ISNULL(CAST(ID_CHECK AS VARCHAR), ''),
                    ISNULL(CAST(MARCACION_EN_PUNTO_FORMULADO AS VARCHAR), '')
                ) AS CU_ELIMINAR
            FROM DatosConMarcacion
        ),
        -- CTE 5: Deduplicar usando ROW_NUMBER
        DatosDeduplicados AS (
            SELECT
                *,
                ROW_NUMBER() OVER (
                    PARTITION BY CU_ELIMINAR
                    ORDER BY ID_CHECK ASC
                ) AS rn
            FROM DatosConCU
        )
        -- Insertar solo registros únicos (rn = 1)
        INSERT INTO dbo.PDV_VISITAS_AD_EJECUTADAS (
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
            programacion_id,
            DIF_METROS,
            MARCACION_EN_PUNTO_FORMULADO,
            TIPO_VISITA_PROGRAMACION,
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
            CASE WHEN MARCACION_EN_PUNTO_ORIG = 'SI' THEN 1 ELSE 0 END AS MARCACION_EN_PUNTO,
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
            programacion_id,
            DIF_METROS,
            MARCACION_EN_PUNTO_FORMULADO,
            TIPO_VISITA_PROGRAMACION,
            GETDATE(),
            'SISTEMA'
        FROM DatosDeduplicados
        WHERE rn = 1;

        -- Capturar cantidad de registros insertados y duplicados eliminados
        DECLARE @RegistrosInsertados INT = @@ROWCOUNT;

        -- Actualizar programacion_id para registros que no tuvieron match en el LEFT JOIN
        -- Primero intentar por CODIGO_ALTERNO = CODIGO_CUM
        UPDATE ejec
        SET ejec.programacion_id = prog.id,
            ejec.TIPO_VISITA_PROGRAMACION = prog.TIPO_VISITA
        FROM dbo.PDV_VISITAS_AD_EJECUTADAS ejec
        INNER JOIN dbo.PDV_VISITAS_AD_PROGRAMACION prog
            ON ejec.CODIGO_ALTERNO = prog.CODIGO_CUM
        WHERE ejec.FECHA_INI = @fecha
            AND ejec.programacion_id IS NULL
            AND ejec.CODIGO_ALTERNO IS NOT NULL
            AND prog.CODIGO_CUM IS NOT NULL;

        -- Si no hay match por CODIGO_CUM, intentar por IDPDV + FECHA (menos preciso)
        UPDATE ejec
        SET ejec.programacion_id = prog.id,
            ejec.TIPO_VISITA_PROGRAMACION = prog.TIPO_VISITA
        FROM dbo.PDV_VISITAS_AD_EJECUTADAS ejec
        INNER JOIN dbo.PDV_VISITAS_AD_PROGRAMACION prog
            ON ejec.IDPDV = CAST(prog.COD_CLIENTE AS CHAR(10))
            AND YEAR(ejec.FECHA_INI) = prog.AÑO
            AND MONTH(ejec.FECHA_INI) = prog.MES
        WHERE ejec.FECHA_INI = @fecha
            AND ejec.programacion_id IS NULL
            AND ejec.IDPDV IS NOT NULL;

        -- Recalcular MARCACION_EN_PUNTO_FORMULADO para registros que ahora tienen TIPO_VISITA_PROGRAMACION
        -- (casos donde no hubo match en el LEFT JOIN inicial pero sí en el UPDATE)
        UPDATE ejec
        SET ejec.MARCACION_EN_PUNTO_FORMULADO =
            CASE
                WHEN ejec.TIPO_VISITA_PROGRAMACION = 'PRESENCIAL' THEN
                    CASE
                        WHEN ejec.MARCACION_EN_PUNTO = 1 THEN 1
                        WHEN ejec.DIF_METROS IS NOT NULL AND ejec.DIF_METROS <= 50 THEN 1
                        ELSE 0
                    END
                ELSE 0
            END
        FROM dbo.PDV_VISITAS_AD_EJECUTADAS ejec
        WHERE ejec.FECHA_INI = @fecha
            AND ejec.TIPO_VISITA_PROGRAMACION IS NOT NULL;

        COMMIT TRANSACTION;

        -- Retornar resultado con estadísticas
        SELECT
            @RegistrosInsertados AS RegistrosInsertados,
            'Sincronización completada exitosamente. Los duplicados fueron eliminados automáticamente.' AS Mensaje;

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
