-- =============================================
-- sp_Recopilacion_Puntos_Pendientes
-- Devuelve los puntos (RC_CLIENTE_PDV) de una zonal que aun no tienen
-- la recopilacion finalizada para el formulario y periodo dados.
-- Incluye puntos sin visita y puntos con visita en borrador/en_progreso.
-- =============================================
CREATE PROCEDURE sp_Recopilacion_Puntos_Pendientes
    @zonal VARCHAR(100),
    @anio INT,
    @mes INT,
    @formulario_codigo VARCHAR(50) = 'DATOS_PDV_VENTAS'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @formulario_id INT;

    SELECT @formulario_id = id
    FROM dbo.RC_FORMULARIO
    WHERE codigo = @formulario_codigo
      AND activo = 1
    ORDER BY version DESC
    OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY;

    IF @formulario_id IS NULL
    BEGIN
        RAISERROR('No existe formulario activo con codigo %s.', 16, 1, @formulario_codigo);
        RETURN;
    END

    SELECT
        c.id AS cliente_id,
        c.nro_documento,
        c.nombre_pdv,
        c.zonal,
        v.id AS visita_id,
        v.estado AS estado_visita,
        v.porcentaje_avance,
        v.fecha_ultima_edicion
    FROM dbo.RC_CLIENTE_PDV c
    LEFT JOIN dbo.RC_VISITA_FORMULARIO v
        ON v.cliente_id = c.id
        AND v.formulario_id = @formulario_id
        AND v.anio = @anio
        AND v.mes = @mes
    WHERE c.zonal = @zonal
      AND (v.id IS NULL OR v.estado <> 'finalizado')
    ORDER BY v.estado ASC, v.porcentaje_avance DESC, c.nombre_pdv;
END;
