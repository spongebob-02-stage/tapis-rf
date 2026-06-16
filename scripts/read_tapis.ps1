<#
  read_tapis.ps1 — écoute le tapis RF sur le port série et affiche les trames.
  Liaison : COM5, 250000 bauds, 8N1. Trame = 4 octets, délimiteur 0xFF.

  Exemples :
    .\read_tapis.ps1                       # COM5, affiche les trames distinctes en continu
    .\read_tapis.ps1 -Port COM5 -Seconds 10
    .\read_tapis.ps1 -Raw                  # dump hexa brut
#>
param(
  [string]$Port = 'COM5',
  [int]$Baud = 250000,
  [int]$Seconds = 0,        # 0 = infini (Ctrl+C pour arrêter)
  [switch]$Raw
)

$sp = New-Object System.IO.Ports.SerialPort($Port, $Baud, 'None', 8, 'One')
$sp.ReadTimeout = 300
$acc = New-Object System.Collections.Generic.List[byte]
$last = $null
$sw = [System.Diagnostics.Stopwatch]::StartNew()

try {
  $sp.Open(); $sp.DiscardInBuffer()
  Write-Host "Ecoute $Port @${Baud} 8N1 (Ctrl+C pour arreter)..." -ForegroundColor Cyan
  while ($Seconds -le 0 -or $sw.Elapsed.TotalSeconds -lt $Seconds) {
    $n = $sp.BytesToRead
    if ($n -gt 0) {
      $buf = New-Object byte[] $n; $r = $sp.Read($buf, 0, $n)
      foreach ($b in $buf[0..($r-1)]) {
        if ($Raw) { Write-Host ('{0:X2} ' -f $b) -NoNewline; continue }
        if ($b -eq 0xFF) {
          if ($acc.Count -gt 0) {
            $frame = ($acc | ForEach-Object { $_.ToString('X2') }) -join ' '
            if ($frame -ne $last) {
              Write-Host ("{0,8:0.00}s  {1} FF" -f $sw.Elapsed.TotalSeconds, $frame)
              $last = $frame
            }
            $acc.Clear()
          }
        } else { $acc.Add($b) }
      }
    } else { Start-Sleep -Milliseconds 20 }
  }
} finally {
  if ($sp.IsOpen) { $sp.Close() }; $sp.Dispose()
}
