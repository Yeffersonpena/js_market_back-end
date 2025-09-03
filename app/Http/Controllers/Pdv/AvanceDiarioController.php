<?php

namespace App\Http\Controllers\Pdv;

use Illuminate\Support\Str;
use App\Http\Controllers\Controller;
use App\Models\PDV_ENTREGABLE;
use App\Models\VI_AVANCES_DIARIOS;
use App\Models\VI_AVANCES_INFO_VENDEDOR;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\Response;

class AvanceDiarioController extends Controller
{
    public function day($dni)
    {
        $avances = VI_AVANCES_DIARIOS::where('dni', $dni)->get();
        return response()->json($avances);
    }
    // public function getAllMonto($dni, $anio, $mes){
    //     $avances = VI_AVANCES_DIARIOS::where('dni', $dni)->get();
    //     return response()->json($avances);
    // }

    public function getAllMonto($dni, $anio, $mes)
    {
        // return response()->json(["status" => Response::HTTP_OK, "message" => "usuario creado"], Response::HTTP_OK);
        try {
            $existeAvance = VI_AVANCES_DIARIOS::where('DNI_Responsable', $dni)->exists();
            // return response()->json($avances);
            if ($existeAvance) {
                $avances = VI_AVANCES_DIARIOS::where('DNI_Responsable', $dni)->get();
                $avances->makeHidden(['id', 'DNI ']);
                $totales = [
                    'ALTA PREPAGO' => 0,
                    'PORTA PREPAGO' => 0,
                    'ALTA POSTPAGO' => 0,
                    'PORTA POSTPAGO' => 0,
                    // 'new_count' => 0
                ];
                // 
                foreach ($avances as $avance) {
                    // $totales['']
                    $totales['ALTA PREPAGO'] += (int)$avance->ALTA_PREPAGO;
                    $totales['PORTA PREPAGO'] += (int)$avance->PORTA_PREPAGO;
                    $totales['ALTA POSTPAGO'] += (int)$avance->ALTA_POSTPAGO;
                    $totales['PORTA POSTPAGO'] += (int)$avance->PORTA_POSTPAGO;
                }
                return response()->json(["status" => Response::HTTP_OK, "message" => "Total --", "data" => $totales], Response::HTTP_OK);
            } else {
                return response()->json(["status" => Response::HTTP_OK, "message" => "No hay avance diario para el usuario " . $dni], Response::HTTP_OK);
            }
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }
    public function getDataPdv($dni, $anio, $mes)
    {
        try {
            $existeAvance = DB::select("EXEC spViewInfoVendedor ?, ?, ?", [$dni, $anio, $mes]);
            if ($existeAvance) {
                $infoVendedor = $existeAvance[0];
                // $dateUpdateCalidad = Carbon::now()->subDays(4)->toDateString();
                // $existeAvance = DB::statement( "EXEC spViewInfoVendedor ?, ?, ?");
                // $infoVendedor = VI_AVANCES_INFO_VENDEDOR::where('DNI_RESPONSABLE', $dni)->firstOrFail();
                $infoVendedor = [
                    "fecha" => $infoVendedor->ULTIMA_FECHA,
                    "nombrePDV" => $infoVendedor->NOMBRE_RESPONSABLE,
                    "dniResponsable" => $infoVendedor->DNI_RESPONSABLE,
                    "vendedor" => $infoVendedor->NOMBRE_VENDEDOR1,
                    "celularVendedor" => $infoVendedor->CELULAR_VENDEDOR != 0 ? $infoVendedor->CELULAR_VENDEDOR : "",
                    "canal" => $infoVendedor->ACCION,
                    "cluster" => $infoVendedor->CLUSTER_PDV_REGULAR,
                    "cuotaPrepago" => (float)$infoVendedor->CUOTA_PREPAGO,
                    "avancePrepago" => (float)$infoVendedor->{'AVANCE PREPAGO'},
                    "recargasTotales" => (float)$infoVendedor->RECARGA_TOTAL,
                    "levelPdv" => $infoVendedor->ACCION_2,
                    "textLevelPdv" => Str::contains($infoVendedor->ACCION_2, 'PDV PREMIUM') ? 'PDV PREMIUM' : $infoVendedor->ACCION_2,
                    "entidadBancaria" => $infoVendedor->{'ENTIDAD BANCARIA MM'},
                    "cctaBancario" => $infoVendedor->{'CCTA BANCARIA MM'},
                    "levelCalidad" => (float)$infoVendedor->{'CALIDAD_CLUSTER'} ?? 0,
                    "infoUpdateCalidad" => $infoVendedor->{'DATE_UPDATE_CALIDAD'} ?? 0,
                    "typeUser" => property_exists($infoVendedor, 'typeUser') ? (float) $infoVendedor->{'typeUser'} : 0
                ];
                
                // Agregar metas manuales
                $metas = $this->getMetasManuales($anio, $mes, $infoVendedor->ZONAL ?? '');
                $infoVendedor['metaPre'] = $metas['pre'];
                $infoVendedor['metaCalidad'] = $metas['calidad'];
                
                return response()->json(["status" => Response::HTTP_OK, "message" => "Información", "data" => $infoVendedor], Response::HTTP_OK);
            } else {
                return response()->json(["status" => Response::HTTP_OK, "message" => "No hay información", "data" => []], Response::HTTP_OK);
            }
        } catch (\Exception $ex) {
            return response()->json(["status" => Response::HTTP_BAD_REQUEST, "message" => $ex->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }

    private function getMetasManuales(int $anio, int $mes, string $zonal): array
    {
        // Array de metas manuales
        $metasManuales = [
            [
                'anio' => 2025,
                'mes' => 9,
                'zonal' => 'LIMA SUR',
                'pre' => 150,
                'calidad' => 40
            ],
            [
                'anio' => 2025,
                'mes' => 9,
                'zonal' => 'REGIONES',
                'pre' => 150,
                'calidad' => 45
            ]
        ];

        // Para septiembre 2025 en adelante
        if ($anio >= 2025 && $mes >= 9) {
            foreach ($metasManuales as $meta) {
                if ($meta['anio'] == $anio && $meta['mes'] <= $mes && $meta['zonal'] === $zonal) {
                    return [
                        'pre' => $meta['pre'],
                        'calidad' => $meta['calidad']
                    ];
                }
            }
        }

        // Para meses anteriores a septiembre, devolver cero
        return [
            'pre' => 0,
            'calidad' => 0
        ];
    }
}
