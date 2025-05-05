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
    
    public function getListEntregable($dni, $anio, $mes){
        try{
            $getListEntregable=DB::connection('twoDb')->select('select * from dbo.PDV_OUT_ENTREGABLE where AÑO=? and mes=? and DNI_RESPONSABLE=?', [$anio, $mes, $dni]);
            
            if(!$getListEntregable){
                return response()->json(["status"=>200, "message"=>"No se encontro la lista de usuario", "data"=>[]], Response::HTTP_OK);
            }
            return response()->json(["status"=>200, "message"=>"Se encontro la lista de usuario", "data"=>$getListEntregable], Response::HTTP_OK);
        }catch(\Exception $ex){
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }
    
    public function getListFunnel($dni, $anio, $mes){
        try{
            $getListEntregable=DB::connection('twoDb')->select('select * from dbo.PP2025_FUNNEL where AÑO=? and mes=? and DNI_RESPONSABLE=?', [$anio, $mes, $dni]);
            if(!$getListEntregable){
                return response()->json(["status"=>200, "message"=>"No se encontro la lista de usuario", "data"=>[]], Response::HTTP_OK);
            }
            return response()->json(["status"=>200, "message"=>"Se encontro la lista de usuario", "data"=>$getListEntregable], Response::HTTP_OK);
        }catch(\Exception $ex){
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }
}
