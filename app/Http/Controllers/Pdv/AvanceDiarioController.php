<?php

namespace App\Http\Controllers\Pdv;

use App\Http\Controllers\Controller;
use App\Models\VI_AVANCES_DIARIOS;
use Illuminate\Http\Request;

class AvanceDiarioController extends Controller
{
    public function day($dni){
        $avances = VI_AVANCES_DIARIOS::where('dni', $dni)->get();
        return response()->json($avances);
    }
}
