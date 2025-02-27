USE [BD_PLANIFICACION_OUTLET_AD]
GO
/****** Object:  StoredProcedure [dbo].[paRegistrarUsuariosMasivo]    Script Date: 27/02/2025 09:53:21 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[paRegistrarUsuariosMasivo]
AS
BEGIN
    SET NOCOUNT ON;
	DECLARE @filasInsertadas INT = 0;
    -- Insertar nuevos usuarios que no existen en la tabla users
    INSERT INTO users ([user], zonal, idPerfil, created_at, created_by)
    SELECT DISTINCT datos.dni, datos.ZONAL, datos.perfil, GETDATE(), 'admin' 
    FROM (
        SELECT 
            CASE 
                WHEN e.DNI_VENDEDOR IS NULL THEN e.DNI_RESPONSABLE
                ELSE e.DNI_VENDEDOR
            END AS dni,
            e.ZONAL,
            CASE
            WHEN e.ACCION_1 LIKE 'PDV%' THEN 2
            WHEN e.ACCION_1 LIKE 'MULTIMARCA%' THEN 3
            ELSE NULL
        END AS perfil
        FROM dbo.PDV_OUT_ENTREGABLE e
        WHERE e.DNI_RESPONSABLE IS NOT NULL OR e.DNI_VENDEDOR IS NOT NULL
    ) AS datos
    LEFT JOIN dbo.users u ON u.[user] = cast(datos.dni as varchar)
    WHERE u.[user] IS NULL;

	SET @filasInsertadas = @@ROWCOUNT;
    -- Generar un salt aleatorio para los nuevos usuarios
    UPDATE users 
    SET salt = CONVERT(VARCHAR(64), NEWID()) 
    WHERE salt IS NULL;

    -- Generar la contraseña encriptada usando SHA2_512
    UPDATE users 
    SET password = HASHBYTES('SHA2_512', [user] + salt) 
    WHERE password IS NULL;
	SELECT @filasInsertadas AS filas_afectadas;
END;
