<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class RcVisitaFormulario extends Model
{
    protected $connection = 'sqlsrv';
    protected $table = 'RC_VISITA_FORMULARIO';
    protected $primaryKey = 'id';
    public $incrementing = true;
    public $timestamps = false;

    protected $fillable = [
        'cliente_id',
        'programacion_id',
        'formulario_id',
        'anio',
        'mes',
        'dni_usuario',
        'zonal_usuario',
        'estado',
        'porcentaje_avance',
        'cod_cliente',
        'nombre_punto',
        'direccion',
        'fecha_inicio',
        'fecha_ultima_edicion',
        'fecha_finalizacion',
        'usuario_actualizacion',
    ];

    protected $casts = [
        'cliente_id' => 'integer',
        'programacion_id' => 'integer',
        'formulario_id' => 'integer',
        'anio' => 'integer',
        'mes' => 'integer',
        'dni_usuario' => 'integer',
        'porcentaje_avance' => 'decimal:2',
        'fecha_inicio' => 'datetime',
        'fecha_ultima_edicion' => 'datetime',
        'fecha_finalizacion' => 'datetime',
    ];

    public function cliente()
    {
        return $this->belongsTo(RcClientePdv::class, 'cliente_id', 'id');
    }

    public function formulario()
    {
        return $this->belongsTo(RcFormulario::class, 'formulario_id', 'id');
    }

    public function respuestas()
    {
        return $this->hasMany(RcRespuesta::class, 'visita_id', 'id');
    }

    public function seccionEstados()
    {
        return $this->hasMany(RcVisitaSeccionEstado::class, 'visita_id', 'id');
    }
}
