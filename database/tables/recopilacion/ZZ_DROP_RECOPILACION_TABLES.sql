-- =============================================
-- Script: ZZ_DROP_RECOPILACION_TABLES.sql
-- Descripción: Elimina por completo las tablas del módulo
--              de recopilación (RC_*) para poder recrearlas
--              desde cero con los scripts 00_..09_.
-- IMPORTANTE:
--   - Solo usar en entornos sin datos de producción.
--   - Verificar que no existan FKs externas adicionales
--     antes de ejecutar.
-- =============================================

PRINT 'Eliminando tablas de recopilación...';

-- Primero tablas hijas (dependientes de visitas / respuestas)
IF OBJECT_ID('dbo.RC_RESPUESTA_MEDIA', 'U') IS NOT NULL
    DROP TABLE dbo.RC_RESPUESTA_MEDIA;

IF OBJECT_ID('dbo.RC_RESPUESTA_OPCION', 'U') IS NOT NULL
    DROP TABLE dbo.RC_RESPUESTA_OPCION;

IF OBJECT_ID('dbo.RC_RESPUESTA', 'U') IS NOT NULL
    DROP TABLE dbo.RC_RESPUESTA;

IF OBJECT_ID('dbo.RC_VISITA_SECCION_ESTADO', 'U') IS NOT NULL
    DROP TABLE dbo.RC_VISITA_SECCION_ESTADO;

IF OBJECT_ID('dbo.RC_VISITA_FORMULARIO', 'U') IS NOT NULL
    DROP TABLE dbo.RC_VISITA_FORMULARIO;

-- Luego catálogo de preguntas / secciones / formularios
IF OBJECT_ID('dbo.RC_PREGUNTA_OPCION', 'U') IS NOT NULL
    DROP TABLE dbo.RC_PREGUNTA_OPCION;

IF OBJECT_ID('dbo.RC_PREGUNTA', 'U') IS NOT NULL
    DROP TABLE dbo.RC_PREGUNTA;

IF OBJECT_ID('dbo.RC_SECCION', 'U') IS NOT NULL
    DROP TABLE dbo.RC_SECCION;

IF OBJECT_ID('dbo.RC_FORMULARIO', 'U') IS NOT NULL
    DROP TABLE dbo.RC_FORMULARIO;

-- Por último, catálogo de clientes/PDV
IF OBJECT_ID('dbo.RC_CLIENTE_PDV', 'U') IS NOT NULL
    DROP TABLE dbo.RC_CLIENTE_PDV;

PRINT 'Tablas de recopilación eliminadas. Ahora puede ejecutar 00_RC_CLIENTE_PDV.sql y siguientes para recrear el esquema.';

