<#
  capture_buttons.ps1 — capture guidee d'UN bouton du tapis RF.

  Ecoute COM5 @250000 8N1, decoupe les trames sur 0xFF, ignore le heartbeat
  et logge toute trame != heartbeat (horodatee) en console + fichier CSV.
  A lancer une fois par bouton : pendant la duree, on tape/maintient LE bouton voulu.

  Exemples :
    .\capture_buttons.ps1 -Label haut
    .\capture_buttons.ps1 -Label droite -Seconds 8
#>
param(
  [string]$Label = 'inconnu',
  [string]$Port = 'COM5',
  [int]$Baud = 250000,
  [double]$Seconds = 7,
  [string]$Heartbeat = '42 CE 4E',   # payload 3 o (le delimiteur 0xFF n'est pas dans la trame)
  [string]$OutDir = "$PSScriptRoot\..\captures"
)

if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$log = Join-Path $OutDir ("capture-{0}-{1}.csv" -f $Label, $stamp)
"t_s,frame,label" | Out-File -FilePath $log -Encoding utf8

$sp = New-Object System.IO.Ports.SerialPort($Port, $Baud, 'None', 8, 'One')
$sp.ReadTimeout = 300
$acc = New-Object System.Collections.Generic.List[byte]
$counts = @{}
$first  = @{}
$hb = 0

$sw = [System.Diagnostics.Stopwatch]::StartNew()
try {
  $sp.Open(); $sp.DiscardInBuffer()
  Write-Host ("=== Bouton '{0}' : tape-le pendant {1}s ===" -f $Label, $Seconds) -ForegroundColor Yellow
  while ($sw.Elapsed.TotalSeconds -lt $Seconds) {
    $n = $sp.BytesToRead
    if ($n -gt 0) {
      $buf = New-Object byte[] $n; $r = $sp.Read($buf, 0, $n)
      foreach ($b in $buf[0..($r-1)]) {
        if ($b -eq 0xFF) {
          if ($acc.Count -gt 0) {
            $frame = ($acc | ForEach-Object { $_.ToString('X2') }) -join ' '
            if ($frame -eq $Heartbeat) {
              $hb++
            } else {
              $t = $sw.Elapsed.TotalSeconds
              Write-Host ("{0,7:0.00}s  {1}" -f $t, $frame) -ForegroundColor Green
              ("{0:0.000},{1},{2}" -f $t, $frame, $Label) | Out-File -FilePath $log -Append -Encoding utf8
              if ($counts.ContainsKey($frame)) { $counts[$frame]++ } else { $counts[$frame] = 1; $first[$frame] = $t }
            }
            $acc.Clear()
          }
        } else { $acc.Add($b) }
      }
    } else { Start-Sleep -Milliseconds 10 }
  }
} finally {
  if ($sp.IsOpen) { $sp.Close() }; $sp.Dispose()
}

Write-Host "`n===== RESUME ($Label) =====" -ForegroundColor Cyan
Write-Host ("heartbeat $Heartbeat ignore x{0}" -f $hb)
if ($counts.Count -eq 0) {
  Write-Host "Aucune trame != heartbeat captee." -ForegroundColor Red
} else {
  $counts.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
    Write-Host ("  {0}   x{1,-4} (1er a {2:0.00}s)" -f $_.Key, $_.Value, $first[$_.Key])
  }
}
Write-Host ("Log: {0}" -f $log)
