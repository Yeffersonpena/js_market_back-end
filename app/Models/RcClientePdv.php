<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class RcClientePdv extends Model
{
    protected $connection = 'sqlsrv';
    protected $table = 'RC_CLIENTE_PDV';
    protected $primaryKey = 'id';
    public $timestamps = false;

    protected $fillable = [
        'nro_documento',
        'nombre_pdv',
        'zonal',
    ];

    public function visitas()
    {
        return $this->hasMany(RcVisitaFormulario::class, 'cliente_id', 'id');
    }
}
