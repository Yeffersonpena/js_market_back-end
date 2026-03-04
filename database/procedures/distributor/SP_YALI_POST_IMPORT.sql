CREATE   PROCEDURE [dbo].[SP_YALI_POST_IMPORT]
AS
BEGIN
    --2. borrar registos no necesarios
    delete from YALI_VENTAS_TEMPO where Tipo_Mov <> 'Regularización'
    delete from YALI_VENTAS_TEMPO where NombreCliente = 'CLIENTE ANULADO'
	delete from YALI_VENTAS_CABECERA_TEMPO where [Nota de crédito] is not null
    --completando comerciales
    update YALI_VENTAS_cabecera_TEMPO set Comercial = 'WILLIAMS ALEGRIA VELA' where [número] = 'BV10-00000009'
    update YALI_VENTAS_cabecera_TEMPO set Comercial = 'DIANA MAURICIO MORENO' where [número]= 'BV30-00000026'
    update YALI_VENTAS_cabecera_TEMPO set Comercial = 'BILLY SALVADOR ARTEAGA' where [número]= 'BV30-00000028'
    update YALI_VENTAS_cabecera_TEMPO set Comercial = 'WILLIAMS ALEGRIA VELA' where [número] = 'FV10-00000037'
    update YALI_VENTAS_cabecera_TEMPO set Comercial = 'ELIZABETH ROJAS FREYRE' where [número] = 'BV10-00000040'
	update YALI_VENTAS_cabecera_TEMPO set Comercial = 'Espinoza Huaman Wilma' where [número] = 'FV20-00000040'

    --formateando el documento
    UPDATE YALI_VENTAS_TEMPO SET Num_Documento = REPLACE(NUM_DOCUMENTO, ';', '')
    --completando datos en ventas
    update y
	set
		Nif_Cliente_Prov = T.[DNI/RUC],
		x_VENDEDOR =T.COMERCIAL,
		x_forma_pago = t.[Forma pago]
    from YALI_VENTAS_TEMPO as y inner join YALI_VENTAS_CABECERA_TEMPO AS T
		on y.Num_Documento = T.[NÚMERO]
    update y
    set x_zonal = v.ZONAL
    from YALI_VENTAS_TEMPO as y inner join YALI_VENDEDOR as v on y.x_vendedor = v.NOMBRE_VENDEDOR

    --3.- insertar en tablas
    insert into yali_ventas
    SELECT [Fecha],[Fecha_Aux],[Tipo_Mov],[Con_Devolucion],[Punto_Venta],[SFID],[Tipo],[Codigo]
    ,[EAN],[Familia],[Categoria],[Imei_Icc_Sn],[Descripcion],[InfoAdicional],[Operacion],[Num_Documento]
    ,[NombreCliente],[Nif_Cliente_Prov],[Segmento],[NombreProveedor],[NifProveedor],[Autor],[Comercial]
    ,[Cantidad],[PVP_Total],[Coste_Total],[Tarifa],[Promocion],[CP],[Servicios],[Estado],[FormaPago]
    ,[Telefono],[Terminal],[Imei_Op],[Icc_Op],[Imei_Acc_Op],[Art_Op],[Articulo],[Contrato],[Servicio]
    ,[Concepto],[Aport_Terminal],[Aport_SIM],[Extra],[Total_Liq],[Precio],[Tot_Coste],[Balance]
    ,[Premiados],[Tripleta],[Modulos],[Tableta],[ImpInicial],[Cuota],[NumCuota],[BaseImponible]
    ,[IVA],[dtoporc],[totaldto],[totaldtosiniva],[Guia],[CodigoLote],[TipoRegularizacion],[documentoAbono]
    ,[CodigoPDVLiq],[Id_Order_Action],[cuotainicial],[TipoStock],[fechaOperacion],[operador],[operadorDonante]
    ,[x_vendedor],[x_zonal], pvp_total, x_forma_pago from yali_ventas_tempo where Num_Documento not in (select Num_Documento from yali_ventas)

    insert into [yali_ventas_resumen]
    select fecha, Punto_Venta, Num_Documento, NombreCliente, Nif_Cliente_Prov, Autor, Comercial,
    sum(cantidad) as cantidad,sum(pvp_total) as pvp_total, sum(coste_total) as coste_total, estado, x_vendedor, x_zonal,
    sum(pvp_total) as x_saldo, FormaPago
    FROM [DISTRIBUTOR_DATAMART].[dbo].[yali_ventas]
    where Num_Documento not in (select Num_Documento from [yali_ventas_resumen] )
    group by
    fecha, Punto_Venta, Num_Documento, NombreCliente, Nif_Cliente_Prov, Autor, Comercial, estado, x_vendedor, x_zonal, FormaPago
END;
