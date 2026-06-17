<#
  live_sensor.ps1 — visualiseur TEMPS REEL du flux du tapis RF.
  A LANCER DANS UNE VRAIE FENETRE PowerShell (affichage continu).

  Affiche ~10x/s :
   - la derniere trame (decoupee sur 0xFF), chaque octet en HEX / DEC / binaire + barre
   - le "repos" (baseline) et surligne en ROUGE les octets qui en different
   - une alerte JAUNE "CHANGEMENT STABLE" quand une valeur != repos se REPETE
     (filtre les bits flippes isoles du bruit RF)
   - min/max vus par octet, la cadence (trames/s) et un apercu brut

  Touches :  [B] = fixer le repos (baseline) maintenant    [Q] = quitter

  Exemples :
    .\live_sensor.ps1
    .\live_sensor.ps1 -Port COM5 -Baud 250000
#>
param(
  [string]$Port = 'COM5',
  [int]$Baud = 250000,
  [int]$MaxBytes = 8,     # octets affiches par trame
  [int]$StableN = 3       # nb de trames identiques != repos pour declarer "stable"
)

function Frame-ToStr($f){ if($f){ ($f | ForEach-Object { $_.ToString('X2') }) -join ' ' } else { '' } }

$sp = New-Object System.IO.Ports.SerialPort($Port, $Baud, 'None', 8, 'One')
$sp.ReadTimeout = 200
$acc      = New-Object System.Collections.Generic.List[byte]
$rawTail  = New-Object System.Collections.Generic.Queue[string]
$lastVals = New-Object System.Collections.Generic.Queue[string]
$latest   = @()
$baseline = $null
$min = @{}; $max = @{}
$frameCount = 0; $rateCount = 0; $rate = 0.0
$stableMsg = ''
$rateT0 = [System.Diagnostics.Stopwatch]::StartNew()
$drawT0 = [System.Diagnostics.Stopwatch]::StartNew()

[Console]::CursorVisible = $false
try {
  $sp.Open(); $sp.DiscardInBuffer()
  Clear-Host
  while ($true) {
    # --- clavier ---
    if ([Console]::KeyAvailable) {
      $k = [Console]::ReadKey($true).Key
      if ($k -eq 'Q') { break }
      if ($k -eq 'B') { if ($latest.Count){ $baseline = $latest.Clone() }; $stableMsg = '' }
    }

    # --- lecture serie ---
    $n = $sp.BytesToRead
    if ($n -gt 0) {
      $buf = New-Object byte[] $n; $r = $sp.Read($buf, 0, $n)
      for ($i=0; $i -lt $r; $i++) {
        $b = $buf[$i]
        $rawTail.Enqueue($b.ToString('X2')); while ($rawTail.Count -gt 24){ [void]$rawTail.Dequeue() }
        if ($b -eq 0xFF) {
          if ($acc.Count -gt 0) {
            $latest = $acc.ToArray()
            $frameCount++; $rateCount++
            if (-not $baseline) { $baseline = $latest.Clone() }
            for ($p=0; $p -lt $latest.Count; $p++) {
              if (-not $min.ContainsKey($p) -or $latest[$p] -lt $min[$p]) { $min[$p] = $latest[$p] }
              if (-not $max.ContainsKey($p) -or $latest[$p] -gt $max[$p]) { $max[$p] = $latest[$p] }
            }
            $s = Frame-ToStr $latest
            $lastVals.Enqueue($s); while ($lastVals.Count -gt $StableN){ [void]$lastVals.Dequeue() }
            if ($lastVals.Count -eq $StableN) {
              $uniq = ($lastVals | Select-Object -Unique).Count
              if ($uniq -eq 1 -and $s -ne (Frame-ToStr $baseline)) { $stableMsg = $s }
            }
            $acc.Clear()
          }
        } else { $acc.Add($b) }
      }
    } else { Start-Sleep -Milliseconds 10 }

    # --- cadence (1x/s) ---
    if ($rateT0.Elapsed.TotalSeconds -ge 1) {
      $rate = $rateCount / $rateT0.Elapsed.TotalSeconds
      $rateCount = 0; $rateT0.Restart()
    }

    # --- affichage (throttle ~10x/s) ---
    if ($drawT0.Elapsed.TotalMilliseconds -lt 100) { continue }
    $drawT0.Restart()
    $W = [Console]::WindowWidth
    [Console]::SetCursorPosition(0, 0)

    function WL($txt, $col){
      $out = if ($txt.Length -ge $W){ $txt.Substring(0,$W-1) } else { $txt.PadRight($W-1) }
      if ($col){ Write-Host $out -ForegroundColor $col } else { Write-Host $out }
    }

    WL ("TAPIS RF -- LIVE   $Port @${Baud}     [B]=repos   [Q]=quitter") 'Cyan'
    WL ("trames: {0,-8} cadence: {1,5:0.0}/s" -f $frameCount, $rate) $null
    WL "" $null
    WL ("repos (baseline) : " + (Frame-ToStr $baseline)) 'DarkGray'
    WL "" $null
    WL "  oct  hex  dec  binaire    barre (0-255)                  plage" $null
    for ($p=0; $p -lt $MaxBytes; $p++) {
      if ($p -ge $latest.Count) { WL "" $null; continue }
      $v = $latest[$p]
      $bar = ('#' * [int]($v / 255 * 30)).PadRight(30)
      $bin = [Convert]::ToString($v,2).PadLeft(8,'0')
      $isDiff = ($baseline -and $p -lt $baseline.Count -and $v -ne $baseline[$p])
      $rng = if ($min.ContainsKey($p)) { "min $($min[$p]) max $($max[$p])" } else { '' }
      $line = ("  [{0}]  {1:X2}  {2,3}  {3}  {4}  {5}" -f $p, $v, $v, $bin, $bar, $rng)
      WL $line (if ($isDiff) { 'Red' } else { 'Green' })
    }
    WL "" $null
    if ($stableMsg) { WL ("*** CHANGEMENT STABLE != repos : $stableMsg ***") 'Yellow' }
    else            { WL ("(rien de stable -- au repos ou bruit isole)") 'DarkGray' }
    WL "" $null
    WL ("brut: " + ($rawTail -join ' ')) 'DarkGray'
  }
} finally {
  if ($sp.IsOpen) { $sp.Close() }; $sp.Dispose()
  [Console]::CursorVisible = $true
  Write-Host "`nArrete."
}
