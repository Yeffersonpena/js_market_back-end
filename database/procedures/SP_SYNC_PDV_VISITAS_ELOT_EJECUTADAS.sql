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

        -- CTE 1: Datos fuente del linked query
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
                src.IMG_03
            FROM [192.168.3.101,1800\MSSQL_NEW].[DISTRIB_MOVIL2].[dbo].[WOLAP_OPERACIONES_MOVILES_FINAL] src
            WHERE src.FECHA_INI = @fecha
                AND src.ZONAL COLLATE DATABASE_DEFAULT LIKE '%ELOT%' COLLATE DATABASE_DEFAULT
        ),
        -- CTE 2: Calcular DIF_METROS con fórmula Haversine
        DatosConDistancia AS (
            SELECT
                *,
                CASE
                    WHEN CLIENTE_LATITUD IS NOT NULL
                        AND CLIENTE_LONGITUD IS NOT NULL
                        AND CHECKIN_LATITUD IS NOT NULL
                        AND CHEKIN_LONGITUD IS NOT NULL
                        AND CLIENTE_LATITUD BETWEEN -90 AND 90
                        AND CLIENTE_LONGITUD BETWEEN -180 AND 180
                        AND CHECKIN_LATITUD BETWEEN -90 AND 90
                        AND CHEKIN_LONGITUD BETWEEN -180 AND 180
                    THEN CAST(
                        (6371 * ACOS(
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
        -- CTE 3: Calcular MARCACION_EN_PUNTO_FORMULADO (usando TIPO_VISITA del linked query)
        DatosConMarcacion AS (
            SELECT
                *,
                CASE
                    WHEN TIPO_VISITA COLLATE DATABASE_DEFAULT = 'PRESENCIAL' COLLATE DATABASE_DEFAULT THEN
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
                CONCAT(
                    ISNULL(MODULO, ''),
                    ISNULL(CAST(DATEDIFF(DAY, '1899-12-30', CAST(FECHA_INI AS DATE)) AS VARCHAR), ''),
                    ISNULL(IDPDV, ''),
                    CASE WHEN MARCACION_EN_PUNTO_FORMULADO = 1 THEN 'SI' ELSE 'NO' END
                ) AS CU_ELIMINAR,
                CONCAT(
                    ISNULL(MODULO, ''),
                    ISNULL(CAST(DATEDIFF(DAY, '1899-12-30', CAST(FECHA_INI AS DATE)) AS VARCHAR), ''),
                    ISNULL(IDPDV, '')
                ) AS CU_VALIDAR
            FROM DatosConMarcacion
        ),
        -- CTE 5: Primera deduplicación por CU_ELIMINAR
        DatosDeduplicadosPorCU_ELIMINAR AS (
            SELECT
                *,
                ROW_NUMBER() OVER (
                    PARTITION BY CU_ELIMINAR
                    ORDER BY ID_CHECK ASC
                ) AS rn_eliminar
            FROM DatosConCU
        ),
        -- CTE 6: Contar cuántas veces aparece cada CU_VALIDAR
        DatosConConteo AS (
            SELECT
                *,
                COUNT(*) OVER (PARTITION BY CU_VALIDAR) AS Q_MARCACION
            FROM DatosDeduplicadosPorCU_ELIMINAR
            WHERE rn_eliminar = 1
        ),
        -- CTE 7: Identificar si hay registros con MARCACION_EN_PUNTO_FORMULADO = 1 por CU_VALIDAR
        DatosConCantidadSI AS (
            SELECT
                *,
                SUM(CASE WHEN MARCACION_EN_PUNTO_FORMULADO = 1 THEN 1 ELSE 0 END) OVER (PARTITION BY CU_VALIDAR) AS CantidadSI,
                ROW_NUMBER() OVER (PARTITION BY CU_VALIDAR ORDER BY ID_CHECK ASC) AS rn_orden
            FROM DatosConConteo
        ),
        -- CTE 8: Filtrar registros según lógica del proceso manual
        DatosFiltradosPorQ_MARCACION AS (
            SELECT
                *
            FROM DatosConCantidadSI
            WHERE
                Q_MARCACION = 1
                OR (Q_MARCACION > 1 AND CantidadSI > 0 AND MARCACION_EN_PUNTO_FORMULADO = 1)
                OR (Q_MARCACION > 1 AND CantidadSI = 0 AND rn_orden = 1)
        ),
        -- CTE 9: Si después del filtro aún hay duplicados por CU_VALIDAR, mantener el primero
        DatosDeduplicados AS (
            SELECT
                *,
                ROW_NUMBER() OVER (
                    PARTITION BY CU_VALIDAR
                    ORDER BY ID_CHECK ASC
                ) AS rn_validar
            FROM DatosFiltradosPorQ_MARCACION
        )
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
            GETDATE(),
            'SISTEMA'
        FROM DatosDeduplicados
        WHERE rn_validar = 1;

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

