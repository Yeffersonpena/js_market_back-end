-- =============================================
-- 9 usuarios de prueba (perfil 6 - Recopilacion) vía paCrearUsuario
-- user = zonal en minusculas sin espacios ni puntos; password = mismo texto + *26
-- Ejecutar en la base donde están la tabla users y el SP paCrearUsuario (ej. PORTAL_COMERCIAL)
-- =============================================

-- Eliminar los 9 usuarios si existen (para recrearlos con hash correcto)
DELETE FROM dbo.users
WHERE [user] IN (
    'ayacucho', 'cusco', 'hcentro', 'hselva', 'huanuco', 'ica', 'limasur', 'pucallpa', 'puno'
);

EXEC paCrearUsuario @user = 'ayacucho',  @password = 'ayacucho*26',  @idPerfil = 6, @zonal = 'AYACUCHO',   @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = 'cusco',     @password = 'cusco*26',     @idPerfil = 6, @zonal = 'CUSCO',      @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = 'hcentro',   @password = 'hcentro*26',   @idPerfil = 6, @zonal = 'H.CENTRO',   @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = 'hselva',    @password = 'hselva*26',    @idPerfil = 6, @zonal = 'H.SELVA',    @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = 'huanuco',   @password = 'huanuco*26',   @idPerfil = 6, @zonal = 'HUANUCO',   @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = 'ica',       @password = 'ica*26',      @idPerfil = 6, @zonal = 'ICA',       @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = 'limasur',   @password = 'limasur*26',   @idPerfil = 6, @zonal = 'LIMA SUR',  @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = 'pucallpa',  @password = 'pucallpa*26',  @idPerfil = 6, @zonal = 'PUCALLPA',  @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = 'puno',      @password = 'puno*26',      @idPerfil = 6, @zonal = 'PUNO',      @created_by = 'SEED_RECOPILACION';
