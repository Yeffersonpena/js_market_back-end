# Eliminación del filtro `estado = 'finalizado'` en recopilación

**Motivo:** En el backend no se actualiza `RC_VISITA_FORMULARIO.estado` a `finalizado` al guardar respuestas; las visitas permanecen en `borrador`. Filtrar por `finalizado` dejaba en cero los reportes y el dashboard de avance zonal.

**Criterio actual:** Los reportes y conteos consideran cualquier visita con el `formulario_id` (y período donde aplique), sin exigir estado `finalizado`. La lista de **puntos pendientes** queda alineada con “sin fila en `RC_VISITA_FORMULARIO`” para el formulario y período (igual criterio en PHP y en el SP).

---

## `app/Http/Controllers/RecopilacionController.php`

| Función | Cambio |
|--------|--------|
| `puntosPendientes` | Se quitó el `OR v.estado <> 'finalizado'`. Criterio: solo `WHERE v.id IS NULL` tras el `LEFT JOIN` a la visita del período. |
| `reporteAvanceZonal` | En el `join` a `RC_VISITA_FORMULARIO` se eliminó `->where('v.estado', 'finalizado')`. Los “ejecutados” cuentan visitas existentes en el período. |
| `reporteOpcionesGrupoSiNo` | Eliminado `->where('v.estado', 'finalizado')` en la consulta a `RC_RESPUESTA` / `RC_VISITA_FORMULARIO`. |
| `reporteOpcionesGrupoEscala5` | Igual que la anterior. |
| `reporteOpcionesGrupoPerfilLocal` | Igual (consulta de conteos por opción). |
| `reporteOpcionesGrupoLineasProducto` | Igual. |
| `reporteOpcionesGrupoCriteriosCompetencia` | Igual. |
| `reporteExcelFinalizadas` | Sin cambios directos en el método; el Excel usa datos de los métodos privados siguientes. |
| `getCabeceraVisitasFinalizadas` (privado) | Eliminado `->where('v.estado', 'finalizado')`. |
| `getRespuestasLegiblesPorVisitaPregunta` (privado) | Eliminado `->where('v.estado', 'finalizado')`. |

---

## `database/procedures/recopilacion/sp_Recopilacion_Puntos_Pendientes.sql`

- **Objeto:** procedimiento almacenado `sp_Recopilacion_Puntos_Pendientes`.
- **Cambio:** la condición `(v.id IS NULL OR v.estado <> 'finalizado')` pasó a `v.id IS NULL` únicamente, acorde a `puntosPendientes` en PHP.
- **Orden:** se simplificó a `ORDER BY c.nombre_pdv` (sin columnas de visita cuando no hay fila).

---

## Sin cambios en este paso

- `database/tables/recopilacion/05_RC_VISITA_FORMULARIO.sql`: el `CHECK` que permite los valores `borrador`, `en_progreso`, `finalizado` se mantiene por si en el futuro se implementa el cierre formal de la visita.
