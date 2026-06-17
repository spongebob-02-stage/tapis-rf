<#
  raw_dump.ps1 — enregistre le flux brut du recepteur RF, SANS supposer de cadrage.
  Ecrit tous les octets (hex, horodates par paquet de lecture) dans captures\raw-*.txt,
  puis affiche une analyse : nb d'octets, histogramme des longueurs de trame (decoupe FF),
  trames distinctes les plus frequentes, et entropie par position.

  Exemple : .\raw_dump.ps1 -Label haut -Seconds 10
#>
param(
  [string]$Label = 'raw',
  [string]$Port = 'COM5',
  [int]$Baud = 250000,
  [double]$Seconds = 10,
  [string]$OutDir = "$PSScriptRoot\..\captures"
)

if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$raw = Join-Path $OutDir ("raw-{0}-{1}.txt" -f $Label, $stamp)

$sp = New-Object System.IO.Ports.SerialPort($Port, $Baud, 'None', 8, 'One')
$sp.ReadTimeout = 300
$all = New-Object System.Collections.Generic.List[byte]
$sw = [System.Diagnostics.Stopwatch]::StartNew()
try {
  $sp.Open(); $sp.DiscardInBuffer()
  Write-Host ("=== RAW '{0}' {1}s @ {2} : tape le bouton ===" -f $Label, $Seconds, $Baud) -ForegroundColor Yellow
  while ($sw.Elapsed.TotalSeconds -lt $Seconds) {
    $n = $sp.BytesToRead
    if ($n -gt 0) {
      $buf = New-Object byte[] $n; $r = $sp.Read($buf, 0, $n)
      for ($i=0; $i -lt $r; $i++) { $all.Add($buf[$i]) }
    } else { Start-Sleep -Milliseconds 5 }
  }
} finally {
  if ($sp.IsOpen) { $sp.Close() }; $sp.Dispose()
}

# dump hex brut
($all | ForEach-Object { $_.ToString('X2') }) -join ' ' | Out-File -FilePath $raw -Encoding ascii

# ---- analyse ----
Write-Host ("`n===== ANALYSE ({0} octets) =====" -f $all.Count) -ForegroundColor Cyan

# decoupe sur 0xFF
$frames = New-Object System.Collections.Generic.List[string]
$acc = New-Object System.Collections.Generic.List[byte]
foreach ($b in $all) {
  if ($b -eq 0xFF) {
    if ($acc.Count -gt 0) { $frames.Add( (($acc | ForEach-Object { $_.ToString('X2') }) -join ' ') ) }
    $acc.Clear()
  } else { $acc.Add($b) }
}

Write-Host ("Trames (decoupe sur FF) : {0}" -f $frames.Count)
Write-Host "Histogramme des LONGUEURS de trame :"
$frames | Group-Object { ($_ -split ' ').Count } | Sort-Object Name | ForEach-Object {
  Write-Host ("  {0} octet(s) : {1}" -f $_.Name, $_.Count)
}

Write-Host "`nTrames distinctes (top 15) :"
$frames | Group-Object | Sort-Object Count -Descending | Select-Object -First 15 | ForEach-Object {
  Write-Host ("  {0,5}x  {1}" -f $_.Count, $_.Name)
}

Write-Host ("`nRaw: {0}" -f $raw)
