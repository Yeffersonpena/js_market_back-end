create view dbo.VI_INGRESO_LOG
as select 
SELECT i.[user],e.NOMBRE_RESPONSABLE,i.ip,FORMAT(i.fecha, 'yyyy-MM-dd HH:mm:ss') as 'fecha', e.ZONAL, e.ACCION_2 
FROM tbl_ingreso i
INNER JOIN PDV_OUT_ENTREGABLE e ON cast(i.[user] as char) = cast(e.DNI_RESPONSABLE as char)
WHERE e.ZONAL = 'AYACUCHO' 
AND CAST(i.fecha AS DATE) = '2025-03-24';
go;