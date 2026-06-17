<#
  wake_probe2.ps1 — essaie d'envoyer des commandes de "reveil" au recepteur et regarde
  si des trames != beacon (donc des boutons) apparaissent. MAINTIENS un bouton (HAUT) tout du long.

  Pour chaque commande candidate : on l'envoie en boucle (~toutes les 40 ms) pendant -Window s,
  on ecoute, et on liste les trames distinctes != beacon. Une trame REPETEE = piste serieuse.

  Exemple : .\wake_probe2.ps1
            .\wake_probe2.ps1 -Window 2 -Dtr $true -Rts $true
#>
param(
  [string]$Port = 'COM5',
  [int]$Baud = 250000,
  [double]$Window = 1.5,
  [bool]$Dtr = $true,
  [bool]$Rts = $true,
  [string]$Heartbeat = '42 CE 4E'
)

# commandes candidates (hex, separes par espaces)
$cmds = @(
  'FF', '00', '55', 'AA', '42', '01', '10', '80',
  '0D', '0A', '0D 0A', '3F', '53', '52', '56', '49',
  '42 CE 4E FF'
)

function Parse-Hex($s){ ($s -split '\s+' | Where-Object { $_ } | ForEach-Object { [Convert]::ToByte($_,16) }) }

Write-Host "=== Sondeur COMMANDES : MAINTIENS HAUT tout du long (DTR=$Dtr RTS=$Rts) ===" -ForegroundColor Yellow

foreach($cmd in $cmds){
  $bytes = [byte[]](Parse-Hex $cmd)
  $sp = New-Object System.IO.Ports.SerialPort($Port, $Baud, 'None', 8, 'One')
  $sp.ReadTimeout = 150; $sp.WriteTimeout = 150
  $sp.DtrEnable = $Dtr; $sp.RtsEnable = $Rts
  $acc = New-Object System.Collections.Generic.List[byte]
  $counts = @{}; $hb = 0
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  $lastSend = [System.Diagnostics.Stopwatch]::StartNew()
  try {
    $sp.Open(); $sp.DiscardInBuffer()
    $sp.Write($bytes, 0, $bytes.Length)   # 1er envoi
    while($sw.Elapsed.TotalSeconds -lt $Window){
      if($lastSend.Elapsed.TotalMilliseconds -ge 40){ try { $sp.Write($bytes,0,$bytes.Length) } catch {}; $lastSend.Restart() }
      $n = $sp.BytesToRead
      if($n -gt 0){
        $buf = New-Object byte[] $n; $r = $sp.Read($buf,0,$n)
        for($i=0;$i -lt $r;$i++){
          $b = $buf[$i]
          if($b -eq 0xFF){
            if($acc.Count -gt 0){
              $frame = ($acc | ForEach-Object { $_.ToString('X2') }) -join ' '
              if($frame -eq $Heartbeat){ $hb++ }
              elseif($counts.ContainsKey($frame)){ $counts[$frame]++ } else { $counts[$frame]=1 }
              $acc.Clear()
            }
          } else { $acc.Add($b) }
        }
      } else { Start-Sleep -Milliseconds 5 }
    }
  } catch {
    Write-Host ("  [{0}] ERREUR : {1}" -f $cmd, $_.Exception.Message) -ForegroundColor Red
  } finally {
    if($sp.IsOpen){ $sp.Close() }; $sp.Dispose()
  }

  $nonHb = ($counts.Values | Measure-Object -Sum).Sum; if(-not $nonHb){ $nonHb=0 }
  $col = if(($counts.Values | Where-Object { $_ -ge 3 }).Count -gt 0){ 'Green' } else { 'Cyan' }
  Write-Host ("`nENVOI [{0,-12}] beacon x{1}  autres x{2}" -f $cmd, $hb, $nonHb) -ForegroundColor $col
  if($counts.Count -gt 0){
    $counts.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
      $star = if($_.Value -ge 3){ '  <== REPETE !' } else { '' }
      Write-Host ("    {0}  x{1}{2}" -f $_.Key, $_.Value, $star)
    }
  }
}
Write-Host "`nFini. Une commande qui fait apparaitre une trame REPETEE != beacon = le reveil." -ForegroundColor Green
