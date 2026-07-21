<?php

namespace App\Services;

class PythonScriptService
{
    private ?string $venvPath = null;
    private ?string $scriptsPath = null;
    private ?string $outputPath = null;
    private bool $isWindows;

    public function __construct()
    {
        $this->isWindows = strtoupper(substr(PHP_OS, 0, 3)) === 'WIN';

        if ($this->isWindows) {
            // Rutas para Windows (desarrollo local - rutas relativas)
            // Buscar logistica-scripts-py al mismo nivel que js_market_back-end
            // Estructura esperada: .../backend/logistica-scripts-py/excel_generator/
            $basePath = realpath(__DIR__ . '/../../') ?: realpath(__DIR__ . '/../../../');
            $pythonProjectPath = $basePath ?
                realpath($basePath . '/../logistica-scripts-py') : null;

            $this->scriptsPath = $pythonProjectPath; // Raíz del proyecto Python
            $this->venvPath = $pythonProjectPath ?
                realpath($pythonProjectPath . '/venv/Scripts/python.exe') : null;
            $this->outputPath = $pythonProjectPath ?
                realpath($pythonProjectPath . '/excel_generator/output') : null;
        } else {
            // Rutas absolutas para Linux (producción)
            // Backend está en: /var/www/html/portal_comercial/backend/js_market_back-end
            // Proyecto Python está en: /var/www/html/portal_comercial/backend/logistica-scripts-py
            // Estructura: logistica-scripts-py/excel_generator/
            $pythonProjectPath = '/var/www/html/portal_comercial/backend/logistica-scripts-py';
            $this->scriptsPath = $pythonProjectPath; // Raíz del proyecto Python
            $this->venvPath = $pythonProjectPath . '/venv/bin/python3';
            $this->outputPath = $pythonProjectPath . '/excel_generator/output';
        }
    }

    /**
     * Ejecuta un script Python como módulo (ej: python -m excel_generator.genera_reportes_postpago)
     *
     * @param string $moduleName Nombre del módulo (ej: 'excel_generator.genera_reportes_postpago')
     * @param array $params Parámetros como array asociativo (ej: ['año' => 2025, 'mes' => 12, 'dias' => '1,2,3'])
     * @return array Resultado de la ejecución
     */
    public function runModule(string $moduleName, array $params = []): array
    {
        if (!$this->venvPath || !is_executable($this->venvPath)) {
            $venvExpectedPath = $this->isWindows
                ? ($this->scriptsPath ? $this->scriptsPath . '/venv/Scripts/python.exe' : 'N/A')
                : '/var/www/html/portal_comercial/backend/excel_generator/venv/bin/python3';

            return [
                'success' => false,
                'message' => 'No se encontró el entorno virtual de Python. Se esperaba en: ' . $venvExpectedPath . '. Por favor, crea el venv e instala las dependencias.',
                'output' => [],
                'command' => $moduleName,
                'venv_path' => $venvExpectedPath,
                'scripts_path' => $this->scriptsPath
            ];
        }

        // Construir comando con argumentos
        $args = [];
        foreach ($params as $key => $value) {
            if (is_bool($value)) {
                // Si es boolean true, agregar flag sin valor
                if ($value) {
                    $args[] = '--' . $key;
                }
            } else {
                // Agregar flag y valor
                $args[] = '--' . $key;
                $args[] = escapeshellarg((string)$value);
            }
        }

        $paramString = implode(' ', $args);
        $command = escapeshellcmd($this->venvPath) . ' -m ' . escapeshellarg($moduleName) . ' ' . $paramString . ' 2>&1';

        $output = [];
        $status = 0;

        // Ejecutar desde la raíz del proyecto Python (logistica-scripts-py)
        // Según la documentación: "Todos los scripts deben ejecutarse desde la raíz del proyecto"
        // Esto permite que Python encuentre el módulo excel_generator correctamente
        $originalDir = getcwd();

        if ($this->scriptsPath && is_dir($this->scriptsPath)) {
            chdir($this->scriptsPath);
        }

        exec($command, $output, $status);

        // Volver al directorio original
        if ($originalDir) {
            chdir($originalDir);
        }

        // Convertir a UTF-8 y eliminar líneas vacías
        $outputUtf8 = array_values(array_filter(array_map(function ($line) {
            // Detectar codificación automáticamente y convertir a UTF-8
            $detectedEncoding = mb_detect_encoding($line, ['UTF-8', 'ISO-8859-1', 'Windows-1252', 'ASCII'], true);
            if ($detectedEncoding && $detectedEncoding !== 'UTF-8') {
                $line = mb_convert_encoding($line, 'UTF-8', $detectedEncoding);
            }
            return trim($line);
        }, $output), fn($line) => $line !== ''));

        return [
            'success' => $status === 0,
            'output' => $outputUtf8,
            'status' => $status,
            'command' => $command
        ];
    }

    /**
     * Ejecuta un script Python directamente (archivo .py)
     *
     * @param string $scriptName Nombre del script (ej: 'genera_reportes_postpago.py')
     * @param array $params Parámetros como array asociativo
     * @return array Resultado de la ejecución
     */
    public function run(string $scriptName, array $params = []): array
    {
        $scriptName = ltrim($scriptName, '/\\');
        $scriptPath = $this->scriptsPath ?
            realpath($this->scriptsPath . DIRECTORY_SEPARATOR . $scriptName) : null;

        if (!$scriptPath || !file_exists($scriptPath)) {
            return [
                'success' => false,
                'message' => 'El script no existe: ' . $scriptName,
                'output' => [],
                'command' => $scriptPath ?? 'N/A'
            ];
        }

        if (!$this->venvPath || !is_executable($this->venvPath)) {
            $venvExpectedPath = $this->isWindows
                ? ($this->scriptsPath ? $this->scriptsPath . '/venv/Scripts/python.exe' : 'N/A')
                : '/var/www/html/portal_comercial/backend/excel_generator/venv/bin/python3';

            return [
                'success' => false,
                'message' => 'No se encontró el entorno virtual de Python. Se esperaba en: ' . $venvExpectedPath,
                'output' => [],
                'command' => $scriptPath,
                'venv_path' => $venvExpectedPath,
                'scripts_path' => $this->scriptsPath
            ];
        }

        // Preparar los parámetros
        $args = [];
        foreach ($params as $key => $value) {
            if (is_bool($value)) {
                if ($value) {
                    $args[] = '--' . $key;
                }
            } else {
                $args[] = '--' . $key;
                $args[] = escapeshellarg((string)$value);
            }
        }

        $paramString = implode(' ', $args);
        $command = escapeshellcmd($this->venvPath) . ' ' . escapeshellarg($scriptPath) . ' ' . $paramString . ' 2>&1';

        $output = [];
        $status = 0;

        // Cambiar al directorio de scripts para ejecutar
        $originalDir = getcwd();
        if ($this->scriptsPath && is_dir($this->scriptsPath)) {
            chdir($this->scriptsPath);
        }

        exec($command, $output, $status);

        // Volver al directorio original
        if ($originalDir) {
            chdir($originalDir);
        }

        // Convertir a UTF-8 y eliminar líneas vacías
        $outputUtf8 = array_values(array_filter(array_map(function ($line) {
            $detectedEncoding = mb_detect_encoding($line, ['UTF-8', 'ISO-8859-1', 'Windows-1252', 'ASCII'], true);
            if ($detectedEncoding && $detectedEncoding !== 'UTF-8') {
                $line = mb_convert_encoding($line, 'UTF-8', $detectedEncoding);
            }
            return trim($line);
        }, $output), fn($line) => $line !== ''));

        return [
            'success' => $status === 0,
            'output' => $outputUtf8,
            'status' => $status,
            'command' => $command
        ];
    }

    /**
     * Obtiene la ruta del directorio de salida de archivos generados
     */
    public function getOutputPath(): ?string
    {
        return $this->outputPath && is_dir($this->outputPath) ? $this->outputPath : null;
    }

    /**
     * Busca archivos Excel generados en el directorio de salida
     *
     * @param string $pattern Patrón de búsqueda (ej: 'CIERRE POSTPAGO LOG*')
     * @return array Lista de nombres de archivos encontrados
     */
    public function buscarArchivosGenerados(string $pattern = '*'): array
    {
        if (!$this->outputPath || !is_dir($this->outputPath)) {
            return [];
        }

        $archivos = glob($this->outputPath . DIRECTORY_SEPARATOR . $pattern . '.xlsx');
        return array_map('basename', $archivos);
    }

    /**
     * Obtiene la ruta completa de un archivo generado
     *
     * @param string $nombreArchivo Nombre del archivo
     * @return string|null Ruta completa o null si no existe
     */
    public function obtenerRutaArchivo(string $nombreArchivo): ?string
    {
        if (!$this->outputPath) {
            return null;
        }

        $ruta = $this->outputPath . DIRECTORY_SEPARATOR . $nombreArchivo;
        return file_exists($ruta) ? $ruta : null;
    }

    /**
     * Obtiene el archivo más reciente que coincida con un patrón
     *
     * @param string $pattern Patrón de búsqueda
     * @return string|null Nombre del archivo más reciente o null
     */
    public function obtenerArchivoMasReciente(string $pattern = '*'): ?string
    {
        $archivos = $this->buscarArchivosGenerados($pattern);

        if (empty($archivos)) {
            return null;
        }

        $archivosConFecha = [];
        foreach ($archivos as $archivo) {
            $ruta = $this->outputPath . DIRECTORY_SEPARATOR . $archivo;
            if (file_exists($ruta)) {
                $archivosConFecha[$archivo] = filemtime($ruta);
            }
        }

        if (empty($archivosConFecha)) {
            return null;
        }

        arsort($archivosConFecha);
        return array_key_first($archivosConFecha);
    }
}
