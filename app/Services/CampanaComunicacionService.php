<?php

namespace App\Services;

use App\Models\PDVOutCampanasFlyers;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;

class CampanaComunicacionService
{
    private CampanaFileManager $fileManager;

    public function __construct(CampanaFileManager $fileManager)
    {
        $this->fileManager = $fileManager;
    }

    /**
     * Valida que la campaña sea de tipo ACELERADOR
     */
    public function validateAceleradorCampana(PDVOutCampanasFlyers $campana): array
    {
        $errors = [];

        if (strtoupper($campana->tipoImg) !== 'ACELERADOR') {
            $errors[] = 'Esta funcionalidad solo está disponible para campañas de tipo ACELERADOR';
        }

        return $errors;
    }

    /**
     * Actualiza los campos de comunicación en la base de datos
     */
    public function updateComunicacionFields(PDVOutCampanasFlyers $campana, string $fileName): bool
    {
        try {
            $campana->update([
                'comunicado' => 1,
                'fecha_comunicacion' => Carbon::now()->toDateString(),
                'archivo_comunicacion' => $fileName
            ]);

            Log::info('Campos de comunicación actualizados en BD', [
                'campana_id' => $campana->id,
                'archivo_comunicacion' => $fileName,
                'fecha_comunicacion' => $campana->fecha_comunicacion
            ]);

            return true;
        } catch (\Exception $e) {
            Log::error('Error actualizando campos de comunicación en BD', [
                'campana_id' => $campana->id,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return false;
        }
    }

    /**
     * Procesa la actualización completa de comunicación
     */
    public function processComunicacionUpdate(PDVOutCampanasFlyers $campana, $archivo): array
    {
        // Validar campaña
        $validationErrors = $this->validateAceleradorCampana($campana);
        if (!empty($validationErrors)) {
            return [
                'success' => false,
                'errors' => $validationErrors
            ];
        }

        // Guardar archivo
        $fileResult = $this->fileManager->saveComunicacionFile($archivo, $campana->id);
        if (!$fileResult['success']) {
            return [
                'success' => false,
                'errors' => $fileResult['errors']
            ];
        }

        // Actualizar campos en BD
        $updateSuccess = $this->updateComunicacionFields($campana, $fileResult['file_name']);
        if (!$updateSuccess) {
            // Si falla la actualización en BD, eliminar el archivo
            $this->fileManager->deleteComunicacionFile($fileResult['file_name']);

            return [
                'success' => false,
                'errors' => ['Error al actualizar los campos en la base de datos']
            ];
        }

        return [
            'success' => true,
            'data' => [
                'id' => $campana->id,
                'comunicado' => true,
                'fecha_comunicacion' => $campana->fecha_comunicacion,
                'archivo_comunicacion' => $campana->archivo_comunicacion,
                'download_url' => $fileResult['download_url']
            ]
        ];
    }

    /**
     * Obtiene información de descarga del archivo
     */
    public function getDownloadInfo(PDVOutCampanasFlyers $campana): array
    {
        if (!$campana->archivo_comunicacion) {
            return [
                'success' => false,
                'message' => 'No hay archivo de comunicación asociado a esta campaña'
            ];
        }

        if (!$this->fileManager->fileExists($campana->archivo_comunicacion)) {
            return [
                'success' => false,
                'message' => 'El archivo de comunicación no existe en el servidor'
            ];
        }

        $fileInfo = $this->fileManager->getFileInfo($campana->archivo_comunicacion);

        return [
            'success' => true,
            'data' => [
                'nombre_archivo' => $campana->archivo_comunicacion,
                'download_url' => $fileInfo['download_url'],
                'fecha_comunicacion' => $campana->fecha_comunicacion,
                'tamaño_archivo' => $fileInfo['file_size'],
                'fecha_modificacion' => $fileInfo['last_modified']
            ]
        ];
    }

    /**
     * Valida que un grupo de aceleradores pueda compartir el mismo Excel
     * Deben tener: mismas fechas, mismo modo, y ser tipo ACELERADOR
     *
     * @param array $flyers Array de objetos PDVOutCampanasFlyers
     * @return array Array de errores (vacío si es válido)
     */
    public function validateGrupoAceleradores(array $flyers): array
    {
        $errors = [];

        if (empty($flyers)) {
            $errors[] = 'Debe proporcionar al menos un acelerador';
            return $errors;
        }

        // Validar que todos sean ACELERADOR
        foreach ($flyers as $flyer) {
            if (strtoupper($flyer->tipoImg) !== 'ACELERADOR') {
                $errors[] = "El flyer ID {$flyer->id} no es de tipo ACELERADOR";
            }
        }

        if (!empty($errors)) {
            return $errors;
        }

        // Obtener valores del primer flyer como referencia
        $primerFlyer = $flyers[0];
        $fechaInicioReferencia = $primerFlyer->fecha_inicio;
        $fechaFinReferencia = $primerFlyer->fecha_fin;
        $modoReferencia = $primerFlyer->modo;

        // Validar que todos tengan las mismas fechas y modo
        foreach ($flyers as $index => $flyer) {
            if ($index === 0) continue; // Saltar el primero

            if ($flyer->fecha_inicio !== $fechaInicioReferencia) {
                $errors[] = "El flyer ID {$flyer->id} tiene fecha_inicio diferente ({$flyer->fecha_inicio} vs {$fechaInicioReferencia})";
            }

            if ($flyer->fecha_fin !== $fechaFinReferencia) {
                $errors[] = "El flyer ID {$flyer->id} tiene fecha_fin diferente ({$flyer->fecha_fin} vs {$fechaFinReferencia})";
            }

            if ($flyer->modo !== $modoReferencia) {
                $errors[] = "El flyer ID {$flyer->id} tiene modo diferente ({$flyer->modo} vs {$modoReferencia})";
            }
        }

        return $errors;
    }

    /**
     * Actualiza múltiples flyers con el mismo archivo de comunicación
     *
     * @param array $flyers Array de objetos PDVOutCampanasFlyers
     * @param string $fileName Nombre del archivo de comunicación
     * @param string $fechaComunicacion Fecha de comunicación
     * @return bool True si se actualizó correctamente, false en caso contrario
     */
    public function updateComunicacionMultiple(array $flyers, string $fileName, string $fechaComunicacion): bool
    {
        try {
            $ids = array_map(function ($flyer) {
                return is_object($flyer) ? $flyer->id : $flyer['id'];
            }, $flyers);

            $updated = PDVOutCampanasFlyers::whereIn('id', $ids)->update([
                'comunicado' => 1,
                'fecha_comunicacion' => $fechaComunicacion,
                'archivo_comunicacion' => $fileName
            ]);

            Log::info('Comunicación actualizada para múltiples flyers', [
                'flyers_ids' => $ids,
                'archivo_comunicacion' => $fileName,
                'fecha_comunicacion' => $fechaComunicacion,
                'total_actualizados' => $updated
            ]);

            return $updated > 0;
        } catch (\Exception $e) {
            Log::error('Error actualizando comunicación para múltiples flyers', [
                'flyers_ids' => $ids ?? [],
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return false;
        }
    }

    /**
     * Elimina un archivo de comunicación
     *
     * @param string $fileName Nombre del archivo a eliminar
     * @return bool True si se eliminó correctamente, false en caso contrario
     */
    public function deleteComunicacionFile(string $fileName): bool
    {
        return $this->fileManager->deleteComunicacionFile($fileName);
    }
}
