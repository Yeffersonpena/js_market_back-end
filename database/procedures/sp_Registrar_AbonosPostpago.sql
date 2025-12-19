-- =============================================
-- Autor: Sistema
-- Fecha de creación: 2025-01-XX
-- Descripción: Calcula y registra abonos de ventas Postpago en la tabla abonos_postpago_log
--              Solo procesa días que no estén ya registrados en la tabla
--              Si se especifica @DiasFiltro, solo procesa esos días específicos (si no están registrados)
-- =============================================
CREATE PROCEDURE PORTAL_COMERCIAL.dbo.sp_Registrar_AbonosPostpago
    @Año INT,
    @Mes INT,
    @DiasFiltro VARCHAR(MAX) = NULL  -- Ejemplo: '4,5,6' o NULL para todos los días
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @RegistrosInsertados INT = 0;

    BEGIN TRANSACTION;

    BEGIN TRY
        -- Calcular y insertar nuevos registros (solo días que no estén ya registrados)
        WITH VentasAgrupadas AS (
            SELECT
                VL.FECHA,
                E.ZONAL,
                E.ACCION_1,
                VL.DNI_RESPONSABLE,
                VL.DNI_VENDEDOR,
                E.NOMBRE_RESPONSABLE,
                SUM(CASE WHEN VL.OPERATION_NAME = 'Alta' THEN 1 ELSE 0 END) AS [Alta],
                SUM(CASE WHEN VL.OPERATION_NAME = 'Portabilidad' THEN 1 ELSE 0 END) AS [Portabilidad],
                SUM(CASE WHEN VL.OPERATION_NAME = 'Alta' THEN 1 ELSE 0 END) +
                SUM(CASE WHEN VL.OPERATION_NAME = 'Portabilidad' THEN 1 ELSE 0 END) AS [Total general]
            FROM
                PORTAL_COMERCIAL.dbo.VentasLog VL
                INNER JOIN PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE E
                    ON CAST(VL.DNI_RESPONSABLE AS INT) = E.DNI_RESPONSABLE
            WHERE
                -- Filtro de producto
                VL.PRODUCT_NAME = 'Postpago'
                -- Filtros de tabla entregable (siempre ACTIVO)
                AND E.AÑO = @Año
                AND E.MES = @Mes
                AND E.ESTADO = 'ACTIVO'
                -- Filtros de fecha en VentasLog
                AND YEAR(VL.FECHA) = @Año
                AND MONTH(VL.FECHA) = @Mes
                -- Filtro opcional de días específicos
                AND (@DiasFiltro IS NULL
                     OR DAY(VL.FECHA) IN (
                         SELECT CAST(LTRIM(RTRIM(value)) AS INT)
                         FROM STRING_SPLIT(@DiasFiltro, ',')
                         WHERE ISNUMERIC(LTRIM(RTRIM(value))) = 1
                     ))
                -- Excluir fechas que ya están registradas en abonos_postpago_log
                AND VL.FECHA NOT IN (
                    SELECT DISTINCT FECHA
                    FROM PORTAL_COMERCIAL.dbo.abonos_postpago_log
                    WHERE YEAR(FECHA) = @Año
                        AND MONTH(FECHA) = @Mes
                )
            GROUP BY
                VL.FECHA,
                E.ZONAL,
                E.ACCION_1,
                VL.DNI_RESPONSABLE,
                VL.DNI_VENDEDOR,
                E.NOMBRE_RESPONSABLE
        ),
        VentasConRecargador AS (
            SELECT
                VA.*,
                R.NUM_RECARGA
            FROM
                VentasAgrupadas VA
                OUTER APPLY (
                    SELECT TOP 1 NUM_RECARGA
                    FROM PORTAL_COMERCIAL.dbo.BASE_RECARGADORES BR
                    WHERE BR.DNI = CAST(VA.DNI_VENDEDOR AS INT)
                    ORDER BY BR.NUM_RECARGA ASC
                ) R
        ),
        VentasConBono AS (
            SELECT
                VCR.*,
                -- BONO: =SI(I15<>"-";SI(L15>3;6;L15*2);0)
                CASE
                    WHEN VCR.NUM_RECARGA IS NOT NULL THEN
                        CASE
                            WHEN VCR.[Total general] > 3 THEN 6
                            ELSE VCR.[Total general] * 2
                        END
                    ELSE 0
                END AS [BONO]
            FROM
                VentasConRecargador VCR
            WHERE
                -- Excluir ventas inusuales: solo procesar CIERRE POST (Alta <= 2)
                -- Alta > 2 → VENTAS INUSUALES (no se procesan)
                -- Alta <= 2 → CIERRE POST (sí se procesan)
                VCR.[Alta] <= 2
        )
        INSERT INTO PORTAL_COMERCIAL.dbo.abonos_postpago_log (
            FECHA,
            ZONAL_JS,
            ACCION_JS,
            CANAL,
            DNI_RESPONSABLE,
            NOMBRE_PDV,
            DNI_VENDEDOR,
            NOMBRE_VVDD,
            RECARGADOR,
            Alta,
            Portabilidad,
            TOTAL,
            BONO,
            ESTADO_ABONO,
            OBS,
            ESTADO_RECARGA,
            FECHA_CARGA
        )
        SELECT
            VCB.FECHA,
            VCB.ZONAL AS [ZONAL_JS],
            VCB.ACCION_1 AS [ACCION_JS],
            -- CANAL: Si DNI_RESPONSABLE == DNI_VENDEDOR entonces "PDV", sino "VVDD PDV"
            CASE
                WHEN VCB.DNI_RESPONSABLE = VCB.DNI_VENDEDOR THEN 'PDV'
                ELSE 'VVDD PDV'
            END AS [CANAL],
            VCB.DNI_RESPONSABLE,
            VCB.NOMBRE_RESPONSABLE AS [NOMBRE_PDV],
            VCB.DNI_VENDEDOR,
            -- NOMBRE VVDD: Si CANAL es "PDV" entonces es el mismo nombre del PDV, sino "-"
            CASE
                WHEN VCB.DNI_RESPONSABLE = VCB.DNI_VENDEDOR THEN VCB.NOMBRE_RESPONSABLE
                ELSE '-'
            END AS [NOMBRE_VVDD],
            -- RECARGADOR: De BASE_RECARGADORES, primer match (como VLOOKUP)
            ISNULL(CAST(VCB.NUM_RECARGA AS VARCHAR), '-') AS [RECARGADOR],
            VCB.[Alta],
            VCB.[Portabilidad],
            VCB.[Total general],
            VCB.[BONO],
            -- ESTADO ABONO: Si BONO = 0 entonces "PENDIENTE", sino "ABONADO"
            CASE
                WHEN VCB.[BONO] = 0 THEN 'PENDIENTE'
                ELSE 'ABONADO'
            END AS [ESTADO_ABONO],
            -- OBS: Si ESTADO ABONO es "ABONADO" entonces "ABONADO", sino "ENVIAR CREACION"
            CASE
                WHEN VCB.[BONO] = 0 THEN 'ENVIAR CREACION'
                ELSE 'ABONADO'
            END AS [OBS],
            0 AS [ESTADO_RECARGA],
            GETDATE() AS [FECHA_CARGA]
        FROM
            VentasConBono VCB;

        -- Capturar el número de registros insertados antes del COMMIT
        SET @RegistrosInsertados = @@ROWCOUNT;

        COMMIT TRANSACTION;

        -- Retornar resumen de registros insertados
        SELECT
            @RegistrosInsertados AS [RegistrosInsertados],
            'Registro completado exitosamente' AS [Mensaje];

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Retornar error
        SELECT
            0 AS [RegistrosInsertados],
            ERROR_MESSAGE() AS [Mensaje];
    END CATCH;

END;
GO

