<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class RcRespuestaMedia extends Model
{
    protected $connection = 'sqlsrv';
    protected $table = 'RC_RESPUESTA_MEDIA';
    protected $primaryKey = 'id';
    public $incrementing = true;
    public $timestamps = false;

    protected $fillable = [
        'respuesta_id',
        'tipo_media',
        'ruta_archivo',
        'nombre_archivo',
        'mime_type',
        'tamano_bytes',
        'orden',
        'fecha_subida',
        'usuario_subida',
    ];

    protected $casts = [
        'respuesta_id' => 'integer',
        'tamano_bytes' => 'integer',
        'orden' => 'integer',
        'fecha_subida' => 'datetime',
    ];

    public function respuesta()
    {
        return $this->belongsTo(RcRespuesta::class, 'respuesta_id', 'id');
    }
}
