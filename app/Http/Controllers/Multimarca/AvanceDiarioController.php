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
        function getPayment($dni, $anio, $mes){
                try{
                    // $existePayment = VI_PDV_PAYMENT::where('DNI', $dni)->where('año', '=', $anio)->where('mes', '=', $mes)->exists();
                    $spPayment=DB::select("exec spCalculoPaymentMM ?,?,?", [$dni, $anio, $mes]);
                    // return $spPayment;
                    if ($spPayment) {
                            $acumuladorPayment = [
                                // "unitarioRec" => 0.0,

                                // "cantidadPortaPre": "0",
                                // "precioUniPortaPre": ".00",
                                // "faltaVenta": "0",
                                // "precioUniSchema": ".00",
                                // "cantidadRecarga": "1",
                                // "bonoPre": ".00",
                                // "bonoRecargaPre": "2.50",
                                // "bonoPortaPre": ".00",
                                // "tipoMultimarca": "multimarca",
                                // "bonoChips": "4",
                                // "bonoTotalEfectivo": "2.50",
                                // "bonoTotal": "6.50"

                                "bonoPre" => 0.0,
                                "bonoRecargaPre" => 0.0,
                                "bonoPortaPre" => 0.0,
                                "bonoAltaPost" => 0.0,
                                "bonoPortaPostOPost" => 0.0,
                                "bonoPortaPostOPre" => 0.0,
                                "bonoChips"=>0.00,
                                "bonoTotalEfectivo"=>0.00,
                                "bonoTotal"=>0.00,
                                "ventaTotal"=>0.00,
                                // "precioUni"=>0.00,
                                // 
                                "faltaVenta"=>0.00,
                                "cantidadPortaPre"=>0.00,
                                "precioUniPortaPre"=>0.00,
                                "cantidadAltaPost"=>0.00,
                                "precioUniAltaPost"=>0.00,
                                "cantidadPortaPostOPost"=>0.00,
                                "precioPortaPostOPost"=>0.00,
                                "cantidadPortaPostOPre"=>0.00,
                                "precioPortaPostOPre"=>0.00,
                                "precioUniSchema"=>0.00,
                                "levelUser"=>0.00,
                                "cantidadRecarga"=>0.00,
        
                            ];
                        // return response()->json(["status" => Response::HTTP_OK, "message" => "Hay pago para el vendedor Pdv", "data" => $acumuladorPayment], Response::HTTP_OK);
                            foreach ($spPayment as $item) {
                                // return $item;
                                // return $spPayment;
                                
                                // $acumuladorPayment["unitarioRec"] += $item->unitarioRec ? (float) $item->unitarioRec : 0.0;
                                $acumuladorPayment["bonoPre"] += $item->bonoPre ? (float) $item->bonoPre : 0.0;
                                $acumuladorPayment["bonoRecargaPre"] += $item->bonoRecargaPre ? (float) $item->bonoRecargaPre : 0.0;
                                $acumuladorPayment["bonoPortaPre"] += $item->bonoPortaPre ? (float) $item->bonoPortaPre : 0.0;
                                // $acumuladorPayment["bonoAltaPost"] += $item->bonoAltaPost ? (float) $item->bonoAltaPost : 0.0;
                                $acumuladorPayment["bonoPortaPostOPost"] += $item->bonoPortaPostOPost ? (float) $item->bonoPortaPostOPost : 0.0;
                                $acumuladorPayment["bonoPortaPostOPre"] += $item->bonoPortaPostOPre ? (float) $item->bonoPortaPostOPre : 0.0;
                                $acumuladorPayment["bonoChips"] += $item->bonoChips ? (float) $item->bonoChips : 0.0;
                                $acumuladorPayment["bonoTotalEfectivo"] += $item->bonoTotalEfectivo ? (float) $item->bonoTotalEfectivo : 0.0;
                                $acumuladorPayment["bonoTotal"] += $item->bonoTotal ? (float) $item->bonoTotal : 0.0;
                                // // 
                                // $acumuladorPayment["faltaVenta"] = (float) $item->faltaVenta;
                                $acumuladorPayment["cantidadPortaPre"] = (float) $item->cantidadPortaPre;
                                $acumuladorPayment["precioUniPortaPre"] =(float) $item->precioUniPortaPre;
                                // $acumuladorPayment["cantidadAltaPost"] =(float) $item->cantidadAltaPost;
                                // $acumuladorPayment["precioUniAltaPost"] =(float) $item->precioUniAltaPost;
                                $acumuladorPayment["cantidadPortaPostOPost"] =(float) $item->cantidadPortaPostOPost;
                                $acumuladorPayment["precioPortaPostOPost"] =(float) $item->precioPortaPostOPost;
                                $acumuladorPayment["cantidadPortaPostOPre"] =(float) $item->cantidadPortaPostOPre;
                                $acumuladorPayment["precioPortaPostOPre"] =(float) $item->precioPortaPostOPre;
                                $acumuladorPayment["precioUniSchema"] =(float) $item->precioUniSchema;
                                // $acumuladorPayment["levelUser"] =(float) $item->levelUser;
                                $acumuladorPayment["cantidadRecarga"] =(float) $item->cantidadRecarga;
                                $acumuladorPayment["cantidadRecarga"] =(float) $item->cantidadRecarga;
                                $acumuladorPayment["ventaTotal"] =(float) $item->bonoChips;
        
                                
                            }
                            // $payment= $spPayment;
                            $payment= $acumuladorPayment;
                        return response()->json(["status" => Response::HTTP_OK, "message" => "Hay pago para el vendedor Pdv", "data" => $payment], Response::HTTP_OK);
                    } else {
                        return response()->json(["status" => Response::HTTP_OK, "message" => "No hay pagos ", "data" => []], Response::HTTP_OK);
                    }
                }catch(\Exception $ex){
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
