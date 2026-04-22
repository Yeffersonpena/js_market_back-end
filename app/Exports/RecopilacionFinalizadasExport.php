<?php

namespace App\Exports;

use Maatwebsite\Excel\Concerns\FromArray;
use Maatwebsite\Excel\Concerns\WithEvents;
use Maatwebsite\Excel\Concerns\WithStyles;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Events\AfterSheet;
use PhpOffice\PhpSpreadsheet\Cell\Coordinate;
use PhpOffice\PhpSpreadsheet\Style\Alignment;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;

class RecopilacionFinalizadasExport implements FromArray, WithHeadings, WithStyles, WithEvents
{
    private const WIDTH_PARAGRAPH_COLUMNS = 106.57;
    private const WIDTH_PHOTO_COLUMNS = 50.00;

    public function __construct(
        private array $headings,
        private array $rows
    ) {
    }

    public function headings(): array
    {
        return $this->headings;
    }

    public function array(): array
    {
        return $this->rows;
    }

    public function styles(Worksheet $sheet): array
    {
        return [
            1 => ['font' => ['bold' => true]],
        ];
    }

    public function registerEvents(): array
    {
        return [
            AfterSheet::class => function (AfterSheet $event): void {
                $sheet = $event->sheet->getDelegate();
                $highestColumn = $sheet->getHighestColumn();
                $highestColumnIndex = Coordinate::columnIndexFromString($highestColumn);

                // Activa autofiltro en toda la fila de encabezados.
                $sheet->setAutoFilter("A1:{$highestColumn}1");

                // Auto-size en columnas no objetivo.
                for ($i = 1; $i <= $highestColumnIndex; $i++) {
                    $letter = Coordinate::stringFromColumnIndex($i);
                    $sheet->getColumnDimension($letter)->setAutoSize(true);
                }

                // Fijar ancho tipo párrafo en columnas de preguntas largas definidas.
                for ($i = 1; $i <= $highestColumnIndex; $i++) {
                    $letter = Coordinate::stringFromColumnIndex($i);
                    $heading = (string) $sheet->getCell($letter . '1')->getValue();
                    if (!$this->isParagraphTargetHeading($heading)) {
                        continue;
                    }

                    $sheet->getColumnDimension($letter)->setAutoSize(false);
                    $sheet->getColumnDimension($letter)->setWidth(self::WIDTH_PARAGRAPH_COLUMNS);
                    $sheet->getStyle($letter . ':' . $letter)->getAlignment()
                        ->setWrapText(true)
                        ->setVertical(Alignment::VERTICAL_TOP);
                }

                // Fijar ancho para todas las columnas de fotos.
                for ($i = 1; $i <= $highestColumnIndex; $i++) {
                    $letter = Coordinate::stringFromColumnIndex($i);
                    $heading = (string) $sheet->getCell($letter . '1')->getValue();
                    if (!$this->isPhotoHeading($heading)) {
                        continue;
                    }

                    $sheet->getColumnDimension($letter)->setAutoSize(false);
                    $sheet->getColumnDimension($letter)->setWidth(self::WIDTH_PHOTO_COLUMNS);
                }
            },
        ];
    }

    private function isParagraphTargetHeading(string $heading): bool
    {
        $h = $this->normalizeHeading($heading);

        return str_contains($h, 'observacion libre del jefe zonal intuicion sobre este canal')
            || str_contains($h, 'observaciones libres del jefe zonal intuicion sobre este canal')
            || str_contains($h, 'mostrando el catalogo le parece atractivo el packaging y la presentacion de los productos zync')
            || str_contains($h, 'revisando el catalogo con precios por volumen este precio le parece competitivo frente a lo que compra hoy')
            || str_contains($h, 'hay algo del producto o empaque que cambiaria o mejoraria')
            || str_contains($h, 'viendo nuestra nueva oferta comercial cuanto le interesaria comprar en el mes de mayo en que lineas de producto armaria esta compra');
    }

    private function normalizeHeading(string $text): string
    {
        $t = trim(mb_strtolower($text));
        $t = strtr($t, [
            'á' => 'a', 'é' => 'e', 'í' => 'i', 'ó' => 'o', 'ú' => 'u',
            'à' => 'a', 'è' => 'e', 'ì' => 'i', 'ò' => 'o', 'ù' => 'u',
            'ä' => 'a', 'ë' => 'e', 'ï' => 'i', 'ö' => 'o', 'ü' => 'u',
            'ñ' => 'n',
        ]);
        $t = preg_replace('/[^a-z0-9\s]/', ' ', $t) ?? $t;
        return preg_replace('/\s+/', ' ', $t) ?? $t;
    }

    private function isPhotoHeading(string $heading): bool
    {
        return str_starts_with(trim($heading), 'Fotos -');
    }
}

