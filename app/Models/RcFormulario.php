<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class RcFormulario extends Model
{
    protected $connection = 'sqlsrv';
    protected $table = 'RC_FORMULARIO';
    protected $primaryKey = 'id';
    public $timestamps = false;

    protected $fillable = [
        'codigo',
        'nombre',
        'version',
        'descripcion',
        'activo',
        'fecha_inicio_vigencia',
        'fecha_fin_vigencia',
        'usuario_creacion',
        'usuario_actualizacion',
    ];

    protected $casts = [
        'activo' => 'boolean',
        'fecha_inicio_vigencia' => 'date',
        'fecha_fin_vigencia' => 'date',
        'fecha_creacion' => 'datetime',
        'fecha_actualizacion' => 'datetime',
    ];

    public function visitas()
    {
        return $this->hasMany(RcVisitaFormulario::class, 'formulario_id', 'id');
    }

    public function secciones()
    {
        return $this->hasMany(RcSeccion::class, 'formulario_id', 'id')->orderBy('orden');
    }
}
