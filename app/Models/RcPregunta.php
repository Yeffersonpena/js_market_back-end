<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class RcPregunta extends Model
{
    protected $connection = 'sqlsrv';
    protected $table = 'RC_PREGUNTA';
    protected $primaryKey = 'id';
    public $incrementing = true;
    public $timestamps = false;

    protected $fillable = [
        'seccion_id',
        'codigo',
        'texto',
        'texto_ayuda',
        'tipo_respuesta',
        'obligatoria',
        'permite_no_aplica',
        'requiere_foto',
        'min_fotos',
        'max_fotos',
        'orden',
        'activo',
        'max_longitud',
        'valor_minimo',
        'valor_maximo',
        'fecha_creacion',
        'usuario_creacion',
        'fecha_actualizacion',
        'usuario_actualizacion',
    ];

    protected $casts = [
        'seccion_id' => 'integer',
        'obligatoria' => 'boolean',
        'permite_no_aplica' => 'boolean',
        'requiere_foto' => 'boolean',
        'min_fotos' => 'integer',
        'max_fotos' => 'integer',
        'orden' => 'integer',
        'activo' => 'boolean',
        'max_longitud' => 'integer',
        'valor_minimo' => 'decimal:4',
        'valor_maximo' => 'decimal:4',
        'fecha_creacion' => 'datetime',
        'fecha_actualizacion' => 'datetime',
    ];

    public function seccion()
    {
        return $this->belongsTo(RcSeccion::class, 'seccion_id', 'id');
    }

    public function opciones()
    {
        return $this->hasMany(RcPreguntaOpcion::class, 'pregunta_id', 'id')->orderBy('orden');
    }
}

