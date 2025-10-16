-- Tabla consolidada para datos de PDV en portal web
-- Optimizada para consultas rápidas y pre-cálculo de bonos
-- Reemplaza la funcionalidad de spCalculoPayment_10 con enfoque masivo

CREATE TABLE PORTAL_COMERCIAL.dbo.PDV_VENTAS_BONOS (
    -- Identificadores principales
    DNI_RESPONSABLE INT NOT NULL,
    NOMBRE_RESPONSABLE VARCHAR(255),
    ZONAL VARCHAR(100),
    TIPO_PDV VARCHAR(50),
    
    -- Período
    AÑO INT NOT NULL,
    MES INT NOT NULL,
    
    -- Ventas y cantidades
    VENTA_AVANCE_PREPAGO INT,           -- Ventas totales del mes (sin límite)
    cantidadRecarga INT,
    cantidadCalidad INT,
    cantidadPortaPre INT,
    cantidadAltaPost INT,
    cantidadPortaPostOPost INT,
    cantidadPortaPostOPre INT,
    
    -- Campos adicionales para cálculos y límites
    cantPrepagoPorta INT,               -- Alias de cantidadPortaPre para compatibilidad
    ratio DECIMAL(10,2),                -- Ratio de recargas (cantidadRecarga / VENTA_AVANCE_PREPAGO * 100)
    ratioCalidad DECIMAL(10,2),         -- Ratio de calidad (cantidadCalidad / VENTA_AVANCE_PREPAGO * 100)
    maxVenta INT,                       -- Límite máximo desde BonoEscala
    VentaPrepagoLimitada INT,           -- VENTA_AVANCE_PREPAGO limitada por maxVenta (para cálculo de bonos)
    
    -- Precios unitarios (valores variables)
    unitarioPrepago DECIMAL(10,2),          -- Precio unitario según BonoEscala
    unitarioRecargas DECIMAL(10,2),         -- Precio unitario por tipo PDV (2.00 o 3.00)
    precioUniCalidadAdi DECIMAL(10,2),     -- Precio unitario calidad adicional
    faltaVenta INT DEFAULT 0,
    
    -- Bonos individuales
    bonoDevolucionChips DECIMAL(10,2),      -- Devolución de chips (VENTA_AVANCE_PREPAGO)
    bonoPre DECIMAL(10,2),                 -- Bono prepago (unitarioPrepago * VentaPrepagoLimitada)
    bonoCalidad DECIMAL(10,2),             -- Bono calidad (cantidadCalidad * precioUniCalidadAdi)
    bonoRecargaPre DECIMAL(10,2),          -- Bono recarga (cantidadRecarga * unitarioRecargas)
    bonoPortaPre DECIMAL(10,2),            -- Bono portabilidad prepago (cantidadPortaPre * precio_fijo)
    bonoAltaPost DECIMAL(10,2),            -- Bono alta postpago (cantidadAltaPost * precio_fijo)
    bonoPortaPostOPost DECIMAL(10,2),      -- Bono portabilidad postpago origen postpago (cantidadPortaPostOPost * precio_fijo)
    bonoPortaPostOPre DECIMAL(10,2),       -- Bono portabilidad postpago origen prepago (cantidadPortaPostOPre * precio_fijo)
    
    -- Totales
    bonoTotalEfectivo DECIMAL(10,2),
    bonoTotal DECIMAL(10,2),
    
    -- Control
    FECHA_CALCULO DATETIME DEFAULT GETDATE(),
    
    -- Clave primaria
    CONSTRAINT PK_PDV_VENTAS_BONOS PRIMARY KEY (DNI_RESPONSABLE, AÑO, MES)
);

-- Índices optimizados para web
CREATE INDEX IX_PDV_VENTAS_BONOS_Zonal_Tipo 
ON PORTAL_COMERCIAL.dbo.PDV_VENTAS_BONOS (ZONAL, TIPO_PDV, AÑO, MES);

CREATE INDEX IX_PDV_VENTAS_BONOS_Periodo 
ON PORTAL_COMERCIAL.dbo.PDV_VENTAS_BONOS (AÑO, MES) 
INCLUDE (DNI_RESPONSABLE, bonoTotal);

CREATE INDEX IX_PDV_VENTAS_BONOS_BonoTotal 
ON PORTAL_COMERCIAL.dbo.PDV_VENTAS_BONOS (bonoTotal DESC, AÑO, MES);

CREATE INDEX IX_PDV_VENTAS_BONOS_TipoPDV 
ON PORTAL_COMERCIAL.dbo.PDV_VENTAS_BONOS (TIPO_PDV, AÑO, MES) 
INCLUDE (DNI_RESPONSABLE, ZONAL, bonoTotal);

-- Comentarios sobre la estructura:
-- 1. VENTA_AVANCE_PREPAGO: Ventas totales del mes (sin límite) - equivale a bonoChips del SP original
-- 2. VentaPrepagoLimitada: Ventas limitadas por BonoEscala (para cálculo de bonos monetarios)
-- 3. bonoDevolucionChips: Devolución física de chips = VENTA_AVANCE_PREPAGO
-- 4. bonoPre: Bono monetario = unitarioPrepago * VentaPrepagoLimitada
-- 5. Solo datos inherentes: No almacena precios fijos (4, 10, 35, 20) que son constantes
-- 6. Enfoque global: No separa responsable/vendedor, siempre muestra totales del equipo

-- Notas de implementación:
-- - Esta tabla será poblada por el SP unificado mensualmente
-- - Reemplaza las consultas individuales de spCalculoPayment_10
-- - Optimizada para el portal web con consultas ultra-rápidas
-- - Mantiene compatibilidad total con la lógica de negocio existente
