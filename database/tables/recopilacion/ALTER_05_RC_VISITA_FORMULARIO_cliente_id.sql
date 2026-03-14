-- =============================================
-- ALTER: RC_VISITA_FORMULARIO
-- Agrega soporte para puntos desde RC_CLIENTE_PDV.
-- Ejecutar sobre la tabla ya creada.
-- Nota: No usar GO en este proyecto; ejecutar cada bloque por separado si hay error.
-- =============================================

-- BLOQUE 1: Agregar columna cliente_id (ejecutar primero)
ALTER TABLE dbo.RC_VISITA_FORMULARIO
    ADD cliente_id INT NULL;

-- BLOQUE 2: FK a RC_CLIENTE_PDV
ALTER TABLE dbo.RC_VISITA_FORMULARIO
    ADD CONSTRAINT FK_RC_VISITA_FORMULARIO_CLIENTE
    FOREIGN KEY (cliente_id) REFERENCES dbo.RC_CLIENTE_PDV(id);

-- BLOQUE 3: Eliminar constraint UNIQUE anterior
ALTER TABLE dbo.RC_VISITA_FORMULARIO
    DROP CONSTRAINT UQ_RC_VISITA_PROGRAMACION_FORMULARIO_PERIODO;

-- BLOQUE 4: Hacer programacion_id nullable
ALTER TABLE dbo.RC_VISITA_FORMULARIO
    ALTER COLUMN programacion_id INT NULL;

-- BLOQUE 5: Regla: al menos uno de cliente_id o programacion_id debe estar lleno
ALTER TABLE dbo.RC_VISITA_FORMULARIO
    ADD CONSTRAINT CHK_RC_VISITA_CLIENTE_O_PROGRAMACION
    CHECK (programacion_id IS NOT NULL OR cliente_id IS NOT NULL);

-- BLOQUE 6: Indice unico filtrado por programacion_id
CREATE UNIQUE NONCLUSTERED INDEX UQ_RC_VISITA_PROGRAMACION_FORMULARIO_PERIODO
    ON dbo.RC_VISITA_FORMULARIO (programacion_id ASC, formulario_id ASC, anio ASC, mes ASC)
    WHERE programacion_id IS NOT NULL
    WITH (PAD_INDEX = OFF, FILLFACTOR = 100, SORT_IN_TEMPDB = OFF,
          IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF,
          ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
    ON [PRIMARY];

-- BLOQUE 7: Indice unico filtrado por cliente_id
CREATE UNIQUE NONCLUSTERED INDEX UQ_RC_VISITA_CLIENTE_FORMULARIO_PERIODO
    ON dbo.RC_VISITA_FORMULARIO (cliente_id ASC, formulario_id ASC, anio ASC, mes ASC)
    WHERE cliente_id IS NOT NULL
    WITH (PAD_INDEX = OFF, FILLFACTOR = 100, SORT_IN_TEMPDB = OFF,
          IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF,
          ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
    ON [PRIMARY];
