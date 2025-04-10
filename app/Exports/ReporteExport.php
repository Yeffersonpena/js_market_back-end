<?php

namespace App\Exports;

use App\Models\Reporte;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithStyles;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;

class ReporteExport implements FromCollection, WithHeadings, WithStyles 
{
    protected $tipoReporte;
    public function __construct($tipoReporte=1)
    {
        $this->tipoReporte=$tipoReporte;
    }
    /**
    * @return \Illuminate\Support\Collection
    */
    public function collection()
    {
        // return Reporte::all();
        // return \App\Models\Reporte::select([
        $query = Reporte::select([
            'idPlantilla',
            'AÑO',
            'MES',
            'ZONAL',
            'DNI_RESPONSABLE',
            'NOMBRE_RESPONSABLE',
            'PROYECTO',
            'ESTADO',
            'AVANCE_PREPAGO',
            'RECARGAS',
            'RATIO',
            'PORTA_PRE',
            'ALTA_POST',
            'PORTA_POST_ORIGEN_POST',
            'PORTA_POST_ORIGEN_PRE',
            'BONO_PRE',
            'BONO_RC',
            'BONO_PORTA_PRE',
            'BONO_ALTA_POST',
            'BONO_PORTA_POST_ORIGEN_POST',
            'BONO_PORTA_POST_ORIGEN_PRE',
            'EFECTIVO_A_PAGAR'
        // ])->get();
        ]);
        
        if ($this->tipoReporte == 2) {
            $query->where('PROYECTO', 'PDV REGULAR');
        } elseif ($this->tipoReporte == 3) {
            $query->where('PROYECTO', 'like', '%PDV PREMIUM%');
        }
        return $query->get();
    }

    /**
     * head excel
     *
     * @return array
     */
    public function headings(): array
    {
        return [
            'idPlantilla',
            'AÑO',
            'MES',
            'ZONAL',
            'DNI_RESPONSABLE',
            'NOMBRE_RESPONSABLE',
            'PROYECTO',
            'ESTADO',
            'AVANCE_PREPAGO',
            'RECARGAS',
            'RATIO',
            'PORTA_PRE',
            'ALTA_POST',
            'PORTA_POST_ORIGEN_POST',
            'PORTA_POST_ORIGEN_PRE',
            'BONO_PRE',
            'BONO_RC',
            'BONO_PORTA_PRE',
            'BONO_ALTA_POST',
            'BONO_PORTA_POST_ORIGEN_POST',
            'BONO_PORTA_POST_ORIGEN_PRE',
            'EFECTIVO_A_PAGAR'
        ];
    }

     /**
     * style excel
     */
    public function styles(Worksheet $sheet)
    {
        $sheet->getRowDimension(1)->setRowHeight(30); 
        foreach (range('A', $sheet->getHighestColumn()) as $col) {
            $sheet->getColumnDimension($col)->setAutoSize(true);
        }

        $sheet->getStyle('A1:' . $sheet->getHighestColumn() . $sheet->getHighestRow())
            ->getAlignment()
            ->setWrapText(true);

        return [
            1 => [
                'font' => [
                    'bold' => true,
                    'color' => ['rgb' => 'FFFFFF'],
                ],
                'fill' => [
                    'fillType' => \PhpOffice\PhpSpreadsheet\Style\Fill::FILL_SOLID,
                    'startColor' => ['rgb' => '16d52e'], 
                ],
                'borders' => [
                'allBorders' => [
                    'borderStyle' => \PhpOffice\PhpSpreadsheet\Style\Border::BORDER_THIN,
                    'color' => ['rgb' => '000000'],
                    ],
                ],
                'alignment' => [
                'vertical' => \PhpOffice\PhpSpreadsheet\Style\Alignment::VERTICAL_CENTER,
                ],  
            ],
        ];
    }
    
}
