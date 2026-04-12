-- Corrige error SQL 8152 (truncamiento) si la tabla ya existía con columnas cortas.
-- Ejecutar en DISTRIBUTOR_DATAMART antes de INSERT/UPDATE con nombres largos o origen PROGRAMACION.

ALTER TABLE [DISTRIBUTOR_DATAMART].[dbo].[vendedor_nombre_diccionario] ALTER COLUMN [nombre_alias] VARCHAR(200) NOT NULL;
ALTER TABLE [DISTRIBUTOR_DATAMART].[dbo].[vendedor_nombre_diccionario] ALTER COLUMN [nombre_canonico] VARCHAR(200) NOT NULL;
ALTER TABLE [DISTRIBUTOR_DATAMART].[dbo].[vendedor_nombre_diccionario] ALTER COLUMN [origen] VARCHAR(50) NULL;
