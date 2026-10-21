<?php

namespace App\Http\Controllers\Admin;

use App\Exports\VentasInusualesExport;
use App\Http\Controllers\Controller;
use App\Services\PythonScriptService;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Maatwebsite\Excel\Facades\Excel;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

class ReportesPostpagoController extends Controller
{
    protected PythonScriptService $pythonService;

    public function __construct(PythonScriptService $pythonService)
    {
        $this->pythonService = $pythonService;
    }

    /**
     * Ejecuta el stored procedure sp_Registrar_AbonosPostpago
     */
    public function ejecutarSP(Request $request)
    {
        try {
            $request->validate([
                'año' => 'required|integer|min:2020|max:2100',
                'mes' => 'required|integer|min:1|max:12',
                'dias_filtro' => 'nullable|string', // Ej: "1,2,3" o null
            ]);

            $año = $request->input('año');
            $mes = $request->input('mes');
            $diasFiltro = $request->input('dias_filtro');

            // Ejecutar SP
            $result = DB::select(
                "EXEC sp_Registrar_AbonosPostpago @Año = ?, @Mes = ?, @DiasFiltro = ?",
                [$año, $mes, $diasFiltro]
            );

            $registrosInsertados = $result[0]->RegistrosInsertados ?? 0;
            $mensaje = $result[0]->Mensaje ?? '';

            return response()->json([
                "status" => Response::HTTP_OK,
                "message" => "Stored procedure ejecutado correctamente",
                "data" => [
                    "registros_insertados" => $registrosInsertados,
                    "mensaje" => $mensaje,
                ],
            ], Response::HTTP_OK);
        } catch (\Exception $ex) {
            Log::error('Error ejecutando SP AbonosPostpago: ' . $ex->getMessage());
            Log::error('Stack trace: ' . $ex->getTraceAsString());
            return response()->json([
                "status" => Response::HTTP_INTERNAL_SERVER_ERROR,
                "message" => "Error al ejecutar stored procedure: " .
                    (app()->environment('production') ? 'Contacte a soporte.' : $ex->getMessage()),
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Genera reporte de Cierre Postpago ejecutando el script Python
     */
    public function generarCierrePostpago(Request $request)
    {
        try {
            $request->validate([
                'año' => 'required|integer|min:2020|max:2100',
                'mes' => 'required|integer|min:1|max:12',
                'dias' => 'required|string', // Ej: "1,2,3"
                'ejecutar_sp' => 'nullable|boolean', // Si ejecutar SP antes
            ]);

            $año = $request->input('año');
            $mes = $request->input('mes');
            $dias = $request->input('dias');
            $ejecutarSP = $request->input('ejecutar_sp', true);

            // Preparar parámetros para el script Python
            $params = [
                'año' => $año,
                'mes' => $mes,
                'dias' => $dias,
            ];

            // Si no se debe ejecutar el SP, agregar flag --sin-sp
            if (!$ejecutarSP) {
                $params['sin-sp'] = true;
            }

            // Ejecutar script Python como módulo
            $result = $this->pythonService->runModule(
                'excel_generator.genera_reportes_postpago',
                $params
            );

            if (!$result['success']) {
                Log::error('Error ejecutando script Python: ' . implode("\n", $result['output']));
                return response()->json([
                    "status" => Response::HTTP_INTERNAL_SERVER_ERROR,
                    "message" => "Error al generar reporte",
                    "error" => $result['message'] ?? 'Error desconocido',
                    "output" => $result['output'] ?? [],
                ], Response::HTTP_INTERNAL_SERVER_ERROR);
            }

            // Buscar archivo generado (CIERRE POSTPAGO LOG)
            $archivo = $this->pythonService->obtenerArchivoMasReciente('CIERRE POSTPAGO LOG*');

            if (!$archivo) {
                Log::warning('Script ejecutado pero no se encontró archivo generado');
                return response()->json([
                    "status" => Response::HTTP_NOT_FOUND,
                    "message" => "El script se ejecutó pero no se encontró el archivo generado",
                    "output" => $result['output'] ?? [],
                ], Response::HTTP_NOT_FOUND);
            }

            return response()->json([
                "status" => Response::HTTP_OK,
                "message" => "Reporte generado correctamente",
                "data" => [
                    "archivo" => $archivo,
                    "download_url" => route('reportes-postpago.download', ['archivo' => $archivo]),
                ],
                "output" => $result['output'] ?? [],
            ], Response::HTTP_OK);
        } catch (\Exception $ex) {
            Log::error('Error generando Cierre Postpago: ' . $ex->getMessage());
            Log::error('Stack trace: ' . $ex->getTraceAsString());
            return response()->json([
                "status" => Response::HTTP_INTERNAL_SERVER_ERROR,
                "message" => "Error al generar reporte: " .
                    (app()->environment('production') ? 'Contacte a soporte.' : $ex->getMessage()),
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Genera reporte de Bono Recargas Postpago
     * Nota: Este reporte se genera automáticamente cuando se ejecuta genera_reportes_postpago
     * pero se puede crear un endpoint específico si es necesario
     */
    public function generarBonoRecargas(Request $request)
    {
        try {
            $request->validate([
                'año' => 'required|integer|min:2020|max:2100',
                'mes' => 'required|integer|min:1|max:12',
                'dias' => 'required|string', // Ej: "1,2,3"
            ]);

            $año = $request->input('año');
            $mes = $request->input('mes');
            $dias = $request->input('dias');

            // El script genera ambos reportes, pero buscamos solo el de Bono Recargas
            $params = [
                'año' => $año,
                'mes' => $mes,
                'dias' => $dias,
                'sin-sp' => true, // Asumimos que el SP ya se ejecutó
            ];

            $result = $this->pythonService->runModule(
                'excel_generator.genera_reportes_postpago',
                $params
            );

            if (!$result['success']) {
                Log::error('Error ejecutando script Python: ' . implode("\n", $result['output']));
                return response()->json([
                    "status" => Response::HTTP_INTERNAL_SERVER_ERROR,
                    "message" => "Error al generar reporte",
                    "error" => $result['message'] ?? 'Error desconocido',
                    "output" => $result['output'] ?? [],
                ], Response::HTTP_INTERNAL_SERVER_ERROR);
            }

            // Buscar archivo generado (ABONOS_POSTPAGO)
            $archivo = $this->pythonService->obtenerArchivoMasReciente('ABONOS_POSTPAGO*');

            if (!$archivo) {
                return response()->json([
                    "status" => Response::HTTP_NOT_FOUND,
                    "message" => "El script se ejecutó pero no se encontró el archivo generado",
                    "output" => $result['output'] ?? [],
                ], Response::HTTP_NOT_FOUND);
            }

            return response()->json([
                "status" => Response::HTTP_OK,
                "message" => "Reporte generado correctamente",
                "data" => [
                    "archivo" => $archivo,
                    "download_url" => route('reportes-postpago.download', ['archivo' => $archivo]),
                ],
                "output" => $result['output'] ?? [],
            ], Response::HTTP_OK);
        } catch (\Exception $ex) {
            Log::error('Error generando Bono Recargas: ' . $ex->getMessage());
            return response()->json([
                "status" => Response::HTTP_INTERNAL_SERVER_ERROR,
                "message" => "Error al generar reporte: " .
                    (app()->environment('production') ? 'Contacte a soporte.' : $ex->getMessage()),
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Genera ambos reportes (Cierre Postpago + Bono Recargas)
     */
    public function generarAmbos(Request $request)
    {
        try {
            $request->validate([
                'año' => 'required|integer|min:2020|max:2100',
                'mes' => 'required|integer|min:1|max:12',
                'dias' => 'required|string',
                'ejecutar_sp' => 'nullable|boolean',
            ]);

            $año = $request->input('año');
            $mes = $request->input('mes');
            $dias = $request->input('dias');
            $ejecutarSP = $request->input('ejecutar_sp', true);

            $params = [
                'año' => $año,
                'mes' => $mes,
                'dias' => $dias,
            ];

            if (!$ejecutarSP) {
                $params['sin-sp'] = true;
            }

            // Ejecutar script (genera ambos reportes)
            $result = $this->pythonService->runModule(
                'excel_generator.genera_reportes_postpago',
                $params
            );

            if (!$result['success']) {
                Log::error('Error ejecutando script Python: ' . implode("\n", $result['output']));
                return response()->json([
                    "status" => Response::HTTP_INTERNAL_SERVER_ERROR,
                    "message" => "Error al generar reportes",
                    "error" => $result['message'] ?? 'Error desconocido',
                    "output" => $result['output'] ?? [],
                ], Response::HTTP_INTERNAL_SERVER_ERROR);
            }

            // Buscar ambos archivos generados
            $archivoCierre = $this->pythonService->obtenerArchivoMasReciente('CIERRE POSTPAGO LOG*');
            $archivoBono = $this->pythonService->obtenerArchivoMasReciente('ABONOS_POSTPAGO*');

            $archivos = [];
            if ($archivoCierre) {
                $archivos[] = [
                    "nombre" => $archivoCierre,
                    "tipo" => "cierre_postpago",
                    "download_url" => route('reportes-postpago.download', ['archivo' => $archivoCierre]),
                ];
            }
            if ($archivoBono) {
                $archivos[] = [
                    "nombre" => $archivoBono,
                    "tipo" => "bono_recargas",
                    "download_url" => route('reportes-postpago.download', ['archivo' => $archivoBono]),
                ];
            }

            return response()->json([
                "status" => Response::HTTP_OK,
                "message" => "Reportes generados correctamente",
                "data" => [
                    "archivos" => $archivos,
                ],
                "output" => $result['output'] ?? [],
            ], Response::HTTP_OK);
        } catch (\Exception $ex) {
            Log::error('Error generando reportes: ' . $ex->getMessage());
            return response()->json([
                "status" => Response::HTTP_INTERNAL_SERVER_ERROR,
                "message" => "Error al generar reportes: " .
                    (app()->environment('production') ? 'Contacte a soporte.' : $ex->getMessage()),
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Descarga un archivo Excel generado
     */
    public function descargarArchivo(string $archivo)
    {
        try {
            $ruta = $this->pythonService->obtenerRutaArchivo($archivo);

            if (!$ruta) {
                return response()->json([
                    "status" => Response::HTTP_NOT_FOUND,
                    "message" => "Archivo no encontrado: " . $archivo,
                ], Response::HTTP_NOT_FOUND);
            }

            return response()->download($ruta, $archivo, [
                'Content-Type' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            ]);
        } catch (\Exception $ex) {
            Log::error('Error descargando archivo: ' . $ex->getMessage());
            return response()->json([
                "status" => Response::HTTP_INTERNAL_SERVER_ERROR,
                "message" => "Error al descargar archivo",
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Obtiene las fechas límite de las tablas relacionadas
     * - Máxima fecha de ventas en VentasLog (solo Postpago)
     * - Máxima fecha de actualización en BASE_RECARGADORES
     * - Máxima fecha en abonos_postpago_log
     */
    public function obtenerFechasData()
    {
        try {
            // 1. Máxima fecha de VentasLog (solo Postpago)
            $maxFechaVentas = DB::connection('sqlsrv')
                ->table('VentasLog')
                ->where('PRODUCT_NAME', 'Postpago')
                ->max('FECHA');

            // 2. Máxima fecha de actualización de BASE_RECARGADORES
            $maxFechaRecargadores = DB::connection('sqlsrv')
                ->table('BASE_RECARGADORES')
                ->max('created_at');

            // 3. Maxima fecha en PDV_OUT_ABONOS
            $row = DB::connection('sqlsrv')->selectOne("SELECT TOP 1 [FECHAS_ ABONO] as max_fecha FROM PDV_OUT_ABONOS ORDER BY TRY_CONVERT(datetime, [FECHAS_ ABONO], 103) DESC");
            $maxFechaAbonos = $row && $row->max_fecha ? \Carbon\Carbon::createFromFormat('d/m/Y', $row->max_fecha)->format('Y-m-d') : null;

            return response()->json([
                "status" => Response::HTTP_OK,
                "message" => "Fechas límite obtenidas correctamente",
                "data" => [
                    "max_fecha_ventas" => $maxFechaVentas ? Carbon::parse($maxFechaVentas)->format('Y-m-d') : null,
                    "max_fecha_recargadores" => $maxFechaRecargadores ? Carbon::parse($maxFechaRecargadores)->setTimezone('America/Lima')->format('Y-m-d\TH:i:s') : null,
                    "max_fecha_abonos" => $maxFechaAbonos ? Carbon::parse($maxFechaAbonos)->format('Y-m-d') : null,
                ],
            ], Response::HTTP_OK);
        } catch (\Exception $ex) {
            Log::error('Error obteniendo fechas límite: ' . $ex->getMessage());
            Log::error('Stack trace: ' . $ex->getTraceAsString());
            return response()->json([
                "status" => Response::HTTP_INTERNAL_SERVER_ERROR,
                "message" => "Error al obtener fechas límite: " .
                    (app()->environment('production') ? 'Contacte a soporte.' : $ex->getMessage()),
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Lista las ventas inusuales (Alta > 2) con paginación y búsqueda
     */
    public function listarVentasInusuales(Request $request)
    {
        try {
            $request->validate([
                'fecha_desde' => 'required|date',
                'fecha_hasta' => 'required|date|after_or_equal:fecha_desde',
                'page' => 'nullable|integer|min:1',
                'per_page' => 'nullable|integer|min:1|max:100',
                'search' => 'nullable|string|max:255',
            ]);

            $fechaDesde = Carbon::parse($request->input('fecha_desde'))->startOfDay();
            $fechaHasta = Carbon::parse($request->input('fecha_hasta'))->endOfDay();
            $año = $fechaDesde->year;
            $mes = $fechaDesde->month;
            $search = $request->input('search', '');
            $perPage = (int) $request->input('per_page', 10);
            $perPage = $perPage > 0 ? min($perPage, 100) : 10;
            $page = (int) $request->input('page', 1);
            $page = $page > 0 ? $page : 1;

            // Construir query base
            $query = DB::connection('sqlsrv')
                ->table('VentasLog as VL')
                ->join('PDV_OUT_ENTREGABLE as E', function ($join) {
                    $join->on(DB::raw('CAST(VL.DNI_RESPONSABLE AS INT)'), '=', 'E.DNI_RESPONSABLE');
                })
                ->where('VL.PRODUCT_NAME', 'Postpago')
                ->where('E.AÑO', $año)
                ->where('E.MES', $mes)
                ->where('E.ESTADO', 'ACTIVO')
                ->whereBetween('VL.FECHA', [$fechaDesde->format('Y-m-d'), $fechaHasta->format('Y-m-d')])
                ->select([
                    'VL.FECHA',
                    DB::raw('E.ZONAL AS [ZONAL_JS]'),
                    DB::raw('E.ACCION_1 AS [ACCION_JS]'),
                    'VL.DNI_RESPONSABLE',
                    'VL.DNI_VENDEDOR',
                    DB::raw('SUM(CASE WHEN VL.OPERATION_NAME = \'Alta\' THEN 1 ELSE 0 END) AS [Alta]'),
                    DB::raw('SUM(CASE WHEN VL.OPERATION_NAME = \'Portabilidad\' THEN 1 ELSE 0 END) AS [Portabilidad]'),
                    DB::raw('SUM(CASE WHEN VL.OPERATION_NAME = \'Alta\' THEN 1 ELSE 0 END) + SUM(CASE WHEN VL.OPERATION_NAME = \'Portabilidad\' THEN 1 ELSE 0 END) AS [Total_general]'),
                ])
                ->groupBy('VL.FECHA', 'E.ZONAL', 'E.ACCION_1', 'VL.DNI_RESPONSABLE', 'VL.DNI_VENDEDOR')
                ->havingRaw('SUM(CASE WHEN VL.OPERATION_NAME = \'Alta\' THEN 1 ELSE 0 END) > 2');

            // Aplicar búsqueda si existe
            if ($search !== '') {
                $query->where(function ($q) use ($search) {
                    $q->whereRaw('CAST(VL.DNI_RESPONSABLE AS VARCHAR) LIKE ?', ["%$search%"])
                        ->orWhereRaw('CAST(VL.DNI_VENDEDOR AS VARCHAR) LIKE ?', ["%$search%"])
                        ->orWhere('E.ZONAL', 'LIKE', "%$search%")
                        ->orWhere('E.ACCION_1', 'LIKE', "%$search%");
                });
            }

            // Obtener todos los resultados y paginar en memoria
            // (Necesario porque GROUP BY + HAVING no funciona bien con skip/take en SQL Server)
            $allResults = $query
                ->orderBy('VL.FECHA', 'asc')
                ->orderBy('E.ZONAL', 'asc')
                ->orderBy('E.ACCION_1', 'asc')
                ->orderBy('VL.DNI_RESPONSABLE', 'asc')
                ->orderBy('VL.DNI_VENDEDOR', 'asc')
                ->get();

            $total = $allResults->count();
            $results = $allResults->slice(($page - 1) * $perPage, $perPage)->values();

            // Transformar datos a snake_case
            $transformedData = [];
            foreach ($results as $row) {
                $transformedData[] = [
                    'fecha' => $row->FECHA ? Carbon::parse($row->FECHA)->format('Y-m-d') : null,
                    'zonal_js' => $row->ZONAL_JS ?? null,
                    'accion_js' => $row->ACCION_JS ?? null,
                    'dni_responsable' => $row->DNI_RESPONSABLE ?? null,
                    'dni_vendedor' => $row->DNI_VENDEDOR ?? null,
                    'alta' => (int) ($row->Alta ?? 0),
                    'portabilidad' => (int) ($row->Portabilidad ?? 0),
                    'total_general' => (int) ($row->Total_general ?? 0),
                ];
            }

            return response()->json([
                "status" => Response::HTTP_OK,
                "message" => "Ventas inusuales obtenidas correctamente",
                "data" => $transformedData,
                "pagination" => [
                    "current_page" => $page,
                    "per_page" => $perPage,
                    "total" => $total,
                    "last_page" => (int) ceil($total / $perPage),
                ],
            ], Response::HTTP_OK);
        } catch (\Exception $ex) {
            Log::error('Error listando ventas inusuales: ' . $ex->getMessage());
            Log::error('Stack trace: ' . $ex->getTraceAsString());
            return response()->json([
                "status" => Response::HTTP_INTERNAL_SERVER_ERROR,
                "message" => "Error al listar ventas inusuales: " .
                    (app()->environment('production') ? 'Contacte a soporte.' : $ex->getMessage()),
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Exporta las ventas inusuales a Excel
     */
    public function exportarVentasInusuales(Request $request)
    {
        try {
            $request->validate([
                'fecha_desde' => 'required|date',
                'fecha_hasta' => 'required|date|after_or_equal:fecha_desde',
            ]);

            $fechaDesde = Carbon::parse($request->input('fecha_desde'));
            $fechaHasta = Carbon::parse($request->input('fecha_hasta'));

            // Generar nombre del archivo
            $nombreArchivo = sprintf(
                'VENTAS_INUSUALES_%s_%s.xlsx',
                $fechaDesde->format('d-m-Y'),
                $fechaHasta->format('d-m-Y')
            );

            return Excel::download(
                new VentasInusualesExport($fechaDesde, $fechaHasta),
                $nombreArchivo
            );
        } catch (\Exception $ex) {
            Log::error('Error exportando ventas inusuales: ' . $ex->getMessage());
            Log::error('Stack trace: ' . $ex->getTraceAsString());
            return response()->json([
                "status" => Response::HTTP_INTERNAL_SERVER_ERROR,
                "message" => "Error al exportar ventas inusuales: " .
                    (app()->environment('production') ? 'Contacte a soporte.' : $ex->getMessage()),
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }
}
