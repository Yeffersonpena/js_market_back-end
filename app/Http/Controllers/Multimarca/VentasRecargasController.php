<?php

namespace App\Http\Controllers\Multimarca;

use App\Http\Controllers\Controller;
use App\Models\PdvOutFunnel;
use App\Models\PP2025N0;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Carbon\Carbon;

class VentasRecargasController extends Controller
{
    /**
     * Obtener lista de períodos N disponibles para el mes actual
     */
    public function getPeriodosN()
    {
        try {
            $fechaActual = Carbon::now();
            $anio = $fechaActual->year;
            $mes = $fechaActual->month;

            // Calcular cuántos N's están disponibles (la medición empezó en junio)
            $mesInicioMedicion = 6; // Junio
            $nMaximo = $mes - $mesInicioMedicion;
            
            // Si estamos antes de junio del año actual, no hay datos
            if ($nMaximo < 0) {
                return response()->json([
                    "status" => Response::HTTP_OK,
                    "message" => "La medición de N's inicia en junio",
                    "data" => []
                ], Response::HTTP_OK);
            }

            $periodosN = PP2025N0::getPeriodosNDisponibles($anio, $mes);
            
            $periodosFormateados = [];
            foreach ($periodosN as $periodo) {
                // Extraer el número del período N
                $numeroN = (int)filter_var($periodo->PERIODO_EVALUACION, FILTER_SANITIZE_NUMBER_INT);
                
                // Solo incluir períodos N válidos según el mes actual
                if ($numeroN <= $nMaximo) {
                    $periodosFormateados[] = [
                        'periodo' => $periodo->PERIODO_EVALUACION,
                        'descripcion' => $this->getDescripcionPeriodo($periodo->PERIODO_EVALUACION, $fechaActual)
                    ];
                }
            }

            return response()->json([
                "status" => Response::HTTP_OK,
                "message" => "Períodos N disponibles",
                "data" => $periodosFormateados
            ], Response::HTTP_OK);

        } catch (\Exception $ex) {
            return response()->json([
                "status" => Response::HTTP_BAD_REQUEST,
                "message" => $ex->getMessage()
            ], Response::HTTP_BAD_REQUEST);
        }
    }

    /**
     * Obtener datos de ventas y recargas por período N y vendedor
     */
    public function getVentasRecargasByN($dniVendedor, $periodoN)
    {
        try {
            $fechaActual = Carbon::now();
            $anio = $fechaActual->year;
            $mes = $fechaActual->month;

            // Obtener la fecha máxima de carga para el mes actual
            $fechaMaximaCarga = PP2025N0::getFechaMaximaCarga($anio, $mes);
            
            if (!$fechaMaximaCarga) {
                return response()->json([
                    "status" => Response::HTTP_OK,
                    "message" => "No hay datos disponibles para este período",
                    "data" => [
                        'numerosConRecarga' => [],
                        'numerosSinRecarga' => [],
                        'resumen' => [
                            'totalNumeros' => 0,
                            'numerosConRecarga' => 0,
                            'numerosSinRecarga' => 0,
                            'montoTotalRecargas' => 0
                        ]
                    ]
                ], Response::HTTP_OK);
            }

            // Obtener los datos del período N seleccionado
            $datosN = PP2025N0::getDatosByPeriodoN($dniVendedor, $periodoN, $fechaMaximaCarga);

            // Calcular el período de ventas según el N seleccionado
            $periodoVenta = $this->calcularPeriodoVenta($fechaActual, $periodoN);
            
            // Obtener teléfonos vendidos en el período correspondiente
            $telefonosVendidos = PdvOutFunnel::getTelefonosVendidosPeriodo(
                $dniVendedor, 
                $periodoVenta['inicio'], 
                $periodoVenta['fin']
            );

            // Separar números con y sin recarga
            $resultado = $this->procesarVentasRecargas($telefonosVendidos, $datosN);

            return response()->json([
                "status" => Response::HTTP_OK,
                "message" => "Datos de ventas y recargas para " . $periodoN,
                "data" => $resultado
            ], Response::HTTP_OK);

        } catch (\Exception $ex) {
            return response()->json([
                "status" => Response::HTTP_BAD_REQUEST,
                "message" => $ex->getMessage()
            ], Response::HTTP_BAD_REQUEST);
        }
    }

    /**
     * Obtener resumen de todos los períodos N para un vendedor
     */
    public function getResumenPeriodosN($dniVendedor)
    {
        try {
            $fechaActual = Carbon::now();
            $anio = $fechaActual->year;
            $mes = $fechaActual->month;

            // Calcular cuántos N's están disponibles (la medición empezó en junio)
            $mesInicioMedicion = 6; // Junio
            $nMaximo = $mes - $mesInicioMedicion;
            
            // Si estamos antes de junio del año actual, no hay datos
            if ($nMaximo < 0) {
                return response()->json([
                    "status" => Response::HTTP_OK,
                    "message" => "La medición de N's inicia en junio",
                    "data" => []
                ], Response::HTTP_OK);
            }

            $periodosN = PP2025N0::getPeriodosNDisponibles($anio, $mes);
            $fechaMaximaCarga = PP2025N0::getFechaMaximaCarga($anio, $mes);

            $resumen = [];

            foreach ($periodosN as $periodo) {
                // Extraer el número del período N
                $numeroN = (int)filter_var($periodo->PERIODO_EVALUACION, FILTER_SANITIZE_NUMBER_INT);
                
                // Solo incluir períodos N válidos según el mes actual
                if ($numeroN <= $nMaximo) {
                    $datosN = PP2025N0::getDatosByPeriodoN($dniVendedor, $periodo->PERIODO_EVALUACION, $fechaMaximaCarga);
                    
                    $periodoVenta = $this->calcularPeriodoVenta($fechaActual, $periodo->PERIODO_EVALUACION);
                    $telefonosVendidos = PdvOutFunnel::getTelefonosVendidosPeriodo(
                        $dniVendedor, 
                        $periodoVenta['inicio'], 
                        $periodoVenta['fin']
                    );

                    $resultado = $this->procesarVentasRecargas($telefonosVendidos, $datosN);

                    $resumen[] = [
                        'periodo' => $periodo->PERIODO_EVALUACION,
                        'descripcion' => $this->getDescripcionPeriodo($periodo->PERIODO_EVALUACION, $fechaActual),
                        'resumen' => $resultado['resumen']
                    ];
                }
            }

            return response()->json([
                "status" => Response::HTTP_OK,
                "message" => "Resumen de todos los períodos N",
                "data" => $resumen
            ], Response::HTTP_OK);

        } catch (\Exception $ex) {
            return response()->json([
                "status" => Response::HTTP_BAD_REQUEST,
                "message" => $ex->getMessage()
            ], Response::HTTP_BAD_REQUEST);
        }
    }

    /**
     * Procesar ventas y recargas para separar números con y sin recarga
     */
    private function procesarVentasRecargas($telefonosVendidos, $datosN)
    {
        $numerosConRecarga = [];
        $numerosSinRecarga = [];
        $montoTotalRecargas = 0;

        // Crear un mapa de teléfonos con recargas
        $telefonosConRecarga = [];
        foreach ($datosN as $dato) {
            $telefonosConRecarga[$dato->TELEFONO] = $dato;
        }

        // Procesar cada teléfono vendido
        foreach ($telefonosVendidos as $telefono) {
            if (isset($telefonosConRecarga[$telefono->TELEFONO])) {
                // Teléfono con recarga
                $datoRecarga = $telefonosConRecarga[$telefono->TELEFONO];
                $numerosConRecarga[] = [
                    'telefono' => $telefono->TELEFONO,
                    'fechaVenta' => $telefono->FECHA,
                    'montoRecarga' => (float)$datoRecarga->MONTO_RECARGADO,
                    'fechaRecarga' => $datoRecarga->FECHA_RECARGA,
                    'ventas' => $datoRecarga->VENTAS
                ];
                $montoTotalRecargas += (float)$datoRecarga->MONTO_RECARGADO;
            } else {
                // Teléfono sin recarga
                $numerosSinRecarga[] = [
                    'telefono' => $telefono->TELEFONO,
                    'fechaVenta' => $telefono->FECHA,
                    'montoAcumuladoOriginal' => (float)$telefono->MONTO_ACUMULADO_RECARGAS
                ];
            }
        }

        return [
            'numerosConRecarga' => $numerosConRecarga,
            'numerosSinRecarga' => $numerosSinRecarga,
            'resumen' => [
                'totalNumeros' => count($telefonosVendidos),
                'numerosConRecarga' => count($numerosConRecarga),
                'numerosSinRecarga' => count($numerosSinRecarga),
                'montoTotalRecargas' => $montoTotalRecargas,
                'porcentajeRecarga' => count($telefonosVendidos) > 0 ? 
                    round((count($numerosConRecarga) / count($telefonosVendidos)) * 100, 2) : 0
            ]
        ];
    }

    /**
     * Calcular el período de ventas según el N seleccionado
     */
    private function calcularPeriodoVenta($fechaActual, $periodoN)
    {
        $mesActual = $fechaActual->month;
        $anioActual = $fechaActual->year;

        // Extraer el número del período (N0, N1, N2, etc.)
        $numeroN = (int)filter_var($periodoN, FILTER_SANITIZE_NUMBER_INT);

        // Calcular el mes de venta basado en el N
        $mesVenta = $mesActual - $numeroN;
        $anioVenta = $anioActual;

        // Ajustar año si el mes es negativo
        if ($mesVenta <= 0) {
            $mesVenta += 12;
            $anioVenta--;
        }

        $fechaInicio = Carbon::create($anioVenta, $mesVenta, 1)->startOfMonth();
        $fechaFin = Carbon::create($anioVenta, $mesVenta, 1)->endOfMonth();

        return [
            'inicio' => $fechaInicio->format('Y-m-d'),
            'fin' => $fechaFin->format('Y-m-d')
        ];
    }

    /**
     * Obtener descripción del período N
     */
    private function getDescripcionPeriodo($periodoN, $fechaActual)
    {
        $numeroN = (int)filter_var($periodoN, FILTER_SANITIZE_NUMBER_INT);
        $mesActual = $fechaActual->month;
        $anioActual = $fechaActual->year;

        if ($numeroN === 0) {
            return "N0: Ventas y recargas del mes actual (" . $fechaActual->format('F Y') . ")";
        }

        $mesVenta = $mesActual - $numeroN;
        $anioVenta = $anioActual;

        if ($mesVenta <= 0) {
            $mesVenta += 12;
            $anioVenta--;
        }

        $fechaVenta = Carbon::create($anioVenta, $mesVenta, 1);
        
        return "N{$numeroN}: Ventas de " . $fechaVenta->format('F Y') . " que recargaron este mes";
    }
}