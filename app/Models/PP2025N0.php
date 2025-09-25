<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\DB;

class PP2025N0 extends Model
{
    protected $table = 'BD_PLANIFICACION.dbo.PP2025_N0';
    public $timestamps = false;

    protected $fillable = [
        'FECHA_CARGA',
        'PERIODO_EVALUACION',
        'PERIODO',
        'FECHA',
        'GRUPOCANAL',
        'SOCIO',
        'ZONAL',
        'ACCION',
        'DNI_RESPONSABLE',
        'DNI_VENDEDOR',
        'DOCUMENTO_CLIENTE',
        'VENTAS',
        'MONTO_RECARGADO',
        'ENTIDAD_ACTIVACION',
        'MIN_FECHA_RECARGA',
        'x_socio',
        'TELEFONO'
    ];

    /**
     * Obtener la fecha máxima de carga por mes para obtener los datos más recientes
     */
    public static function getFechaMaximaCarga($anio, $mes)
    {
        $result = DB::select("
            SELECT MAX(FECHA_CARGA) as max_fecha
            FROM BD_PLANIFICACION.dbo.PP2025_N0 
            WHERE YEAR(FECHA_CARGA) = ? 
            AND MONTH(FECHA_CARGA) = ?
        ", [$anio, $mes]);

        return $result[0]->max_fecha ?? null;
    }

    /**
     * Obtener datos por período N y vendedor
     */
    public static function getDatosByPeriodoN($dniVendedor, $periodoN, $fechaCarga)
    {
        return DB::select("
            SELECT TELEFONO, MONTO_RECARGADO, MIN_FECHA_RECARGA, PERIODO_EVALUACION, VENTAS
            FROM BD_PLANIFICACION.dbo.PP2025_N0 
            WHERE DNI_VENDEDOR = ? 
            AND PERIODO_EVALUACION = ?
            AND FECHA_CARGA = ?
            ORDER BY MIN_FECHA_RECARGA DESC
        ", [$dniVendedor, $periodoN, $fechaCarga]);
    }

    /**
     * Obtener todos los períodos N disponibles para un mes específico
     */
    public static function getPeriodosNDisponibles($anio, $mes)
    {
        $fechaMaxima = self::getFechaMaximaCarga($anio, $mes);
        
        if (!$fechaMaxima) {
            return [];
        }

        $result = DB::select("
            SELECT DISTINCT PERIODO_EVALUACION
            FROM BD_PLANIFICACION.dbo.PP2025_N0 
            WHERE FECHA_CARGA = ?
            ORDER BY PERIODO_EVALUACION
        ", [$fechaMaxima]);

        return $result;
    }

    /**
     * Obtener recargas por teléfonos específicos en un período N
     */
    public static function getRecargasByTelefonos($telefonos, $periodoN, $fechaCarga)
    {
        if (empty($telefonos)) {
            return [];
        }

        $telefonosString = implode(',', $telefonos);
        
        return DB::select("
            SELECT TELEFONO, MONTO_RECARGADO, MIN_FECHA_RECARGA, VENTAS
            FROM BD_PLANIFICACION.dbo.PP2025_N0 
            WHERE TELEFONO IN ($telefonosString)
            AND PERIODO_EVALUACION = ?
            AND FECHA_CARGA = ?
        ", [$periodoN, $fechaCarga]);
    }
}