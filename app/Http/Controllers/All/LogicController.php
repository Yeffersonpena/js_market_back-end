<?php

namespace App\Http\Controllers\All;

use App\Http\Controllers\Controller;
use App\Models\PDV_ABONOS;
use App\Models\PDV_AVANCES_DIARIOS_MM;
use App\Models\VI_AVANCES_DIARIOS;
use App\Models\VI_FLYERS;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class LogicController extends Controller
{
    public function getAvanceDiario($dni){
        // return response()->json(["status" => Response::HTTP_OK, "message" => "usuario creado"], Response::HTTP_OK);
        try{

            $existeAvance = VI_AVANCES_DIARIOS::where('DNI_Responsable', $dni)->exists();
            // return response()->json($avances);
            if($existeAvance){
                $avances = VI_AVANCES_DIARIOS::where('DNI_Responsable', $dni)->get();
                $avances->makeHidden(['id', 'DNI ']);
            return response()->json(["status" => Response::HTTP_OK, "message" => "Avance Diario MM", "data"=>$avances], Response::HTTP_OK);
        } else {
            return response()->json(["status" => Response::HTTP_UNAUTHORIZED, "message" => "No hay avance diario para el usuario ".$dni], Response::HTTP_UNAUTHORIZED);
        }

        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST,"message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
       
    }
    
    public function getHistoryVenta($dni, $anio, $mes){
        try{
            $existeAvance = VI_AVANCES_DIARIOS::where('DNI_Responsable', $dni)->where('año', '=', $anio)->where('mes','=',$mes)->exists();
            if($existeAvance){
                $avances = VI_AVANCES_DIARIOS::where('DNI_Responsable', $dni)->where('año', '=', $anio)->where('mes','=',$mes)->orderBy('FECHA','asc')->get();
                $avances->makeHidden(['id', 'canal', 'cluster', 'DNI_RESPONSABLE', 'Nombre AD', 'Vendedor AD', 'Cuota PDV', 'cuota_enero', 'Celular Vendedor AD', 'MAX_FECHA', 'RECARGAS']);
            return response()->json(["status" => Response::HTTP_OK, "message" => "Historial de Venta", "data"=>$avances], Response::HTTP_OK);
        } else {
            return response()->json(["status" => Response::HTTP_UNAUTHORIZED, "message" => "No hay historial de venta"], Response::HTTP_UNAUTHORIZED);
        }

        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST,"message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
       
    }
    
    public function getFlyers($dni, $anio, $mes){
        try{
            $avances = VI_FLYERS::where('DNI_Responsable', $dni)->where('año', '=', $anio)->where('mes','=',$mes)->get();
            $existeAvance = VI_FLYERS::where('DNI_Responsable', $dni)->exists();
            if($existeAvance){
            return response()->json(["status" => Response::HTTP_OK, "message" => "Fyers", "data"=>$avances], Response::HTTP_OK);
        } else {
            return response()->json(["status" => Response::HTTP_UNAUTHORIZED, "message" => "No hay fyers ".$dni], Response::HTTP_UNAUTHORIZED);
        }

        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST,"message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }
    public function getAbono($dni, $anio, $mes){
        try{
            $existeAbono = PDV_ABONOS::where('DNI', $dni)->where('año', '=', $anio)->where('mes','=',$mes)->exists();
            if($existeAbono){
                $abono = PDV_ABONOS::where('DNI', $dni)->where('año', '=', $anio)->where('mes','=',$mes)->get();
                $abono->makeHidden(['id', 'DNI ']);
            return response()->json(["status" => Response::HTTP_OK, "message" => "Historial de Abono", "data"=>$abono], Response::HTTP_OK);
        } else {
            return response()->json(["status" => Response::HTTP_UNAUTHORIZED, "message" => "No hay historial de Abono"], Response::HTTP_UNAUTHORIZED);
        }

        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST,"message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }
    public function getDataMM($dni, $anio, $mes){
        try{
            $avances = PDV_AVANCES_DIARIOS_MM::where('DNI VENDEDOR', $dni)->where('año', '=', $anio)->where('mes','=',$mes)->get();
            $existeAvance = PDV_AVANCES_DIARIOS_MM::where('DNI VENDEDOR', $dni)->where('año', '=', $anio)->where('mes','=',$mes)->exists();
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
