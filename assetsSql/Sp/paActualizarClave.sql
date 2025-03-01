USE [BD_PLANIFICACION_OUTLET_AD]
GO
/****** Object:  StoredProcedure [dbo].[paActualizarClave]    Script Date: 27/02/2025 17:18:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[paActualizarClave]
    @usuario varchar(30),
    @password VARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @salt VARCHAR(64);
    DECLARE @hashedPassword VARBINARY(64);

    -- Generar un salt aleatorio
    SET @salt = CONVERT(VARCHAR(64), NEWID());

    -- Concatenar la contraseña con el salt y generar el hash
    SET @hashedPassword = HASHBYTES('SHA2_512', @password + @salt);

    -- Actualizar la contraseña y el salt del usuario
    UPDATE users
    SET password = @hashedPassword,
        salt = @salt
    WHERE [user] = @usuario;
END;
