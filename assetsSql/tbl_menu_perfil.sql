CREATE TABLE [dbo].[tbl_menu_perfil](
    [idMenuPerfil] INT IDENTITY(1,1) NOT NULL,
    [idMenu] INT NOT NULL,
    [idPerfil] INT NOT NULL,
    PRIMARY KEY ([idMenuPerfil]),
    FOREIGN KEY ([idMenu]) REFERENCES [dbo].[tbl_menu]([idMenu]),
    FOREIGN KEY ([idPerfil]) REFERENCES [dbo].[tbl_perfil]([idPerfil])
);

INSERT INTO BD_PLANIFICACION_OUTLET_AD.dbo.tbl_menu_perfil (idMenu,idPerfil) VALUES
	 (3,1),
	 (2,1),
	 (8,1),
	 (7,3),
	 (5,3),
	 (6,3),
	 (3,2),
	 (5,2),
	 (6,2);

