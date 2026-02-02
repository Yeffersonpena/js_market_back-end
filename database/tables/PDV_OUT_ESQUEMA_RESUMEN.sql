-- Tabla de resumen final (denormalizada para consulta rápida)
-- Se actualiza después de calcular métricas y bonos
CREATE TABLE dbo.PDV_OUT_ESQUEMA_RESUMEN (
    DNI_RESPONSABLE INT NOT NULL,
    AÑO INT NOT NULL,
    MES INT NOT NULL,

    -- Datos básicos (de entregable)
    NOMBRE_RESPONSABLE NVARCHAR(255),
    ZONAL NVARCHAR(100),
    ACCION_1 NVARCHAR(50),
    ACCION_2 NVARCHAR(50),
    RANGO_MES_ANTERIOR INT,

    -- Métricas de ventas
    TOTAL_RECARGAS INT DEFAULT 0,
    TOTAL_VCALIDAD INT DEFAULT 0,
    PRE_PORTA INT DEFAULT 0,
    PORTAPRE INT DEFAULT 0,
    PORTAPOS INT DEFAULT 0,
    DIAS_VENTAS_RESPONSABLE INT DEFAULT 0,
    VENTAS_MES_ANTERIOR INT DEFAULT 0,
    VENTA_AVANCE_PREPAGO INT DEFAULT 0,
    VENTA_PREPAGO_CALIDAD INT DEFAULT 0,

    -- Campos intermedios (para cálculos, no se muestran en consulta final)
    VentaPrepagoLimitada INT DEFAULT 0,
    VentaPrepagoCalidadLimitada INT DEFAULT 0,
    ratio DECIMAL(10,2) DEFAULT 0,
    ratioCalidad DECIMAL(10,2) DEFAULT 0,
    MAX_VENTA INT DEFAULT 0,

    -- Datos de postpago y portabilidades
    cantidadAltaPost INT DEFAULT 0,
    cantidadPortaPostOPost INT DEFAULT 0,
    cantidadPortaPostOPre INT DEFAULT 0,
    cantPrepagoPorta INT DEFAULT 0,

    -- Cálculos de bonos
    bonoChips INT DEFAULT 0,
    BONO_UNITARIO_EQUIPO DECIMAL(10,2) DEFAULT 0,
    bonoDevolucionChips INT DEFAULT 0,
    precioUniCalidadAdi DECIMAL(10,2) DEFAULT 0,
    adicional_post_unitario DECIMAL(10,2) DEFAULT 0,
    bono_prepago_con_adicional DECIMAL(10,2) DEFAULT 0,
    bonoCalidad DECIMAL(10,2) DEFAULT 0,
    bonoRecargaPre DECIMAL(10,2) DEFAULT 0,
    bonoPortaPre DECIMAL(10,2) DEFAULT 0,
    bonoPortaPostOPost DECIMAL(10,2) DEFAULT 0,
    bonoPortaPostOPre DECIMAL(10,2) DEFAULT 0,

    -- Bono de rango
    nivel_rango INT DEFAULT 0,
    rango_actual INT DEFAULT 0,
    tipo_bono NVARCHAR(20) NULL,
    bono_rango DECIMAL(10,2) DEFAULT 0,
    ratio_min_requerido DECIMAL(10,2) DEFAULT 0,

    -- Totales
    bonoTotalEfectivo DECIMAL(10,2) DEFAULT 0,
    bonoTotal DECIMAL(10,2) DEFAULT 0,

    fecha_actualizacion DATETIME DEFAULT GETDATE(),

    PRIMARY KEY (DNI_RESPONSABLE, AÑO, MES),
    INDEX IX_AÑO_MES (AÑO, MES),
    INDEX IX_ZONAL (ZONAL)
);

