<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        //
        $user=new User();
        $user->user='admin';
        $user->password=bcrypt('07640716');
        $user->perfil=1;
        $user->zonal='PERU';
        $user->memo=null;
        $user->save();

        $user=new User();
        $user->user='10236231';
        $user->password=bcrypt('10236231');
        $user->perfil=2;
        $user->zonal='PERU';
        $user->memo=null;
        $user->save();

        $user=new User();
        $user->user='10300144';
        $user->password=bcrypt('10300144');
        $user->perfil=3;
        $user->zonal='PERU';
        $user->memo=null;
        $user->save();
    }
}
