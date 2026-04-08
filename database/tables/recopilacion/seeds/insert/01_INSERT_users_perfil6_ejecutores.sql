-- =============================================
-- Usuarios ejecutores (perfil 6 - Recopilacion) vía paCrearUsuario
-- user = dni; password = dni exacto
-- Ejecutar en la base donde están la tabla users y el SP paCrearUsuario
-- =============================================

-- Eliminar los usuarios ejecutores si existen (para recrearlos con hash correcto)
DELETE FROM dbo.users
WHERE [user] IN (
    '42942175', '47066592', '70338898', '76415110', '70416262',
    '46429295', '41926573', '71688856', '70420471', '46284947',
    '46238206', '77088293', '45196555', '43373925', '7643160',
    '61548132', '71831227', '46892328', '48956503', '72215842',
    '001524263', '44280827', '42828113', '46188157', '70498168',
    '21526748', '74208157', '21435215', '73455533', '45139383',
    '42237554', '48304791', '72618955', '71980749', '70405427',
    '40054154', '70495091', '46548930', '72880282', '44234715'
);

EXEC paCrearUsuario @user = '42942175',  @password = '42942175',  @idPerfil = 6, @zonal = 'AREQUIPA',  @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = '47066592',  @password = '47066592',  @idPerfil = 6, @zonal = 'AYACUCHO',  @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = '70338898',  @password = '70338898',  @idPerfil = 6, @zonal = 'AYACUCHO',  @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = '76415110',  @password = '76415110',  @idPerfil = 6, @zonal = 'AYACUCHO',  @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = '70416262',  @password = '70416262',  @idPerfil = 6, @zonal = 'AYACUCHO',  @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = '46429295',  @password = '46429295',  @idPerfil = 6, @zonal = 'CUSCO',     @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = '41926573',  @password = '41926573',  @idPerfil = 6, @zonal = 'CUSCO',     @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = '71688856',  @password = '71688856',  @idPerfil = 6, @zonal = 'CUSCO',     @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = '70420471',  @password = '70420471',  @idPerfil = 6, @zonal = 'CUSCO',     @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = '46284947',  @password = '46284947',  @idPerfil = 6, @zonal = 'CUSCO',     @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = '46238206',  @password = '46238206',  @idPerfil = 6, @zonal = 'CUSCO',     @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = '77088293',  @password = '77088293',  @idPerfil = 6, @zonal = 'CUSCO',     @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = '45196555',  @password = '45196555',  @idPerfil = 6, @zonal = 'CUSCO',     @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = '43373925',  @password = '43373925',  @idPerfil = 6, @zonal = 'H.CENTRO',  @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = '7643160',   @password = '7643160',   @idPerfil = 6, @zonal = 'H.CENTRO',  @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = '61548132',  @password = '61548132',  @idPerfil = 6, @zonal = 'H.CENTRO',  @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = '71831227',  @password = '71831227',  @idPerfil = 6, @zonal = 'H.SELVA',   @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = '46892328',  @password = '46892328',  @idPerfil = 6, @zonal = 'H.SELVA',   @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = '48956503',  @password = '48956503',  @idPerfil = 6, @zonal = 'HUANUCO',   @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = '72215842',  @password = '72215842',  @idPerfil = 6, @zonal = 'HUANUCO',   @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = '1524263', @password = '1524263', @idPerfil = 6, @zonal = 'HUANUCO',   @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = '44280827',  @password = '44280827',  @idPerfil = 6, @zonal = 'HUANUCO',   @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = '42828113',  @password = '42828113',  @idPerfil = 6, @zonal = 'ICA',       @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = '46188157',  @password = '46188157',  @idPerfil = 6, @zonal = 'ICA',       @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = '70498168',  @password = '70498168',  @idPerfil = 6, @zonal = 'ICA',       @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = '21526748',  @password = '21526748',  @idPerfil = 6, @zonal = 'ICA',       @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = '74208157',  @password = '74208157',  @idPerfil = 6, @zonal = 'ICA',       @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = '21435215',  @password = '21435215',  @idPerfil = 6, @zonal = 'ICA',       @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = '73455533',  @password = '73455533',  @idPerfil = 6, @zonal = 'LIMA SUR',  @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = '45139383',  @password = '45139383',  @idPerfil = 6, @zonal = 'LIMA SUR',  @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = '42237554',  @password = '42237554',  @idPerfil = 6, @zonal = 'LIMA SUR',  @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = '48304791',  @password = '48304791',  @idPerfil = 6, @zonal = 'PUCALLPA',  @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = '72618955',  @password = '72618955',  @idPerfil = 6, @zonal = 'PUCALLPA',  @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = '71980749',  @password = '71980749',  @idPerfil = 6, @zonal = 'PUCALLPA',  @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = '70405427',  @password = '70405427',  @idPerfil = 6, @zonal = 'PUNO',      @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = '40054154',  @password = '40054154',  @idPerfil = 6, @zonal = 'PUNO',      @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = '70495091',  @password = '70495091',  @idPerfil = 6, @zonal = 'PUNO',      @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = '46548930',  @password = '46548930',  @idPerfil = 6, @zonal = 'PUNO',      @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = '72880282',  @password = '72880282',  @idPerfil = 6, @zonal = 'PUNO',      @created_by = 'SEED_RECOPILACION';
EXEC paCrearUsuario @user = '44234715',  @password = '44234715',  @idPerfil = 6, @zonal = 'PUNO',      @created_by = 'SEED_RECOPILACION';
