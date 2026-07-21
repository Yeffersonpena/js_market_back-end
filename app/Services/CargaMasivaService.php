<?php

namespace App\Services;

use App\Models\PDVOutCampanasFlyers;
use App\Models\PDVOutImagen;
use Carbon\Carbon;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

class CargaMasivaService
{
    public function procesarArchivos(array $archivos, string $tipoImg, string $multiTienda): array
    {
        $resultados = [];
        $archivosValidos = [];

        foreach ($archivos as $archivo) {
            $nombreOriginal = $archivo->getClientOriginalName();
            preg_match('/(?<!\d)(\d{8,12})(?!\d)/', $nombreOriginal, $coincidencias);

            if (empty($coincidencias)) {
                $resultados[] = $this->resultado(
                    $nombreOriginal,
                    '',
                    'error',
                    'No se encontró un DNI válido (8 a 12 dígitos) en el nombre del archivo.'
                );
                continue;
            }

            $dni = $coincidencias[0];
            $archivosValidos[] = [
                'archivo' => $archivo,
                'nombre' => $nombreOriginal,
                'dni' => $dni,
                'direccion' => $this->extraerDireccion($nombreOriginal),
            ];
        }

        $vendedores = $this->validarDnis(array_values(array_unique(array_column($archivosValidos, 'dni'))));

        foreach ($archivosValidos as $item) {
            $dni = $item['dni'];
            if (!isset($vendedores[$dni])) {
                $resultados[] = $this->resultado(
                    $item['nombre'],
                    $dni,
                    'error',
                    "El DNI ($dni) no pertenece a un vendedor/PDV válido."
                );
                continue;
            }

            $nombreGuardado = null;
            try {
                DB::transaction(function () use (
                    $item,
                    $dni,
                    $tipoImg,
                    $multiTienda,
                    $vendedores,
                    &$nombreGuardado
                ) {
                    $nombreGuardado = $this->guardarArchivo($item['archivo'], $dni, $tipoImg);
                    PDVOutImagen::create([
                        'nombre_imagen' => $nombreGuardado,
                        'fecha_modificacion' => Carbon::now(),
                    ]);
                    $this->actualizarCampana(
                        $nombreGuardado,
                        $dni,
                        $tipoImg,
                        $multiTienda,
                        $vendedores[$dni],
                        $item['direccion']
                    );
                });

                $resultados[] = $this->resultado(
                    $item['nombre'],
                    $dni,
                    'exito',
                    'Archivo procesado y asignado exitosamente.'
                );
            } catch (\Throwable $e) {
                if ($nombreGuardado) {
                    Storage::disk('public')->delete('img/' . $nombreGuardado);
                }
                Log::error('Error en carga masiva de documento', [
                    'archivo' => $item['nombre'],
                    'dni' => $dni,
                    'error' => $e->getMessage(),
                ]);
                $resultados[] = $this->resultado($item['nombre'], $dni, 'error', $e->getMessage());
            }
        }

        return $resultados;
    }

    private function validarDnis(array $dnis): array
    {
        if ($dnis === []) {
            return [];
        }

        $vendedores = DB::table('PORTAL_COMERCIAL.dbo.PDV_VENDEDORES')
            ->whereIn('dni_vendedor', $dnis)
            ->get(['dni_vendedor', 'zonal'])
            ->keyBy(fn ($item) => (string) $item->dni_vendedor)
            ->all();

        $usuarios = DB::table('users')
            ->whereIn('user', $dnis)
            ->get(['user', 'zonal'])
            ->keyBy(fn ($item) => (string) $item->user)
            ->all();

        return $vendedores + $usuarios;
    }

    private function guardarArchivo(UploadedFile $archivo, string $dni, string $tipoImg): string
    {
        $inicio = Carbon::now()->format('Ymd');
        $fin = Carbon::now()->addYears(10)->format('Ymd');
        $hash = substr(hash('sha256', $archivo->getClientOriginalName() . microtime(true) . random_int(1, PHP_INT_MAX)), 0, 12);
        $extension = strtolower($archivo->getClientOriginalExtension());
        $nombre = "Doc_{$dni}_{$inicio}_{$fin}_{$tipoImg}_PDV_{$dni}_{$hash}.{$extension}";

        if (!$archivo->storeAs('img', $nombre, 'public')) {
            throw new \RuntimeException('No se pudo guardar el archivo en el almacenamiento del portal.');
        }

        return $nombre;
    }

    private function actualizarCampana(
        string $nombre,
        string $dni,
        string $tipoImg,
        string $multiTienda,
        object $vendedor,
        ?string $direccion
    ): void {
        $consulta = PDVOutCampanasFlyers::where('criterio_filtro', $dni)
            ->where('tipoImg', $tipoImg);

        $direccion
            ? $consulta->where('direccion', $direccion)
            : $consulta->whereNull('direccion');

        $campana = $consulta->first() ?? new PDVOutCampanasFlyers();
        if (!$campana->exists) {
            $campana->fecha_creacion = Carbon::now()->format('Y-m-d H:i:s');
        }

        $campana->{'nombre_campaña'} = $nombre;
        $campana->foto_esquema = $nombre;
        $campana->fecha_inicio = Carbon::now()->format('Y-m-d');
        $campana->fecha_fin = Carbon::now()->addYears(10)->format('Y-m-d');
        $campana->tipoImg = $tipoImg;
        $campana->modo = 'PDV';
        $campana->criterio_filtro = $dni;
        $campana->zonales = in_array($multiTienda, ['SI', 'NO'], true)
            ? $multiTienda
            : ($vendedor->zonal ?? 'TODOS');
        $campana->activa = 1;
        $campana->todos = 0;
        $campana->comunicado = 0;
        if ($direccion) {
            $campana->direccion = $direccion;
        }
        $campana->save();
    }

    private function extraerDireccion(string $nombre): ?string
    {
        return preg_match('/_contrato_(.*?)\.pdf$/i', $nombre, $coincidencias)
            ? trim($coincidencias[1])
            : null;
    }

    private function resultado(string $archivo, string $dni, string $estado, string $mensaje): array
    {
        return compact('archivo', 'dni', 'estado', 'mensaje');
    }
}
