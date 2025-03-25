<?php

namespace App\Http\Controllers\Multimarca;

use App\Http\Controllers\Controller;
use App\Models\VI_AVANCES_DIARIOS;
use App\Models\VI_FLYERS;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\Response;

class AvanceDiarioController extends Controller
{
        public function getDataMM($dni, $anio, $mes)
        {
        try {
                $existeAvance = DB::select( "EXEC spViewInfoVendedorMM ?, ?, ?", [$dni, $anio, $mes]);
                if($existeAvance){
                $infoVendedor=$existeAvance[0];
                    $infoVendedor=[
                            "zonal" => $infoVendedor->ZONAL,
                            "dni_responsable" => $infoVendedor->{'DNI_RESPONSABLE'},
                            "dni_vendedor" => $infoVendedor->{'DNI_VENDEDOR'},
                            "nombre_vendedor" => $infoVendedor->{'NOMBRE_VENDEDOR'},
                            "supervisor" => $infoVendedor->{'NOMBRE_SUPERVISOR'},
                            "celularVendedor"=> $infoVendedor->CELULAR_VENDEDOR !=0 ? $infoVendedor->CELULAR_VENDEDOR: "" ,
                            "proyecto" => $infoVendedor->{'ACCION_2'},
                            "cuotaPrepago"=>(float)$infoVendedor->CUOTA_PREPAGO,
                            "recargasTotales"=>(float)$infoVendedor->RECARGA_TOTAL,
                            "avancePrepago"=>(float)$infoVendedor->{'AVANCE PREPAGO'},
                            "fecha_inicio" => $infoVendedor->FECHA_INICIO,
                            "fecha_cierre"=> $infoVendedor->ULTIMA_FECHA,
                        ];
                return response()->json(["status" => Response::HTTP_OK, "message" => "Información", "data"=>$infoVendedor ], Response::HTTP_OK);
                } else {
                return response()->json(["status" => Response::HTTP_OK, "message" => "No hay información","data"=>[]], Response::HTTP_OK);
                }
        } catch (\Exception $ex) {
                return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
        }

        // public function getAvanceDiario($dni){
        //     // return response()->json(["status" => Response::HTTP_OK, "message" => "usuario creado"], Response::HTTP_OK);
        //     try{

        //         $avances = VI_AVANCES_DIARIOS::where('DNI_Responsable', $dni)->get();
        //         $existeAvance = VI_AVANCES_DIARIOS::where('DNI_Responsable', $dni)->exists();
        //         // return response()->json($avances);
        //         if($existeAvance){
        //         return response()->json(["status" => Response::HTTP_OK, "message" => "Avance Diario MM", "data"=>$avances], Response::HTTP_OK);
        //     } else {
        //         return response()->json(["status" => Response::HTTP_UNAUTHORIZED, "message" => "No hay avance diario para el usuario ".$dni], Response::HTTP_UNAUTHORIZED);
        //     }

        //     } catch (\Exception $ex) {
        //         return response()->json(["status" => Response::HTTP_BAD_REQUEST,"message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        //     }
           
                    
        // }

       

        
}
