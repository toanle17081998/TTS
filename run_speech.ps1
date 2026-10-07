[CmdletBinding()]
param(
    [string]$ProxyUrl,
    [string]$BindAddress = '127.0.0.1',
    [ValidateRange(1, 65535)]
    [int]$Port = 8000
)

$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot

# Python does not automatically use Windows' PAC proxy settings.
if ($ProxyUrl) {
    $env:HTTP_PROXY = $ProxyUrl
    $env:HTTPS_PROXY = $ProxyUrl
} elseif (-not $env:HTTP_PROXY -and -not $env:HTTPS_PROXY) {
    $target = [Uri]'https://huggingface.co'
    $proxy = [System.Net.WebRequest]::GetSystemWebProxy()
    $resolved = $proxy.GetProxy($target)
    if ($resolved -and $resolved.AbsoluteUri -ne $target.AbsoluteUri) {
        $env:HTTP_PROXY = $resolved.AbsoluteUri
        $env:HTTPS_PROXY = $resolved.AbsoluteUri
        Write-Host 'Using the Windows system proxy for model downloads.'
    }
}

$bypass = @($env:NO_PROXY -split ',' | Where-Object { $_ })
$env:NO_PROXY = (($bypass + @('localhost', '127.0.0.1', '::1')) | Select-Object -Unique) -join ','
$env:HOST = $BindAddress
$env:PORT = [string]$Port
$env:PYTHONUNBUFFERED = '1'
$env:PYTHONIOENCODING = 'utf-8'

$python = Join-Path $PSScriptRoot '.venv\Scripts\python.exe'
if (Test-Path -LiteralPath $python) {
    & $python -u -m apps.openai_speech
} else {
    & uv run python -u -m apps.openai_speech
}
exit $LASTEXITCODE
