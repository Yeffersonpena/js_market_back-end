<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MenuPerfil extends Model
{
    use HasFactory;

    protected $table = 'tbl_menu_perfil';
    protected $primaryKey = 'idMenuPerfil';

    public $timestamps = false;

    protected $fillable = ['idMenu', 'idPerfil'];
}
