-- Registro oficial de ganadores por incentivo
-- Base de datos: DISTRIBUTOR_DATAMART
-- Guarda el resultado consolidado para reporte y gestion de pago

CREATE TABLE [DISTRIBUTOR_DATAMART].[dbo].[incentivo_ganadores] (
    id INT IDENTITY(1,1) NOT NULL,
    incentivo_id INT NOT NULL,
    zonal VARCHAR(50) COLLATE Modern_Spanish_CI_AS NOT NULL,
    categoria VARCHAR(20) COLLATE Modern_Spanish_CI_AS NOT NULL, -- EQUIPOS, ACCESORIOS, TODAS
    dni_vendedor VARCHAR(20) COLLATE Modern_Spanish_CI_AS NULL,
    vendedor VARCHAR(150) COLLATE Modern_Spanish_CI_AS NOT NULL,
    venta_monto DECIMAL(18,2) NOT NULL DEFAULT 0,
    venta_total_zonal DECIMAL(18,2) NOT NULL DEFAULT 0,
    participacion_pct DECIMAL(9,4) NOT NULL DEFAULT 0,            -- 0 a 100
    cuota_alcanzada VARCHAR(20) COLLATE Modern_Spanish_CI_AS NULL, -- CUOTA 1, CUOTA 2, -
    bono_zonal DECIMAL(18,2) NOT NULL DEFAULT 0,
    bono_asignado DECIMAL(18,2) NOT NULL DEFAULT 0,
    premio_asignado_texto VARCHAR(500) COLLATE Modern_Spanish_CI_AS NULL,
    observacion VARCHAR(500) COLLATE Modern_Spanish_CI_AS NULL,
    estado_pago VARCHAR(20) COLLATE Modern_Spanish_CI_AS NOT NULL DEFAULT 'PENDIENTE', -- PENDIENTE, ENVIADO_FINANZAS, PAGADO, OBSERVADO
    fecha_generacion DATETIME NOT NULL DEFAULT GETDATE(),
    fecha_pago DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT GETDATE(),
    updated_at DATETIME NULL,
    CONSTRAINT PK_incentivo_ganadores PRIMARY KEY (id),
    CONSTRAINT FK_incentivo_ganadores_cabecera FOREIGN KEY (incentivo_id)
        REFERENCES [DISTRIBUTOR_DATAMART].[dbo].[incentivo_cabecera] (id),
    CONSTRAINT CK_incentivo_ganadores_categoria
        CHECK (categoria IN ('EQUIPOS', 'ACCESORIOS', 'TODAS')),
    CONSTRAINT CK_incentivo_ganadores_estado_pago
        CHECK (estado_pago IN ('PENDIENTE', 'ENVIADO_FINANZAS', 'PAGADO', 'OBSERVADO')),
    CONSTRAINT CK_incentivo_ganadores_participacion
        CHECK (participacion_pct >= 0 AND participacion_pct <= 100),
    CONSTRAINT CK_incentivo_ganadores_montos
        CHECK (venta_monto >= 0 AND venta_total_zonal >= 0 AND bono_zonal >= 0 AND bono_asignado >= 0),
    CONSTRAINT UQ_incentivo_ganadores_unico
        UNIQUE (incentivo_id, zonal, categoria, vendedor)
);

CREATE INDEX IX_incentivo_ganadores_incentivo
ON [DISTRIBUTOR_DATAMART].[dbo].[incentivo_ganadores] (incentivo_id, zonal, categoria);

CREATE INDEX IX_incentivo_ganadores_estado_pago
ON [DISTRIBUTOR_DATAMART].[dbo].[incentivo_ganadores] (estado_pago, fecha_generacion);

