<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class BaseRecargadores extends Model
{
    protected $connection = 'sqlsrv';
    protected $table = 'BASE_RECARGADORES';
    public $timestamps = false;

    protected $fillable = [
        'DNI',
        'ZONAL',
        'NOMBRE',
        'NUM_RECARGA',
    ];
}

