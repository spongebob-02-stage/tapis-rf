<#
  wake_probe.ps1 — cherche comment "reveiller" le recepteur pour qu'il sorte les boutons.
  Teste les 4 etats des lignes DTR/RTS. Pendant TOUTE la duree, appuie/maintiens UN bouton.
  Pour chaque combinaison, affiche le beacon + toute trame distincte (= signal bouton si ca apparait).

  Exemple : .\wake_probe.ps1            (4 combos x 4s ; maintiens HAUT tout du long)
            .\wake_probe.ps1 -PerCombo 5
#>
param(
  [string]$Port = 'COM5',
  [int]$Baud = 250000,
  [double]$PerCombo = 4,
  [string]$Heartbeat = '42 CE 4E'
)

$combos = @(
  @{ d=$false; r=$false },
  @{ d=$true;  r=$false },
  @{ d=$false; r=$true  },
  @{ d=$true;  r=$true  }
)

Write-Host "=== Sondeur DTR/RTS : MAINTIENS un bouton (HAUT) pendant tout le test ===" -ForegroundColor Yellow

foreach($c in $combos){
  $sp = New-Object System.IO.Ports.SerialPort($Port, $Baud, 'None', 8, 'One')
  $sp.ReadTimeout = 200
  $sp.DtrEnable = $c.d
  $sp.RtsEnable = $c.r
  $acc = New-Object System.Collections.Generic.List[byte]
  $counts = @{}; $hb = 0
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  try {
    $sp.Open(); $sp.DiscardInBuffer()
    while($sw.Elapsed.TotalSeconds -lt $PerCombo){
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
      } else { Start-Sleep -Milliseconds 10 }
    }
  } catch {
    Write-Host ("  ERREUR ouverture/lecture : {0}" -f $_.Exception.Message) -ForegroundColor Red
  } finally {
    if($sp.IsOpen){ $sp.Close() }; $sp.Dispose()
  }

  $tag = ("DTR={0} RTS={1}" -f $(if($c.d){'1'}else{'0'}), $(if($c.r){'1'}else{'0'}))
  $nonHb = ($counts.Values | Measure-Object -Sum).Sum; if(-not $nonHb){ $nonHb = 0 }
  Write-Host ("`n[{0}]  beacon x{1}   autres x{2}" -f $tag, $hb, $nonHb) -ForegroundColor Cyan
  if($counts.Count -gt 0){
    $counts.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
      $star = if($_.Value -ge 3){ '  <== REPETE (signal ?)' } else { '' }
      Write-Host ("    {0}  x{1}{2}" -f $_.Key, $_.Value, $star)
    }
  } else {
    Write-Host "    (rien d'autre que le beacon)" -ForegroundColor DarkGray
  }
}
Write-Host "`nFini. Une combinaison qui sort des trames REPETEES != beacon = on tient le reveil." -ForegroundColor Green
