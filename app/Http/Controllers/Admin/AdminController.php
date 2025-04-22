<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\DB;

class AdminController extends Controller
{
    function getListGroup(){
        try{
            $listGroup = DB::select('EXEC dbo.spGetListGroup');
            if($listGroup){
                return response()->json(["status"=>Response::HTTP_OK, "message"=>"Existe lista de grupos", "data"=>$listGroup],Response::HTTP_OK); 
            }else{
                return response()->json(["status"=>Response::HTTP_OK, "message"=>"No hay group", "data"=>[]],Response::HTTP_OK,); 
            }
        }catch(\Exception $ex){
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }
    public function getListFlyers($dateStart)
    {
        try {
            $listGroup = DB::select('
                select distinct e.foto_esquema,e.fecha_inicio,e.fecha_fin,e.tipoImg 
                from dbo.PDV_OUT_FLYERS e WHERE fecha_inicio=?
                order by e.fecha_inicio desc;',[$dateStart]);
            if ($listGroup) {
                return response()->json(["status" => Response::HTTP_OK, "message" => "Fyers", "data" => $listGroup], Response::HTTP_OK);
            } else {
                return response()->json(["status" => Response::HTTP_OK, "message" => "No hay fyers para la fecha " . $dateStart, "data" => []], Response::HTTP_OK);
            }
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }
}
