<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Services\PythonScriptService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
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
}
