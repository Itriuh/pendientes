# Servidor local mínimo para la app de Pendientes.
# Las notificaciones del navegador solo funcionan en http://localhost, no abriendo el archivo directo.
$puerto = 8765
$url = "http://localhost:$puerto/"
$carpeta = Join-Path $PSScriptRoot 'www'

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($url)
try {
    $listener.Start()
} catch {
    # Ya hay un servidor corriendo: solo abre la app.
    Start-Process $url
    exit
}
Start-Process $url

$tipos = @{ '.html' = 'text/html; charset=utf-8'; '.js' = 'text/javascript'; '.css' = 'text/css'; '.json' = 'application/json'; '.png' = 'image/png'; '.ico' = 'image/x-icon' }

while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    $ruta = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath.TrimStart('/'))
    if ($ruta -eq '') { $ruta = 'index.html' }
    $archivo = [IO.Path]::GetFullPath((Join-Path $carpeta $ruta))
    $res = $ctx.Response
    if ($archivo.StartsWith($carpeta) -and (Test-Path $archivo -PathType Leaf)) {
        $bytes = [IO.File]::ReadAllBytes($archivo)
        $ext = [IO.Path]::GetExtension($archivo).ToLower()
        $res.ContentType = if ($tipos[$ext]) { $tipos[$ext] } else { 'application/octet-stream' }
        $res.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
        $res.StatusCode = 404
    }
    $res.Close()
}
