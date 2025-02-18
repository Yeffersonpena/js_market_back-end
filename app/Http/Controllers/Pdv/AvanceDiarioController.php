<?php

namespace App\Http\Controllers\Pdv;

use App\Http\Controllers\Controller;
use App\Models\VI_AVANCES_DIARIOS;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class AvanceDiarioController extends Controller
{
    public function day($dni){
        $avances = VI_AVANCES_DIARIOS::where('dni', $dni)->get();
        return response()->json($avances);
    }
    public function getDataPdv($dni, $anio, $mes){
        try{
            $avances = VI_AVANCES_DIARIOS::where('DNI_RESPONSABLE', $dni)->where('año', '=', $anio)->where('mes','=',$mes)->get();
            $existeAvance = VI_AVANCES_DIARIOS::where('DNI_RESPONSABLE', $dni)->where('año', '=', $anio)->where('mes','=',$mes)->exists();
            if($existeAvance){
            return response()->json(["status" => Response::HTTP_OK, "message" => "Información", "data"=>$avances], Response::HTTP_OK);
        } else {
            return response()->json(["status" => Response::HTTP_UNAUTHORIZED, "message" => "No hay información"], Response::HTTP_UNAUTHORIZED);
        }
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST,"message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }   
}
