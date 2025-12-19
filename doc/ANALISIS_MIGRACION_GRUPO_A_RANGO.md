# Análisis Completo: Migración de GRUPO a RANGO en Carga de Imágenes

## Resumen Ejecutivo
Este documento identifica **TODOS** los elementos que intervienen en el proceso de carga de imágenes (flyers) en la ruta `/carga-imagenes`, para migrar de filtrado por **GRUPO** a filtrado por **RANGO**.

---

## 1. RUTA Y NAVEGACIÓN

### 1.1 Configuración de Ruta
**Ubicación Backend**: `assetsSql/tbl_menu.sql` (Línea 20)
```sql
('Carga Imágenes', '/carga-imagenes', 'MdTrendingUp', 1, 8, 'ImagenesPage'),
```

**Componente Asociado**: `ImagenesPage`
- **Ruta Frontend**: `/carga-imagenes`
- **Componente React**: `src/pages/ImagenesPage.tsx`

**Estado Actual**: ✅ No requiere cambios (solo configuración de menú)

---

## 2. FLUJO COMPLETO DEL PROCESO

### 2.1 Estructura de Componentes Frontend

```
ImagenesPage
  └── ListadomagenesContainer
      ├── ListadoImagenesView (Lista de campañas existentes)
      └── FormImagenesContainer (Formulario de carga)
          └── FormImagenesView (UI del formulario)
```

### 2.2 Flujo de Datos

```
1. Usuario accede a /carga-imagenes
   ↓
2. Se renderiza ImagenesPage → ListadomagenesContainer
   ↓
3. ListadomagenesContainer carga campañas existentes
   ↓
4. Usuario hace clic en botón "+" para nueva imagen
   ↓
5. Se abre FormImagenesContainer (Drawer)
   ↓
6. Usuario completa formulario (incluye selección de GRUPO)
   ↓
7. FormImagenesContainer envía FormData al backend
   ↓
8. Backend (ImagenController::load) procesa y guarda
   ↓
9. Backend ejecuta sp_Sincronizar_Flyers
   ↓
10. Se crean registros en PDV_OUT_FLYERS según GRUPO
```

---

## 3. ELEMENTOS QUE INTERVIENEN - FRONTEND

### 3.1 `ImagenesPage.tsx`
**Ubicación**: `src/pages/ImagenesPage.tsx`
**Líneas**: 1-13

**Función**: Página principal que renderiza el contenedor
**Estado**: ✅ No requiere cambios

---

### 3.2 `ListadomagenesContainer.tsx`
**Ubicación**: `src/components/imagenes/listado/ListadomagenesContainer.tsx`
**Líneas**: 1-131

**Funciones Clave**:
- **Línea 27**: `ImagenesService.getCampanasFlyers(año, mes)` - Obtiene campañas
- **Línea 117**: Renderiza `FormImagenesContainer` cuando se abre el formulario

**Estado**: ✅ No requiere cambios (solo maneja listado)

---

### 3.3 `ListadoImagenesView.tsx`
**Ubicación**: `src/components/imagenes/listado/ListadoImagenesView.tsx`
**Líneas**: 1-230

**Funciones Clave**:
- **Línea 206-208**: Muestra `criterio_filtro` como Tag (actualmente muestra GRUPO)
  ```tsx
  {item.criterio_filtro && (
    <Tag color="orange">{item.criterio_filtro}</Tag>
  )}
  ```

**Cambios Necesarios**:
- ⚠️ **Línea 206-208**: El Tag mostrará RANGO en lugar de GRUPO (cambio automático si backend devuelve RANGO)

---

### 3.4 `FormImagenesContainer.tsx`
**Ubicación**: `src/components/imagenes/formulario/FormImagenesContainer.tsx`
**Líneas**: 1-353

**Funciones Clave que usan GRUPO**:

#### 3.4.1 Mapeo de valores (Líneas 136-149)
```typescript
const groupValue =
  typeof datos.group === "string"
    ? datos.group === "G1"
      ? 1
      : datos.group === "G2"
      ? 2
      : datos.group === "G3"
      ? 3
      : datos.group === "Pdv Premium" ||
        datos.group === "GRUPO 4" ||
        datos.group === "G4"
      ? 4
      : null
    : datos.group;
```

**Cambios Necesarios**:
- 🔴 **REEMPLAZAR COMPLETAMENTE**: Cambiar mapeo de G1-G4 a RANGO 1-8
- Nuevo mapeo debería ser:
  ```typescript
  const rangoValue =
    typeof datos.rango === "string"
      ? datos.rango === "RANGO 1" ? 1
      : datos.rango === "RANGO 2" ? 2
      : datos.rango === "RANGO 3" ? 3
      : datos.rango === "RANGO 4" ? 4
      : datos.rango === "RANGO 5" ? 5
      : datos.rango === "RANGO 6" ? 6
      : datos.rango === "RANGO 7" ? 7
      : datos.rango === "RANGO 8" ? 8
      : null
    : datos.rango;
  ```

#### 3.4.2 Envío al backend (Líneas 244-251)
```typescript
if (!todosChecked) {
  formData.append("modo", formValues.modo);
  formData.append("group", formValues.group?.toString() || "");
} else {
  formData.append("modo", "");
  formData.append("group", "");
}
```

**Cambios Necesarios**:
- 🔴 **CAMBIAR**: `formData.append("group", ...)` → `formData.append("rango", ...)`
- Actualizar validación y manejo del campo

#### 3.4.3 Estado del formulario (Líneas 30, 71, 87, 191, 197)
```typescript
const [isGroupDisabled, setIsGroupDisabled] = useState(false);
// ... varios usos
form.setFieldsValue({ group: null });
```

**Cambios Necesarios**:
- 🔴 **RENOMBRAR**: `isGroupDisabled` → `isRangoDisabled`
- 🔴 **CAMBIAR**: `group: null` → `rango: null`

---

### 3.5 `FormImagenesView.tsx`
**Ubicación**: `src/components/imagenes/formulario/FormImagenesView.tsx`
**Líneas**: 1-340

**Funciones Clave que usan GRUPO**:

#### 3.5.1 Campo Select de Grupo (Líneas 192-221)
```tsx
<Form.Item
  label="Grupo"
  name="group"
  rules={[...]}
>
  <Select
    placeholder="Seleccione el grupo"
    disabled={isGroupDisabled || isFieldsDisabled}
  >
    <Option value={1}>G1</Option>
    <Option value={2}>G2</Option>
    <Option value={3}>G3</Option>
    <Option value={4}>G4</Option>
  </Select>
</Form.Item>
```

**Cambios Necesarios**:
- 🔴 **REEMPLAZAR COMPLETAMENTE**:
  - Label: "Grupo" → "Rango"
  - name: "group" → "rango"
  - Placeholder: "Seleccione el grupo" → "Seleccione el rango"
  - Options: G1-G4 → RANGO 1 - RANGO 8
  - Values: 1-4 → 1-8
  - Prop: `isGroupDisabled` → `isRangoDisabled`

---

### 3.6 `ImagenesType.ts`
**Ubicación**: `src/types/ImagenesType.ts`
**Líneas**: 1-13

**Definición Actual**:
```typescript
export default interface ImagenesType {
  // ...
  group: "G1" | "G2" | "G3" | "Pdv Premium" | null;
  // ...
}
```

**Cambios Necesarios**:
- 🔴 **CAMBIAR**:
  ```typescript
  rango: "RANGO 1" | "RANGO 2" | "RANGO 3" | "RANGO 4" | "RANGO 5" | "RANGO 6" | "RANGO 7" | "RANGO 8" | null;
  ```

---

### 3.7 `CampanasFlyersType.ts`
**Ubicación**: `src/types/CampanasFlyersType.ts`
**Líneas**: 1-17

**Definición Actual**:
```typescript
export default interface CampanasFlyersType {
  // ...
  criterio_filtro: string | null;  // Actualmente contiene GRUPO
  // ...
}
```

**Estado**: ✅ No requiere cambios (el campo `criterio_filtro` puede contener RANGO)

---

### 3.8 `ImagenesService.ts`
**Ubicación**: `src/services/ImagenesService.ts`
**Líneas**: 1-60

**Funciones**:
- `load(data: FormData)` - Envía FormData con campo `group`

**Estado**: ✅ No requiere cambios (solo envía datos, no valida contenido)

---

## 4. ELEMENTOS QUE INTERVIENEN - BACKEND

### 4.1 `ImagenController.php`
**Ubicación**: `app/Http/Controllers/Admin/ImagenController.php`
**Líneas**: 155-279

#### 4.1.1 Validación (Líneas 172, 187)
```php
'group' => 'nullable|integer|min:0|max:4',
```

**Cambios Necesarios**:
- 🔴 **CAMBIAR**: `'group' => 'nullable|integer|min:0|max:4'`
- 🔴 **A**: `'rango' => 'nullable|integer|min:0|max:8'`

#### 4.1.2 Mapeo de Grupo (Líneas 210-217)
```php
$grupoMapping = [
    1 => "G1",
    2 => "G2",
    3 => "G3",
    4 => "PDV PREMIUM"
];
$grupoNumber = (int) ($request->input('group') ?? 0);
$pictureGroup = $grupoMapping[$grupoNumber] ?? null;
```

**Cambios Necesarios**:
- 🔴 **REEMPLAZAR COMPLETAMENTE**:
  ```php
  $rangoMapping = [
      1 => "RANGO 1",
      2 => "RANGO 2",
      3 => "RANGO 3",
      4 => "RANGO 4",
      5 => "RANGO 5",
      6 => "RANGO 6",
      7 => "RANGO 7",
      8 => "RANGO 8"
  ];
  $rangoNumber = (int) ($request->input('rango') ?? 0);
  $pictureRango = $rangoMapping[$rangoNumber] ?? null;
  ```

#### 4.1.3 Guardado en BD (Línea 251)
```php
$campanaFlyer->criterio_filtro = $pictureGroup;
```

**Cambios Necesarios**:
- 🔴 **CAMBIAR**: `$campanaFlyer->criterio_filtro = $pictureGroup;`
- 🔴 **A**: `$campanaFlyer->criterio_filtro = $pictureRango;`

#### 4.1.4 Generación de nombre de archivo (Línea 226)
```php
$baseName = $pictureName . '_' . $pictureDateStar . '_' . $pictureEnd . '_' . $pictureType . '_' . $pictureModo . '_' . $pictureGroup;
```

**Cambios Necesarios**:
- 🔴 **CAMBIAR**: `$pictureGroup` → `$pictureRango` en la concatenación

---

### 4.2 `sp_Sincronizar_Flyers.sql`
**Ubicación**: `database/procedures/sp_Sincronizar_Flyers.sql`
**Líneas**: 113-118

**Código Actual**:
```sql
-- Validar GRUPO exacto (soporta grupos concatenados como G1,G2,G3)
AND (
    e.GRUPO = c.criterio_filtro
    OR (',' + c.criterio_filtro + ',' LIKE '%,' + e.GRUPO + ',%')
    OR (', ' + c.criterio_filtro + ', ' LIKE '%, ' + e.GRUPO + ', %')
)
```

**Cambios Necesarios**:
- 🔴 **REEMPLAZAR COMPLETAMENTE**:
  ```sql
  -- Validar RANGO exacto (soporta rangos concatenados como RANGO 1,RANGO 2)
  AND (
      e.RANGO = c.criterio_filtro
      OR (',' + c.criterio_filtro + ',' LIKE '%,' + e.RANGO + ',%')
      OR (', ' + c.criterio_filtro + ', ' LIKE '%, ' + e.RANGO + ', %')
  )
  ```

**Nota**: Este cambio afecta la lógica de sincronización de flyers. Actualmente compara `PDV_OUT_ENTREGABLE.GRUPO` con `PDV_OUT_CAMPAÑAS_FLYERS.criterio_filtro`. Debe cambiar a comparar `PDV_OUT_ENTREGABLE.RANGO`.

---

## 5. BASE DE DATOS

### 5.1 Tabla `PDV_OUT_ENTREGABLE`
**Campo**: `RANGO` (varchar(100))
**Estado**: ✅ Ya existe el campo RANGO

**Valores posibles**: "RANGO 1", "RANGO 2", ..., "RANGO 8"

---

### 5.2 Tabla `PDV_OUT_CAMPAÑAS_FLYERS`
**Campo**: `criterio_filtro` (varchar(500))
**Estado**: ✅ No requiere cambios estructurales

**Nota**: Este campo actualmente almacena valores como "G1", "G2", etc. Después de la migración almacenará "RANGO 1", "RANGO 2", etc.

---

### 5.3 Tabla `PDV_OUT_FLYERS`
**Estado**: ✅ No requiere cambios estructurales

**Nota**: Los registros se crearán basándose en RANGO en lugar de GRUPO.

---

## 6. RESUMEN DE CAMBIOS REQUERIDOS

### 6.1 Frontend - Archivos a Modificar

| Archivo | Líneas | Tipo de Cambio | Prioridad |
|---------|--------|-----------------|-----------|
| `FormImagenesContainer.tsx` | 136-149 | Reemplazar mapeo G1-G4 → RANGO 1-8 | 🔴 CRÍTICO |
| `FormImagenesContainer.tsx` | 244-251 | Cambiar `group` → `rango` en FormData | 🔴 CRÍTICO |
| `FormImagenesContainer.tsx` | 30, 71, 87, 191, 197 | Renombrar `isGroupDisabled` → `isRangoDisabled` | 🔴 CRÍTICO |
| `FormImagenesView.tsx` | 192-221 | Reemplazar Select de Grupo por Rango (1-8) | 🔴 CRÍTICO |
| `ImagenesType.ts` | 10 | Cambiar tipo `group` → `rango` con valores RANGO 1-8 | 🔴 CRÍTICO |
| `ListadoImagenesView.tsx` | 206-208 | (Automático) Mostrará RANGO en lugar de GRUPO | 🟡 MENOR |

**Total Frontend**: 5 archivos, ~15 cambios específicos

---

### 6.2 Backend - Archivos a Modificar

| Archivo | Líneas | Tipo de Cambio | Prioridad |
|---------|--------|-----------------|-----------|
| `ImagenController.php` | 172, 187 | Validación: `group` → `rango`, max:4 → max:8 | 🔴 CRÍTICO |
| `ImagenController.php` | 210-217 | Reemplazar mapeo G1-G4 → RANGO 1-8 | 🔴 CRÍTICO |
| `ImagenController.php` | 251 | Cambiar `$pictureGroup` → `$pictureRango` | 🔴 CRÍTICO |
| `ImagenController.php` | 226 | Cambiar variable en nombre de archivo | 🔴 CRÍTICO |
| `sp_Sincronizar_Flyers.sql` | 113-118 | Cambiar comparación GRUPO → RANGO | 🔴 CRÍTICO |

**Total Backend**: 2 archivos, ~5 cambios específicos

---

## 7. CONSIDERACIONES IMPORTANTES

### 7.1 Compatibilidad con Datos Existentes
- ⚠️ **Campañas existentes**: Las campañas creadas con GRUPO seguirán funcionando si `sp_Sincronizar_Flyers` mantiene ambas validaciones temporalmente
- ⚠️ **Migración de datos**: Considerar migrar `criterio_filtro` de "G1" → "RANGO X" si hay correspondencia

### 7.2 Validación de Rangos
- Los rangos son: RANGO 1, RANGO 2, ..., RANGO 8
- El formato debe ser exacto: "RANGO " (con espacio) + número
- El frontend enviará números 1-8, el backend los convierte a "RANGO 1"-"RANGO 8"

### 7.3 Múltiples Rangos
- El sistema actual soporta múltiples grupos concatenados (ej: "G1,G2,G3")
- Debe soportar múltiples rangos (ej: "RANGO 1,RANGO 2,RANGO 3")
- La validación en `sp_Sincronizar_Flyers` ya soporta esto con LIKE

### 7.4 Campo "Todos"
- Cuando `todos = 1`, no se valida grupo/rango
- Este comportamiento se mantiene igual

---

## 8. PLAN DE IMPLEMENTACIÓN SUGERIDO

### Fase 1: Backend
1. Modificar `ImagenController.php`:
   - Cambiar validación de `group` a `rango`
   - Actualizar mapeo a RANGO 1-8
   - Cambiar variables y guardado

2. Modificar `sp_Sincronizar_Flyers.sql`:
   - Cambiar comparación de GRUPO a RANGO
   - Mantener compatibilidad temporal si es necesario

### Fase 2: Frontend
1. Actualizar tipos:
   - `ImagenesType.ts`: Cambiar `group` → `rango`

2. Actualizar formulario:
   - `FormImagenesView.tsx`: Cambiar Select de Grupo a Rango
   - `FormImagenesContainer.tsx`: Actualizar mapeo y envío

3. Actualizar visualización:
   - `ListadoImagenesView.tsx`: (Automático, mostrará RANGO)

### Fase 3: Pruebas
1. Crear nueva campaña con RANGO
2. Verificar que se sincroniza correctamente
3. Verificar que los flyers se asignan a responsables con el RANGO correcto
4. Probar con múltiples rangos
5. Probar con "Todos"

---

## 9. PREGUNTAS PENDIENTES

1. **¿Hay correspondencia entre GRUPO y RANGO?**
   - ¿G1 = RANGO 1? ¿O hay otra lógica?
   - ¿Necesitamos migrar campañas existentes?

2. **¿Los rangos pueden ser múltiples?**
   - ¿Una imagen puede ir a "RANGO 1,RANGO 2"?
   - ¿O solo a un rango a la vez?

3. **¿Mantener compatibilidad temporal?**
   - ¿El sistema debe soportar GRUPO y RANGO simultáneamente durante la transición?

4. **¿Validación de rangos en el frontend?**
   - ¿Debemos obtener la lista de rangos disponibles desde el backend?
   - ¿O son siempre 1-8 fijos?

---

## 10. CONCLUSIÓN

**Total de archivos a modificar**: 7
- Frontend: 5 archivos
- Backend: 2 archivos

**Total de cambios específicos**: ~20

**Impacto**:
- 🔴 **ALTO**: Cambia la lógica de filtrado de flyers
- 🔴 **ALTO**: Requiere actualización coordinada frontend + backend
- 🟡 **MEDIO**: Los datos existentes pueden necesitar migración

**Recomendación**: Implementar en orden Backend → Frontend, con pruebas exhaustivas en cada fase.

