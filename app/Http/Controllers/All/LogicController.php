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
        try{

            $existeAvance = VI_AVANCES_DIARIOS::where('DNI_Responsable', $dni)->exists();
            if($existeAvance){
                $avances = VI_AVANCES_DIARIOS::where('DNI_Responsable', $dni)->get();
                // return response()->json($avances);
                $avances->makeHidden(['id', 'DNI ', 'MAX_FECHA']);
                $avances= $avances->map(function ($item){
                    return [
                        "fecha"=>$item->FECHA,
                        "altaPrepago"=>(float)$item->{"ALTA PREPAGO"},
                        "portaPrepago"=>(float)$item->{"PORTA PREPAGO"},
                        "altaPostpago"=>(float)$item->{"ALTA POSTPAGO"},
                        "portaPostpago"=>(float)$item->{"PORTA POSTPAGO"},
                    ];
                    
                });
            return response()->json(["status" => Response::HTTP_OK, "message" => "Avance Diario", "data"=>$avances], Response::HTTP_OK);
        } else {
            return response()->json(["status" => Response::HTTP_OK, "message" => "No hay avance diario para el usuario ".$dni], Response::HTTP_OK);
        }

        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST,"message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
       
    }
    
    public function getHistoryVenta($dni, $anio, $mes){
        try{
            // $existeAvance = VI_AVANCES_DIARIOS::where('DNI_Responsable', $dni)->where('año', '=', $anio)->where('mes','=',$mes)->exists();
            $existeAvance = VI_AVANCES_DIARIOS::where('DNI_Responsable', $dni)->exists();
            if($existeAvance){
                // $avances->makeHidden(['id', 'canal', 'cluster', 'DNI_RESPONSABLE', 'Nombre AD', 'Vendedor AD', 'Cuota PDV', 'cuota_enero', 'Celular Vendedor AD', 'MAX_FECHA', 'RECARGAS']);
                $avances = VI_AVANCES_DIARIOS::where('DNI_Responsable', $dni)->orderBy('FECHA','asc')->get();
                $avances->makeHidden(['id', 'DNI ', 'MAX_FECHA']);
                $avances= $avances->map(function ($item){
                    return [
                        "fecha"=>$item->FECHA,
                        "altaPrepago"=>(float)$item->{"ALTA PREPAGO"},
                        "portaPrepago"=>(float)$item->{"PORTA PREPAGO"},
                        "altaPostpago"=>(float)$item->{"ALTA POSTPAGO"},
                        "portaPostpago"=>(float)$item->{"PORTA POSTPAGO"},
                    ];
                    
                });
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
                $abono->makeHidden(['DNI ']);
                $abono=$abono->map(function ($item){
                    return ["id"=>$item->id,
                    "detalle"=>$item->DETALLE,
                    "estado"=>$item->{"STATUS DEL ABONO"},
                    "total" => (float)$item->{"BONO TOTAL"}
                ];
                });
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
