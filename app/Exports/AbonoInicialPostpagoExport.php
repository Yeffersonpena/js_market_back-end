<?php

namespace App\Exports;

use App\Models\AbonoInicialPostpago;
use Carbon\Carbon;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithStyles;
use Maatwebsite\Excel\Concerns\WithColumnFormatting;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;
use PhpOffice\PhpSpreadsheet\Style\NumberFormat;

class AbonoInicialPostpagoExport implements FromCollection, WithHeadings, WithStyles, WithColumnFormatting
{
    /**
     * @return \Illuminate\Support\Collection
     */
    public function collection()
    {
        return AbonoInicialPostpago::select([
            'FECHA_HORA_RECARGA',
            'ZONAL',
            'ACCION',
            'DNI',
            'RECARGADOR_CELULAR',
            'MONTO',
            'SE_ABONO',
        ])
            ->orderBy('FECHA_HORA_RECARGA', 'asc')
            ->get()
            ->map(function ($item) {
                return [
                    'FECHA_HORA_RECARGA' => $item->FECHA_HORA_RECARGA
                        ? Carbon::parse($item->FECHA_HORA_RECARGA)->setTimezone('America/Lima')->format('d/m/Y H:i')
                        : '',
                    'ZONAL' => $item->ZONAL ?? '',
                    'ACCION' => $item->ACCION ?? '',
                    'DNI' => $item->DNI,
                    'RECARGADOR_CELULAR' => $item->RECARGADOR_CELULAR,
                    'MONTO' => (float) $item->MONTO,
                    'SE_ABONO' => $item->SE_ABONO ? 'Sí' : 'No',
                ];
            });
    }

    /**
     * Headers del Excel
     *
     * @return array
     */
    public function headings(): array
    {
        return [
            'Fecha/Hora Recarga',
            'Zonal',
            'Acción',
            'DNI',
            'Recargador Celular',
            'Monto',
            'Se Abonó',
        ];
    }

    /**
     * Estilos del Excel
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

        return $headerStyle;
    }

    /**
     * Formato de columnas
     */
    public function columnFormats(): array
    {
        return [
            'F' => '"S/" #,##0.00', // Columna F = Monto
        ];
    }
}

