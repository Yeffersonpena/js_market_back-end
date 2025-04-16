<?php

namespace App\Exports;

use App\Models\ReporteMultimarca;
use Maatwebsite\Excel\Concerns\FromCollection;
// 
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithStyles;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;
// 
use Maatwebsite\Excel\Concerns\WithColumnFormatting;
use PhpOffice\PhpSpreadsheet\Style\NumberFormat;

class ReporteMultimarcaExport implements FromCollection, WithHeadings, WithStyles, WithColumnFormatting
// class ReporteMultimarcaExport implements FromCollection, WithHeadings,WithColumnFormatting
// class ReporteMultimarcaExport implements FromCollection
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
        $query = ReporteMultimarca::select([
            "año",
            "mes",
            "zonal",
            "dni_vendedor",
            "nombre_vendedor",
            "fecha_inicio",
            "dni_responsable",
            "supervisor",
            "proyecto",
            "alta_pre",
            "porta_pre",
            "prepago_total",
            "recargas_total",
            "porcentaje_recargas",
            "regularidad",
            "q_recargas_n0_mayor",
            "q_ventas_marzo",
            "q_recargas_n1",
            "porcentaje_recargas_n1",
            "q_recargas_n1_mayor",
            "rango_pre_total",
            "rango_porta_pre",
            "rango_final",
            "unitario",
            "bono",
            "chips_r1",
            "chips_x_regularidad",
            "bono_x_venta_recargada",
            "bono_total",
            "recarga_financiada",
            "chips_financiado",
            "total_financiado",
            "bono_total_a_pagar",
            "porta_post_o_pre",
            "porta_post_o_post",
            "total_porta_post",
            "bono_porta_post_o_pre",
            "bono_porta_post_o_post",
            "efectivo_post",
            "chips_post",
            "total_post"
        ]);
        
        // if ($this->tipoReporte == 2) {
        //     $query->where('PROYECTO', 'PDV REGULAR');
        // } elseif ($this->tipoReporte == 3) {
        //     $query->where('PROYECTO', 'like', '%PDV PREMIUM%');
        // }
        return $query->get();
        // return $query->get()->map(function ($item) {
        //     $item->RATIO = $item->RATIO / 100;
        //     return $item;
        // });
    }

    /**
     * head excel
     *
     * @return array
     */
    public function headings(): array
    {
        return [
            "año",
            "mes",
            "zonal",
            "dni_vendedor",
            "nombre_vendedor",
            "fecha_inicio",
            "dni_responsable",
            "supervisor",
            "proyecto",
            "alta_pre",
            "porta_pre",
            "prepago_total",
            "recargas_total",
            "porcentaje_recargas",
            "regularidad",
            "q_recargas_n0_mayor",
            "q_ventas_marzo",
            "q_recargas_n1",
            "porcentaje_recargas_n1",
            "q_recargas_n1_mayor",
            "rango_pre_total",
            "rango_porta_pre",
            "rango_final",
            "unitario",
            "bono",
            "chips_r1",
            "chips_x_regularidad",
            "bono_x_venta_recargada",
            "bono_total",
            "recarga_financiada",
            "chips_financiado",
            "total_financiado",
            "bono_total_a_pagar",
            "porta_post_o_pre",
            "porta_post_o_post",
            "total_porta_post",
            "bono_porta_post_o_pre",
            "bono_porta_post_o_post",
            "efectivo_post",
            "chips_post",
            "total_post"
        ];
    }

     /**
     * style excel
     */
    public function styles(Worksheet $sheet)
    {
        $sheet->getRowDimension(1)->setRowHeight(30); 
        $highestColumn = $sheet->getHighestColumn();
        $highestColumnIndex = \PhpOffice\PhpSpreadsheet\Cell\Coordinate::columnIndexFromString($highestColumn);
        for ($col = 1; $col <= $highestColumnIndex; $col++) {
            $column = \PhpOffice\PhpSpreadsheet\Cell\Coordinate::stringFromColumnIndex($col);
            $sheet->getColumnDimension($column)->setAutoSize(true);
        }
        $sheet->getStyle('A1:' . $highestColumn . '1')
            ->getAlignment()
            ->setWrapText(true);
        $headerStyle = [
            1 => [
                'font' => [
                    'bold' => true,
                    'color' => ['rgb' => 'FFFFFF'],
                ],
                'fill' => [
                    'fillType' => \PhpOffice\PhpSpreadsheet\Style\Fill::FILL_SOLID,
                    'startColor' => ['rgb' => '538DD5'],
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
        $sheet->getStyle('A1:' . $highestColumn . '1')->applyFromArray($headerStyle[1]);

        return $headerStyle;
    }
    
    public function columnFormats(): array
    {
        return [
            // 'J' => '0.00%',
            // 'J' => '0%',
            // 'J' => '.00%',
            // 'J' => NumberFormat::FORMAT_PERCENTAGE, //FORMAT_PERCENTAGE_0 FORMAT_PERCENTAGE_00
            'N' => '0%',
            // 'O' => '"S/" #,##0.00',
            // 'P' => '"S/" #,##0.00',
            // 'Q' => '"S/" #,##0.00',
            // 'R' => '"S/" #,##0.00',
            // 'S' => '"S/" #,##0.00',
            // 'T' => '"S/" #,##0.00',
            // 'U' => '"S/" #,##0.00',
            
            'Y' => '"S/" #,##0.00',
            // '' => '"S/" #,##0.00',
            // '' => '"S/" #,##0.00',
            'AB' => '"S/" #,##0.00',
            'AC' => '"S/" #,##0.00',
            'AD' => '"S/" #,##0.00',
            'AE' => '"S/" #,##0.00',
            'AF' => '"S/" #,##0.00',
            // '' => '"S/" #,##0.00',
            // '' => '"S/" #,##0.00',
            // '' => '"S/" #,##0.00',
            'AJ' => '"S/" #,##0.00',
            'AK' => '"S/" #,##0.00',
            'AL' => '"S/" #,##0.00',
            'AM' => '"S/" #,##0.00',

        ];
    }

}
