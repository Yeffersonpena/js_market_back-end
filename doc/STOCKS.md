Diferencias que importan para “lo que falta”

1. Identificador de producto (ccod_prod)
   JS: La PQ agrupa por ccod_prod. El SP no devuelve esa columna.
   Amazonía: La PQ agrupa por codigo. El SP no devuelve codigo.
   Propuesta:
   Parte JS: Añadir al SELECT algo como RTRIM(LTRIM(w.CCOD_PROD)) AS CCOD_PROD (o el nombre real del campo en WOLAP si es distinto).
   Parte YALI: Añadir y.Codigo AS CCOD_PROD para que el mismo concepto “código de producto” exista en ambas ramas y puedas agrupar en Excel igual que en las PQ.
2. Fecha usada para los rangos de edad en Amazonía ✅ Aplicado
   PQ Amazonía: usa fechafactura en todos los DATEDIFF(day, fechafactura, GETDATE()).
   SP actual: usa FechaRecibido para DIAS, EDAD y FCOMPRA en YALI.
   Si factura y recepción no son el mismo día, los rangos 0–15, 15–30, etc. no coincidirán entre PQ y SP.
   Propuesta (aplicada):
   En la parte YALI del SP, usar FechaFactura (en lugar de FechaRecibido) para:
   el cálculo de DIAS,
   el CASE de EDAD,
   y FCOMPRA (CAST de FechaFactura a DATE).
   Así la regla de “día 15” y el resto de rangos quedan alineados con la Power Query de Amazonía.
   Documentación y cómo revertir: database/procedures/distributor/sp_Stock_General.md §7.
3. Costo en Amazonía ✅ Aplicado
   PQ Amazonía: AVG(costetotal).
   SP: parte YALI usa COALESCE(y.CosteTotal, y.Precio) para NCOSTO y COSTO. Doc: sp_Stock_General.md §8.
   (Antes: y.Precio como NCOSTO y COSTO.)
   Aunque no uses el SP para precios de venta, si en Excel promedias “costo” para comparar con la PQ de Amazonía, el resultado no coincidirá porque la base es distinta (Precio vs CosteTotal).
   Propuesta:
   En la parte YALI, usar CosteTotal en lugar de Precio para NCOSTO y COSTO (p. ej. y.CosteTotal AS NCOSTO, y.CosteTotal AS COSTO o el mismo campo en ambas si no aplican IVA). Si CosteTotal puede ser NULL, decidir si dejar NULL o usar COALESCE con Precio. Con eso, los promedios por almacén/codigo en Excel se alinean con la PQ.
4. Almacén en Amazonía (nombre) — Aceptado como está
   PQ Amazonía: nombrepv AS ALMACEN (valor crudo, ej. "YALI-LIMA").
   SP: ALMACEN normalizado (quita prefijo "YALI-", UCAYALI→PUCALLPA, etc.).
   No se añade columna; la diferencia es solo el nombre del almacén y es manejo interno del proceso. El SP sigue devolviendo ALMACEN normalizado.
   Resumen de estado
   Tema Estado
   CCOD_PROD JS ✅ Aplicado
   CCOD_PROD YALI ✅ Aplicado
   Fecha EDAD/DIAS (Amazonía) ✅ Aplicado (FechaFactura)
   Costo (Amazonía) ✅ Aplicado (CosteTotal, COALESCE con Precio)
   Almacén Amazonía Aceptado: SP con ALMACEN normalizado; PQ con NombrePV crudo (sin cambio en SP).
