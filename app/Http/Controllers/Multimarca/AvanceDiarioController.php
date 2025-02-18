<?php

namespace App\Http\Controllers\Multimarca;

use App\Http\Controllers\Controller;
use App\Models\VI_AVANCES_DIARIOS;
use App\Models\VI_FLYERS;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class AvanceDiarioController extends Controller
{
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
