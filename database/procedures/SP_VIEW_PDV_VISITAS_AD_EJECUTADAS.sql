-- =============================================
-- Stored Procedure: SP_VIEW_PDV_VISITAS_AD_EJECUTADAS
-- Descripcion: Visualiza datos de visitas ejecutadas desde el linked query
--              sin insertar ni actualizar tablas.
--              Aplica filtros por fecha y zona, y calcula campos formulados.
-- Parametros:
--   @fecha DATE: Fecha de las visitas a visualizar (filtra por FECHA_INI)
-- =============================================
CREATE PROCEDURE dbo.SP_VIEW_PDV_VISITAS_AD_EJECUTADAS
    @fecha DATE
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- CTE 1: Datos fuente del linked query con JOIN a programacion
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
                COALESCE(prog.MODULO COLLATE DATABASE_DEFAULT, src.MODULO COLLATE DATABASE_DEFAULT) AS MODULO,
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
        -- CTE 2: Calcular DIF_METROS con formula Haversine
        DatosConDistancia AS (
            SELECT
                *,
                -- Formula Haversine: distancia en metros
                CASE
                    WHEN CLIENTE_LATITUD IS NOT NULL
                        AND CLIENTE_LONGITUD IS NOT NULL
                        AND CHECKIN_LATITUD IS NOT NULL
                        AND CHEKIN_LONGITUD IS NOT NULL
                        -- Validar rangos validos de coordenadas
                        AND CLIENTE_LATITUD BETWEEN -90 AND 90
                        AND CLIENTE_LONGITUD BETWEEN -180 AND 180
                        AND CHECKIN_LATITUD BETWEEN -90 AND 90
                        AND CHEKIN_LONGITUD BETWEEN -180 AND 180
                    THEN CAST(
                        (6371 * ACOS(
                            -- Asegurar que el argumento de ACOS este en el rango [-1, 1] para evitar errores de coma flotante
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
                -- Logica: Si TIPO_VISITA='PRESENCIAL' AND (MARCACION_ORIG='SI' OR DIF_METROS<=50) THEN 1 ELSE 0
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
        -- CTE 4: Generar CU_ELIMINAR y CU_VALIDAR (solo visualizacion)
        DatosConCU AS (
            SELECT
                *,
                -- CU_ELIMINAR = MODULO + FECHA_INI (serial Excel) + IDPDV + MARCACION_EN_PUNTO_FORMULADO
                REPLACE(CONCAT(
                    REPLACE(ISNULL(MODULO, ''), ' ', ''),
                    ISNULL(CAST(DATEDIFF(DAY, '1899-12-30', CAST(FECHA_INI AS DATE)) AS VARCHAR), ''),
                    REPLACE(ISNULL(IDPDV, ''), ' ', ''),
                    CASE WHEN MARCACION_EN_PUNTO_FORMULADO = 1 THEN 'SI' ELSE 'NO' END
                ), ' ', '') AS CU_ELIMINAR,
                -- CU_VALIDAR = MODULO + FECHA_INI (serial Excel) + IDPDV (sin MARCACION_EN_PUNTO_FORMULADO)
                REPLACE(CONCAT(
                    REPLACE(ISNULL(MODULO, ''), ' ', ''),
                    ISNULL(CAST(DATEDIFF(DAY, '1899-12-30', CAST(FECHA_INI AS DATE)) AS VARCHAR), ''),
                    REPLACE(ISNULL(IDPDV, ''), ' ', '')
                ), ' ', '') AS CU_VALIDAR
                ,
                -- CU_FRECUENCIA = MODULO + FECHA_INI (serial Excel)
                REPLACE(CONCAT(
                    REPLACE(ISNULL(MODULO, ''), ' ', ''),
                    ISNULL(CAST(DATEDIFF(DAY, '1899-12-30', CAST(FECHA_INI AS DATE)) AS VARCHAR), '')
                ), ' ', '') AS CU_FRECUENCIA
            FROM DatosConMarcacion
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
            CU_ELIMINAR,
            CU_VALIDAR,
            CU_FRECUENCIA
        FROM DatosConCU;

    END TRY
    BEGIN CATCH
        DECLARE @ErrorNumber INT = ERROR_NUMBER();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        DECLARE @ErrorProcedure NVARCHAR(128) = ERROR_PROCEDURE();
        DECLARE @ErrorLine INT = ERROR_LINE();
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();

        RAISERROR(
            'Error en %s (Linea %d): %s',
            @ErrorSeverity,
            @ErrorState,
            @ErrorProcedure,
            @ErrorLine,
            @ErrorMessage
        );
    END CATCH;
END;
