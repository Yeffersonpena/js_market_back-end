<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AbonosPostpagoLog;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\Response;

class AbonosPostpagoLogController extends Controller
{
    /**
     * Transformar datos de la BD a formato snake_case para el frontend
     */
    private function transformData($row)
    {
        try {
            return [
                'fecha' => $row->FECHA ? Carbon::parse($row->FECHA)->format('Y-m-d') : null,
                'zonal_js' => $row->ZONAL_JS ?? null,
                'accion_js' => $row->ACCION_JS ?? null,
                'canal' => $row->CANAL ?? null,
                'dni_responsable' => $row->DNI_RESPONSABLE ?? null,
                'nombre_pdv' => $row->NOMBRE_PDV ?? null,
                'dni_vendedor' => $row->DNI_VENDEDOR ?? null,
                'nombre_vvdd' => $row->NOMBRE_VVDD ?? null,
                'recargador' => $row->RECARGADOR ?? null,
                'alta' => isset($row->Alta) ? (int) $row->Alta : 0,
                'portabilidad' => isset($row->Portabilidad) ? (int) $row->Portabilidad : 0,
                'total' => isset($row->TOTAL) ? (int) $row->TOTAL : 0,
                'bono' => isset($row->BONO) ? (float) $row->BONO : 0,
                'estado_abono' => $row->ESTADO_ABONO ?? null,
                'obs' => $row->OBS ?? null,
                'estado_recarga' => isset($row->ESTADO_RECARGA) ? (bool) $row->ESTADO_RECARGA : false,
                'fecha_carga' => $row->FECHA_CARGA ? Carbon::parse($row->FECHA_CARGA)->setTimezone('America/Lima')->format('Y-m-d\TH:i:s') : null,
            ];
        } catch (\Exception $e) {
            Log::error('Error transformando datos AbonosPostpagoLog: ' . $e->getMessage());
            return null;
        }
    }

    /**
     * Listar registros de abonos postpago log
     * Orden: más nuevo primero (FECHA_CARGA DESC)
     */
    public function index(Request $request)
    {
        try {
            // Usar Query Builder directamente por la primary key compuesta
            $query = DB::connection('sqlsrv')
                ->table('abonos_postpago_log');

            // Búsqueda en múltiples campos
            $search = $request->input('search', '');
            if ($search !== '') {
                $query->where(function ($q) use ($search) {
                    $q->where('DNI_RESPONSABLE', 'LIKE', "%$search%")
                        ->orWhere('NOMBRE_PDV', 'LIKE', "%$search%")
                        ->orWhere('DNI_VENDEDOR', 'LIKE', "%$search%")
                        ->orWhere('NOMBRE_VVDD', 'LIKE', "%$search%")
                        ->orWhere('RECARGADOR', 'LIKE', "%$search%");
                });
            }

            // Ordenar por más nuevo primero (FECHA_CARGA DESC)
            $query->orderBy('FECHA_CARGA', 'desc');

            // Paginación
            $perPage = (int) $request->input('per_page', 10);
            $perPage = $perPage > 0 ? min($perPage, 100) : 10;

            $page = (int) $request->input('page', 1);
            $page = $page > 0 ? $page : 1;

            // Obtener total antes de paginar
            $total = $query->count();

            // Aplicar paginación manual
            $offset = ($page - 1) * $perPage;
            $rows = $query->skip($offset)->take($perPage)->get();

            // Transformar los datos a snake_case
            $transformedData = [];
            foreach ($rows as $item) {
                $transformed = $this->transformData($item);
                if ($transformed) {
                    $transformedData[] = $transformed;
                }
            }

            // Calcular last_page
            $lastPage = $total > 0 ? (int) ceil($total / $perPage) : 1;

            return response()->json([
                "status" => Response::HTTP_OK,
                "message" => "Listado de abonos postpago log",
                "data" => $transformedData,
                "pagination" => [
                    "current_page" => $page,
                    "per_page" => $perPage,
                    "total" => $total,
                    "last_page" => $lastPage,
                ],
            ], Response::HTTP_OK);
        } catch (\Exception $ex) {
            Log::error('Error en index AbonosPostpagoLog: ' . $ex->getMessage());
            Log::error('Stack trace: ' . $ex->getTraceAsString());
            return response()->json([
                "status" => Response::HTTP_INTERNAL_SERVER_ERROR,
                "message" => "Error al obtener datos: " . (app()->environment('production') ? 'Contacte a soporte.' : $ex->getMessage()),
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }
}

