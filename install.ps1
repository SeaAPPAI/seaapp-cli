param([string]$Version = 'latest', [string]$InstallDir = "$env:LOCALAPPDATA\SeaApp\bin")
$ErrorActionPreference = 'Stop'
if ($Version -ne 'latest' -and $Version -notmatch '^v[0-9][A-Za-z0-9._-]*$') { throw 'Version must be latest or a v-prefixed release tag' }
if ($env:PROCESSOR_ARCHITECTURE -ne 'AMD64') { throw 'This installer supports Windows x64.' }
$release = if ($Version -eq 'latest') { 'latest/download' } else { "download/$Version" }
$base = "https://github.com/SeaAPPAI/seaapp-cli/releases/$release"
$asset = 'seaapp-windows-x64.tar.gz'
$tmp = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
  Invoke-WebRequest "$base/$asset" -OutFile "$tmp\$asset"
  Invoke-WebRequest "$base/SHA256SUMS" -OutFile "$tmp\SHA256SUMS"
  $line = @(Get-Content "$tmp\SHA256SUMS" | Where-Object { $_ -match "^[a-f0-9]{64}\s+$([regex]::Escape($asset))$" })
  if ($line.Count -ne 1) { throw 'Missing checksum' }
  $expected = ($line[0] -split '\s+')[0]
  if ((Get-FileHash "$tmp\$asset" -Algorithm SHA256).Hash.ToLower() -ne $expected) { throw 'Checksum mismatch' }
  tar -xzf "$tmp\$asset" -C $tmp seaapp.exe
  if ($LASTEXITCODE -ne 0) { throw 'Archive extraction failed' }
  New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
  Copy-Item "$tmp\seaapp.exe" "$InstallDir\seaapp.exe" -Force
  & "$InstallDir\seaapp.exe" --version
  if ($LASTEXITCODE -ne 0) { throw 'Installed binary smoke failed' }
  Write-Host "Installed to $InstallDir\seaapp.exe. Add $InstallDir to PATH if needed."
} finally { Remove-Item -Recurse -Force $tmp }
