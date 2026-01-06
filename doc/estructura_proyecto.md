# Estructura del Proyecto - Excel Generator

## Descripción General

Este proyecto es un sistema modular de generación de reportes Excel que utiliza Python como lenguaje principal. Está organizado siguiendo una arquitectura en capas (layered architecture) con separación clara de responsabilidades.

---

## Estructura de Directorios

```
logistica-scripts-py/
│
├── excel_generator/              # Módulo principal del proyecto
│   ├── __init__.py              # Hace que excel_generator sea un paquete Python
│   │
│   ├── config/                  # Configuración del proyecto
│   │   ├── __init__.py
│   │   ├── conexion_linked.py   # Configuración de conexiones a BD
│   │   ├── db_config.py         # Configuración de base de datos
│   │   ├── email_config.py      # Configuración de email
│   │   └── formulas_config.py   # Configuración de fórmulas
│   │
│   ├── domain/                  # Modelos de dominio (Pydantic)
│   │   ├── __init__.py
│   │   ├── ventas_postpago.py
│   │   ├── bono_recargas_postpago.py
│   │   ├── compras.py
│   │   └── ...                  # Otros modelos de dominio
│   │
│   ├── repositories/            # Capa de acceso a datos
│   │   ├── __init__.py
│   │   ├── ventas_postpago_repository.py
│   │   ├── bono_recargas_postpago_repository.py
│   │   ├── compras_repository.py
│   │   └── ...                  # Otros repositorios
│   │
│   ├── services/                # Lógica de negocio y servicios
│   │   ├── __init__.py
│   │   ├── ventas_postpago_service.py
│   │   ├── ventas_postpago_export_service.py
│   │   ├── bono_recargas_postpago_export_service.py
│   │   ├── compras_export_service.py
│   │   ├── mail_service.py
│   │   ├── brevo_mail_service.py
│   │   │
│   │   ├── pdv_regular/        # Servicios específicos para PDV Regular
│   │   │   ├── __init__.py
│   │   │   ├── bono_n1_service.py
│   │   │   ├── calculos_regular_service.py
│   │   │   └── ...
│   │   │
│   │   └── pdv_premium/         # Servicios específicos para PDV Premium
│   │       ├── __init__.py
│   │       ├── bono_n1_service.py
│   │       └── ...
│   │
│   ├── utils/                   # Utilidades y helpers
│   │   ├── base_excel_writer.py
│   │   ├── excel_workbook_writer.py
│   │   ├── column_mapper.py
│   │   ├── data_separator.py
│   │   ├── formatter.py
│   │   └── email_template_renderer.py
│   │
│   ├── genera_reportes_postpago.py    # Script principal de reportes postpago
│   ├── genera_cierre_postpago.py       # Script de cierre postpago
│   ├── bono_recargas_postpago.py      # Script de bono recargas
│   ├── genera_esquema_regular.py       # Script de esquema regular
│   ├── genera_esquema_premium.py       # Script de esquema premium
│   ├── genera_esquema_multimarca.py    # Script de esquema multimarca
│   ├── export_compras.py               # Script de exportación de compras
│   ├── cxc_export.py                   # Script de exportación CxC
│   ├── main.py                         # Punto de entrada principal alternativo
│   └── main_export.py                  # Punto de entrada para exportaciones
│
├── templates/                   # Plantillas Excel
│   ├── ABONOS_DE_VENTAS_POSTPAGO.xlsx
│   ├── COMPRAS.xlsx
│   ├── DAM.xlsx
│   ├── esquema_mm_template.xlsx
│   ├── esquema_premium_template.xlsx
│   └── esquema_regular_template.xlsx
│
├── output/                      # Directorio de salida (generado automáticamente)
│
├── doc/                         # Documentación
│   ├── estructura_proyecto.md
│   ├── documentacion_genera_reportes_postpago.md
│   └── manual_ejecucion_scripts.md
│
├── scripts/                     # Scripts shell de ejecución
│   ├── export_compras.sh
│   ├── export_cxc.sh
│   └── export_dam.sh
│
├── tests/                       # Tests unitarios
│   └── test_excel_writer.py
│
├── requirements.txt             # Dependencias del proyecto
├── README.md                    # Documentación principal
└── .env                        # Variables de entorno (no versionado)
```

---

## Arquitectura en Capas

El proyecto sigue una arquitectura en capas que separa las responsabilidades:

### 1. **Capa de Configuración** (`config/`)
- Maneja todas las configuraciones del sistema
- Conexiones a bases de datos
- Configuración de email
- Variables de entorno

### 2. **Capa de Dominio** (`domain/`)
- Define los modelos de datos usando Pydantic
- Representa las entidades del negocio
- Validación de datos
- Cada archivo representa un modelo específico

### 3. **Capa de Repositorio** (`repositories/`)
- Acceso directo a la base de datos
- Ejecución de queries SQL
- Mapeo de resultados a modelos de dominio
- Cada repositorio maneja una entidad específica

### 4. **Capa de Servicios** (`services/`)
- Contiene la lógica de negocio
- Orquesta las operaciones entre repositorios
- Servicios de exportación a Excel
- Servicios de email
- Servicios específicos por tipo de PDV (regular/premium)

### 5. **Capa de Utilidades** (`utils/`)
- Funciones auxiliares reutilizables
- Escritura de archivos Excel
- Formateo de datos
- Renderizado de plantillas

### 6. **Scripts de Ejecución** (raíz de `excel_generator/`)
- Puntos de entrada del sistema
- Cada script es ejecutable de forma independiente
- Manejan argumentos de línea de comandos
- Orquestan el flujo completo de generación de reportes

---

## Ejecución de Scripts con `python -m`

### ¿Qué es `python -m`?

El flag `-m` de Python permite ejecutar un módulo como script. Cuando usas `python -m excel_generator.genera_reportes_postpago`, Python:

1. **Busca el módulo** `excel_generator` en el `PYTHONPATH` (incluyendo el directorio actual)
2. **Importa el módulo** `excel_generator.genera_reportes_postpago`
3. **Ejecuta la función** `main()` si existe, o el código en el bloque `if __name__ == "__main__"`

### Estructura de un Script Ejecutable

Cada script ejecutable en el proyecto sigue este patrón:

```python
# excel_generator/genera_reportes_postpago.py

# 1. Imports
import argparse
from excel_generator.repositories.ventas_postpago_repository import ...

# 2. Funciones de lógica
def ejecutar_reportes_postpago(...):
    # Lógica del script
    pass

# 3. Función main() con argparse
def main():
    parser = argparse.ArgumentParser(...)
    parser.add_argument('--año', ...)
    # ...
    args = parser.parse_args()
    ejecutar_reportes_postpago(...)

# 4. Punto de entrada
if __name__ == "__main__":
    main()
```

### Ejemplo de Ejecución

```bash
# Desde la raíz del proyecto
python -m excel_generator.genera_reportes_postpago --año 2025 --mes 12 --dias 1,2,3
```

**¿Por qué funciona esto?**

1. Python encuentra el directorio `excel_generator/` (porque está en el directorio actual)
2. Python reconoce `excel_generator` como un paquete (tiene `__init__.py`)
3. Python importa `genera_reportes_postpago` como un submódulo
4. Python ejecuta el bloque `if __name__ == "__main__"` que llama a `main()`

### Ventajas de usar `python -m`

- ✅ **Rutas relativas funcionan correctamente**: El módulo se ejecuta en el contexto del paquete
- ✅ **Imports funcionan sin problemas**: Puedes importar otros módulos del paquete fácilmente
- ✅ **No necesitas estar en un directorio específico**: Puedes ejecutar desde cualquier lugar si el proyecto está en el PYTHONPATH
- ✅ **Estándar de Python**: Es la forma recomendada de ejecutar módulos

---

## Convenciones de Nomenclatura

### Scripts Ejecutables
- **Prefijo `genera_`**: Scripts que generan reportes específicos
  - `genera_reportes_postpago.py`
  - `genera_cierre_postpago.py`
  - `genera_esquema_regular.py`

- **Prefijo `export_`**: Scripts que exportan datos
  - `export_compras.py`
  - `cxc_export.py`

### Repositorios
- **Sufijo `_repository.py`**: Acceso a datos
  - `ventas_postpago_repository.py`
  - `bono_recargas_postpago_repository.py`

### Servicios
- **Sufijo `_service.py`**: Lógica de negocio
  - `ventas_postpago_service.py`
  - `ventas_postpago_export_service.py`

### Modelos de Dominio
- **Sin sufijo especial**: Nombres descriptivos
  - `ventas_postpago.py`
  - `bono_recargas_postpago.py`
  - `compras.py`

---

## Flujo de Datos Típico

```
Script Ejecutable (genera_reportes_postpago.py)
    ↓
Servicio (ventas_postpago_service.py)
    ↓
Repositorio (ventas_postpago_repository.py)
    ↓
Base de Datos (SQL Server)
    ↓
Modelo de Dominio (ventas_postpago.py)
    ↓
Servicio de Exportación (ventas_postpago_export_service.py)
    ↓
Archivo Excel (output/)
```

---

## Dependencias Principales

Las dependencias del proyecto están en `requirements.txt`:

- **pydantic**: Validación de datos y modelos
- **openpyxl**: Manipulación de archivos Excel
- **pyodbc**: Conexión a SQL Server
- **python-dotenv**: Manejo de variables de entorno
- **Jinja2**: Renderizado de plantillas HTML para emails

---

## Directorios Importantes

### `templates/`
Contiene las plantillas Excel que se usan como base para generar los reportes. Los servicios de exportación cargan estas plantillas y las completan con datos.

### `output/`
Directorio donde se generan todos los archivos Excel. Se crea automáticamente si no existe.

### `config/`
Centraliza toda la configuración del sistema. Las conexiones a BD, credenciales de email, etc., se manejan aquí.

### `doc/`
Documentación del proyecto. Incluye manuales de ejecución y documentación técnica.

---

## Puntos de Entrada Principales

### Scripts Individuales
Cada script puede ejecutarse de forma independiente:

```bash
python -m excel_generator.genera_reportes_postpago --año 2025 --mes 12 --dias 1,2,3
python -m excel_generator.genera_cierre_postpago --año 2025 --mes 12 --dias 1,2,3
python -m excel_generator.bono_recargas_postpago --fecha-inicio 2025-12-01 --fecha-fin 2025-12-03
```

### Script Principal
El archivo `main.py` es un punto de entrada alternativo que ejecuta múltiples procesos:

```bash
python -m excel_generator.main
```

---

## Notas Importantes

1. **Todos los scripts deben ejecutarse desde la raíz del proyecto** o asegurarse de que el proyecto esté en el `PYTHONPATH`

2. **El módulo `excel_generator` debe tener `__init__.py`** para ser reconocido como paquete Python

3. **Las variables de entorno** se cargan desde `.env` en la raíz del proyecto

4. **Los archivos Excel generados** se guardan en `output/` (se crea automáticamente)

5. **Cada script es independiente** pero puede reutilizar código de otros módulos mediante imports

---

## Estructura de Imports Típica

Los scripts típicamente importan de esta manera:

```python
# Imports de otros módulos del proyecto
from excel_generator.repositories.ventas_postpago_repository import VentasPostpagoRepository
from excel_generator.services.ventas_postpago_service import VentasPostpagoService
from excel_generator.domain.ventas_postpago import VentasPostpago
from excel_generator.config.conexion_linked import get_portal_comercial_connection
```

Esto funciona porque Python reconoce `excel_generator` como un paquete y puede resolver los imports relativos.

