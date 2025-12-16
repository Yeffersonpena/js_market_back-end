<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PDV_OUT_ESQUEMA_RESUMEN extends Model
{
    protected $table = 'PDV_OUT_ESQUEMA_RESUMEN';
    protected $connection = 'sqlsrv';
    public $timestamps = false;

    protected $primaryKey = ['DNI_RESPONSABLE', 'AÑO', 'MES'];
    public $incrementing = false;

    protected $fillable = [
        'DNI_RESPONSABLE',
        'AÑO',
        'MES',
        'NOMBRE_RESPONSABLE',
        'ZONAL',
        'ACCION_1',
        'ACCION_2',
        'RANGO_MES_ANTERIOR',
        'TOTAL_RECARGAS',
        'TOTAL_VCALIDAD',
        'PRE_PORTA',
        'PORTAPRE',
        'PORTAPOS',
        'DIAS_VENTAS_RESPONSABLE',
        'VENTAS_MES_ANTERIOR',
        'VENTA_AVANCE_PREPAGO',
        'VENTA_PREPAGO_CALIDAD',
        'VentaPrepagoLimitada',
        'VentaPrepagoCalidadLimitada',
        'ratio',
        'ratioCalidad',
        'MAX_VENTA',
        'cantidadAltaPost',
        'cantidadPortaPostOPost',
        'cantidadPortaPostOPre',
        'cantPrepagoPorta',
        'bonoChips',
        'BONO_UNITARIO_EQUIPO',
        'bonoDevolucionChips',
        'precioUniCalidadAdi',
        'bonoCalidad',
        'bonoRecargaPre',
        'bonoPortaPre',
        'bonoPortaPostOPost',
        'bonoPortaPostOPre',
        'nivel_rango',
        'rango_actual',
        'tipo_bono',
        'bono_rango',
        'ratio_min_requerido',
        'bonoTotalEfectivo',
        'bonoTotal',
        'fecha_actualizacion'
    ];

    protected $casts = [
        'DNI_RESPONSABLE' => 'integer',
        'AÑO' => 'integer',
        'MES' => 'integer',
        'RANGO_MES_ANTERIOR' => 'integer',
        'TOTAL_RECARGAS' => 'integer',
        'TOTAL_VCALIDAD' => 'integer',
        'PRE_PORTA' => 'integer',
        'PORTAPRE' => 'integer',
        'PORTAPOS' => 'integer',
        'DIAS_VENTAS_RESPONSABLE' => 'integer',
        'VENTAS_MES_ANTERIOR' => 'integer',
        'VENTA_AVANCE_PREPAGO' => 'integer',
        'VENTA_PREPAGO_CALIDAD' => 'integer',
        'VentaPrepagoLimitada' => 'integer',
        'VentaPrepagoCalidadLimitada' => 'integer',
        'ratio' => 'decimal:2',
        'ratioCalidad' => 'decimal:2',
        'MAX_VENTA' => 'integer',
        'cantidadAltaPost' => 'integer',
        'cantidadPortaPostOPost' => 'integer',
        'cantidadPortaPostOPre' => 'integer',
        'cantPrepagoPorta' => 'integer',
        'bonoChips' => 'integer',
        'BONO_UNITARIO_EQUIPO' => 'decimal:2',
        'bonoDevolucionChips' => 'integer',
        'precioUniCalidadAdi' => 'decimal:2',
        'bonoCalidad' => 'decimal:2',
        'bonoRecargaPre' => 'decimal:2',
        'bonoPortaPre' => 'decimal:2',
        'bonoPortaPostOPost' => 'decimal:2',
        'bonoPortaPostOPre' => 'decimal:2',
        'nivel_rango' => 'integer',
        'rango_actual' => 'integer',
        'bono_rango' => 'decimal:2',
        'ratio_min_requerido' => 'decimal:2',
        'bonoTotalEfectivo' => 'decimal:2',
        'bonoTotal' => 'decimal:2',
        'fecha_actualizacion' => 'datetime'
    ];
}

