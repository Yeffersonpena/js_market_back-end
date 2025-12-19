<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AbonosPostpagoLog extends Model
{
    use HasFactory;

    protected $connection = 'sqlsrv';
    protected $table = 'abonos_postpago_log';
    public $timestamps = false;

    // Primary key compuesta - Eloquent no maneja bien PK compuestas
    // Usaremos Query Builder directamente en el controller
    protected $primaryKey = null;
    public $incrementing = false;

    // Campos de solo lectura (no se insertan desde Laravel)
    protected $fillable = [];

    protected $casts = [
        'FECHA' => 'date',
        'Alta' => 'integer',
        'Portabilidad' => 'integer',
        'TOTAL' => 'integer',
        'BONO' => 'decimal:2',
        'ESTADO_RECARGA' => 'boolean',
        'FECHA_CARGA' => 'datetime',
    ];
}

