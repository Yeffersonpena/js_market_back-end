<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class RcRespuestaOpcion extends Model
{
    protected $connection = 'sqlsrv';
    protected $table = 'RC_RESPUESTA_OPCION';
    protected $primaryKey = 'id';
    public $incrementing = true;
    public $timestamps = false;

    protected $fillable = [
        'respuesta_id',
        'opcion_id',
        'fecha_guardado',
        'usuario_guardado',
    ];

    protected $casts = [
        'respuesta_id' => 'integer',
        'opcion_id' => 'integer',
        'fecha_guardado' => 'datetime',
    ];

    public function respuesta()
    {
        return $this->belongsTo(RcRespuesta::class, 'respuesta_id', 'id');
    }

    public function opcion()
    {
        return $this->belongsTo(RcPreguntaOpcion::class, 'opcion_id', 'id');
    }
}
