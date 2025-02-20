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
            $existeAvance = VI_AVANCES_DIARIOS::where('DNI_Responsable', $dni)->whereYear('FECHA', $anio)->whereMonth('FECHA', $mes)->exists();
            if($existeAvance){
                // $avances->makeHidden(['id', 'canal', 'cluster', 'DNI_RESPONSABLE', 'Nombre AD', 'Vendedor AD', 'Cuota PDV', 'cuota_enero', 'Celular Vendedor AD', 'MAX_FECHA', 'RECARGAS']);
                $avances = VI_AVANCES_DIARIOS::where('DNI_Responsable', $dni)->whereYear('FECHA', $anio)->whereMonth('FECHA', $mes)->orderBy('FECHA','asc')->get();
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
            return response()->json(["status" => Response::HTTP_OK, "message" => "No hay historial de venta"], Response::HTTP_OK);
        }

        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST,"message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
       
    }
    
    public function getFlyers($dni, $anio, $mes){
        try{
            $existeAvance = VI_FLYERS::where('DNI_Responsable', $dni)->exists();
            if($existeAvance){
                $avances = VI_FLYERS::where('DNI_Responsable', $dni)->where('año', '=', $anio)->where('mes','=',$mes)->get();
                $avances= $avances->map(function ($item){
                  return [  "año"=>$item->año,
                    "mes"=>$item->mes,
                    "dni_responsable"=>$item->dni_responsable,
                    "zonal"=>$item->zonal,
                    // "foto_esquema"=>env('APP_DOMAIN').'/api/v1/pictures/img/'.$item->foto_esquema,
                    "foto_esquema"=>env('APP_DOMAIN').'/storage/img/'.$item->foto_esquema,
                    // http://127.0.0.1:8000/storage/img/Esquema_PDV_Febrero1.jpg
                    // http://127.0.0.1:8000/api/v1/pictures/img/Esquema_PDV_Febrero1.jpg
                    "fecha_inicio"=>$item->fecha_inicio,
                    "fecha_fin"=>$item->fecha_fin
                ];
                });
            return response()->json(["status" => Response::HTTP_OK, "message" => "Fyers", "data"=>$avances], Response::HTTP_OK);
        } else {
            return response()->json(["status" => Response::HTTP_OK, "message" => "No hay fyers ".$dni], Response::HTTP_OK);
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
            return response()->json(["status" => Response::HTTP_OK, "message" => "No hay historial de Abono"], Response::HTTP_OK);
        }

        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST,"message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }
    public function getDataMM($dni, $anio, $mes){
        try{
            $existeAvance = PDV_AVANCES_DIARIOS_MM::where('DNI VENDEDOR', $dni)->where('año', '=', $anio)->where('mes','=',$mes)->exists();
            if($existeAvance){
                $infoVendedor = PDV_AVANCES_DIARIOS_MM::where('DNI VENDEDOR', $dni)->where('año', '=', $anio)->where('mes','=',$mes)->firstOrFail();
                $infoVendedor=[
                    "zonal"=> $infoVendedor->ZONAL,
                    "dni_vendedor"=> $infoVendedor->{'DNI VENDEDOR'},
                    "nombre_vendedor"=> $infoVendedor->{'NOMBRE VENDEDOR'},
                    "fecha_inicio"=> $infoVendedor->{'FECHA INICIO'},
                    "dni_responsable"=> $infoVendedor->{'DNI RESPONSABLE'},
                    "supervisor"=> $infoVendedor->SUPERVISOR,
                    "proyecto"=> $infoVendedor->PROYECTO,
                    "prepago_total_1"=> (float)$infoVendedor->{'PREPAGO TOTAL'},
                    "porta_pre_1"=> (float)$infoVendedor->{'PORTA PRE'},
                    "recarga_total_1"=> (float)$infoVendedor->{'RECARGAS TOTAL'},
                    "porta_post_1"=> (float)$infoVendedor->{'PORTA POST'},
                    "rango_pre_total_2"=> $infoVendedor->{'RANGO PRE TOTAL'},
                    "rango_porta_pre_2"=> $infoVendedor->{'RANGO PORTA PRE'},
                    "rango_recarga_2"=> $infoVendedor->{'RANGO RECARGAS'},
                    "rango_final_2"=> $infoVendedor->{'RANGO FINAL'},
                    "bono_pre_3"=> (float)$infoVendedor->{'BONO PRE'},
                    "bono_porta_post_3"=> (float)$infoVendedor->{'BONO PORTA POST'},
                    "bono_adicional_porta_post_3"=> (float)$infoVendedor->{'BONO ADICIONAL PORTA POST'},
                    "bono_total_3"=> (float)$infoVendedor->{'BONO TOTAL'},
                    "raecarga_finaciada_3"=> (float)$infoVendedor->{'RECARGA FINANCIADA'},
                    "chips_financiados_3"=> (float)$infoVendedor->{'CHIPS FINANCIADO'},
                    "total_financiado_3"=> (float)$infoVendedor->{'TOTAL FINANCIADO'},
                    "bono_total_a_pagar_3"=> (float)$infoVendedor->{'BONO TOTAL A PAGAR'}
                ];
            return response()->json(["status" => Response::HTTP_OK, "message" => "Información", "data"=>$infoVendedor], Response::HTTP_OK);
        } else {
            return response()->json(["status" => Response::HTTP_OK, "message" => "No hay información"], Response::HTTP_OK);
        }
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST,"message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }
}
