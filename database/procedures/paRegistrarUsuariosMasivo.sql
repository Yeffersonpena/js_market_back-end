CREATE PROCEDURE [dbo].[paRegistrarUsuariosMasivo]
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @filasInsertadas INT = 0;
	DECLARE @AñoActual INT;
    DECLARE @MesActual INT;
    
    -- Insertar nuevos usuarios que no existen en la tabla users
    /*INSERT INTO users ([user], zonal, idPerfil, created_at, created_by)
    SELECT
        datos.dni,
        datos.ZONAL,
        datos.perfil,
        GETDATE() AS fecha,
        'admin' AS creado_por
    FROM (
        SELECT
            CONVERT(VARCHAR(20), 
                CASE
                    WHEN e.DNI_VENDEDOR IS NULL THEN e.DNI_RESPONSABLE
                    ELSE e.DNI_VENDEDOR
                END
            ) AS dni,
            e.ZONAL,
            CASE
                WHEN e.ACCION_1 LIKE 'PDV%' THEN 2
                WHEN e.ACCION_1 LIKE 'MULTIMARCA%' THEN 3
                ELSE NULL
            END AS perfil
        FROM dbo.PDV_OUT_ENTREGABLE e
        WHERE e.DNI_RESPONSABLE IS NOT NULL OR e.DNI_VENDEDOR IS NOT NULL
        GROUP BY
            CASE
                WHEN e.DNI_VENDEDOR IS NULL THEN e.DNI_RESPONSABLE
                ELSE e.DNI_VENDEDOR
            END,
            e.ZONAL,
            CASE
                WHEN e.ACCION_1 LIKE 'PDV%' THEN 2
                WHEN e.ACCION_1 LIKE 'MULTIMARCA%' THEN 3
                ELSE NULL
            END
    ) AS datos
    LEFT JOIN dbo.users u ON u.[user] = datos.dni
    WHERE u.[user] IS NULL;*/

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
INSERT INTO users ([user], zonal, idPerfil, created_at, created_by)
SELECT
    ResponsablesPDV.DniVarchar,
    ResponsablesPDV.ZONAL,
    ResponsablesPDV.idPerfil,
    GETDATE(),
    'admin'
FROM ResponsablesPDV;



-- Query 2: Insertar Vendedores de MULTIMARCA (perfil 3)
WITH VendedoresMultimarca AS (
    SELECT
        distinct
        CONVERT(VARCHAR(20), e.DNI_VENDEDOR) AS DniVarchar,
        e.ZONAL,
        3 AS idPerfil
    FROM
        dbo.PDV_OUT_ENTREGABLE e
    WHERE
        e.DNI_VENDEDOR IS NOT NULL
        AND e.ACCION_1 LIKE 'MULTIMARCA%'
        AND NOT EXISTS (
            SELECT 1
            FROM dbo.users u
            WHERE u.[user] = CONVERT(VARCHAR(20), e.DNI_VENDEDOR)
        )
)
INSERT INTO users ([user], zonal, idPerfil, created_at, created_by)
SELECT
    VendedoresMultimarca.DniVarchar,
    VendedoresMultimarca.ZONAL,
    VendedoresMultimarca.idPerfil,
    GETDATE(),
    'admin'
FROM VendedoresMultimarca;

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
    INSERT INTO users ([user], zonal, idPerfil, created_at, created_by)
    SELECT
        CONVERT(VARCHAR(20), nf.dni), 
        nf.ZONAL,
        CASE
            WHEN nf.ACCION LIKE 'PDV%' THEN 2
            ELSE NULL
        END AS perfil,
        GETDATE() AS fecha, 
        'admin' AS creado_por
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
        updated_at = GETDATE(),
        updated_by = 'admin'
    FROM PORTAL_COMERCIAL.dbo.users u
    INNER JOIN PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE e 
        ON u.[user] = CAST(e.DNI_RESPONSABLE AS VARCHAR(255))
    WHERE e.ACCION_1 IN ('PDV REGULAR', 'PDV PREMIUM')
        AND e.AÑO = @AñoActual
        AND e.MES = @MesActual
        AND u.idPerfil != 2;
    
    PRINT 'Registros actualizados en entregable DNI_RESPONSABLE: ' + CAST(@@ROWCOUNT AS VARCHAR(10));
        -- Actualizar a perfil 2 (PDV) para usuarios con DNI_VENDEDOR de funnel
    UPDATE u
    SET idPerfil = 2,
        updated_at = GETDATE(),
        updated_by = 'admin'
    FROM PORTAL_COMERCIAL.dbo.users u
    INNER JOIN PORTAL_COMERCIAL.dbo.PDV_OUT_FUNNEL f 
        ON u.[user] = CAST(f.DNI_VENDEDOR AS VARCHAR(255))
    WHERE (f.ACCION LIKE '%PDV%')
        AND f.SOCIO LIKE '%JS MARKET%'
        AND YEAR(f.FECHA) = @AñoActual
        AND MONTH(f.FECHA) = @MesActual
        AND u.idPerfil != 2;
    
    PRINT 'Registros actualizados en funnel DNI_VENDEDOR: ' + CAST(@@ROWCOUNT AS VARCHAR(10));
    -- Actualizar a perfil 3 (MULTIMARCA) para usuarios con DNI_VENDEDOR
    UPDATE u
    SET idPerfil = 3,
        updated_at = GETDATE(),
        updated_by = 'admin'
    FROM PORTAL_COMERCIAL.dbo.users u
    INNER JOIN PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE e 
        ON u.[user] = CAST(e.DNI_VENDEDOR AS VARCHAR(255))
    WHERE e.ACCION_1 = 'MULTIMARCA'
        AND e.AÑO = @AñoActual
        AND e.MES = @MesActual
        AND u.idPerfil != 3;
    
    PRINT 'Registros actualizados en entregable DNI_VENDEDOR MULTIMARCA: ' + CAST(@@ROWCOUNT AS VARCHAR(10));
    -- Devolver el número de filas afectadas
    SELECT @filasInsertadas AS filas_afectadas;
END;