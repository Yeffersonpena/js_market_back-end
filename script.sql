--  insert valor perfiles
INSERT INTO [js_BD_PLANIFICACION_OUTLET_AD].[dbo].tbl_perfil
    (idPerfil, perfil)
VALUES
    (1, 'admin'),(2,'pdv'),(3,'multimarca');

-- insert valor user
INSERT INTO js_BD_PLANIFICACION_OUTLET_AD.dbo.users
(id, idPerfil, [user], password, zonal, created_by, created_at, updated_by, updated_at)
VALUES
(1, 1, N'admin', N'$2y$12$8LwFbdSreYzZsxwOLsAtw.31NIDnR54laFcRhJtBno3XJm7taj0NW', N'Perú', NULL, NULL, NULL, NULL),
(2, 2, N'10236231', N'$2y$12$gQvNc5OWI0W.gVss4/GUqO7LzidtGmbvdzF4ii0sPT7MXTbsMfk5e', N'Perú', NULL, NULL, NULL, NULL),
(3, 3, N'10300144', N'$2y$12$duMJd9W58BVMj6enTevYSeGRy23ZgLxjCSct.lKBLs7KhyodaYAla', N'Perú', NULL, NULL, NULL, NULL);