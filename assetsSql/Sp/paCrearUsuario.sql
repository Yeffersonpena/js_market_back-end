USE [BD_PLANIFICACION_OUTLET_AD]
GO
/****** Object:  StoredProcedure [dbo].[paCrearUsuario]    Script Date: 27/02/2025 17:42:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[paCrearUsuario]
    @user VARCHAR(255),
    @password VARCHAR(255),
    @idPerfil INT,
    @zonal VARCHAR(100),
    @created_by VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @salt VARCHAR(200);
    DECLARE @hashedPassword VARBINARY(64);
    
    -- Generar un salt aleatorio
    SET @salt = CONVERT(VARCHAR(64), NEWID());
    
    -- Concatenar la contraseña con el salt y generar el hash
    SET @hashedPassword = HASHBYTES('SHA2_512', @password + @salt);
    
    -- Insertar el usuario en la tabla
    INSERT INTO users (idPerfil, [user], password, zonal, created_by, created_at, salt)
    VALUES (@idPerfil, @user, @hashedPassword, @zonal, @created_by, GETDATE(), @salt);
END;
