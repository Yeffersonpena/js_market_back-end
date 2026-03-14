<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class RcPreguntaOpcion extends Model
{
    protected $connection = 'sqlsrv';
    protected $table = 'RC_PREGUNTA_OPCION';
    protected $primaryKey = 'id';
    public $incrementing = true;
    public $timestamps = false;

    protected $fillable = [
        'pregunta_id', 'codigo', 'etiqueta', 'valor', 'orden', 'activo',
        'fecha_creacion', 'usuario_creacion', 'fecha_actualizacion', 'usuario_actualizacion',
    ];

    protected $casts = [
        'pregunta_id' => 'integer',
        'orden' => 'integer',
        'activo' => 'boolean',
        'fecha_creacion' => 'datetime',
        'fecha_actualizacion' => 'datetime',
    ];

    public function pregunta()
    {
        return $this->belongsTo(RcPregunta::class, 'pregunta_id', 'id');
    }
}
