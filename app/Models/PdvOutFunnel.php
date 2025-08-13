<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\DB;

class PdvOutFunnel extends Model
{
    protected $table = 'PORTAL_COMERCIAL.dbo.PDV_OUT_FUNNEL';
    public $timestamps = false;

    protected $fillable = [
        'ZONAL',
        'REGION', 
        'SOCIO',
        'DNI_RESPONSABLE',
        'DNI_VENDEDOR',
        'FECHA',
        'PRODUCTO_WEB',
        'PRODUCTOORIGEN',
        'OPERADORCEDENTE',
        'TELEFONO',
        'TIPO_PREPAGO',
        'CALIDAD_CLUSTER',
        'FECHA_PRIMERA_RECARGA',
        'DOCUMENTO_CLIENTE',
        'VENTA_EXTRANJERO',
        'MONTO_ACUMULADO_RECARGAS',
        'PRODUCTO',
        'RECARGA_SI_NO',
        'MONTO_PRIMERA_RECARGA',
        'RECARGAS>5',
        'ACCION',
        'ACCION_INTERNA',
        'VENTAS_REPETIDAS',
        'TRIPLICADO_SI_NO',
        'dateUpdateFile'
    ];

    /**
     * Obtener ventas por vendedor y mes
     */
    public static function getVentasByVendedorMes($dniVendedor, $anio, $mes)
    {
        return DB::select("
            SELECT DISTINCT TELEFONO, FECHA, RECARGA_SI_NO, MONTO_ACUMULADO_RECARGAS
            FROM PORTAL_COMERCIAL.dbo.PDV_OUT_FUNNEL 
            WHERE DNI_VENDEDOR = ? 
            AND YEAR(FECHA) = ? 
            AND MONTH(FECHA) = ?
            AND PRODUCTO = 'PREPAGO'
            ORDER BY FECHA DESC
        ", [$dniVendedor, $anio, $mes]);
    }

    /**
     * Obtener teléfonos vendidos en un período específico
     */
    public static function getTelefonosVendidosPeriodo($dniVendedor, $fechaInicio, $fechaFin)
    {
        return DB::select("
            SELECT DISTINCT TELEFONO, FECHA, RECARGA_SI_NO, MONTO_ACUMULADO_RECARGAS
            FROM PORTAL_COMERCIAL.dbo.PDV_OUT_FUNNEL 
            WHERE DNI_VENDEDOR = ? 
            AND FECHA >= ? 
            AND FECHA <= ?
            AND PRODUCTO = 'PREPAGO'
            ORDER BY FECHA DESC
        ", [$dniVendedor, $fechaInicio, $fechaFin]);
    }
}