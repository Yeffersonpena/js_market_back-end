USE [BD_PLANIFICACION_OUTLET_AD]
GO
/****** Object:  StoredProcedure [dbo].[sp_LoginUser]    Script Date: 27/02/2025 17:46:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_LoginUser]
    @user VARCHAR(50),
    @password VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    -- Retornar el usuario si la contraseña coincide
    SELECT [user], idPerfil, zonal
    FROM users
    WHERE [user] = @user 
    AND password = HASHBYTES('SHA2_512', @password + salt);
END;