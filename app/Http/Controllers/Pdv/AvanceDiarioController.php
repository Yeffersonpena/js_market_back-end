<?php

namespace App\Http\Controllers\Pdv;

use App\Http\Controllers\Controller;
use App\Models\PDV_ENTREGABLE;
use App\Models\VI_AVANCES_DIARIOS;
use App\Models\VI_AVANCES_INFO_VENDEDOR;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class AvanceDiarioController extends Controller
{
    public function day($dni){
        $avances = VI_AVANCES_DIARIOS::where('dni', $dni)->get();
        return response()->json($avances);
    }
    // public function getAllMonto($dni, $anio, $mes){
    //     $avances = VI_AVANCES_DIARIOS::where('dni', $dni)->get();
    //     return response()->json($avances);
    // }
    
    public function getAllMonto($dni, $anio, $mes){
        // return response()->json(["status" => Response::HTTP_OK, "message" => "usuario creado"], Response::HTTP_OK);
        try{

            $existeAvance = VI_AVANCES_DIARIOS::where('DNI_Responsable', $dni)->exists();
            // return response()->json($avances);
            if($existeAvance){
                $avances = VI_AVANCES_DIARIOS::where('DNI_Responsable', $dni)->get();
                $avances->makeHidden(['id', 'DNI ']);
                $totales = [
                    'ALTA PREPAGO' => 0,
                    'PORTA PREPAGO' => 0,
                    'ALTA POSTPAGO' => 0,
                    'PORTA POSTPAGO' => 0,
                    // 'new_count' => 0
                ];
            // 
                foreach ($avances as $avance) {
                   // $totales['']
                    $totales['ALTA PREPAGO'] += (int)$avance->ALTA_PREPAGO;
                    $totales['PORTA PREPAGO'] += (int)$avance->PORTA_PREPAGO;
                    $totales['ALTA POSTPAGO'] += (int)$avance->ALTA_POSTPAGO;
                    $totales['PORTA POSTPAGO'] += (int)$avance->PORTA_POSTPAGO;
                }
            
            return response()->json(["status" => Response::HTTP_OK, "message" => "Total --", "data"=>$totales], Response::HTTP_OK);
        } else {
            return response()->json(["status" => Response::HTTP_OK, "message" => "No hay avance diario para el usuario ".$dni], Response::HTTP_OK);
        }

        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST,"message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
       
    }
    public function getDataPdv($dni, $anio, $mes){
        try{
          /*  $avances = VI_AVANCES_DIARIOS::where('DNI_RESPONSABLE', $dni)->where('año', '=', $anio)->where('mes','=',$mes)->get();
            $existeAvance = VI_AVANCES_DIARIOS::where('DNI_RESPONSABLE', $dni)->where('año', '=', $anio)->where('mes','=',$mes)->exists();
           */
          ///
        //    $avances = PDV_ENTREGABLE::where('DNI_RESPONSABLE', $dni)->where('año', '=', $anio)->where('mes','=',$mes)->get();
        //    $existeAvance = PDV_ENTREGABLE::where('DNI_RESPONSABLE', $dni)->where('año', '=', $anio)->where('mes','=',$mes)->exists();
        //    if($existeAvance){
        //        $infoClient = [
        //            "fecha"=>$avances[0]->FECHA_INICIO,
        //            "nombrePDV"=> $avances[0]->NOMBRE_VENDEDOR1,
        //            "dniResponsable"=>$avances[0]->DNI_RESPONSABLE,
        //            "vendedor"=>$avances[0]->DNI_VENDEDOR
        //            /* 
        //            "celularVendedor"=>$avances[0]->
        //            "canal"=>$avances[0]->
        //            "cluster"=>$avances[0]->CLUSTER_PDV_REGULAR,
        //            "cuotaPrepago"=>$avances[0]->
        //            "avancePrepago"=>$avances[0]->
        //            "recargasTotales"=>$avances[0]->
                   
        //            "status" =>
        //            */
        //         ];
        //     }
        $existeAvance = VI_AVANCES_INFO_VENDEDOR::where('DNI_RESPONSABLE', $dni)->exists();
        
        if($existeAvance){
                $infoVendedor = VI_AVANCES_INFO_VENDEDOR::where('DNI_RESPONSABLE', $dni)->firstOrFail();
                $infoVendedor->cuota_pre=30;
                $infoVendedor->avance_pre=19;
                $infoVendedor=[
                    "fecha"=> $infoVendedor->ULTIMA_FECHA,
                    "nombrePDV"=> $infoVendedor->NOMBRE_RESPONSABLE,
                    "dniResponsable"=> $infoVendedor->DNI_RESPONSABLE,
                    "vendedor"=> $infoVendedor->NOMBRE_VENDEDOR1,
                    "celularVendedor"=> $infoVendedor->CELULAR_VENDEDOR,
                    "canal"=> $infoVendedor->ACCION,
                    "cluster"=> $infoVendedor->CLUSTER_PDV_REGULAR,
                    "cuotaPrepago"=>(float)$infoVendedor->CUOTA_PREPAGO,
                    "avancePrepago"=>(float)$infoVendedor->{'AVANCE PREPAGO'},
                    "recargasTotales"=>(float)$infoVendedor->RECARGA_TOTAL
                ];
            return response()->json(["status" => Response::HTTP_OK, "message" => "Información", "data"=>$infoVendedor ], Response::HTTP_OK);
        } else {
            return response()->json(["status" => Response::HTTP_OK, "message" => "No hay información"], Response::HTTP_OK);
        }
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST,"message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }   
}
