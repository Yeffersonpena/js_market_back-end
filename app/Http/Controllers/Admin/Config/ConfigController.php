<?php

namespace App\Http\Controllers\Admin\Config;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\DB;

class ConfigController extends Controller
{
    function getListConfig(){
        try{
            // $listGroup = DB::select('EXEC dbo.spGetListGroup');
            $listGroup = DB::select('
                WITH UltimoPeriodo AS (
                SELECT TOP 1 año, mes FROM dbo.PDV_OUT_ENTREGABLE WHERE año IS NOT NULL AND mes IS NOT NULL ORDER BY año DESC, mes DESC)
                SELECT DISTINCT e.GRUPO FROM dbo.PDV_OUT_ENTREGABLE e JOIN UltimoPeriodo u ON e.año = u.año AND e.mes = u.mes
                WHERE e.GRUPO IS NOT NULL ORDER BY e.GRUPO;');
            if($listGroup){
                return response()->json(["status"=>Response::HTTP_OK, "message"=>"Existe lista de grupos", "data"=>$listGroup],Response::HTTP_OK); 
            }else{
                return response()->json(["status"=>Response::HTTP_OK, "message"=>"No hay group", "data"=>[]],Response::HTTP_OK,); 
            }
        }catch(\Exception $ex){
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }
}
