# Laravel 11
##### Requisitos previos 
- php 8.3
- Composer
- Driver de sql server para la version de php 
- Tener instalado sql server
### Requisitos para levantar un proyecto en local
- crear la base de datos js_BD_PLANIFICACION_OUTLET_AD
- ejecutar la migración con `php artisan migrate:fresh --seed`
##### Base de datos provisional 
- Modifique el .env en la propiedad database `DB_DATABASE=BD_PLANIFICACION_OUTLET_AD``
- Elimina la basa de datos 
- Carga el .bak
- Para iniciar el servidor de laravel `php artisan serve` te mostrara la url del proyecto local en la terminal

## Actualizar el proyecto en local 
- Ejecutar el comando `composer update`

##### Habilitar el key para el jwt [optional, si no lo tines agregado en el .env]
- Generar el key con `php artisan jwt:secret` te generara un key y el mismo lo agregas en el .env `JWT_SECRET=your_generated_secret_key`

## Gerarquida de perfiles
- -2 => `Anonymous`
- -1 => `Admin`
-  0 => `Default`
-  1 => `Pdv`
-  2 => `Multimarca`    
### Nuevo id para Perfiles
- 1 => `admin`
- 2 => `pdv`
- 3 => `multimarca`
- 4 => `default`

## Documentación del ApiRest
- Postman link de la [documentación ApiRest](https://web.postman.co/workspace/jsMarket-back-end~cea7cab2-08c0-4ccb-bb37-87c3df14d617/request/42215171-1471a1e8-1f91-4105-8fb5-2c57eb1318e2)

#### user de Pruebas
#### Complemento del sql
> Para la creación de los perfiles y los usuarios ejecutar el script.sql que se encuentra en la misma ruta del readme.
- admin = user=admin , pass=07640716
- (pdv) = user=10236231
- (multimarca)= user=10300144

### 
- user pdv [45203397 = data ]  -- 10487996 
- user actual mm_ 42575210 --  [data history= 42575210]

```sh
# usuario con datos:
	[PDV]:
		con data (abono):
			10236231	
			45203397 --
			10487996
	[M.M]: 
	    	Con data:
			42575210 --

		No hay datos (avance, abono), other multimarca:AVANCE modulo si hay data
			1844532
	
	[ADMIN]:
		admin
```

### Modulos del Back-end [Admin - Pdv - MM]
#### Portal AD [PDV]
- módulos 
	- Avance de ventas
	- Histórico de ventas
	- Histórico de abonos
	- Campañas y Esquemas

#### Portal AD [Multimarca]
- módulos 
	- Multimarca: Avance
	- Histórico de abonos
	- Campañas y Esquemas
	- Avance de ventas M.M	

#### Portal AD [Admin]
- módulos 
	- Mantenimiento de perfiles
		- User (crud)
	- Mantenimiento de usuarios
	- Mantenimiento de carga de imágenes
	- Mantenimiento de carga de esquemas
	- Auditoria
