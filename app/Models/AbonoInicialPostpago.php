<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AbonoInicialPostpago extends Model
{
    use HasFactory;

    protected $connection = 'sqlsrv';
    protected $table = 'abono_inicial_postpago';
    protected $primaryKey = 'ID';
    public $timestamps = false;

    protected $fillable = [
        'FECHA_HORA_RECARGA',
        'ZONAL',
        'ACCION',
        'DNI',
        'RECARGADOR_CELULAR',
        'MONTO',
        'SE_ABONO',
    ];

    protected $casts = [
        'SE_ABONO' => 'boolean',
        'MONTO' => 'decimal:2',
        'FECHA_HORA_RECARGA' => 'datetime',
    ];
}


