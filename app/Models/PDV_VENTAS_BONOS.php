<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PDV_VENTAS_BONOS extends Model
{
    protected $table = 'PDV_VENTAS_BONOS';
    protected $connection = 'sqlsrv';
    
    // Campos que pueden ser asignados masivamente
    protected $fillable = [
        'DNI_RESPONSABLE',
        'NOMBRE_RESPONSABLE', 
        'ZONAL',
        'TIPO_PDV',
        'AÑO',
        'MES',
        'VENTA_AVANCE_PREPAGO',
        'cantidadRecarga',
        'cantidadCalidad',
        'cantidadPortaPre',
        'cantidadAltaPost',
        'cantidadPortaPostOPost',
        'cantidadPortaPostOPre',
        'cantPrepagoPorta',
        'ratio',
        'ratioCalidad',
        'maxVenta',
        'VentaPrepagoLimitada',
        'unitarioPrepago',
        'unitarioRecargas',
        'precioUniCalidadAdi',
        'faltaVenta',
        'bonoDevolucionChips',
        'bonoPre',
        'bonoCalidad',
        'bonoRecargaPre',
        'bonoPortaPre',
        'bonoAltaPost',
        'bonoPortaPostOPost',
        'bonoPortaPostOPre',
        'bonoTotalEfectivo',
        'bonoTotal',
        'FECHA_CALCULO'
    ];

    // Campos que deben ser tratados como fechas
    protected $dates = [
        'FECHA_CALCULO'
    ];

    // Campos que deben ser tratados como números decimales
    protected $casts = [
        'VENTA_AVANCE_PREPAGO' => 'integer',
        'cantidadRecarga' => 'integer',
        'cantidadCalidad' => 'integer',
        'cantidadPortaPre' => 'integer',
        'cantidadAltaPost' => 'integer',
        'cantidadPortaPostOPost' => 'integer',
        'cantidadPortaPostOPre' => 'integer',
        'cantPrepagoPorta' => 'integer',
        'ratio' => 'decimal:2',
        'ratioCalidad' => 'decimal:2',
        'maxVenta' => 'integer',
        'VentaPrepagoLimitada' => 'integer',
        'unitarioPrepago' => 'decimal:2',
        'unitarioRecargas' => 'decimal:2',
        'precioUniCalidadAdi' => 'decimal:2',
        'faltaVenta' => 'integer',
        'bonoDevolucionChips' => 'decimal:2',
        'bonoPre' => 'decimal:2',
        'bonoCalidad' => 'decimal:2',
        'bonoRecargaPre' => 'decimal:2',
        'bonoPortaPre' => 'decimal:2',
        'bonoAltaPost' => 'decimal:2',
        'bonoPortaPostOPost' => 'decimal:2',
        'bonoPortaPostOPre' => 'decimal:2',
        'bonoTotalEfectivo' => 'decimal:2',
        'bonoTotal' => 'decimal:2',
        'AÑO' => 'integer',
        'MES' => 'integer',
        'DNI_RESPONSABLE' => 'integer'
    ];

    // No usar timestamps automáticos
    public $timestamps = false;

    // Clave primaria compuesta
    protected $primaryKey = ['DNI_RESPONSABLE', 'AÑO', 'MES'];
    public $incrementing = false;
}
