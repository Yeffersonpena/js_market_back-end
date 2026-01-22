-- =============================================
-- Stored Procedure: SP_SYNC_PDV_VISITAS_AD_EJECUTADAS
-- Descripción: Sincroniza datos de visitas ejecutadas desde el linked query
--              hacia la tabla PDV_VISITAS_AD_EJECUTADAS
--              Incluye cálculo de campos formulados y doble deduplicación:
--              1. Por CU_ELIMINAR: Elimina duplicados exactos (MODULO+IDPDV+ID_CHECK+MARCACION_FORMULADO)
--              2. Por CU_VALIDAR: Entre registros con mismo CU_VALIDAR, mantiene los con MARCACION_FORMULADO=1
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
                ON CAST(src.IDPDV AS INT) = CAST(prog.COD_CLIENTE AS INT)
            WHERE src.FECHA_INI = @fecha
                AND src.ZONAL COLLATE DATABASE_DEFAULT LIKE '%MOVISTAR%' COLLATE DATABASE_DEFAULT
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
                        -- Validar rangos válidos de coordenadas
                        AND CLIENTE_LATITUD BETWEEN -90 AND 90
                        AND CLIENTE_LONGITUD BETWEEN -180 AND 180
                        AND CHECKIN_LATITUD BETWEEN -90 AND 90
                        AND CHEKIN_LONGITUD BETWEEN -180 AND 180
                    THEN CAST(
                        (6371 * ACOS(
                            -- Asegurar que el argumento de ACOS esté en el rango [-1, 1] para evitar errores de coma flotante
                            CASE
                                WHEN (
                                    COS(RADIANS(90 - CLIENTE_LATITUD)) *
                                    COS(RADIANS(90 - CHECKIN_LATITUD)) +
                                    SIN(RADIANS(90 - CLIENTE_LATITUD)) *
                                    SIN(RADIANS(90 - CHECKIN_LATITUD)) *
                                    COS(RADIANS(CLIENTE_LONGITUD - CHEKIN_LONGITUD))
                                ) > 1.0 THEN 1.0
                                WHEN (
                                    COS(RADIANS(90 - CLIENTE_LATITUD)) *
                                    COS(RADIANS(90 - CHECKIN_LATITUD)) +
                                    SIN(RADIANS(90 - CLIENTE_LATITUD)) *
                                    SIN(RADIANS(90 - CHECKIN_LATITUD)) *
                                    COS(RADIANS(CLIENTE_LONGITUD - CHEKIN_LONGITUD))
                                ) < -1.0 THEN -1.0
                                ELSE (
                                    COS(RADIANS(90 - CLIENTE_LATITUD)) *
                                    COS(RADIANS(90 - CHECKIN_LATITUD)) +
                                    SIN(RADIANS(90 - CLIENTE_LATITUD)) *
                                    SIN(RADIANS(90 - CHECKIN_LATITUD)) *
                                    COS(RADIANS(CLIENTE_LONGITUD - CHEKIN_LONGITUD))
                                )
                            END
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
                    WHEN TIPO_VISITA_PROGRAMACION COLLATE DATABASE_DEFAULT = 'PRESENCIAL' COLLATE DATABASE_DEFAULT THEN
                        CASE
                            WHEN MARCACION_EN_PUNTO_ORIG COLLATE DATABASE_DEFAULT = 'SI' COLLATE DATABASE_DEFAULT THEN 1
                            WHEN DIF_METROS IS NOT NULL AND DIF_METROS <= 50 THEN 1
                            ELSE 0
                        END
                    ELSE 0
                END AS MARCACION_EN_PUNTO_FORMULADO
            FROM DatosConDistancia
        ),
        -- CTE 4: Generar CU_ELIMINAR y CU_VALIDAR para deduplicación
        DatosConCU AS (
            SELECT
                *,
                -- CU_ELIMINAR = MODULO + FECHA_INI (serial Excel) + IDPDV + MARCACION_EN_PUNTO_FORMULADO
                CONCAT(
                    ISNULL(MODULO, ''),
                    ISNULL(CAST(DATEDIFF(DAY, '1899-12-30', CAST(FECHA_INI AS DATE)) AS VARCHAR), ''),
                    ISNULL(IDPDV, ''),
                    CASE WHEN MARCACION_EN_PUNTO_FORMULADO = 1 THEN 'SI' ELSE 'NO' END
                ) AS CU_ELIMINAR,
                -- CU_VALIDAR = MODULO + FECHA_INI (serial Excel) + IDPDV (sin MARCACION_EN_PUNTO_FORMULADO)
                CONCAT(
                    ISNULL(MODULO, ''),
                    ISNULL(CAST(DATEDIFF(DAY, '1899-12-30', CAST(FECHA_INI AS DATE)) AS VARCHAR), ''),
                    ISNULL(IDPDV, '')
                ) AS CU_VALIDAR
            FROM DatosConMarcacion
        ),
        -- CTE 5: Primera deduplicación por CU_ELIMINAR (elimina duplicados exactos)
        DatosDeduplicadosPorCU_ELIMINAR AS (
            SELECT
                *,
                ROW_NUMBER() OVER (
                    PARTITION BY CU_ELIMINAR
                    ORDER BY ID_CHECK ASC
                ) AS rn_eliminar
            FROM DatosConCU
        ),
        -- CTE 6: Contar cuántas veces aparece cada CU_VALIDAR (equivalente a tabla dinámica)
        DatosConConteo AS (
            SELECT
                *,
                COUNT(*) OVER (PARTITION BY CU_VALIDAR) AS Q_MARCACION
            FROM DatosDeduplicadosPorCU_ELIMINAR
            WHERE rn_eliminar = 1  -- Solo procesar registros únicos de la primera deduplicación
        ),
        -- CTE 7: Identificar si hay registros con MARCACION_EN_PUNTO_FORMULADO = 1 por CU_VALIDAR
        DatosConCantidadSI AS (
            SELECT
                *,
                -- Contar cuántos registros con MARCACION_EN_PUNTO_FORMULADO = 1 hay por CU_VALIDAR
                SUM(CASE WHEN MARCACION_EN_PUNTO_FORMULADO = 1 THEN 1 ELSE 0 END) OVER (PARTITION BY CU_VALIDAR) AS CantidadSI,
                ROW_NUMBER() OVER (PARTITION BY CU_VALIDAR ORDER BY ID_CHECK ASC) AS rn_orden
            FROM DatosConConteo
        ),
        -- CTE 8: Filtrar registros según lógica del proceso manual
        -- Si Q_MARCACION = 1, mantener el registro (no importa SI o NO)
        -- Si Q_MARCACION > 1 y hay registros con MARCACION_EN_PUNTO_FORMULADO = 1, mantener solo esos
        -- Si Q_MARCACION > 1 y todos tienen MARCACION_EN_PUNTO_FORMULADO = 0, mantener el primero por ID_CHECK
        DatosFiltradosPorQ_MARCACION AS (
            SELECT
                *
            FROM DatosConCantidadSI
            WHERE
                -- Si Q_MARCACION = 1, mantener el registro
                Q_MARCACION = 1
                -- Si Q_MARCACION > 1 y hay registros con MARCACION_EN_PUNTO_FORMULADO = 1, mantener solo esos
                OR (Q_MARCACION > 1 AND CantidadSI > 0 AND MARCACION_EN_PUNTO_FORMULADO = 1)
                -- Si Q_MARCACION > 1 y todos tienen MARCACION_EN_PUNTO_FORMULADO = 0, mantener el primero por ID_CHECK
                OR (Q_MARCACION > 1 AND CantidadSI = 0 AND rn_orden = 1)
        ),
        -- CTE 8: Si después del filtro aún hay duplicados por CU_VALIDAR, mantener el primero por ID_CHECK
        DatosDeduplicados AS (
            SELECT
                *,
                ROW_NUMBER() OVER (
                    PARTITION BY CU_VALIDAR
                    ORDER BY ID_CHECK ASC
                ) AS rn_validar
            FROM DatosFiltradosPorQ_MARCACION
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
            CASE WHEN VISITA_EFECTIVA COLLATE DATABASE_DEFAULT = 'SI' COLLATE DATABASE_DEFAULT THEN 1 ELSE 0 END AS VISITA_EFECTIVA,
            CASE WHEN MARCACION_EN_PUNTO_ORIG COLLATE DATABASE_DEFAULT = 'SI' COLLATE DATABASE_DEFAULT THEN 1 ELSE 0 END AS MARCACION_EN_PUNTO,
            CASE WHEN EXTRA_RUTA COLLATE DATABASE_DEFAULT = 'SI' COLLATE DATABASE_DEFAULT THEN 1 ELSE 0 END AS EXTRA_RUTA,
            CASE WHEN POSICION_SIMULADA COLLATE DATABASE_DEFAULT = 'SI' COLLATE DATABASE_DEFAULT THEN 1 ELSE 0 END AS POSICION_SIMULADA,
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
        WHERE rn_validar = 1;

        -- Capturar cantidad de registros insertados y duplicados eliminados
        DECLARE @RegistrosInsertados INT = @@ROWCOUNT;

        -- Actualizar programacion_id para registros que no tuvieron match en el LEFT JOIN
        -- Relación: IDPDV (ejecución) = COD_CLIENTE (programación) - comparación como enteros
        UPDATE ejec
        SET ejec.programacion_id = prog.id,
            ejec.TIPO_VISITA_PROGRAMACION = prog.TIPO_VISITA
        FROM dbo.PDV_VISITAS_AD_EJECUTADAS ejec
        INNER JOIN dbo.PDV_VISITAS_AD_PROGRAMACION prog
            ON CAST(ejec.IDPDV AS INT) = CAST(prog.COD_CLIENTE AS INT)
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
                WHEN ejec.TIPO_VISITA_PROGRAMACION COLLATE DATABASE_DEFAULT = 'PRESENCIAL' COLLATE DATABASE_DEFAULT THEN
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

        -- Retornar cantidad de registros insertados
        SELECT @RegistrosInsertados AS RegistrosInsertados;

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
