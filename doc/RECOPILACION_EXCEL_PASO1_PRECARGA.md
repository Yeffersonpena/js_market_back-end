# Recopilacion - Excel finalizadas: precarga de PASO 1

## Objetivo

Hacer que el endpoint `GET /api/v1/recopilacion/reporte/excel/finalizadas` exporte en el Excel las mismas respuestas precargadas que se muestran en frontend para `PASO_1` (`P01` a `P05`), aun cuando esas preguntas no se hayan guardado en `RC_RESPUESTA`.

## Alcance

- Archivo modificado: `app/Http/Controllers/RecopilacionController.php`
- Metodo afectado: `reporteExcelFinalizadas`
- Solo aplica a codigos de pregunta `P01`, `P02`, `P03`, `P04`, `P05`.
- El resto de preguntas se mantiene con la logica actual (respuesta desde `RC_RESPUESTA`).

## Fuente de datos usada para precarga

Se toma la informacion de cabecera de visita (join `RC_VISITA_FORMULARIO` + `RC_CLIENTE_PDV`), especificamente:

- `promedio_equipo`
- `total_s_venta_accesorio`
- `vende_accesorios`
- `zonal`
- `vendedor` (expuesto como `vendedor_ruta`)

## Mapeo aplicado en Excel

- `P01` ("¿Cuánto compra en equipos por mes?"):
  - `S/ {promedio_equipo} /mes`
- `P02` ("¿Cuánto debería comprar en accesorios ZYNC?"):
  - `S/ {promedio_equipo * 0.1} /mes`
- `P03` ("¿Ya compra accesorios a JS Market hoy?"):
  - Si `vende_accesorios = true/1`:
    - `Sí | S/ {total_s_venta_accesorio}` (si hay monto)
    - `Sí` (si no hay monto)
  - Si `vende_accesorios = false/0`:
    - `No`
- `P04` ("¿Qué zona y quién la atiende?"):
  - `Zonal: {zonal}\nVendedor JS: {vendedor}`
- `P05` ("¿Qué llevo para mostrar?"):
  - `Catálogo y fotos` (valor fijo)

## Prioridad de valor

Para `P01` a `P05`, el Excel prioriza esta precarga.
Para el resto de preguntas, usa el valor legible de `RC_RESPUESTA`.

## Nota funcional

Este ajuste alinea el Excel con el frontend de recopilacion, donde `PASO_1` se muestra precargado desde datos del punto y no depende del guardado de respuestas de esa seccion.
