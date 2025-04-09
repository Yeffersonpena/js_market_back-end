<?php

namespace App\Http\Controllers\Admin;

use App\Exports\ReporteExport;
use App\Http\Controllers\Controller;
use App\Models\Reporte;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Maatwebsite\Excel\Facades\Excel;

class ReporteController extends Controller
{
    /**
     * Exporta los datos de usuarios a un archivo Excel.
     *
     * @return \Symfony\Component\HttpFoundation\StreamedResponse
     */
   

    public function reporteAll(){
        try{
            // $reporte=Reporte::all();
            // return $reporte;
            return Excel::download(new ReporteExport, 'reporte.xlsx');
        }catch(\Exception $ex){
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }
}
