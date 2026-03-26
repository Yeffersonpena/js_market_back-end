-- =============================================
-- Stored Procedure: sp_Incentivo_Cerrar_Ganadores
-- Descripción:
--   Cierra un incentivo y registra ganadores en DISTRIBUTOR_DATAMART.dbo.incentivo_ganadores
--   calculando reparto proporcional por vendedor.
--
-- Reglas:
--   - Usa fechas de incentivo_cabecera (fecha_inicio/fecha_fin).
--   - Usa cuotas de incentivo_cuotas_detalle.
--   - Calcula ventas con la misma lógica base de sp_Ventas_Incentivo (WOLAP + YALI).
--   - bono_asignado se redondea a 1 decimal.
-- =============================================
CREATE OR ALTER PROCEDURE sp_Incentivo_Cerrar_Ganadores
    @incentivo_id INT,
    @categoria VARCHAR(20) = NULL,   -- NULL = todas las categorias del incentivo
    @reprocesar BIT = 0,             -- 1 = borra resultados previos y recalcula
    @cerrar_incentivo BIT = 0        -- 1 = actualiza estado a CERRADO
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @fecha_inicio DATE;
    DECLARE @fecha_fin DATE;
    DECLARE @categoria_norm VARCHAR(20);

    IF @incentivo_id IS NULL OR @incentivo_id <= 0
    BEGIN
        RAISERROR('@incentivo_id es obligatorio y debe ser mayor a 0', 16, 1);
        RETURN;
    END;

    SET @categoria_norm = UPPER(LTRIM(RTRIM(ISNULL(@categoria, ''))));
    IF @categoria_norm = ''
        SET @categoria_norm = NULL;

    IF @categoria_norm IS NOT NULL AND @categoria_norm NOT IN ('EQUIPOS', 'ACCESORIOS', 'TODAS')
    BEGIN
        RAISERROR('La categoria debe ser EQUIPOS, ACCESORIOS, TODAS o NULL', 16, 1);
        RETURN;
    END;

    SELECT
        @fecha_inicio = c.fecha_inicio,
        @fecha_fin = c.fecha_fin
    FROM [DISTRIBUTOR_DATAMART].[dbo].[incentivo_cabecera] c
    WHERE c.id = @incentivo_id
      AND c.activo = 1;

    IF @fecha_inicio IS NULL OR @fecha_fin IS NULL
    BEGIN
        RAISERROR('No existe incentivo activo con el id indicado', 16, 1);
        RETURN;
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM [DISTRIBUTOR_DATAMART].[dbo].[incentivo_cuotas_detalle] d
        WHERE d.incentivo_id = @incentivo_id
          AND d.activo = 1
          AND (@categoria_norm IS NULL OR UPPER(LTRIM(RTRIM(d.categoria))) = @categoria_norm)
    )
    BEGIN
        RAISERROR('No hay cuotas activas para el incentivo/categoria solicitada', 16, 1);
        RETURN;
    END;

    IF EXISTS (
        SELECT 1
        FROM [DISTRIBUTOR_DATAMART].[dbo].[incentivo_ganadores] g
        WHERE g.incentivo_id = @incentivo_id
          AND (@categoria_norm IS NULL OR UPPER(LTRIM(RTRIM(g.categoria))) = @categoria_norm)
    ) AND @reprocesar = 0
    BEGIN
        RAISERROR('Ya existen ganadores registrados para ese incentivo. Use @reprocesar = 1 para recalcular.', 16, 1);
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRAN;

        IF @reprocesar = 1
        BEGIN
            DELETE FROM [DISTRIBUTOR_DATAMART].[dbo].[incentivo_ganadores]
            WHERE incentivo_id = @incentivo_id
              AND (@categoria_norm IS NULL OR UPPER(LTRIM(RTRIM(categoria))) = @categoria_norm);
        END;

        ;WITH CuotasScope AS (
            SELECT
                UPPER(LTRIM(RTRIM(d.zonal))) AS zonal,
                REPLACE(UPPER(LTRIM(RTRIM(d.zonal))), ' ', '') AS zonal_key,
                UPPER(LTRIM(RTRIM(d.categoria))) AS categoria,
                d.cuota1,
                d.bono1,
                d.cuota2,
                d.bono2
            FROM [DISTRIBUTOR_DATAMART].[dbo].[incentivo_cuotas_detalle] d
            WHERE d.incentivo_id = @incentivo_id
              AND d.activo = 1
              AND (@categoria_norm IS NULL OR UPPER(LTRIM(RTRIM(d.categoria))) = @categoria_norm)
        ),
        VentasBase AS (
            SELECT
                REPLACE(UPPER(z.ZONA), ' ', '') AS zonal_key,
                COALESCE(dict.nombre_canonico, vn.nom_norm) AS vendedor,
                UPPER(LTRIM(RTRIM(v.PROD_LINEA))) AS prod_linea,
                CAST(SUM(v.PRECIO_VTA) AS DECIMAL(18,4)) AS venta
            FROM [DISTRIBUTOR_DATAMART].[dbo].[DD_WOLAP_VENTA_ANALISIS_DETALLADO] v
            CROSS APPLY (
                VALUES (
                    CASE
                        WHEN v.COD_VENDEDOR IN (148, 225, 279, 280) THEN 'HUANUCO'
                        WHEN v.COD_VENDEDOR IN (185, 277, 278) THEN 'PUCALLPA'
                        WHEN v.COD_VENDEDOR IN (221, 276) THEN 'HUANCAYO'
                        WHEN v.COD_VENDEDOR IN (198) THEN 'AYACUCHO'
                        WHEN v.COD_VENDEDOR IN (281) THEN 'CUSCO'
                        WHEN LTRIM(RTRIM(v.ALMACEN)) = 'LOG - AREQUIPA' THEN 'AREQUIPA'
                        WHEN LTRIM(RTRIM(v.ALMACEN)) = 'La Merced' THEN 'HUANCAYO'
                        WHEN UPPER(LTRIM(RTRIM(v.ALMACEN))) LIKE '%LIMA SUR%' THEN 'LIMASUR'
                        ELSE UPPER(LTRIM(RTRIM(v.ALMACEN)))
                    END
                )
            ) z(ZONA)
            CROSS APPLY (
                SELECT UPPER(LTRIM(RTRIM(
                    REPLACE(REPLACE(ISNULL(v.NOM_VENDEDOR, N''), CHAR(160), N' '), CHAR(9), N' ')
                ))) AS nom_norm
            ) vn
            LEFT JOIN [DISTRIBUTOR_DATAMART].[dbo].[vendedor_nombre_diccionario] dict
                ON dict.nombre_alias = vn.nom_norm
                AND dict.activo = 1
            WHERE CAST(v.FEC_EMISION AS DATE) >= @fecha_inicio
              AND CAST(v.FEC_EMISION AS DATE) <= @fecha_fin
              AND v.PROD_LINEA != 'CHIPS'
              AND v.cod_cliente <> '00026087'
              AND v.REPARTO NOT LIKE 'CANAL MASIVO%'
              AND v.cdoc_ide NOT IN ('20612606405', '20615283607')
            GROUP BY
                REPLACE(UPPER(z.ZONA), ' ', ''),
                COALESCE(dict.nombre_canonico, vn.nom_norm),
                UPPER(LTRIM(RTRIM(v.PROD_LINEA)))

            UNION ALL

            SELECT
                REPLACE(UPPER(LTRIM(RTRIM(y.x_zonal))), ' ', '') AS zonal_key,
                COALESCE(dict.nombre_canonico, vn.nom_norm) AS vendedor,
                'EQUIPOS' AS prod_linea,
                CAST(SUM(y.X_SALDO) AS DECIMAL(18,4)) AS venta
            FROM [DISTRIBUTOR_DATAMART].[dbo].[YALI_VENTAS] y
            CROSS APPLY (
                SELECT UPPER(LTRIM(RTRIM(
                    REPLACE(REPLACE(ISNULL(y.x_vendedor, N''), CHAR(160), N' '), CHAR(9), N' ')
                ))) AS nom_norm
            ) vn
            LEFT JOIN [DISTRIBUTOR_DATAMART].[dbo].[vendedor_nombre_diccionario] dict
                ON dict.nombre_alias = vn.nom_norm
                AND dict.activo = 1
            WHERE CAST(y.Fecha AS DATE) >= @fecha_inicio
              AND CAST(y.Fecha AS DATE) <= @fecha_fin
            GROUP BY
                REPLACE(UPPER(LTRIM(RTRIM(y.x_zonal))), ' ', ''),
                COALESCE(dict.nombre_canonico, vn.nom_norm)
        ),
        VentasPorVendedor AS (
            SELECT
                c.zonal,
                c.categoria,
                v.vendedor,
                CAST(SUM(v.venta) AS DECIMAL(18,4)) AS venta_monto
            FROM CuotasScope c
            INNER JOIN VentasBase v
                ON v.zonal_key COLLATE Latin1_General_CI_AI = c.zonal_key COLLATE Latin1_General_CI_AI
               AND (
                    c.categoria = 'TODAS'
                    OR (c.categoria = 'EQUIPOS' AND v.prod_linea = 'EQUIPOS')
                    OR (c.categoria = 'ACCESORIOS' AND v.prod_linea = 'ACCESORIOS')
               )
            GROUP BY c.zonal, c.categoria, v.vendedor
        ),
        TotalesZonal AS (
            SELECT
                zonal,
                categoria,
                CAST(SUM(venta_monto) AS DECIMAL(18,4)) AS venta_total_zonal
            FROM VentasPorVendedor
            GROUP BY zonal, categoria
        ),
        BonoZonal AS (
            SELECT
                c.zonal,
                c.categoria,
                t.venta_total_zonal,
                c.cuota1,
                c.cuota2,
                CASE
                    WHEN t.venta_total_zonal >= c.cuota2 THEN 'CUOTA 2'
                    WHEN t.venta_total_zonal >= c.cuota1 THEN 'CUOTA 1'
                    ELSE '-'
                END AS cuota_alcanzada,
                CASE
                    WHEN t.venta_total_zonal >= c.cuota2 THEN c.bono2
                    WHEN t.venta_total_zonal >= c.cuota1 THEN c.bono1
                    ELSE 0
                END AS bono_zonal
            FROM CuotasScope c
            INNER JOIN TotalesZonal t
                ON t.zonal = c.zonal
               AND t.categoria = c.categoria
        ),
        GanadoresBase AS (
            SELECT
                v.zonal,
                v.categoria,
                v.vendedor,
                CAST(v.venta_monto AS DECIMAL(18,4)) AS venta_monto,
                CAST(b.venta_total_zonal AS DECIMAL(18,4)) AS venta_total_zonal,
                b.cuota_alcanzada,
                CAST(b.bono_zonal AS DECIMAL(18,4)) AS bono_zonal,
                CAST((v.venta_monto / NULLIF(b.venta_total_zonal, 0)) * 100.0 AS DECIMAL(18,8)) AS participacion_pct,
                CAST((b.bono_zonal * (v.venta_monto / NULLIF(b.venta_total_zonal, 0))) AS DECIMAL(18,8)) AS bono_exacto,
                CAST(ROUND((b.bono_zonal * (v.venta_monto / NULLIF(b.venta_total_zonal, 0))), 1) AS DECIMAL(18,1)) AS bono_redondeado
            FROM VentasPorVendedor v
            INNER JOIN BonoZonal b
                ON b.zonal = v.zonal
               AND b.categoria = v.categoria
            WHERE b.bono_zonal > 0
              AND b.venta_total_zonal > 0
              AND v.venta_monto > 0
        ),
        Diferencia AS (
            SELECT
                zonal,
                categoria,
                CAST(MAX(bono_zonal) AS DECIMAL(18,1)) AS bono_zonal,
                CAST(SUM(bono_redondeado) AS DECIMAL(18,1)) AS suma_redondeada,
                CAST(ROUND(MAX(bono_zonal) - SUM(bono_redondeado), 1) AS DECIMAL(18,1)) AS diff
            FROM GanadoresBase
            GROUP BY zonal, categoria
        ),
        RankAjuste AS (
            SELECT
                g.*,
                d.diff,
                ROW_NUMBER() OVER (
                    PARTITION BY g.zonal, g.categoria
                    ORDER BY
                        CASE WHEN d.diff >= 0 THEN (g.bono_exacto - g.bono_redondeado) ELSE (g.bono_redondeado - g.bono_exacto) END DESC,
                        g.venta_monto DESC,
                        g.vendedor
                ) AS rn
            FROM GanadoresBase g
            INNER JOIN Diferencia d
                ON d.zonal = g.zonal
               AND d.categoria = g.categoria
        ),
        GanadoresFinal AS (
            SELECT
                zonal,
                categoria,
                vendedor,
                CAST(venta_monto AS DECIMAL(18,2)) AS venta_monto,
                CAST(venta_total_zonal AS DECIMAL(18,2)) AS venta_total_zonal,
                CAST(ROUND(participacion_pct, 4) AS DECIMAL(9,4)) AS participacion_pct,
                cuota_alcanzada,
                CAST(bono_zonal AS DECIMAL(18,2)) AS bono_zonal,
                CAST(ROUND(
                    CASE
                        WHEN rn = 1 THEN bono_redondeado + diff
                        ELSE bono_redondeado
                    END
                , 1) AS DECIMAL(18,2)) AS bono_asignado
            FROM RankAjuste
        )
        INSERT INTO [DISTRIBUTOR_DATAMART].[dbo].[incentivo_ganadores] (
            incentivo_id,
            zonal,
            categoria,
            dni_vendedor,
            vendedor,
            venta_monto,
            venta_total_zonal,
            participacion_pct,
            cuota_alcanzada,
            bono_zonal,
            bono_asignado,
            premio_asignado_texto,
            observacion,
            estado_pago,
            fecha_generacion,
            created_at
        )
        SELECT
            @incentivo_id AS incentivo_id,
            gf.zonal,
            gf.categoria,
            NULL AS dni_vendedor,
            gf.vendedor,
            gf.venta_monto,
            gf.venta_total_zonal,
            gf.participacion_pct,
            gf.cuota_alcanzada,
            gf.bono_zonal,
            gf.bono_asignado,
            NULL AS premio_asignado_texto,
            'CIERRE AUTOMATICO' AS observacion,
            'PENDIENTE' AS estado_pago,
            GETDATE() AS fecha_generacion,
            GETDATE() AS created_at
        FROM GanadoresFinal gf
        WHERE gf.bono_asignado > 0;

        IF @cerrar_incentivo = 1
        BEGIN
            UPDATE [DISTRIBUTOR_DATAMART].[dbo].[incentivo_cabecera]
            SET estado = 'CERRADO',
                updated_at = GETDATE()
            WHERE id = @incentivo_id;
        END;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END CATCH;

    SELECT
        g.zonal,
        g.categoria,
        MAX(g.cuota_alcanzada) AS cuota_alcanzada,
        MAX(g.bono_zonal) AS bono_zonal,
        CAST(SUM(g.bono_asignado) AS DECIMAL(18,2)) AS bono_asignado_total,
        COUNT(*) AS vendedores_registrados
    FROM [DISTRIBUTOR_DATAMART].[dbo].[incentivo_ganadores] g
    WHERE g.incentivo_id = @incentivo_id
      AND (@categoria_norm IS NULL OR UPPER(LTRIM(RTRIM(g.categoria))) = @categoria_norm)
    GROUP BY g.zonal, g.categoria
    ORDER BY g.zonal, g.categoria;
END;
