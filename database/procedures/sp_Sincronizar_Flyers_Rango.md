# Documentacion `sp_Sincronizar_Flyers_Rango`

## Objetivo

Sincronizar asignaciones de campañas en `PORTAL_COMERCIAL.dbo.PDV_OUT_FLYERS` para el periodo `@año/@mes`, asegurando la regla de prioridad de RECUPERO por fechas exactas.

## Reglas de negocio implementadas

1. Si un DNI existe en `PDV_RECUPERO` con las mismas fechas (`fecha_inicio` y `fecha_fin`) de una campaña PDV, ese DNI solo puede recibir incentivos con `criterio_filtro = 'RECUPERO'`.
2. Excepcion: campañas con `modo = 'TODOS'` aplican para todos los DNI, incluyendo DNI en RECUPERO.
3. La validacion de RECUPERO se hace por igualdad exacta de fechas, no por solape.

## Cambios aplicados

### 1) Saneo preventivo al inicio del SP

Se agrego un `DELETE` que elimina filas invalidas existentes en `PDV_OUT_FLYERS` para el periodo ejecutado:

- Borra solo cuando el DNI esta en `PDV_RECUPERO` con fechas exactas del flyer.
- Borra solo campañas de tipo PDV que no sean `RECUPERO`.
- Conserva campañas `modo = 'TODOS'`.

Con esto, si el SP se reejecuta, no persisten asignaciones historicas incorrectas para DNIs de RECUPERO.

### 2) Bloque `modo = 'TODOS'`

Se retiro la exclusion de DNIs en RECUPERO.  
Comportamiento final: `TODOS` se asigna sin excepcion.

### 3) Bloque de incentivos regulares por RANGO

La exclusion de `PDV_RECUPERO` se actualizo a fechas exactas:

- Antes: condicion por solape de fechas.
- Ahora: `c.fecha_inicio = pr.fecha_inicio` y `c.fecha_fin = pr.fecha_fin`.

### 4) Bloque de incentivos `TOP`

La exclusion de `PDV_RECUPERO` tambien se actualizo a fechas exactas:

- Antes: condicion por solape de fechas.
- Ahora: `c.fecha_inicio = pr.fecha_inicio` y `c.fecha_fin = pr.fecha_fin`.

### 5) Bloque de incentivos `RECUPERO`

Se mantiene la logica correcta ya existente:

- Inserta solo para DNIs en `PDV_RECUPERO` con mismas fechas exactas de la campaña.

## Flujo final de ejecucion

1. Determina `@año_real/@mes_real` para fuente de entregables (fallback al ultimo periodo activo anterior si no existe el solicitado).
2. Ejecuta saneo preventivo de asignaciones invalidas para RECUPERO en el periodo solicitado.
3. Inserta campañas `TODOS` para todos los DNI.
4. Inserta campañas PDV por RANGO, excluyendo TOP y RECUPERO por fechas exactas.
5. Inserta campañas PDV `TOP`, excluyendo RECUPERO por fechas exactas.
6. Inserta campañas PDV `RECUPERO` para los DNIs de `PDV_RECUPERO` del mismo rango exacto de fechas.

## Verificacion recomendada post-ejecucion

Validar que no existan filas invalidas en el periodo:

```sql
SELECT f.*
FROM PORTAL_COMERCIAL.dbo.PDV_OUT_FLYERS f
WHERE YEAR(f.fecha_inicio) = @año
  AND MONTH(f.fecha_inicio) = @mes
  AND EXISTS (
      SELECT 1
      FROM PORTAL_COMERCIAL.dbo.PDV_RECUPERO pr
      WHERE pr.DNI_RESPONSABLE = TRY_CAST(f.dni_responsable AS INT)
        AND pr.fecha_inicio = f.fecha_inicio
        AND pr.fecha_fin = f.fecha_fin
  )
  AND EXISTS (
      SELECT 1
      FROM PORTAL_COMERCIAL.dbo.PDV_OUT_CAMPAÑAS_FLYERS c
      WHERE c.foto_esquema = f.foto_esquema
        AND c.fecha_inicio = f.fecha_inicio
        AND c.fecha_fin = f.fecha_fin
        AND c.modo = 'PDV'
        AND UPPER(LTRIM(RTRIM(ISNULL(c.criterio_filtro, '')))) <> 'RECUPERO'
  )
  AND NOT EXISTS (
      SELECT 1
      FROM PORTAL_COMERCIAL.dbo.PDV_OUT_CAMPAÑAS_FLYERS c
      WHERE c.foto_esquema = f.foto_esquema
        AND c.fecha_inicio = f.fecha_inicio
        AND c.fecha_fin = f.fecha_fin
        AND c.modo = 'TODOS'
  );
```

Resultado esperado: cero filas.
