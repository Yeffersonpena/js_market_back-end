<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ImportacionController extends Controller
{
    public function getLogActual()
    {
        try {
            $logs = DB::select("
                SELECT idLog, nombre_procedimiento 
                FROM tbl_log_procedimientos 
                WHERE CAST(fecha_hora_registro AS DATE) = CAST(GETDATE() AS DATE)
            ");

            return response()->json($logs);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 500,
                'message' => 'Error al obtener los logs',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
