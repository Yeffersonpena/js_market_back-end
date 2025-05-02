<?php

namespace App\Exports;

use App\Models\PlantillaVvddPdv;
use App\Models\Reporte;
use App\Models\VI_AVANCE_MM_PDV;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithStyles;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;
use Maatwebsite\Excel\Concerns\WithColumnFormatting;
use PhpOffice\PhpSpreadsheet\Style\NumberFormat;
use Maatwebsite\Excel\Concerns\WithMultipleSheets;
use Maatwebsite\Excel\Concerns\WithTitle;

class ReportePdvExport implements FromCollection, WithHeadings, WithStyles, WithColumnFormatting, WithMultipleSheets
{
    protected $tipoReporte;
    public function __construct($tipoReporte = 1)
    {
        $this->tipoReporte = $tipoReporte;
    }
    /**
     * @return \Illuminate\Support\Collection
     */
    public function collection()
    {
        $query = Reporte::select([
            'AÑO',
            'MES',
            'ZONAL',
            'DNI_RESPONSABLE',
            'NOMBRE_RESPONSABLE',
            'VENDEDOR_ZONIFICADO',
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
        ]);
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
            'AÑO',
            'MES',
            'ZONAL',
            'DNI_RESPONSABLE',
            'NOMBRE_RESPONSABLE',
            'PROYECTO',
            'ESTADO',
            'AVANCE_PREPAGO',
            'RECARGAS',
            '% RATIO',
            'PORTA_PRE',
            'ALTA_POST',
            'PORTA_POST_ORIGEN_POST',
            'PORTA_POST_ORIGEN_PRE',
            'S/. BONO_PRE',
            'S/. BONO_RC',
            'S/. BONO_PORTA_PRE',
            'S/. BONO_ALTA_POST',
            'S/. BONO_PORTA_POST_ORIGEN_POST',
            'S/. BONO_PORTA_POST_ORIGEN_PRE',
            'S/. EFECTIVO_A_PAGAR'
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

        $headerStyle = [
            1 => [
                'font' => [
                    'bold' => true,
                    'color' => ['rgb' => 'FFFFFF'],
                ],
                'fill' => [
                    'fillType' => \PhpOffice\PhpSpreadsheet\Style\Fill::FILL_SOLID,
                    // 'startColor' => ['rgb' => '538DD5'], 
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
            'M' => '538DD5',
            'N' => '538DD5',
            // 
            'O' => '16d52e',
            'P' => '16d52e',
            'Q' => '16d52e',
            'R' => '16d52e',
            'S' => '16d52e',
            'T' => '16d52e',
            'U' => '16d52e',
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
            'J' => '0%',
            'O' => '"S/" #,##0.00',
            'P' => '"S/" #,##0.00',
            'Q' => '"S/" #,##0.00',
            'R' => '"S/" #,##0.00',
            'S' => '"S/" #,##0.00',
            'T' => '"S/" #,##0.00',
            'U' => '"S/" #,##0.00',
        ];
    }
    // Crear múltiples hojas
    public function sheets(): array
    {
        $dataPdvRegular = Reporte::where('PROYECTO', 'PDV REGULAR')->get();
        // $dataPdvPremium = Reporte::where('PROYECTO', 'like', '%PDV PREMIUM%')->get();
        $dataPdvPremium = Reporte::where('PROYECTO', 'PDV PREMIUM SIN VVDD MM')->get();
        $dataPdvPremiumResp = PlantillaVvddPdv::where('tipo', '=', '1')->get();
        $dataPdvPremiumVvdd = PlantillaVvddPdv::where('tipo', '=', '2')->get();
        $dataPdvPremiumPdv = VI_AVANCE_MM_PDV::get();

        $detallePdvRegularColumns = $dataPdvRegular->map(function ($item) {
            return [
                "AÑO" => $item->AÑO,
                "MES" => $item->MES,
                "ZONAL" => $item->ZONAL,
                "DNI_RESPONSABLE" => $item->DNI_RESPONSABLE,
                "NOMBRE_RESPONSABLE" => $item->NOMBRE_RESPONSABLE,
                "VENDEDOR_ZONIFICADO" => $item->VENDEDOR_ZONIFICADO,
                "PROYECTO" => $item->PROYECTO,
                "ESTADO" => $item->ESTADO,
                "AVANCE_PREPAGO" => $item->AVANCE_PREPAGO,
                "RECARGAS" => $item->RECARGAS,
                "RATIO" => $item->RATIO / 100,
                "PORTA_PRE" => $item->PORTA_PRE,
                "ALTA_POST" => $item->ALTA_POST,
                "PORTA_POST_ORIGEN_POST" => $item->PORTA_POST_ORIGEN_POST,
                "PORTA_POST_ORIGEN_PRE" => $item->PORTA_POST_ORIGEN_PRE,
                "BONO_PRE" => $item->BONO_PRE,
                "BONO_RC" => $item->BONO_RC,
                "BONO_PORTA_PRE" => $item->BONO_PORTA_PRE,
                "BONO_ALTA_POST" => $item->BONO_ALTA_POST,
                "BONO_PORTA_POST_ORIGEN_POST" => $item->BONO_PORTA_POST_ORIGEN_POST,
                "BONO_PORTA_POST_ORIGEN_PRE" => $item->BONO_PORTA_POST_ORIGEN_PRE,
                "EFECTIVO_A_PAGAR" => $item->EFECTIVO_A_PAGAR,
            ];
        });

        $detallePdvPremiumColumns = $dataPdvPremium->map(function ($item) {
            return [
                "AÑO" => $item->AÑO,
                "MES" => $item->MES,
                "ZONAL" => $item->ZONAL,
                "DNI_RESPONSABLE" => $item->DNI_RESPONSABLE,
                "NOMBRE_RESPONSABLE" => $item->NOMBRE_RESPONSABLE,
                "VENDEDOR_ZONIFICADO" => $item->VENDEDOR_ZONIFICADO,
                "PROYECTO" => $item->PROYECTO,
                "ESTADO" => $item->ESTADO,
                "AVANCE_PREPAGO" => $item->AVANCE_PREPAGO,
                "RECARGAS" => $item->RECARGAS,
                "RATIO" => $item->RATIO / 100,
                "PORTA_PRE" => $item->PORTA_PRE,
                "ALTA_POST" => $item->ALTA_POST,
                "PORTA_POST_ORIGEN_POST" => $item->PORTA_POST_ORIGEN_POST,
                "PORTA_POST_ORIGEN_PRE" => $item->PORTA_POST_ORIGEN_PRE,
                "BONO_PRE" => $item->BONO_PRE,
                "BONO_RC" => $item->BONO_RC,
                "BONO_PORTA_PRE" => $item->BONO_PORTA_PRE,
                "BONO_ALTA_POST" => $item->BONO_ALTA_POST,
                "BONO_PORTA_POST_ORIGEN_POST" => $item->BONO_PORTA_POST_ORIGEN_POST,
                "BONO_PORTA_POST_ORIGEN_PRE" => $item->BONO_PORTA_POST_ORIGEN_PRE,
                "EFECTIVO_A_PAGAR" => $item->EFECTIVO_A_PAGAR,
            ];
        });
        
        $detallePdvPremiumRespColumns = $dataPdvPremiumResp->map(function ($item) {
            return [
                "AÑO" => $item->AÑO,
                "MES" => $item->MES,
                "ZONAL" => $item->ZONAL,
                "DNI_RESPONSABLE" => $item->DNI_RESPONSABLE,
                "NOMBRE_RESPONSABLE" => $item->NOMBRE_RESPONSABLE,
                "DNI_VENDEDOR" => $item->DNI_VENDEDOR,
                "NOMBRE_VENDEDOR" => $item->NOMBRE_VENDEDOR,
                "VENDEDOR_ZONIFICADO" => $item->VENDEDOR_ZONIFICADO,
                "PROYECTO" => $item->PROYECTO,
                "ESTADO" => $item->ESTADO,
                "AVANCE_PREPAGO" => $item->AVANCE_PREPAGO,
                "RECARGAS" => $item->RECARGAS,
                "RATIO" => $item->RATIO/100,
                "PORTA_PRE" => $item->PORTA_PRE,
                "ALTA_POST" => $item->ALTA_POST,
                "PORTA_POST_ORIGEN_POST" => $item->PORTA_POST_ORIGEN_POST,
                "PORTA_POST_ORIGEN_PRE" => $item->PORTA_POST_ORIGEN_PRE,
                "BONO_PRE" => $item->BONO_PRE,
                "BONO_RC" => $item->BONO_RC,
                "BONO_PORTA_PRE" => $item->BONO_PORTA_PRE,
                "BONO_ALTA_POST" => $item->BONO_ALTA_POST,
                "BONO_PORTA_POST_ORIGEN_POST" => $item->BONO_PORTA_POST_ORIGEN_POST,
                "BONO_PORTA_POST_ORIGEN_PRE" => $item->BONO_PORTA_POST_ORIGEN_PRE,
                "EFECTIVO_A_PAGAR" => $item->EFECTIVO_A_PAGAR,
                "CHIPS_LIBERAR" => $item->CHIPS_LIBERAR,
            ];
        });

        $detallePdvPremiumVvddColumns = $dataPdvPremiumVvdd->map(function ($item) {
            return [
                "AÑO" => $item->AÑO,
                "MES" => $item->MES,
                "ZONAL" => $item->ZONAL,
                "DNI_RESPONSABLE" => $item->DNI_RESPONSABLE,
                "NOMBRE_RESPONSABLE" => $item->NOMBRE_RESPONSABLE,
                "DNI_VENDEDOR" => $item->DNI_VENDEDOR,
                "NOMBRE_VENDEDOR" => $item->NOMBRE_VENDEDOR,
                "VENDEDOR_ZONIFICADO" => $item->VENDEDOR_ZONIFICADO, //
                "PROYECTO" => $item->PROYECTO,
                "ESTADO" => $item->ESTADO,
                "AVANCE_PREPAGO" => $item->AVANCE_PREPAGO,
                "RECARGAS" => $item->RECARGAS,
                "RATIO" => $item->RATIO/100,
                "PORTA_PRE" => $item->PORTA_PRE,
                "ALTA_POST" => $item->ALTA_POST,
                "PORTA_POST_ORIGEN_POST" => $item->PORTA_POST_ORIGEN_POST,
                "PORTA_POST_ORIGEN_PRE" => $item->PORTA_POST_ORIGEN_PRE,
                "BONO_PRE" => $item->BONO_PRE,
                "BONO_RC" => $item->BONO_RC,
                "BONO_PORTA_PRE" => $item->BONO_PORTA_PRE,
                "BONO_ALTA_POST" => $item->BONO_ALTA_POST,
                "BONO_PORTA_POST_ORIGEN_POST" => $item->BONO_PORTA_POST_ORIGEN_POST,
                "BONO_PORTA_POST_ORIGEN_PRE" => $item->BONO_PORTA_POST_ORIGEN_PRE,
                "EFECTIVO_A_PAGAR" => $item->EFECTIVO_A_PAGAR,
                "CHIPS_LIBERAR" => $item->CHIPS_LIBERAR,
            ];
        });

        $detallePdvPremiumPdvColumns = $dataPdvPremiumPdv->map(function ($item) {
            return [
                "AÑO" => $item->AÑO,
                "MES" => $item->MES,
                "ZONAL" => $item->ZONAL,
                "DNI_RESPONSABLE" => $item->DNI_RESPONSABLE,
                "NOMBRE_RESPONSABLE" => $item->NOMBRE_RESPONSABLE,
                "DNI_VENDEDOR" => $item->DNI_VENDEDOR,
                "NOMBRE_VENDEDOR" => $item->NOMBRE_VENDEDOR,
                "VENDEDOR_ZONIFICADO" => $item->VENDEDOR_ZONIFICADO, //
                "PROYECTO" => $item->PROYECTO,
                // "ESTADO" => $item->ESTADO,
                "AVANCE_PREPAGO" => $item->AVANCE_PREPAGO,
                "RECARGAS" => $item->RECARGAS,
                "RATIO" => $item->RATIO/100,
                "PORTA_PRE" => $item->PORTA_PRE,
                "ALTA_POST" => $item->ALTA_POST,
                "PORTA_POST_ORIGEN_POST" => $item->PORTA_POST_ORIGEN_POST,
                "PORTA_POST_ORIGEN_PRE" => $item->PORTA_POST_ORIGEN_PRE,
                "BONO_PRE" => $item->BONO_PRE,
                "BONO_RC" => $item->BONO_RC,
                "BONO_PORTA_PRE" => $item->BONO_PORTA_PRE,
                "BONO_ALTA_POST" => $item->BONO_ALTA_POST,
                "BONO_PORTA_POST_ORIGEN_POST" => $item->BONO_PORTA_POST_ORIGEN_POST,
                "BONO_PORTA_POST_ORIGEN_PRE" => $item->BONO_PORTA_POST_ORIGEN_PRE,
                "EFECTIVO_A_PAGAR" => $item->EFECTIVO_A_PAGAR,
                "CHIPS_LIBERAR" => $item->CHIPS_LIBERAR,
            ];
        });

        return [
            new ReportePdvRegularSheet($detallePdvRegularColumns),
            new ReportePdvPremiumSheet($detallePdvPremiumColumns),
            new ReportePdvPremiumRespSheet($detallePdvPremiumRespColumns),
            new ReportePdvPremiumVvddSheet($detallePdvPremiumVvddColumns),
            new ReportePdvPremiumPdvpSheet($detallePdvPremiumPdvColumns),
        ];
    }
}


// 
class ReportePdvRegularSheet implements FromCollection, WithHeadings, WithStyles, WithColumnFormatting, WithTitle
{
    protected $data;

    public function __construct($data)
    {
        $this->data = $data;
    }

    public function collection()
    {
        return $this->data;
        // $query = Reporte::select([
        //     'AÑO',
        //     'MES',
        //     'ZONAL',
        //     'DNI_RESPONSABLE',
        //     'NOMBRE_RESPONSABLE',
        //     'PROYECTO',
        //     'ESTADO',
        //     'AVANCE_PREPAGO',
        //     'RECARGAS',
        //     'RATIO',
        //     'PORTA_PRE',
        //     'ALTA_POST',
        //     'PORTA_POST_ORIGEN_POST',
        //     'PORTA_POST_ORIGEN_PRE',
        //     'BONO_PRE',
        //     'BONO_RC',
        //     'BONO_PORTA_PRE',
        //     'BONO_ALTA_POST',
        //     'BONO_PORTA_POST_ORIGEN_POST',
        //     'BONO_PORTA_POST_ORIGEN_PRE',
        //     'EFECTIVO_A_PAGAR'
        // ]);    
        // $query->where('PROYECTO', 'PDV REGULAR');
        // return $query->get()->map(function ($item) {
        //     $item->RATIO = $item->RATIO / 100;
        //     return $item;
        // });
    }

    public function headings(): array
    {
        return [
            'AÑO',
            'MES',
            'ZONAL',
            'DNI_RESPONSABLE',
            'NOMBRE_RESPONSABLE',
            'VENDEDOR_ZONIFICADO',
            'PROYECTO',
            'ESTADO',
            'AVANCE_PREPAGO',
            'RECARGAS',
            '% RATIO',
            'PORTA_PRE',
            'ALTA_POST',
            'PORTA_POST_ORIGEN_POST',
            'PORTA_POST_ORIGEN_PRE',
            'S/. BONO_PRE',
            'S/. BONO_RC',
            'S/. BONO_PORTA_PRE',
            'S/. BONO_ALTA_POST',
            'S/. BONO_PORTA_POST_ORIGEN_POST',
            'S/. BONO_PORTA_POST_ORIGEN_PRE',
            'S/. EFECTIVO_A_PAGAR'
        ];
    }
    public function title(): string
    {
        return "Pdv_Regular";
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

            'P' => '16d52e',
            'Q' => '16d52e',
            'R' => '16d52e',
            'S' => '16d52e',
            'T' => '16d52e',
            'U' => '16d52e',
            'V' => '16d52e',
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
            'J' => '0%',
            'P' => '"S/" #,##0.00',
            'Q' => '"S/" #,##0.00',
            'R' => '"S/" #,##0.00',
            'S' => '"S/" #,##0.00',
            'T' => '"S/" #,##0.00',
            'U' => '"S/" #,##0.00',
            'V' => '"S/" #,##0.00',
        ];
    }
}
class ReportePdvPremiumSheet implements FromCollection, WithHeadings, WithStyles, WithColumnFormatting, WithTitle
{
    protected $data;

    public function __construct($data)
    {
        $this->data = $data;
    }

    public function collection()
    {
        return $this->data;
        // $query = Reporte::select([
        //     'AÑO',
        //     'MES',
        //     'ZONAL',
        //     'DNI_RESPONSABLE',
        //     'NOMBRE_RESPONSABLE',
        //     'PROYECTO',
        //     'ESTADO',
        //     'AVANCE_PREPAGO',
        //     'RECARGAS',
        //     'RATIO',
        //     'PORTA_PRE',
        //     'ALTA_POST',
        //     'PORTA_POST_ORIGEN_POST',
        //     'PORTA_POST_ORIGEN_PRE',
        //     'BONO_PRE',
        //     'BONO_RC',
        //     'BONO_PORTA_PRE',
        //     'BONO_ALTA_POST',
        //     'BONO_PORTA_POST_ORIGEN_POST',
        //     'BONO_PORTA_POST_ORIGEN_PRE',
        //     'EFECTIVO_A_PAGAR'
        // ]);    
        // $query->where('PROYECTO', 'like', '%PDV PREMIUM%');
        // return $query->get()->map(function ($item) {
        //     $item->RATIO = $item->RATIO / 100;
        //     return $item;
        // });
    }

    public function headings(): array
    {
        return [
            'AÑO',
            'MES',
            'ZONAL',
            'DNI_RESPONSABLE',
            'NOMBRE_RESPONSABLE',
            'VENDEDOR_ZONIFICADO',
            'PROYECTO',
            'ESTADO',
            'AVANCE_PREPAGO',
            'RECARGAS',
            '% RATIO',
            'PORTA_PRE',
            'ALTA_POST',
            'PORTA_POST_ORIGEN_POST',
            'PORTA_POST_ORIGEN_PRE',
            'S/. BONO_PRE',
            'S/. BONO_RC',
            'S/. BONO_PORTA_PRE',
            'S/. BONO_ALTA_POST',
            'S/. BONO_PORTA_POST_ORIGEN_POST',
            'S/. BONO_PORTA_POST_ORIGEN_PRE',
            'S/. EFECTIVO_A_PAGAR'
        ];
    }

    public function title(): string
    {
        return "Pdv_Premium";
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
            'M' => '538DD5',
            'N' => '538DD5',
            'O' => '538DD5',

            'P' => '16d52e',
            'Q' => '16d52e',
            'R' => '16d52e',
            'S' => '16d52e',
            'T' => '16d52e',
            'U' => '16d52e',
            'V' => '16d52e',
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
            'J' => '0%',
            'P' => '"S/" #,##0.00',
            'Q' => '"S/" #,##0.00',
            'R' => '"S/" #,##0.00',
            'S' => '"S/" #,##0.00',
            'T' => '"S/" #,##0.00',
            'U' => '"S/" #,##0.00',
            'V' => '"S/" #,##0.00',
        ];
    }
}

// resp
class ReportePdvPremiumRespSheet implements FromCollection, WithHeadings, WithStyles, WithColumnFormatting, WithTitle
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
        return [
            "AÑO",
            "MES",
            "ZONAL",
            "DNI_RESPONSABLE",
            "NOMBRE_RESPONSABLE",
            "DNI_VENDEDOR",
            "NOMBRE_VENDEDOR",
            'VENDEDOR_ZONIFICADO',
            "PROYECTO",
            "ESTADO",
            "AVANCE_PREPAGO",
            "RECARGAS",
            "RATIO",
            "PORTA_PRE",
            "ALTA_POST",
            "PORTA_POST_ORIGEN_POST",
            "PORTA_POST_ORIGEN_PRE",
            "BONO_PRE",
            "BONO_RC",
            "BONO_PORTA_PRE",
            "BONO_ALTA_POST",
            "BONO_PORTA_POST_ORIGEN_POST",
            "BONO_PORTA_POST_ORIGEN_PRE",
            "EFECTIVO_A_PAGAR",
            "CHIPS_LIBERAR"
        ];
    }

    public function title(): string
    {
        return "Pdv_Premium_Resp";
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
            'M' => '538DD5',
            'N' => '538DD5',
            'O' => '538DD5',
            'P' => '538DD5',
            'Q' => '538DD5',

            'R' => '16d52e',
            'S' => '16d52e',
            'T' => '16d52e',
            'U' => '16d52e',
            'V' => '16d52e',
            'W' => '16d52e',
            'X' => '16d52e',
            'Y' => '16d52e',
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
            'L' => '0%',
            // 'O' => '"S/" #,##0.00',
            // 'P' => '"S/" #,##0.00',
            'R' => '"S/" #,##0.00',
            'S' => '"S/" #,##0.00',
            'T' => '"S/" #,##0.00',
            'U' => '"S/" #,##0.00',
            'V' => '"S/" #,##0.00',
            'W' => '"S/" #,##0.00',
            'X' => '"S/" #,##0.00',
            'Y' => '"S/" #,##0.00',

        ];
    }
}
// vvdd
class ReportePdvPremiumVvddSheet implements FromCollection, WithHeadings, WithStyles, WithColumnFormatting, WithTitle
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
        return [
            "AÑO",
            "MES",
            "ZONAL",
            "DNI_RESPONSABLE",
            "NOMBRE_RESPONSABLE",
            "DNI_VENDEDOR",
            "NOMBRE_VENDEDOR",
            'VENDEDOR_ZONIFICADO',
            "PROYECTO",
            "ESTADO",
            "AVANCE_PREPAGO",
            "RECARGAS",
            "RATIO",
            "PORTA_PRE",
            "ALTA_POST",
            "PORTA_POST_ORIGEN_POST",
            "PORTA_POST_ORIGEN_PRE",
            "BONO_PRE",
            "BONO_RC",
            "BONO_PORTA_PRE",
            "BONO_ALTA_POST",
            "BONO_PORTA_POST_ORIGEN_POST",
            "BONO_PORTA_POST_ORIGEN_PRE",
            "EFECTIVO_A_PAGAR",
            "CHIPS_LIBERAR"
        ];
    }

    public function title(): string
    {
        return "Pdv_Premium_Vvdd";
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
            'M' => '538DD5',
            'N' => '538DD5',
            'O' => '538DD5',
            'P' => '538DD5',
            'Q' => '538DD5',

            'R' => '16d52e',
            'S' => '16d52e',
            'T' => '16d52e',
            'U' => '16d52e',
            'V' => '16d52e',
            'W' => '16d52e',
            'X' => '16d52e',
            'Y' => '16d52e',
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
            'L' => '0%',
            // 'O' => '"S/" #,##0.00',
            // 'P' => '"S/" #,##0.00',
            'R' => '"S/" #,##0.00',
            'S' => '"S/" #,##0.00',
            'T' => '"S/" #,##0.00',
            'U' => '"S/" #,##0.00',
            'V' => '"S/" #,##0.00',
            'W' => '"S/" #,##0.00',
            'X' => '"S/" #,##0.00',
            'Y' => '"S/" #,##0.00',

        ];
    }
}
// pdv
class ReportePdvPremiumPdvpSheet implements FromCollection, WithHeadings, WithStyles, WithColumnFormatting, WithTitle
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
        return [
            "AÑO",
            "MES",
            "ZONAL",
            "DNI_RESPONSABLE",
            "NOMBRE_RESPONSABLE",
            "DNI_VENDEDOR",
            "NOMBRE_VENDEDOR",
            'VENDEDOR_ZONIFICADO',
            "PROYECTO",
            // "ESTADO",
            "AVANCE_PREPAGO",
            "RECARGAS",
            "RATIO",
            "PORTA_PRE",
            "ALTA_POST",
            "PORTA_POST_ORIGEN_POST",
            "PORTA_POST_ORIGEN_PRE",
            "BONO_PRE",
            "BONO_RC",
            "BONO_PORTA_PRE",
            "BONO_ALTA_POST",
            "BONO_PORTA_POST_ORIGEN_POST",
            "BONO_PORTA_POST_ORIGEN_PRE",
            "EFECTIVO_A_PAGAR",
            "CHIPS_LIBERAR"
        ];
    }

    public function title(): string
    {
        return "Pdv_Premium_Pdv";
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
            'M' => '538DD5',
            'N' => '538DD5',
            'O' => '538DD5',
            'P' => '538DD5',
            
            'Q' => '16d52e',
            'R' => '16d52e',
            'S' => '16d52e',
            'T' => '16d52e',
            'U' => '16d52e',
            'V' => '16d52e',
            'W' => '16d52e',
            'X' => '16d52e',
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
            'K' => '0%',
            // 'O' => '"S/" #,##0.00',
            // 'P' => '"S/" #,##0.00',
            'Q' => '"S/" #,##0.00',
            'R' => '"S/" #,##0.00',
            'S' => '"S/" #,##0.00',
            'T' => '"S/" #,##0.00',
            'U' => '"S/" #,##0.00',
            'V' => '"S/" #,##0.00',
            'W' => '"S/" #,##0.00',
            'X' => '"S/" #,##0.00',
        ];
    }
}
