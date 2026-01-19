CREATE PROCEDURE [dbo].[paRegistrarUsuariosMasivo]
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @filasInsertadas INT = 0;
	DECLARE @AñoActual INT;
    DECLARE @MesActual INT;

-- Query 1: Insertar Responsables de PDV (perfil 2)
WITH ResponsablesPDV AS (
    SELECT
    distinct
        CONVERT(VARCHAR(20), e.DNI_RESPONSABLE) AS DniVarchar,
        e.ZONAL,
        2 AS idPerfil
    FROM
        dbo.PDV_OUT_ENTREGABLE e
    WHERE
        -- Regla 1: Nos aseguramos que el DNI no sea nulo
        e.DNI_RESPONSABLE IS NOT NULL
        -- Regla 2: La acción debe ser de tipo PDV para los responsables
        AND e.ACCION_1 LIKE 'PDV%'
        -- Verificamos que el usuario no exista ya en la tabla de destino
        AND NOT EXISTS (
            SELECT 1
            FROM dbo.users u
            WHERE u.[user] = CONVERT(VARCHAR(20), e.DNI_RESPONSABLE)
        )
)
INSERT INTO users ([user], zonal, idPerfil, created_at, created_by, estado)
SELECT
    ResponsablesPDV.DniVarchar,
    ResponsablesPDV.ZONAL,
    ResponsablesPDV.idPerfil,
    GETDATE(),
    'admin',
    1
FROM ResponsablesPDV;



    SET @filasInsertadas = @@ROWCOUNT;

    -- Generar un salt aleatorio para los nuevos usuarios
    UPDATE users
    SET salt = CONVERT(VARCHAR(64), NEWID())
    WHERE salt IS NULL;

    -- Generar la contraseña encriptada usando SHA2_512
    UPDATE users
    SET password = HASHBYTES('SHA2_512', [user] + salt)
    WHERE password IS NULL;

    -- -------------------------------------------------------------------
    -- Insertar vendedores desde la tabla PDV_OUT_FUNNEL
    WITH MaxFecha AS (
    SELECT
        YEAR(MAX(FECHA)) AS MaxAnio,
        MONTH(MAX(FECHA)) AS MaxMes
	    FROM dbo.PDV_OUT_FUNNEL
	),
     newFunnel AS (
        SELECT
            DNI_VENDEDOR AS dni, ZONAL, REGION, SOCIO, DNI_RESPONSABLE, DNI_VENDEDOR, FECHA, ACCION,
            ROW_NUMBER() OVER (PARTITION BY DNI_VENDEDOR ORDER BY FECHA DESC) AS rn
        FROM dbo.PDV_OUT_FUNNEL f
    CROSS JOIN MaxFecha mf
    WHERE YEAR(f.FECHA) = mf.MaxAnio
      AND MONTH(f.FECHA) = mf.MaxMes
      AND f.ACCION LIKE '%pdv%'
      AND f.SOCIO LIKE '%JS MARKET%'
    )
    INSERT INTO users ([user], zonal, idPerfil, created_at, created_by, estado)
    SELECT
        CONVERT(VARCHAR(20), nf.dni),
        nf.ZONAL,
        2 AS perfil,
        GETDATE() AS fecha,
        'admin' AS creado_por,
        1 AS estado
    FROM newFunnel nf
    LEFT JOIN dbo.users u ON u.[user] = CONVERT(VARCHAR(20), nf.dni)
    WHERE nf.rn = 1 AND u.[user] IS NULL;

    SET @filasInsertadas = @filasInsertadas + @@ROWCOUNT;

    -- Generar un salt aleatorio para los nuevos usuarios de funnel
    UPDATE users
    SET salt = CONVERT(VARCHAR(64), NEWID())
    WHERE salt IS NULL;

    -- Generar la contraseña encriptada usando SHA2_512 para los nuevos usuarios de funnel
    UPDATE users
    SET password = HASHBYTES('SHA2_512', [user] + salt)
    WHERE password IS NULL;

    -- -------------------------------------------------------------------
    --ACTUALIZACION DE PERFIL SEGUN ENTREGABLE Y FUNNEL
	delete from PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE where año>YEAR(GETDATE());
    SELECT @AñoActual = MAX(AÑO) FROM PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE;
    SELECT @MesActual = MAX(MES) FROM PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE WHERE AÑO = @AñoActual;

    PRINT 'Año actual: ' + CAST(@AñoActual AS VARCHAR(10));
	PRINT 'Mes actual: ' + CAST(@MesActual AS VARCHAR(10));

    -- Actualizar a perfil 2 (PDV) para usuarios con DNI_RESPONSABLE
    UPDATE u
    SET idPerfil = 2,
        estado = 1,
        updated_at = GETDATE(),
        updated_by = 'admin'
    FROM PORTAL_COMERCIAL.dbo.users u
    INNER JOIN PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE e
        ON u.[user] = CAST(e.DNI_RESPONSABLE AS VARCHAR(255))
    WHERE e.ACCION_1 IN ('PDV REGULAR', 'PDV PREMIUM')
        AND e.AÑO = @AñoActual
        AND e.MES = @MesActual;

    PRINT 'Registros actualizados en entregable DNI_RESPONSABLE: ' + CAST(@@ROWCOUNT AS VARCHAR(10));
        -- Actualizar a perfil 2 (PDV) para usuarios con DNI_VENDEDOR de funnel
    UPDATE u
    SET idPerfil = 2,
        estado = 1,
        updated_at = GETDATE(),
        updated_by = 'admin'
    FROM PORTAL_COMERCIAL.dbo.users u
    INNER JOIN PORTAL_COMERCIAL.dbo.PDV_OUT_FUNNEL f
        ON u.[user] = CAST(f.DNI_VENDEDOR AS VARCHAR(255))
    WHERE (f.ACCION LIKE '%PDV%')
        AND f.SOCIO LIKE '%JS MARKET%'
        AND YEAR(f.FECHA) = @AñoActual
        AND MONTH(f.FECHA) = @MesActual;

    PRINT 'Registros actualizados en funnel DNI_VENDEDOR: ' + CAST(@@ROWCOUNT AS VARCHAR(10));
    -- Devolver el número de filas afectadas
    SELECT @filasInsertadas AS filas_afectadas;
END;
