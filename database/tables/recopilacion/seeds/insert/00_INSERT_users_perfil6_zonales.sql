-- =============================================
-- 9 usuarios supervisor zonal (perfil 7 - Recopilacion) vía paCrearUsuario
-- user = zonal en minusculas sin espacios ni puntos; password = mismo texto + *26
-- Perfil 6 = ejecutor (DNI); perfil 7 = vista por zonal (este script)
-- Ejecutar en la base donde están la tabla users y el SP paCrearUsuario (ej. PORTAL_COMERCIAL)
-- =============================================

-- Eliminar los 9 usuarios si existen (para recrearlos con hash correcto)
DELETE FROM dbo.users
WHERE [user] IN (
    'ayacucho', 'cusco', 'hcentro', 'hselva', 'huanuco', 'ica', 'limasur', 'pucallpa', 'puno',
    'admin_form'
);

EXEC paCrearUsuario @user = 'ayacucho',  @password = 'ayacucho*26',  @idPerfil = 7, @zonal = 'AYACUCHO',   @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = 'cusco',     @password = 'cusco*26',     @idPerfil = 7, @zonal = 'CUSCO',      @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = 'hcentro',   @password = 'hcentro*26',   @idPerfil = 7, @zonal = 'H.CENTRO',   @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = 'hselva',    @password = 'hselva*26',    @idPerfil = 7, @zonal = 'H.SELVA',    @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = 'huanuco',   @password = 'huanuco*26',   @idPerfil = 7, @zonal = 'HUANUCO',   @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = 'ica',       @password = 'ica*26',      @idPerfil = 7, @zonal = 'ICA',       @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = 'limasur',   @password = 'limasur*26',   @idPerfil = 7, @zonal = 'LIMA SUR',  @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = 'pucallpa',  @password = 'pucallpa*26',  @idPerfil = 7, @zonal = 'PUCALLPA',  @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = 'puno',      @password = 'puno*26',      @idPerfil = 7, @zonal = 'PUNO',      @created_by = 'SEED_RECOPILACION';

-- Usuario administrador de reporteria (perfil 8)
EXEC paCrearUsuario @user = 'admin_form', @password = 'formulario*26', @idPerfil = 8, @zonal = 'TODAS', @created_by = 'SEED_RECOPILACION';
