<?php

namespace App\Http\Controllers\Admin;

use App\Exports\Finanza\ReporteFinanzaExport;
use App\Exports\ReporteExport;
use App\Exports\ReporteMultimarcaExport;
use App\Exports\ReportePdvExport;
use App\Exports\ReportePdvPremiun;
use App\Exports\ReportePdvRegular;
use App\Http\Controllers\Controller;
use App\Models\Reporte;
use App\Models\ReporteMultimarca;
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


    public function reporteAll()
    {
        try {
            // $reporte=Reporte::all();
            // return $reporte;
            // $nombreArchivo = match ($tipo) {
            //     2 => 'reportePdvRegular.xlsx',
            //     3 => 'reportePdvPremium.xlsx',
            //     default => 'reporteCompleto.xlsx',
            // };
            return Excel::download(new ReporteExport(1), 'reporte.xlsx');
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }

    public function reportePdvRegular()
    {
        try {
            return Excel::download(new ReporteExport(2), 'reportePdvRegular.xlsx');
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }

    public function reportePremiun()
    {
        try {
            return Excel::download(new ReporteExport(3), 'reportePremiun.xlsx');
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }

    public function getReporte($typeReporte)
    {
        try {
            // $reporte=ReporteMultimarca::all();
            // return $reporte;
            $nameFile = match ($typeReporte) {
                2 => 'reporteMmPre.xlsx',
                3 => 'reporteMmPost.xlsx',
                default => 'reporteCompletoMm.xlsx',
            };
            // return $nameFile;
            return Excel::download(new ReporteMultimarcaExport($typeReporte), '' . $nameFile);
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }
    public function getReportePdv($typeReporte)
    {
        try {
            $nameFile = match ($typeReporte) {
                2 => 'reportePdvRegular.xlsx',
                3 => 'reportePdvPremium.xlsx',
                default => 'reporteCompletoPdv.xlsx',
            };
            return Excel::download(new ReportePdvExport($typeReporte), '' . $nameFile);
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }

    public function getReporteFinanza($typeReporte, $anio, $mes)
    {
        try {
            $dateFileLoad = '2025-05-22';
            $nameFile = match ($typeReporte) {
                2 => 'reportePdvRegular.xlsx',
                3 => 'reportePdvPremium.xlsx',
                default => 'reporteCompletoFinanza.xlsx',
            };
            return Excel::download(new ReporteFinanzaExport($typeReporte, $anio, $mes, $dateFileLoad), '' . $nameFile);
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }
}
