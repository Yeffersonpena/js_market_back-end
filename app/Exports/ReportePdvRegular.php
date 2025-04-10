<?php

namespace App\Exports;

use App\Models\Reporte;
use Maatwebsite\Excel\Concerns\FromCollection;

class ReportePdvRegular implements FromCollection
{
    /**
    * @return \Illuminate\Support\Collection
    */
    public function collection()
    {
        return Reporte::where('PROYECTO','=','PDV REGULAR')->get();
    }
}
