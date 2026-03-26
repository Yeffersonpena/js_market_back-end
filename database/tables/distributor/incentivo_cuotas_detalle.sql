-- Detalle de cuotas por zonal y categoria para cada incentivo
-- Base de datos: DISTRIBUTOR_DATAMART
-- Permite definir metas y bonos por nivel (cuota1/cuota2)

CREATE TABLE [DISTRIBUTOR_DATAMART].[dbo].[incentivo_cuotas_detalle] (
    id INT IDENTITY(1,1) NOT NULL,
    incentivo_id INT NOT NULL,
    zonal VARCHAR(50) COLLATE Modern_Spanish_CI_AS NOT NULL,
    categoria VARCHAR(20) COLLATE Modern_Spanish_CI_AS NOT NULL, -- EQUIPOS, ACCESORIOS, TODAS
    cuota1 DECIMAL(18,2) NOT NULL,
    bono1 DECIMAL(18,2) NOT NULL,
    cuota2 DECIMAL(18,2) NOT NULL,
    bono2 DECIMAL(18,2) NOT NULL,
    activo BIT NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT GETDATE(),
    updated_at DATETIME NULL,
    CONSTRAINT PK_incentivo_cuotas_detalle PRIMARY KEY (id),
    CONSTRAINT FK_incentivo_cuotas_detalle_cabecera FOREIGN KEY (incentivo_id)
        REFERENCES [DISTRIBUTOR_DATAMART].[dbo].[incentivo_cabecera] (id),
    CONSTRAINT UQ_incentivo_cuotas_detalle_unico
        UNIQUE (incentivo_id, zonal, categoria),
    CONSTRAINT CK_incentivo_cuotas_detalle_categoria
        CHECK (categoria IN ('EQUIPOS', 'ACCESORIOS', 'TODAS')),
    CONSTRAINT CK_incentivo_cuotas_detalle_cuotas
        CHECK (cuota1 >= 0 AND cuota2 >= cuota1),
    CONSTRAINT CK_incentivo_cuotas_detalle_bonos
        CHECK (bono1 >= 0 AND bono2 >= bono1)
);

CREATE INDEX IX_incentivo_cuotas_detalle_incentivo
ON [DISTRIBUTOR_DATAMART].[dbo].[incentivo_cuotas_detalle] (incentivo_id, activo);

CREATE INDEX IX_incentivo_cuotas_detalle_zonal_categoria
ON [DISTRIBUTOR_DATAMART].[dbo].[incentivo_cuotas_detalle] (zonal, categoria, activo);

