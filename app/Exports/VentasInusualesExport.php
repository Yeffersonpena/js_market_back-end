<?php

namespace App\Exports;

use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithStyles;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;

class VentasInusualesExport implements FromCollection, WithHeadings, WithStyles
{
    protected Carbon $fechaDesde;
    protected Carbon $fechaHasta;

    public function __construct(Carbon $fechaDesde, Carbon $fechaHasta)
    {
        $this->fechaDesde = $fechaDesde->copy()->startOfDay();
        $this->fechaHasta = $fechaHasta->copy()->endOfDay();
    }

    /**
     * @return \Illuminate\Support\Collection
     */
    public function collection()
    {
        $año = $this->fechaDesde->year;
        $mes = $this->fechaDesde->month;

        $results = DB::connection('sqlsrv')
            ->table('VentasLog as VL')
            ->join('PDV_OUT_ENTREGABLE as E', function ($join) {
                $join->on(DB::raw('CAST(VL.DNI_RESPONSABLE AS INT)'), '=', 'E.DNI_RESPONSABLE');
            })
            ->where('VL.PRODUCT_NAME', 'Postpago')
            ->where('E.AÑO', $año)
            ->where('E.MES', $mes)
            ->where('E.ESTADO', 'ACTIVO')
            ->whereBetween('VL.FECHA', [$this->fechaDesde->format('Y-m-d'), $this->fechaHasta->format('Y-m-d')])
            ->select([
                'VL.FECHA',
                DB::raw('E.ZONAL AS [ZONAL_JS]'),
                DB::raw('E.ACCION_1 AS [ACCION_JS]'),
                'VL.DNI_RESPONSABLE',
                'VL.DNI_VENDEDOR',
                DB::raw('SUM(CASE WHEN VL.OPERATION_NAME = \'Alta\' THEN 1 ELSE 0 END) AS [Alta]'),
                DB::raw('SUM(CASE WHEN VL.OPERATION_NAME = \'Portabilidad\' THEN 1 ELSE 0 END) AS [Portabilidad]'),
                DB::raw('SUM(CASE WHEN VL.OPERATION_NAME = \'Alta\' THEN 1 ELSE 0 END) + SUM(CASE WHEN VL.OPERATION_NAME = \'Portabilidad\' THEN 1 ELSE 0 END) AS [Total_general]'),
            ])
            ->groupBy('VL.FECHA', 'E.ZONAL', 'E.ACCION_1', 'VL.DNI_RESPONSABLE', 'VL.DNI_VENDEDOR')
            ->havingRaw('SUM(CASE WHEN VL.OPERATION_NAME = \'Alta\' THEN 1 ELSE 0 END) > 2')
            ->orderBy('VL.FECHA', 'asc')
            ->orderBy('E.ZONAL', 'asc')
            ->orderBy('E.ACCION_1', 'asc')
            ->orderBy('VL.DNI_RESPONSABLE', 'asc')
            ->orderBy('VL.DNI_VENDEDOR', 'asc')
            ->get();

        return $results->map(function ($item) {
            return [
                'FECHA' => $item->FECHA ? Carbon::parse($item->FECHA)->format('d/m/Y') : '',
                'ZONAL JS' => $item->ZONAL_JS ?? '',
                'ACCION JS' => $item->ACCION_JS ?? '',
                'DNI_RESPONSABLE' => $item->DNI_RESPONSABLE ?? '',
                'DNI_VENDEDOR' => $item->DNI_VENDEDOR ?? '',
                'Alta' => (int) ($item->Alta ?? 0),
                'Portabilidad' => (int) ($item->Portabilidad ?? 0),
                'Total general' => (int) ($item->Total_general ?? 0),
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
            'FECHA',
            'ZONAL JS',
            'ACCION JS',
            'DNI_RESPONSABLE',
            'DNI_VENDEDOR',
            'Alta',
            'Portabilidad',
            'Total general',
        ];
    }

    /**
     * Estilos del Excel
     */
    public function styles(Worksheet $sheet)
    {
        // Ajustar altura de la fila de encabezado
        $sheet->getRowDimension(1)->setRowHeight(30);

        // Ajustar ancho de columnas automáticamente (mínimo 10, máximo 50)
        foreach (range('A', $sheet->getHighestColumn()) as $col) {
            $sheet->getColumnDimension($col)->setAutoSize(true);
            $colWidth = $sheet->getColumnDimension($col)->getWidth();
            if ($colWidth < 10) {
                $sheet->getColumnDimension($col)->setWidth(10);
            } elseif ($colWidth > 50) {
                $sheet->getColumnDimension($col)->setWidth(50);
            }
        }

        // Aplicar bordes a todas las celdas con datos
        $lastRow = $sheet->getHighestRow();
        $lastCol = $sheet->getHighestColumn();
        if ($lastRow > 0) {
            $sheet->getStyle('A1:' . $lastCol . $lastRow)
                ->applyFromArray([
                    'borders' => [
                        'allBorders' => [
                            'borderStyle' => \PhpOffice\PhpSpreadsheet\Style\Border::BORDER_THIN,
                            'color' => ['rgb' => '000000'],
                        ],
                    ],
                ]);
        }

        // Estilo del encabezado (negrita)
        $sheet->getStyle('A1:' . $lastCol . '1')
            ->applyFromArray([
                'font' => [
                    'bold' => true,
                ],
            ]);

        return [];
    }
}

