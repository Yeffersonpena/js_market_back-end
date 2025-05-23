<?php

namespace App\Exports\Finanza;

use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
// use Maatwebsite\Excel\Concerns\FromCollection;
// use Maatwebsite\Excel\Concerns\WithColumnFormatting;
// use Maatwebsite\Excel\Concerns\WithHeadings;
// use Maatwebsite\Excel\Concerns\WithStyles;

use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithStyles;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;
use Maatwebsite\Excel\Concerns\WithColumnFormatting;
use PhpOffice\PhpSpreadsheet\Style\NumberFormat;
use Maatwebsite\Excel\Concerns\WithMultipleSheets;
use Maatwebsite\Excel\Concerns\WithTitle;


// 

class ReporteFinanzaExport implements FromCollection, WithHeadings, WithStyles, WithColumnFormatting, WithMultipleSheets
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
    }
        /**
     * head excel
     *
     * @return array
     */
    public function headings(): array
    {
        return [
        ];

    }
     /**
     * style excel
     */
    public function styles(Worksheet $sheet)
    {
    }

    public function columnFormats(): array
    {
        return [
        ];
    }
    public function sheets(): array
    {
            $año=2025;
            $mes=5;
            $dni=73532841;
            $dateFileLoad='2025-05-22';
            $getResumenChip= DB::select('
            select chip.saldo,e.DNI_VENDEDOR as DNI_FINAL, e.ACCION_1 as PROYECTO from dbo.tbl_chip_q2 chip 
            inner join
            dbo.PDV_OUT_ENTREGABLE e on chip.dni=e.DNI_VENDEDOR
            WHERE e.AÑO = ? AND e.MES = ? AND CONVERT(date, chip.dateFileLoad) = ?;',[$año, $mes, $dateFileLoad]);

            $getResumenRecarga= DB::select('
            select sum(redDig.Monto) as MONTO, e.DNI_VENDEDOR as DNI_FINAL, e.ACCION_1 as PROYECTO from dbo.tbl_red_digital_q2 redDig
            inner join
            dbo.PDV_OUT_ENTREGABLE e on redDig.dni=e.DNI_VENDEDOR
            WHERE e.AÑO = ? AND e.MES = ?  and (redDig.CONDICION LIKE ? OR redDig.CONDICION = ?) and (redDig.CONDICION1 like ? OR redDig.CONDICION1 = ?) 
            and Columna1 <> ? AND CONVERT(date, redDig.dateFileLoad) = ? group by e.DNI_VENDEDOR, e.ACCION_1
            ;',[$año, $mes, '%CR%', 'N/C', '%CR%', 'N/C', 'CHIP', $dateFileLoad]);
            // and redDig.CONDICION in (?,?) 

            $getBaseRecarga = DB::select('
            select redDig.*, \'\' as MOVIMIENTO, e.DNI_VENDEDOR as DNI_FINAL, e.ACCION_1 as PROYECTO, e.ZONAL, e.ESTADO from dbo.tbl_red_digital_q2 redDig
            inner join
            dbo.PDV_OUT_ENTREGABLE e on redDig.dni=e.DNI_VENDEDOR
            WHERE e.AÑO = ? AND e.MES = ? and (redDig.CONDICION LIKE ? OR redDig.CONDICION = ?) and (redDig.CONDICION1 like ? OR redDig.CONDICION1 = ?)
            and Columna1 <> ? AND CONVERT(date, redDig.dateFileLoad) = ?
            ;',[$año, $mes, '%CR%', 'N/C', '%CR%', 'N/C', 'CHIP', $dateFileLoad]);

            $getBaseChip = DB::select('
            select chip.*,e.DNI_VENDEDOR as DNI_FINAL, e.ACCION_1 as PROYECTO, e.ZONAL, e.ESTADO as E_ESTADO from dbo.tbl_chip_q2 chip 

            inner join
            dbo.PDV_OUT_ENTREGABLE e on chip.dni=e.DNI_VENDEDOR
            WHERE e.AÑO =? AND e.MES =? AND CONVERT(date, chip.dateFileLoad) = ?;',[$año, $mes, $dateFileLoad]);
            
            $resumenChip=collect($getResumenChip)->map(function ($item) {
                return [
                    'DNI_FINAL'=>$item->DNI_FINAL,
                    'PROYECTO'=>$item->PROYECTO,
                    'CHIPS'=>$item->saldo,
                ];
            });
            
            $resumenRecarga=collect($getResumenRecarga)->map(function ($item) {
                return [
                    'DNI_FINAL'=>$item->DNI_FINAL,
                    'PROYECTO'=>$item->PROYECTO,
                    'MONTO'=>$item->MONTO,
                ];
            });

            $baseRecarga = collect($getBaseRecarga)->map(function ($item) {
                return [
                        "Fecha" => $item->Fecha,
                        "Hora" => Carbon::parse($item->Hora)->format('H:i:s'),
                        "ID_Movto" => $item->ID_Movto,
                        "ID_Zonal" => $item->ID_Zonal,
                        "UsuarioId" => $item->UsuarioId,
                        "Monto" => $item->Monto,
                        "Comentario" => $item->Comentario,
                        "Tipo" => $item->Tipo,
                        "x_Activador" => $item->x_Activador,
                        "Telefono" => $item->Telefono,
                        "Telefono2" => $item->Telefono2,
                        "Valida_Dni" => $item->Valida_Dni,
                        "Nombre" => $item->Nombre,
                        "DNI" => $item->DNI,
                        "ERP_ID_PDV" => $item->ERP_ID_PDV,
                        "CONDICION" => $item->CONDICION,
                        "CONDICION1" => $item->CONDICION1,
                        "MOVIMIENTO" => $item->MOVIMIENTO,
                        "DNI_FINAL" => $item->DNI_FINAL,
                        "PROYECTO" => $item->PROYECTO,
                        "ZONAL" => $item->ZONAL,
                        "ESTADO" => $item->ESTADO
                ];
            });

            $baseChip = collect($getBaseChip)->map(function ($item) {
            return [
                "PERIODO" => $item->PERIODO,
                "TD_SUNAT" => $item->TD_SUNAT,
                "TD" => $item->TD,
                "NRODOC" => $item->NRODOC,
                "FECHA" => $item->FECHA,
                "RAZON_SOCIAL" => $item->RAZON_SOCIAL,
                "TIPO_CLI" => $item->TIPO_CLI,
                "TIPO_DOCCLI" => $item->TIPO_DOCCLI,
                "DOCCLI" => $item->DOCCLI,
                "BASE" => $item->BASE,
                "IGV" => $item->IGV,
                "TOTAL" => $item->TOTAL,
                "SALDO" => $item->SALDO,
                "ESTADO" => $item->ESTADO,
                "CCOD_PROD" => $item->CCOD_PROD,
                "CNOM_PROD" => $item->CNOM_PROD,
                "NCANT_DETA" => $item->NCANT_DETA,
                "NPRECIO_VTA" => $item->NPRECIO_VTA,
                "SUBTOTAL" => $item->SUBTOTAL,
                "ALMACEN" => $item->ALMACEN,
                "REPARTO" => $item->REPARTO,
                "CONDICION" => $item->CONDICION,
                "PROD_CATEGORIA" => $item->PROD_CATEGORIA,
                "PROD_LINEA" => $item->PROD_LINEA,
                "GIRO" => $item->GIRO,
                "COD_ALTERNO" => $item->COD_ALTERNO,
                "NOMBRE" => $item->NOMBRE,
                "DNI" => $item->DNI,
                "DNI_FINAL" => $item->DNI_FINAL,
                "PROYECTO" => $item->PROYECTO,
                "ZONAL" => $item->ZONAL,
                "E_ESTADO" => $item->E_ESTADO,
            ];
        });

        return [
            new ReporteResumenChipSheet($resumenChip, $resumenRecarga), 
            new ReporteBaseRecargaSheet($baseRecarga),
            new ReporteBaseChipSheet($baseChip),

        ];
    }
}

use Maatwebsite\Excel\Events\AfterSheet;
use Maatwebsite\Excel\Concerns\WithEvents;

class ReporteResumenChipSheet implements FromCollection, WithHeadings, WithStyles, WithColumnFormatting, WithTitle, WithEvents
{
    protected $resumenChip;
    protected $resumenRecarga;

    public function __construct($resumenChip, $resumenRecarga)
    {
        $this->resumenChip = $resumenChip;
        $this->resumenRecarga = $resumenRecarga;
    }

    public function collection()
    {
        return $this->resumenChip;
    }

    public function headings(): array
    {
        return [
            'DNI FINAL',
            'PROYECTO',
            'CHIPS',
        ];
    }

    public function title(): string
    {
        return 'RESUMEN';
    }

    public function styles(Worksheet $sheet)
    {
        $sheet->getRowDimension(1)->setRowHeight(30);
        $sheet->getStyle('A1:C1')->applyFromArray([
            'font' => ['bold' => true, 'color' => ['rgb' => 'FFFFFF']],
            'fill' => ['fillType' => \PhpOffice\PhpSpreadsheet\Style\Fill::FILL_SOLID, 'startColor' => ['rgb' => '538DD5']],
            'alignment' => ['vertical' => \PhpOffice\PhpSpreadsheet\Style\Alignment::VERTICAL_CENTER],
            'borders' => ['allBorders' => ['borderStyle' => \PhpOffice\PhpSpreadsheet\Style\Border::BORDER_THIN]],
        ]);
        foreach (['A', 'B', 'C'] as $col) {
            $sheet->getColumnDimension($col)->setAutoSize(true);
        }
    }

    public function columnFormats(): array
    {
        return [];
    }

    public function registerEvents(): array
    {
        return [
        AfterSheet::class => function(AfterSheet $event) {
            $sheet = $event->sheet->getDelegate();

            $headerStyle = [
                'font' => ['bold' => true, 'color' => ['rgb' => 'FFFFFF']],
                'fill' => ['fillType' => \PhpOffice\PhpSpreadsheet\Style\Fill::FILL_SOLID, 'startColor' => ['rgb' => '538DD5']],
                'alignment' => ['vertical' => \PhpOffice\PhpSpreadsheet\Style\Alignment::VERTICAL_CENTER],
                'borders' => ['allBorders' => ['borderStyle' => \PhpOffice\PhpSpreadsheet\Style\Border::BORDER_THIN]],
            ];

            $headers = ['DNI FINAL', 'PROYECTO', 'MONTO_RECARGA'];
            $colStart = 9;

            foreach ($headers as $index => $header) {
                $cell = \PhpOffice\PhpSpreadsheet\Cell\Coordinate::stringFromColumnIndex($colStart + $index) . '1';
                $sheet->setCellValue($cell, $header);
                $sheet->getStyle($cell)->applyFromArray($headerStyle);
                $sheet->getColumnDimension(\PhpOffice\PhpSpreadsheet\Cell\Coordinate::stringFromColumnIndex($colStart + $index))->setAutoSize(true);
            }

            $row = 2;
            foreach ($this->resumenRecarga as $item) {
                $sheet->setCellValueByColumnAndRow($colStart, $row, $item['DNI_FINAL']);
                $sheet->setCellValueByColumnAndRow($colStart + 1, $row, $item['PROYECTO']);
                $sheet->setCellValueByColumnAndRow($colStart + 2, $row, $item['MONTO']);
                $row++;
            }

            $totalRowRecarga = $row;
            $sheet->setCellValue(\PhpOffice\PhpSpreadsheet\Cell\Coordinate::stringFromColumnIndex($colStart + 1) . $totalRowRecarga, 'TOTAL GENERAL');
            
            $sheet->setCellValue(
                \PhpOffice\PhpSpreadsheet\Cell\Coordinate::stringFromColumnIndex($colStart + 2) . $totalRowRecarga,
                '=SUM(' . \PhpOffice\PhpSpreadsheet\Cell\Coordinate::stringFromColumnIndex($colStart + 2) . '2:' .
                \PhpOffice\PhpSpreadsheet\Cell\Coordinate::stringFromColumnIndex($colStart + 2) . ($totalRowRecarga - 1) . ')'
            );

            $sheet->getStyle(\PhpOffice\PhpSpreadsheet\Cell\Coordinate::stringFromColumnIndex($colStart + 1) . $totalRowRecarga . ':' .
                \PhpOffice\PhpSpreadsheet\Cell\Coordinate::stringFromColumnIndex($colStart + 2) . $totalRowRecarga)
                ->applyFromArray([
                    'fill' => ['fillType' => \PhpOffice\PhpSpreadsheet\Style\Fill::FILL_SOLID, 'startColor' => ['rgb' => 'b6d7a8']],
                    'font' => ['bold' => true],
                ]);

            $totalRowChip = count($this->resumenChip) + 2;
            $sheet->setCellValue('B' . $totalRowChip, 'TOTAL GENERAL');
            $sheet->setCellValue('C' . $totalRowChip, '=SUM(C2:C' . ($totalRowChip - 1) . ')');

            $sheet->getStyle('B' . $totalRowChip . ':C' . $totalRowChip)->applyFromArray([
                'fill' => ['fillType' => \PhpOffice\PhpSpreadsheet\Style\Fill::FILL_SOLID, 'startColor' => ['rgb' => 'b6d7a8']],
                'font' => ['bold' => true],
            ]);
        },
    ];
    }
}

class ReporteBaseRecargaSheet implements FromCollection, WithHeadings, WithStyles, WithColumnFormatting, WithTitle
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
                "Fecha",
                "Hora",
                "ID_Movto",
                "ID_Zonal",
                "UsuarioId",
                "Monto",
                "Comentario",
                "Tipo",
                "x_Activador",
                "Telefono",
                "Telefono2",
                "Valida_Dni",
                "Nombre",
                "DNI",
                "ERP_ID_PDV",
                "CONDICION",
                "CONDICION1",
                "T_MOVIMIENTO",
                "DNI_FINAL",
                "PROYECTO",
                "ZONAL",
                "ESTADO"
        ];
    }
    public function title(): string
    {
        return "BASE RECARGAS";
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
            'P' => '538DD5',
            'Q' => '538DD5',
            'R' => '538DD5',
            // 'S' => 'eebe23',
            // 'T' => 'eebe23',
            // 'P' => 'eebe23',
            // 'Q' => 'eebe23',

            // 'R' => '538DD5',
            'S' => '16d52e',
            'T' => '16d52e',
            'U' => '16d52e',
            'V' => '16d52e',
            // 'W' => '16d52e',
            // 'X' => '16d52e',

            // 'Y' => 'f7603a',
            // 'Z' => 'f7603a',
            // 'AA' => 'f7603a',

            // 'AB' => '16d52e',

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
            'B' => NumberFormat::FORMAT_DATE_TIME4, 
            // 'N' => '0%',
            // 'S' => '0%',
            // 'Y' => '"S/" #,##0.00',
            // 'AB' => '"S/" #,##0.00',
            // 'AC' => '"S/" #,##0.00',
            // 'AD' => '"S/" #,##0.00',
            // 'AE' => '"S/" #,##0.00',
            // 'AF' => '"S/" #,##0.00',
            // 'AG' => '"S/" #,##0.00',
            // 'T' => '"S/" #,##0.00',
            // 'W' => '"S/" #,##0.00',
            // 'X' => '"S/" #,##0.00',
            // 'Y' => '"S/" #,##0.00',
            // 'Z' => '"S/" #,##0.00',
            // 'AA' => '"S/" #,##0.00',
            // 'AB' => '"S/" #,##0.00',
        ];
    }
}

class ReporteBaseChipSheet implements FromCollection, WithHeadings, WithStyles, WithColumnFormatting, WithTitle
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
               "PERIODO",
                "TD_SUNAT",
                "TD",
                "NRODOC",
                "FECHA",
                "RAZON_SOCIAL",
                "TIPO_CLI",
                "TIPO_DOCCLI",
                "DOCCLI",
                "BASE",
                "IGV",
                "TOTAL",
                "SALDO",
                "ESTADO",
                "CCOD_PROD",
                "CNOM_PROD",
                "NCANT_DETA",
                "NPRECIO_VTA",
                "SUBTOTAL",
                "ALMACEN",
                "REPARTO",
                "CONDICION",
                "PROD_CATEGORIA",
                "PROD_LINEA",
                "GIRO",
                "COD_ALTERNO",
                "NOMBRE",
                "DNI",
                "DNI_FINAL",
                "PROYECTO",
                "ZONAL",
                "ESTADO"
        ];
    }
    public function title(): string
    {
        return "BASE CHIPS";
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

            // 'P' => 'eebe23',
            // 'Q' => 'eebe23',
            // 'R' => 'eebe23',
            // 'S' => 'eebe23',
            // 'T' => 'eebe23',
            'P' => '538DD5',
            'Q' => '538DD5',

            'R' => '538DD5',
            'S' => '538DD5',
            // 
            'T' => '538DD5',
            'U' => '538DD5',
            'V' => '538DD5',
            'W' => '538DD5',
            'X' => '538DD5',

            'Y' => '538DD5',
            'Z' => '538DD5',
            'AA' => '538DD5',
            'AB' => '538DD5',

            'AC' => '16d52e',
            'AD' => '16d52e',
            'AE' => '16d52e',
            'AF' => '16d52e',

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
            // 'N' => '0%',
            // 'S' => '0%',
            // 'Y' => '"S/" #,##0.00',
            // 'AB' => '"S/" #,##0.00',
            // 'AC' => '"S/" #,##0.00',
            // 'AD' => '"S/" #,##0.00',
            // 'AE' => '"S/" #,##0.00',
            // 'AF' => '"S/" #,##0.00',
            // 'AG' => '"S/" #,##0.00',
            // 'T' => '"S/" #,##0.00',
            // 'W' => '"S/" #,##0.00',
            // 'X' => '"S/" #,##0.00',
            // 'Y' => '"S/" #,##0.00',
            // 'Z' => '"S/" #,##0.00',
            // 'AA' => '"S/" #,##0.00',
            // 'AB' => '"S/" #,##0.00',
        ];
    }
}
