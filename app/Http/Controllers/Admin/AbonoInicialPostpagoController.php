<?php

namespace App\Http\Controllers\Admin;

use App\Exports\AbonoInicialPostpagoExport;
use App\Http\Controllers\Controller;
use App\Models\AbonoInicialPostpago;
use App\Models\PDV_ENTREGABLE;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Maatwebsite\Excel\Facades\Excel;
use Symfony\Component\HttpFoundation\Response;

class AbonoInicialPostpagoController extends Controller
{
    /**
     * Transforma los campos del modelo de mayúsculas a snake_case en minúsculas
     */
    private function transformData($row)
    {
        if (!$row) {
            return null;
        }

        try {
            return [
                'id' => $row->ID,
                'fecha_hora_recarga' => $row->FECHA_HORA_RECARGA ? Carbon::parse($row->FECHA_HORA_RECARGA)->setTimezone('America/Lima')->format('Y-m-d\TH:i:s') : null,
                'zonal' => $row->ZONAL,
                'accion' => $row->ACCION,
                'dni' => $row->DNI,
                'recargador_celular' => $row->RECARGADOR_CELULAR,
                'monto' => (float) $row->MONTO,
                'se_abono' => (bool) $row->SE_ABONO,
                'fecha_carga' => $row->FECHA_CARGA ? Carbon::parse($row->FECHA_CARGA)->setTimezone('America/Lima')->format('Y-m-d\TH:i:s') : null,
            ];
        } catch (\Exception $e) {
            // Si hay error al transformar, devolver datos básicos
            return [
                'id' => $row->ID ?? null,
                'fecha_hora_recarga' => $row->FECHA_HORA_RECARGA ? (string) $row->FECHA_HORA_RECARGA : null,
                'zonal' => $row->ZONAL ?? null,
                'accion' => $row->ACCION ?? null,
                'dni' => $row->DNI ?? null,
                'recargador_celular' => $row->RECARGADOR_CELULAR ?? null,
                'monto' => isset($row->MONTO) ? (float) $row->MONTO : 0,
                'se_abono' => isset($row->SE_ABONO) ? (bool) $row->SE_ABONO : false,
                'fecha_carga' => $row->FECHA_CARGA ? (string) $row->FECHA_CARGA : null,
            ];
        }
    }

    public function index(Request $request)
    {
        try {
            $query = AbonoInicialPostpago::query();

            if ($request->filled('dni')) {
                $query->where('DNI', (int) $request->input('dni'));
            }

            $recargador = $request->input('recargador');
            if ($recargador !== null && $recargador !== '') {
                $query->where('RECARGADOR_CELULAR', $recargador);
            }

            if ($request->filled('se_abono')) {
                $seAbono = filter_var($request->input('se_abono'), FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE);
                if ($seAbono !== null) {
                    $query->where('SE_ABONO', $seAbono ? 1 : 0);
                }
            }

            $search = $request->input('search', '');
            if ($search !== '') {
                $query->where(function ($q) use ($search) {
                    $q->where('ZONAL', 'LIKE', "%$search%")
                        ->orWhereRaw('CAST(DNI AS VARCHAR) LIKE ?', ["%$search%"])
                        ->orWhere('RECARGADOR_CELULAR', 'LIKE', "%$search%");
                });
            }

            $perPage = (int) $request->input('per_page', 10);
            $perPage = $perPage > 0 ? min($perPage, 100) : 10;

            $page = (int) $request->input('page', 1);
            $page = $page > 0 ? $page : 1;

            $rows = $query->orderBy('FECHA_HORA_RECARGA', 'desc')->paginate($perPage, ['*'], 'page', $page);

            // Transformar los datos a snake_case en minúsculas
            $transformedData = [];
            foreach ($rows->items() as $item) {
                $transformed = $this->transformData($item);
                if ($transformed) {
                    $transformedData[] = $transformed;
                }
            }

            return response()->json([
                "status" => Response::HTTP_OK,
                "message" => "Listado de abono inicial postpago",
                "data" => $transformedData,
                "pagination" => [
                    "current_page" => $rows->currentPage(),
                    "per_page" => $rows->perPage(),
                    "total" => $rows->total(),
                    "last_page" => $rows->lastPage(),
                ],
            ], Response::HTTP_OK);
        } catch (\Exception $ex) {
            Log::error('Error en index AbonoInicialPostpago: ' . $ex->getMessage());
            Log::error('Stack trace: ' . $ex->getTraceAsString());
            return response()->json([
                "status" => Response::HTTP_INTERNAL_SERVER_ERROR,
                "message" => "Error al obtener datos: " . $ex->getMessage(),
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    public function show($id)
    {
        try {
            $row = AbonoInicialPostpago::find($id);
            if (!$row) {
                return response()->json([
                    "status" => Response::HTTP_NOT_FOUND,
                    "message" => "Registro no encontrado",
                    "data" => null,
                ], Response::HTTP_NOT_FOUND);
            }
            return response()->json([
                "status" => Response::HTTP_OK,
                "message" => "Detalle de abono inicial postpago",
                "data" => $this->transformData($row),
            ], Response::HTTP_OK);
        } catch (\Exception $ex) {
            return response()->json([
                "status" => Response::HTTP_BAD_REQUEST,
                "message" => $ex->getMessage(),
            ], Response::HTTP_BAD_REQUEST);
        }
    }

    public function store(Request $request)
    {
        try {
            // Validar campos básicos primero
            $validated = $request->validate([
                'fecha_hora_recarga' => 'required|string',
                'zonal' => 'nullable|string|max:100',
                'accion' => 'nullable|string|max:50',
                'dni' => 'required|integer',
                'recargador_celular' => ['required', 'string', 'regex:/^[0-9]{9}$/'],
                'monto' => 'required|numeric',
                'se_abono' => 'nullable|boolean',
            ]);

            $row = new AbonoInicialPostpago();

            // Parsear fecha - acepta formato Y-m-d H:i:s o cualquier formato válido
            try {
                // Intentar primero con el formato esperado del frontend
                $row->FECHA_HORA_RECARGA = Carbon::createFromFormat('Y-m-d H:i:s', $validated['fecha_hora_recarga']);
            } catch (\Exception $e) {
                // Si falla, intentar parseo automático de Carbon
                try {
                    $row->FECHA_HORA_RECARGA = Carbon::parse($validated['fecha_hora_recarga']);
                } catch (\Exception $e2) {
                    return response()->json([
                        "status" => Response::HTTP_BAD_REQUEST,
                        "message" => "Formato de fecha inválido: " . $validated['fecha_hora_recarga'],
                    ], Response::HTTP_BAD_REQUEST);
                }
            }

            $row->ZONAL = $validated['zonal'] ?? null;
            $row->ACCION = $validated['accion'] ?? null;
            $row->DNI = (int) $validated['dni'];
            $row->RECARGADOR_CELULAR = $validated['recargador_celular'];
            $row->MONTO = (float) $validated['monto'];
            $row->SE_ABONO = isset($validated['se_abono']) && $validated['se_abono'] ? 1 : 0;

            $row->save();
            $row->refresh(); // Recargar para obtener FECHA_CARGA

            return response()->json([
                "status" => Response::HTTP_CREATED,
                "message" => "Registro creado",
                "data" => $this->transformData($row),
            ], Response::HTTP_CREATED);
        } catch (\Illuminate\Validation\ValidationException $ex) {
            return response()->json([
                "status" => Response::HTTP_UNPROCESSABLE_ENTITY,
                "message" => "Error de validación",
                "errors" => $ex->errors(),
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        } catch (\Exception $ex) {
            Log::error('Error en store AbonoInicialPostpago: ' . $ex->getMessage());
            Log::error('Stack trace: ' . $ex->getTraceAsString());
            return response()->json([
                "status" => Response::HTTP_INTERNAL_SERVER_ERROR,
                "message" => "Error al crear registro: " . $ex->getMessage(),
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    public function update(Request $request, $id)
    {
        try {
            $row = AbonoInicialPostpago::find($id);
            if (!$row) {
                return response()->json([
                    "status" => Response::HTTP_NOT_FOUND,
                    "message" => "Registro no encontrado",
                    "data" => null,
                ], Response::HTTP_NOT_FOUND);
            }

            $validated = $request->validate([
                'fecha_hora_recarga' => 'sometimes|date',
                'zonal' => 'sometimes|nullable|string|max:100',
                'accion' => 'sometimes|nullable|string|max:50',
                'dni' => 'sometimes|integer',
                'recargador_celular' => ['sometimes', 'string', 'regex:/^[0-9]{9}$/'],
                'monto' => 'sometimes|numeric',
                'se_abono' => 'sometimes|boolean',
            ]);

            if (array_key_exists('fecha_hora_recarga', $validated)) {
                $row->FECHA_HORA_RECARGA = Carbon::parse($validated['fecha_hora_recarga']);
            }
            if (array_key_exists('zonal', $validated)) {
                $row->ZONAL = $validated['zonal'];
            }
            if (array_key_exists('accion', $validated)) {
                $row->ACCION = $validated['accion'];
            }
            if (array_key_exists('dni', $validated)) {
                $row->DNI = (int) $validated['dni'];
            }
            if (array_key_exists('recargador_celular', $validated)) {
                $row->RECARGADOR_CELULAR = $validated['recargador_celular'];
            }
            if (array_key_exists('monto', $validated)) {
                $row->MONTO = $validated['monto'];
            }
            if (array_key_exists('se_abono', $validated)) {
                $row->SE_ABONO = ((bool) $validated['se_abono']) ? 1 : 0;
            }

            $row->save();
            $row->refresh(); // Recargar para obtener datos actualizados

            return response()->json([
                "status" => Response::HTTP_OK,
                "message" => "Registro actualizado",
                "data" => $this->transformData($row),
            ], Response::HTTP_OK);
        } catch (\Exception $ex) {
            return response()->json([
                "status" => Response::HTTP_BAD_REQUEST,
                "message" => $ex->getMessage(),
            ], Response::HTTP_BAD_REQUEST);
        }
    }

    public function destroy($id)
    {
        try {
            $row = AbonoInicialPostpago::find($id);
            if (!$row) {
                return response()->json([
                    "status" => Response::HTTP_NOT_FOUND,
                    "message" => "Registro no encontrado",
                ], Response::HTTP_NOT_FOUND);
            }

            $row->delete();
            return response()->json([
                "status" => Response::HTTP_OK,
                "message" => "Registro eliminado",
            ], Response::HTTP_OK);
        } catch (\Exception $ex) {
            return response()->json([
                "status" => Response::HTTP_BAD_REQUEST,
                "message" => $ex->getMessage(),
            ], Response::HTTP_BAD_REQUEST);
        }
    }

    public function autocompletar($dni)
    {
        try {
            $dniInt = (int) $dni;

            // Query con LEFT JOIN para obtener datos de PDV_OUT_ENTREGABLE y BASE_RECARGADORES
            $result = PDV_ENTREGABLE::select(
                'PDV_OUT_ENTREGABLE.ZONAL',
                'PDV_OUT_ENTREGABLE.ACCION_1',
                'BASE_RECARGADORES.NUM_RECARGA'
            )
                ->leftJoin('PORTAL_COMERCIAL.dbo.BASE_RECARGADORES', function ($join) {
                    $join->on('PDV_OUT_ENTREGABLE.DNI_RESPONSABLE', '=', 'BASE_RECARGADORES.DNI');
                })
                ->where('PDV_OUT_ENTREGABLE.DNI_RESPONSABLE', $dniInt)
                ->orderBy('PDV_OUT_ENTREGABLE.AÑO', 'desc')
                ->orderBy('PDV_OUT_ENTREGABLE.MES', 'desc')
                ->first();

            if (!$result) {
                return response()->json([
                    "status" => Response::HTTP_OK,
                    "message" => "No se encontraron datos para el DNI proporcionado",
                    "data" => null,
                ], Response::HTTP_OK);
            }

            // Convertir NUM_RECARGA a string y validar formato
            $recargador = null;
            if ($result->NUM_RECARGA) {
                $recargadorStr = (string) $result->NUM_RECARGA;
                // Si tiene menos de 9 dígitos, rellenar con ceros a la izquierda
                $recargador = str_pad($recargadorStr, 9, '0', STR_PAD_LEFT);
            }

            return response()->json([
                "status" => Response::HTTP_OK,
                "message" => "Datos obtenidos correctamente",
                "data" => [
                    "zonal" => $result->ZONAL,
                    "accion" => $result->ACCION_1,
                    "recargador_celular" => $recargador,
                ],
            ], Response::HTTP_OK);
        } catch (\Exception $ex) {
            Log::error('Error en autocompletar AbonoInicialPostpago: ' . $ex->getMessage());
            return response()->json([
                "status" => Response::HTTP_INTERNAL_SERVER_ERROR,
                "message" => "Error al obtener datos: " . $ex->getMessage(),
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Exportar datos a Excel
     */
    public function export()
    {
        try {
            $nombreArchivo = 'abono_inicial_postpago_' . date('Y-m-d_His') . '.xlsx';
            return Excel::download(new AbonoInicialPostpagoExport(), $nombreArchivo);
        } catch (\Exception $ex) {
            // Intentar loggear solo si no es un error de permisos
            try {
                if (strpos($ex->getMessage(), 'Permission denied') === false) {
                    Log::error('Error en export AbonoInicialPostpago: ' . $ex->getMessage());
                }
            } catch (\Exception $logEx) {
                // Ignorar errores de log si no hay permisos
            }

            $errorMessage = $ex->getMessage();
            if (strpos($errorMessage, 'Permission denied') !== false) {
                $errorMessage = 'Error de permisos en el servidor. Contacte al administrador del sistema.';
            }

            return response()->json([
                "status" => Response::HTTP_INTERNAL_SERVER_ERROR,
                "message" => "Error al exportar datos: " . (app()->environment('production') ? 'Contacte a soporte.' : $errorMessage),
            ], Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }
}
