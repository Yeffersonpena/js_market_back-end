<?php

namespace App\Http\Controllers;

use App\Models\RcFormulario;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\Response;
use Tymon\JWTAuth\Facades\JWTAuth;

class RecopilacionController extends Controller
{
    private function getZonalUsuario()
    {
        try {
            $user = JWTAuth::parseToken()->authenticate();
            return $user->zonal ?? null;
        } catch (\Exception $e) {
            return null;
        }
    }

    /**
     * Lista de puntos (RC_CLIENTE_PDV) de la zonal del usuario que aun no tienen
     * la recopilacion finalizada para el formulario y periodo dados.
     */
    public function puntosPendientes(Request $request)
    {
        $zonal = $this->getZonalUsuario();
        if (!$zonal) {
            return response()->json([
                'status' => Response::HTTP_UNAUTHORIZED,
                'message' => 'No se pudo obtener la zonal del usuario',
            ], Response::HTTP_UNAUTHORIZED);
        }

        $anio = (int) $request->get('anio', now()->year);
        $mes = (int) $request->get('mes', now()->month);
        $formularioCodigo = $request->get('formulario_codigo', 'DATOS_PDV_VENTAS');

        $formulario = RcFormulario::where('codigo', $formularioCodigo)
            ->where('activo', 1)
            ->orderByDesc('version')
            ->first();

        if (!$formulario) {
            return response()->json([
                'status' => Response::HTTP_UNPROCESSABLE_ENTITY,
                'message' => "No existe formulario activo con codigo {$formularioCodigo}",
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        $lista = DB::connection('sqlsrv')
            ->table('RC_CLIENTE_PDV as c')
            ->leftJoin('RC_VISITA_FORMULARIO as v', function ($join) use ($formulario, $anio, $mes) {
                $join->on('v.cliente_id', '=', 'c.id')
                    ->where('v.formulario_id', $formulario->id)
                    ->where('v.anio', $anio)
                    ->where('v.mes', $mes);
            })
            ->where('c.zonal', $zonal)
            ->where(function ($q) {
                $q->whereNull('v.id')
                    ->orWhere('v.estado', '!=', 'finalizado');
            })
            ->select(
                'c.id as cliente_id',
                'c.nro_documento',
                'c.nombre_pdv',
                'c.zonal',
                'v.id as visita_id',
                'v.estado as estado_visita',
                'v.porcentaje_avance',
                'v.fecha_ultima_edicion'
            )
            ->orderByRaw("CASE WHEN v.estado IS NULL THEN 0 WHEN v.estado = 'borrador' THEN 1 ELSE 2 END")
            ->orderByDesc('v.porcentaje_avance')
            ->orderBy('c.nombre_pdv')
            ->get();

        return response()->json([
            'status' => Response::HTTP_OK,
            'data' => $lista,
        ], Response::HTTP_OK);
    }
}
