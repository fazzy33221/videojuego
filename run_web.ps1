param(
    [int]$Port = 8060,
    [switch]$ServeOnly,
    [string]$GodotExecutable = ""
)

$ErrorActionPreference = "Stop"
$projectRoot = $PSScriptRoot
$webRoot = Join-Path $projectRoot "build\web"
$indexPath = Join-Path $webRoot "index.html"

if (-not $ServeOnly) {
    if ([string]::IsNullOrWhiteSpace($GodotExecutable)) {
        $candidate = Get-Command godot, godot4 -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($candidate) {
            $GodotExecutable = $candidate.Source
        }
    }

    if ([string]::IsNullOrWhiteSpace($GodotExecutable) -or -not (Test-Path -LiteralPath $GodotExecutable)) {
        throw "No encontré Godot 4.7.2. Instálalo y sus Web export templates, o usa -ServeOnly si ya descargaste el artefacto videojuego-web-build."
    }

    New-Item -ItemType Directory -Path $webRoot -Force | Out-Null
    Write-Host "Exportando el juego para Web con Godot..."
    & $GodotExecutable --headless --path $projectRoot --export-debug "Web" $indexPath
    if ($LASTEXITCODE -ne 0) {
        throw "La exportación Web falló (código $LASTEXITCODE)."
    }
}

if (-not (Test-Path -LiteralPath $indexPath)) {
    throw "No existe $indexPath. Exporta la build Web primero o descarga videojuego-web-build y extráelo en build\web."
}

$mimeTypes = @{
    ".html" = "text/html; charset=utf-8"
    ".js"   = "application/javascript"
    ".wasm" = "application/wasm"
    ".pck"  = "application/octet-stream"
    ".png"  = "image/png"
    ".svg"  = "image/svg+xml"
    ".json" = "application/json"
    ".css"  = "text/css; charset=utf-8"
    ".ico"  = "image/x-icon"
}

$listener = [System.Net.HttpListener]::new()
$prefix = "http://127.0.0.1:$Port/"
$listener.Prefixes.Add($prefix)
$listener.Start()

$url = $prefix
Write-Host "Juego local listo: $url"
Write-Host "Deja esta ventana abierta mientras juegas. Presiona Ctrl+C para detenerlo."

$chrome = Get-Command chrome.exe -ErrorAction SilentlyContinue | Select-Object -First 1
if ($chrome) {
    Start-Process -FilePath $chrome.Source -ArgumentList $url
} else {
    Start-Process $url
}

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        try {
            $relativePath = [Uri]::UnescapeDataString($context.Request.Url.AbsolutePath.TrimStart("/"))
            if ([string]::IsNullOrWhiteSpace($relativePath)) {
                $relativePath = "index.html"
            }

            $filePath = [IO.Path]::GetFullPath((Join-Path $webRoot $relativePath))
            $rootPrefix = [IO.Path]::GetFullPath($webRoot).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
            if (-not $filePath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath $filePath -PathType Leaf)) {
                $context.Response.StatusCode = 404
                $context.Response.Close()
                continue
            }

            $extension = [IO.Path]::GetExtension($filePath).ToLowerInvariant()
            $context.Response.ContentType = $mimeTypes[$extension]
            if (-not $context.Response.ContentType) {
                $context.Response.ContentType = "application/octet-stream"
            }
            $context.Response.Headers["Cache-Control"] = "no-store"
            $bytes = [IO.File]::ReadAllBytes($filePath)
            $context.Response.ContentLength64 = $bytes.Length
            if ($context.Request.HttpMethod -ne "HEAD") {
                $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
            }
            $context.Response.Close()
        } catch {
            $context.Response.StatusCode = 500
            $context.Response.Close()
            Write-Warning $_.Exception.Message
        }
    }
} finally {
    $listener.Stop()
    $listener.Close()
}
