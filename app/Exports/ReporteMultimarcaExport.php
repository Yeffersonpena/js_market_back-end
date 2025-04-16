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
use Maatwebsite\Excel\Concerns\WithMultipleSheets;
use Maatwebsite\Excel\Concerns\WithTitle;

class ReporteMultimarcaExport implements FromCollection, WithHeadings, WithStyles, WithColumnFormatting, WithMultipleSheets
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
    // 
     // Crear múltiples hojas
     public function sheets(): array
     {
        //  Filtrar datos para cada pestaña
        //  $detallePre = ReporteMultimarca::where('porta_post_o_pre', 'pre')->get();
        //  $detallePost = ReporteMultimarca::where('porta_post_o_pre', 'post')->get();
        // Obtener los datos completos
    $data = ReporteMultimarca::all();

    // Seleccionar las columnas que irán en la hoja "Detalle Pre"
    $detallePreColumns = $data->map(function($item) {
        return [
            "año" => $item->año,
            "mes" => $item->mes,
            "zonal" => $item->zonal,
            "dni_vendedor" => $item->dni_vendedor,
            "nombre_vendedor" => $item->nombre_vendedor,
            "fecha_inicio" => $item->fecha_inicio,
            "dni_responsable" => $item->dni_responsable,
            "supervisor" => $item->supervisor,
            "proyecto" => $item->proyecto,
            // 
            "alta_pre" => $item->alta_pre,
            "porta_pre" => $item->porta_pre,
            "prepago_total" => $item->prepago_total,
            "recargas_total" => $item->recargas_total,
            // "porcentaje_recargas" => $item->porcentaje_recargas, //
            "porcentaje_recargas" => $item->porcentaje_recargas /100, //

            "regularidad" => $item->regularidad,
            "q_recargas_n0_mayor" => $item->q_recargas_n0_mayor,
            "q_ventas_marzo" => $item->q_ventas_marzo,
            "q_recargas_n1" => $item->q_recargas_n1,
            "porcentaje_recargas_n1" => $item->porcentaje_recargas_n1,
            "q_recargas_n1_mayor" => $item->q_recargas_n1_mayor,
            
            "rango_pre_total" => $item->rango_pre_total,
            "rango_porta_pre" => $item->rango_porta_pre,

            "rango_final" => $item->rango_final,
            // 
            "unitario" => $item->unitario,
            "bono" => $item->bono,
            "chips_r1" => $item->chips_r1,
            "chips_x_regularidad" => $item->chips_x_regularidad,
            "bono_x_venta_recargada" => $item->bono_x_venta_recargada,

            "bono_total" => $item->bono_total,
            "recarga_financiada" => $item->recarga_financiada,
            "chips_financiado" => $item->chips_financiado,
            "total_financiado" => $item->total_financiado,
            "bono_total_a_pagar" => $item->bono_total_a_pagar,

            // 
            // ALTA PRE	PORTA PRE	PREPAGO TOTAL	RECARGAS TOTAL	%RECARGAS	
            // REGULARIDAD	Q RECARGAS N0 CON MONTO ACUM >= S/ 10	
            // Q VENTAS MARZO	Q RECARGAS N1
            	// %RECARGAS N1	Q RECARGAS N1 CON MONTO ACUM >= S/ 15	
                // "RANGO FINAL"
            // UNITARIO	BONO	CHIPS R1	CHIPS X REGULARIDAD	BONO X VENTA RECARGADA	
            // BONO TOTAL	RECARGA FINANCIADA	CHIPS FINANCIADO	TOTAL FINANCIADO	
            // BONO TOTAL A PAGAR

        ];
    });

    // Seleccionar las columnas que irán en la hoja "Detalle Post"
    $detallePostColumns = $data->map(function($item) {
        return [
            "año" => $item->año,
            "mes" => $item->mes,
            "zonal" => $item->zonal,
            "dni_vendedor" => $item->dni_vendedor,
            "nombre_vendedor" => $item->nombre_vendedor,
            "fecha_inicio" => $item->fecha_inicio,
            "dni_responsable" => $item->dni_responsable,
            "supervisor" => $item->supervisor,
            "proyecto" => $item->proyecto,
            // 
            "porta_post_o_pre" => $item->porta_post_o_pre,
            "porta_post_o_post" => $item->porta_post_o_post,
            "total_porta_post" => $item->total_porta_post,
            // 
            "bono_porta_post_o_pre" => $item->bono_porta_post_o_pre,
            "bono_porta_post_o_post" => $item->bono_porta_post_o_post,
            "efectivo_post" => $item->efectivo_post,
            "chips_post" => $item->chips_post,
            "total_post" => $item->total_post,


// ZONAL	DNI VENDEDOR	NOMBRE VENDEDOR	FECHA INICIO	DNI RESPONSABLE	SUPERVISOR	PROYECTO


            // --------------
            // PORTA POST ORIGEN PRE	
        // PORTA POST ORIGEN POST
	// TOTAL PORTA POST 
    	// RANGO	---
        // BONO PORTA POST ORIGEN PRE	
        // BONO PORTA POST ORIGEN POST	
        // INGRESOS EFECTIVO
        // INGRESOS CHIPS
        // 	INGRESO TOTAL


           
        ];
    });
         
         return [
             new ReportePreSheet($detallePreColumns),
             new ReportePostSheet($detallePostColumns),
         ];
     }
}
// class ReportePreSheet implements FromCollection, WithHeadings, WithStyles, WithColumnFormatting, WithMultipleSheets, WithTitle
class ReportePreSheet implements FromCollection, WithHeadings, WithStyles, WithColumnFormatting, WithTitle
{
    protected $data;

    public function __construct($data)
    {
        $this->data = $data;
    }

    public function collection()
    {
        return $this->data;
    }

    public function headings(): array
    {
        // return (new ReporteMultimarcaExport())->headings();
        return [
            // "año",
            // "mes",
            // "zonal",
            // "dni_vendedor",
            // "nombre_vendedor",
            // "fecha_inicio",
            // "dni_responsable",
            // "supervisor",
            // "proyecto",
            // // 
            // "alta_pre",
            // "porta_pre",
            // "prepago_total",
            // "recargas_total",
            // "porcentaje_recargas",
            // "regularidad",
            // "q_recargas_n0_mayor",
            // "q_ventas_marzo",
            // "q_recargas_n1",
            // "porcentaje_recargas_n1",
            // "q_recargas_n1_mayor",
            
            // "rango_pre_total",
            // "rango_porta_pre",

            // "rango_final",
            
            // "unitario",
            // "bono",
            // "chips_r1",
            // "chips_x_regularidad",
            // "bono_x_venta_recargada",
            // "bono_total",
            // "recarga_financiada",
            // "chips_financiado",
            // "total_financiado",
            // "bono_total_a_pagar",
            // // "porta_post_o_pre",
            // // "porta_post_o_post",
            // // "total_porta_post",
            // // "bono_porta_post_o_pre",
            // // "bono_porta_post_o_post",
            // // "efectivo_post",
            // // "chips_post",
            // // "total_post"

            // ----------------
            "AÑO",
            "MES",
            "ZONAL",
            "DNI VENDEDOR",
            "NOMBRE VENDEDOR",
            "FECHA INICIO",
            "DNI RESPONSABLE",
            "SUPERVISOR",
            "PROYECTO",
            // --
            "ALTA PRE",
            "PORTA PRE",
            "PREPAGO TOTAL",
            "RECARGAS TOTAL",
            "%RECARGAS",
            "REGULARIDAD",
            "Q RECARGAS N0 CON MONTO ACUM >= S/ 10",
            "Q VENTAS MARZO",
            "Q RECARGAS N1",
            "%RECARGAS N1",
            "Q RECARGAS N1 CON MONTO ACUM >= S/ 15",
            
            "rango_pre_total",
            "rango_porta_pre",

            "RANGO FINAL",
            "UNITARIO",
            "BONO",
            "CHIPS R1",
            "CHIPS X REGULARIDAD",
            "BONO X VENTA RECARGADA",
            "BONO TOTAL",
            "RECARGA FINANCIADA",
            "CHIPS FINANCIADO",
            "TOTAL FINANCIADO",
            "BONO TOTAL A PAGAR",
        ];
    }
    public function title(): string
    {
        return "DETALLE PRE";
    }
    // 
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
                    // 'startColor' => ['rgb' => '538DD5'],
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
        // $sheet->getStyle('A1:' . $highestColumn . '1')->applyFromArray($headerStyle[1]);
        $customHeaderColors = [
            'A' => '538DD5',
            'B' => '538DD5',
            'C' => '538DD5',
            'D' => '538DD5',
            'E' => '538DD5',
            'F' => '538DD5',
            'G' => '538DD5',
            'H' => '538DD5',
            'I' => '538DD5',
            'J' => '538DD5',
            'K' => '538DD5',
            'L' => '538DD5',
            'M' => '538DD5',
            'N' => '538DD5',
            'O' => '538DD5',
            
            'P' => 'eebe23',
            'Q' => 'eebe23',
            'R' => 'eebe23',
            'S' => 'eebe23',
            'T' => 'eebe23',
            'U' => 'eebe23',
            'V' => 'eebe23',

            'W' => '538DD5',
            'X' => '538DD5',
            // 
            'Y' => '16d52e',
            'Z' => '16d52e',
            'AA' => '16d52e',
            'AB' => '16d52e',
            'AC' => '16d52e',
            
            'AD' => 'f7603a',
            'AE' => 'f7603a',
            'AF' => 'f7603a',
            
            'AG' => '16d52e',

        ];

        foreach ($customHeaderColors as $column => $color) {
            $sheet->getStyle($column . '1')->applyFromArray([
                    'fill' => [
                        'fillType' => \PhpOffice\PhpSpreadsheet\Style\Fill::FILL_SOLID,
                        'startColor' => ['rgb' => $color],
                    ],
                ]);
        }
        return $headerStyle;
    }
    
    public function columnFormats(): array
    {
        return [
            'N' => '0%',
            'S' => '0%',
            'Y' => '"S/" #,##0.00',
            'AB' => '"S/" #,##0.00',
            'AC' => '"S/" #,##0.00',
            'AD' => '"S/" #,##0.00',
            'AE' => '"S/" #,##0.00',
            'AF' => '"S/" #,##0.00',
            'AG' => '"S/" #,##0.00',

        ];
    }
}
class ReportePostSheet implements FromCollection, WithHeadings, WithStyles, WithColumnFormatting, WithTitle
{
    protected $data;

    public function __construct($data)
    {
        $this->data = $data;
    }

    public function collection()
    {
        return $this->data;
    }

    public function headings(): array
    {
        // return (new ReporteMultimarcaExport())->headings();
        return [
            // "año",
            // "mes",
            // "zonal",
            // "dni_vendedor",
            // "nombre_vendedor",
            // "fecha_inicio",
            // "dni_responsable",
            // "supervisor",
            // "proyecto",
            // // 
            // "porta_post_o_pre",
            // "porta_post_o_post",
            // "total_porta_post",
            // "bono_porta_post_o_pre",
            // "bono_porta_post_o_post",
            // "efectivo_post",
            // "chips_post",
            // "total_post",
        // ----
        "AÑO",
        "MES",
        "ZONAL",
        "DNI VENDEDOR",
        "NOMBRE VENDEDOR",
        "FECHA INICIO",
        "DNI RESPONSABLE",
        "SUPERVISOR",
        "PROYECTO",
        // 
        "PORTA POST ORIGEN PRE",
        "PORTA POST ORIGEN POST",
        "TOTAL PORTA POST",

        "BONO PORTA POST ORIGEN PRE",
        "BONO PORTA POST ORIGEN POST",
        "INGRESOS EFECTIVO",
        "INGRESOS CHIPS",
        "INGRESO TOTAL",
        ];
    }
    
    public function title(): string
    {
        return "DETALLE POST";
    }
    // 
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
                    // 'startColor' => ['rgb' => '538DD5'],
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
        $customHeaderColors = [
            'A' => '538DD5',
            'B' => '538DD5',
            'C' => '538DD5',
            'D' => '538DD5',
            'E' => '538DD5',
            'F' => '538DD5',
            'G' => '538DD5',
            'H' => '538DD5',
            'I' => '538DD5',
            'J' => '538DD5',
            'K' => '538DD5',
            'L' => '538DD5',
            // 
            'M' => '16d52e',
            'N' => '16d52e',
            'O' => '16d52e',
            'P' => '16d52e',
            'Q' => '16d52e',
        ];
        foreach ($customHeaderColors as $column => $color) {
            $sheet->getStyle($column . '1')->applyFromArray([
                    'fill' => [
                        'fillType' => \PhpOffice\PhpSpreadsheet\Style\Fill::FILL_SOLID,
                        'startColor' => ['rgb' => $color],
                    ],
                ]);
        }

        return $headerStyle;
    }
    
    public function columnFormats(): array
    {
        return [
            'M' => '"S/" #,##0.00',
            'N' => '"S/" #,##0.00',
            'O' => '"S/" #,##0.00',
            'P' => '"S/" #,##0.00',
            'Q' => '"S/" #,##0.00',
        ];
    }
}
