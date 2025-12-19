<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AbonoInicialPostpago;
use Carbon\Carbon;
use Illuminate\Http\Request;
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

        return [
            'id' => $row->ID,
            'fecha_hora_recarga' => $row->FECHA_HORA_RECARGA ? $row->FECHA_HORA_RECARGA->toIso8601String() : null,
            'zonal' => $row->ZONAL,
            'accion' => $row->ACCION,
            'dni' => $row->DNI,
            'recargador_celular' => $row->RECARGADOR_CELULAR,
            'monto' => (float) $row->MONTO,
            'se_abono' => (bool) $row->SE_ABONO,
            'fecha_carga' => $row->FECHA_CARGA ? $row->FECHA_CARGA->toIso8601String() : null,
        ];
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
                        ->orWhere('ACCION', 'LIKE', "%$search%")
                        ->orWhere('RECARGADOR_CELULAR', 'LIKE', "%$search%");
                });
            }

            // Rango de fechas (acepta date o datetime)
            $desde = $request->input('desde');
            if ($desde !== null && $desde !== '') {
                $query->where('FECHA_HORA_RECARGA', '>=', Carbon::parse($desde));
            }
            $hasta = $request->input('hasta');
            if ($hasta !== null && $hasta !== '') {
                $query->where('FECHA_HORA_RECARGA', '<=', Carbon::parse($hasta));
            }

            $perPage = (int) $request->input('per_page', 10);
            $perPage = $perPage > 0 ? min($perPage, 100) : 10;

            $rows = $query->orderBy('FECHA_HORA_RECARGA', 'desc')->paginate($perPage);

            // Transformar los datos a snake_case en minúsculas
            $transformedData = array_map(function ($item) {
                return $this->transformData($item);
            }, $rows->items());

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
            return response()->json([
                "status" => Response::HTTP_BAD_REQUEST,
                "message" => $ex->getMessage(),
            ], Response::HTTP_BAD_REQUEST);
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
            $validated = $request->validate([
                'fecha_hora_recarga' => 'required|date',
                'zonal' => 'nullable|string|max:100',
                'accion' => 'nullable|string|max:50',
                'dni' => 'required|integer',
                'recargador_celular' => ['required', 'string', 'regex:/^[0-9]{9}$/'],
                'monto' => 'required|numeric',
                'se_abono' => 'nullable|boolean',
            ]);

            $row = new AbonoInicialPostpago();
            $row->FECHA_HORA_RECARGA = Carbon::parse($validated['fecha_hora_recarga']);
            $row->ZONAL = $validated['zonal'] ?? null;
            $row->ACCION = $validated['accion'] ?? null;
            $row->DNI = (int) $validated['dni'];
            $row->RECARGADOR_CELULAR = $validated['recargador_celular'];
            $row->MONTO = $validated['monto'];
            $row->SE_ABONO = array_key_exists('se_abono', $validated) ? ((bool) $validated['se_abono'] ? 1 : 0) : 0;
            $row->save();
            $row->refresh(); // Recargar para obtener FECHA_CARGA

            return response()->json([
                "status" => Response::HTTP_CREATED,
                "message" => "Registro creado",
                "data" => $this->transformData($row),
            ], Response::HTTP_CREATED);
        } catch (\Exception $ex) {
            return response()->json([
                "status" => Response::HTTP_BAD_REQUEST,
                "message" => $ex->getMessage(),
            ], Response::HTTP_BAD_REQUEST);
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
}
