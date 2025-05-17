<!DOCTYPE html>
<html>
<head>
    <title>Descargar Reporte</title>
</head>
<body>
    <h1>Reporte General</h1>

    <form action="{{ route('reporteAll.reporte.api') }}" method="GET">
        <button type="submit">📥 Descargar Reporte Excel</button>
    </form>

    <br>
    <br>
    <form action="{{ route('getReporteMM.reporte.api', ['typeReporte'=>1]) }}" method="GET">
        <button type="submit">📥 Descargar Reporte multimarca Excel</button>
    </form>
    <br>
    <br>
    <form action="{{ route('getReportePdv.reporte.api', ['typeReporte'=>1]) }}" method="GET">
        <button type="submit">📥 Descargar Reporte Pdv Excel</button>
    </form>
    <br>
    <form action="{{ route('getFinanza.reporte.api', ['typeReporte'=>1]) }}" method="GET">
        <button type="submit">📥 Descargar Reporte de Finanza Excel</button>
    </form>
    <br>
</body>
</html>
