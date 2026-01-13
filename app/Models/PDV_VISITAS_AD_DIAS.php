<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PDV_VISITAS_AD_DIAS extends Model
{
    use HasFactory;

    protected $connection = 'sqlsrv';
    protected $table = 'PDV_VISITAS_AD_DIAS';
    protected $primaryKey = 'id';
    public $timestamps = false;

    protected $fillable = [
        'programacion_id',
        'DIA_MES',
        'FECHA_COMPLETA',
        'PROGRAMADO',
        'es_extraordinario',
        'FECHA_CREACION',
        'USUARIO_CREACION',
        'FECHA_ACTUALIZACION',
        'USUARIO_ACTUALIZACION',
    ];

    protected $casts = [
        'programacion_id' => 'integer',
        'DIA_MES' => 'integer',
        'FECHA_COMPLETA' => 'date',
        'PROGRAMADO' => 'boolean',
        'es_extraordinario' => 'boolean',
        'FECHA_CREACION' => 'datetime',
        'FECHA_ACTUALIZACION' => 'datetime',
    ];

    /**
     * Relación con la programación
     */
    public function programacion()
    {
        return $this->belongsTo(PDV_VISITAS_AD_PROGRAMACION::class, 'programacion_id', 'id');
    }
}

