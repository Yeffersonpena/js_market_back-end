<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class RcSeccion extends Model
{
    protected $connection = 'sqlsrv';
    protected $table = 'RC_SECCION';
    protected $primaryKey = 'id';
    public $incrementing = true;
    public $timestamps = false;

    protected $fillable = [
        'formulario_id', 'codigo', 'titulo', 'descripcion', 'orden', 'activo',
        'fecha_creacion', 'usuario_creacion', 'fecha_actualizacion', 'usuario_actualizacion',
    ];

    protected $casts = [
        'formulario_id' => 'integer',
        'orden' => 'integer',
        'activo' => 'boolean',
        'fecha_creacion' => 'datetime',
        'fecha_actualizacion' => 'datetime',
    ];

    public function formulario()
    {
        return $this->belongsTo(RcFormulario::class, 'formulario_id', 'id');
    }

    public function preguntas()
    {
        return $this->hasMany(RcPregunta::class, 'seccion_id', 'id')->orderBy('orden');
    }
}
