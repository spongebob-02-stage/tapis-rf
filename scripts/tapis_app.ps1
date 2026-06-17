<#
  tapis_app.ps1 — application fenetree (WPF) : visualisation TEMPS REEL du recepteur RF + historique.
  A LANCER DANS UNE FENETRE PowerShell (ouvre sa propre fenetre graphique).

  - Trame courante : chaque octet en hex/dec + barre 0-255 ; ROUGE si != repos.
  - Historique : un log qui ajoute une ligne a CHAQUE changement de trame
      gris  = repos / heartbeat
      orange= ecart vs repos (probable bruit si isole)
      jaune = ecart STABLE (s'est repete -> reaction reelle probable)
  - Tableau des trames distinctes + compteur (rafraichi 1x/s).
  - Boutons : Fixer le repos | Pause | Effacer | Exporter CSV.

  Exemple : .\tapis_app.ps1            (COM5 @250000 par defaut)
            .\tapis_app.ps1 -Port COM5 -Baud 250000
#>
param(
  [string]$Port = 'COM5',
  [int]$Baud = 250000,
  [int]$MaxBytes = 6,
  [int]$StableN = 3
)

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Xaml

# ---------- helpers ----------
function Frame-ToStr($f){ if($f){ ($f | ForEach-Object { $_.ToString('X2') }) -join ' ' } else { '' } }
function Diff-Desc($cur, $base){
  if(-not $base){ return '' }
  $d = @()
  $m = [Math]::Max($cur.Count, $base.Count)
  for($i=0;$i -lt $m;$i++){
    $a = if($i -lt $base.Count){ $base[$i] } else { $null }
    $b = if($i -lt $cur.Count){ $cur[$i] } else { $null }
    if($a -ne $b){ $d += ('oct{0} {1}->{2}' -f $i, ('{0:X2}' -f $a), ('{0:X2}' -f $b)) }
  }
  $d -join ' '
}

# ---------- XAML ----------
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Tapis RF - recepteur live" Height="660" Width="940" Background="#1E1E1E">
  <Grid Margin="10">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <StackPanel Grid.Row="0" Orientation="Horizontal">
      <TextBlock x:Name="lblConn" Foreground="#4FC3F7" FontFamily="Consolas" FontSize="14" Margin="0,0,24,0"/>
      <TextBlock x:Name="lblStats" Foreground="#DDDDDD" FontFamily="Consolas" FontSize="14"/>
    </StackPanel>

    <Border Grid.Row="1" Margin="0,8,0,8" Padding="8" Background="#252526" CornerRadius="4">
      <StackPanel x:Name="panelBytes" Orientation="Horizontal"/>
    </Border>

    <Grid Grid.Row="2">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="2*"/>
        <ColumnDefinition Width="*"/>
      </Grid.ColumnDefinitions>
      <ListView x:Name="lvHist" Grid.Column="0" Margin="0,0,8,0"
                Background="#111111" Foreground="#DDDDDD" FontFamily="Consolas" FontSize="13" BorderBrush="#333333">
        <ListView.ItemContainerStyle>
          <Style TargetType="ListViewItem">
            <Setter Property="Foreground" Value="{Binding Brush}"/>
            <Setter Property="Background" Value="Transparent"/>
          </Style>
        </ListView.ItemContainerStyle>
        <ListView.View>
          <GridView>
            <GridViewColumn Header="t (s)" Width="70"  DisplayMemberBinding="{Binding Time}"/>
            <GridViewColumn Header="trame" Width="150" DisplayMemberBinding="{Binding Frame}"/>
            <GridViewColumn Header="note"  Width="300" DisplayMemberBinding="{Binding Note}"/>
          </GridView>
        </ListView.View>
      </ListView>
      <ListView x:Name="lvCounts" Grid.Column="1"
                Background="#111111" Foreground="#DDDDDD" FontFamily="Consolas" FontSize="13" BorderBrush="#333333">
        <ListView.View>
          <GridView>
            <GridViewColumn Header="trame distincte" Width="150" DisplayMemberBinding="{Binding Frame}"/>
            <GridViewColumn Header="x" Width="80" DisplayMemberBinding="{Binding Count}"/>
          </GridView>
        </ListView.View>
      </ListView>
    </Grid>

    <StackPanel Grid.Row="3" Orientation="Horizontal" Margin="0,8,0,0">
      <Button x:Name="btnBase"   Content="Fixer le repos"   Width="120" Margin="0,0,8,0"/>
      <Button x:Name="btnPause"  Content="Pause"            Width="90"  Margin="0,0,8,0"/>
      <Button x:Name="btnClear"  Content="Effacer"          Width="90"  Margin="0,0,8,0"/>
      <Button x:Name="btnExport" Content="Exporter CSV"     Width="120" Margin="0,0,8,0"/>
      <TextBlock x:Name="lblMsg" Foreground="#FFD54F" FontFamily="Consolas" FontSize="13" VerticalAlignment="Center"/>
    </StackPanel>
  </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$win = [Windows.Markup.XamlReader]::Load($reader)

# refs UI
$lblConn  = $win.FindName('lblConn')
$lblStats = $win.FindName('lblStats')
$lblMsg   = $win.FindName('lblMsg')
$panelBytes = $win.FindName('panelBytes')
$lvHist   = $win.FindName('lvHist')
$lvCounts = $win.FindName('lvCounts')
$btnBase  = $win.FindName('btnBase')
$btnPause = $win.FindName('btnPause')
$btnClear = $win.FindName('btnClear')
$btnExport= $win.FindName('btnExport')

$lblConn.Text = "$Port @ $Baud  8N1"

# ---------- etat (script scope) ----------
$script:sp = New-Object System.IO.Ports.SerialPort($Port, $Baud, 'None', 8, 'One')
$script:sp.ReadTimeout = 150
$script:acc       = New-Object System.Collections.Generic.List[byte]
$script:latest    = @()
$script:baseline  = $null
$script:counts    = @{}
$script:lastVals  = New-Object System.Collections.Generic.Queue[string]
$script:prevStr   = ''
$script:frameCount= 0
$script:rateCount = 0
$script:rate      = 0.0
$script:paused    = $false
$script:min = @{}; $script:max = @{}
$script:history    = New-Object System.Collections.ObjectModel.ObservableCollection[object]
$script:countsView = New-Object System.Collections.ObjectModel.ObservableCollection[object]
$lvHist.ItemsSource   = $script:history
$lvCounts.ItemsSource = $script:countsView
$script:sw     = [System.Diagnostics.Stopwatch]::StartNew()
$script:rateT0 = [System.Diagnostics.Stopwatch]::StartNew()
$script:cntT0  = [System.Diagnostics.Stopwatch]::StartNew()

$brHb     = [System.Windows.Media.Brushes]::Gray
$brDiff   = [System.Windows.Media.Brushes]::Orange
$brStable = [System.Windows.Media.Brushes]::Gold
$brNorm   = [System.Windows.Media.Brushes]::Gainsboro
$brBarOk  = [System.Windows.Media.Brushes]::MediumSeaGreen
$brBarDif = [System.Windows.Media.Brushes]::OrangeRed

# ---------- panneaux octets ----------
$script:byteCtls = @()
for($p=0; $p -lt $MaxBytes; $p++){
  $bd = New-Object System.Windows.Controls.Border
  $bd.Margin = '0,0,10,0'; $bd.Padding = '8,4,8,4'; $bd.CornerRadius = '4'
  $bd.Background = [System.Windows.Media.Brushes]::Black
  $bd.BorderThickness = '1'; $bd.BorderBrush = [System.Windows.Media.Brushes]::DimGray
  $sp2 = New-Object System.Windows.Controls.StackPanel
  $lblIdx = New-Object System.Windows.Controls.TextBlock
  $lblIdx.Text = "[$p]"; $lblIdx.Foreground=[System.Windows.Media.Brushes]::SteelBlue; $lblIdx.FontFamily='Consolas'
  $lblHex = New-Object System.Windows.Controls.TextBlock
  $lblHex.FontFamily='Consolas'; $lblHex.FontSize=26; $lblHex.Foreground=[System.Windows.Media.Brushes]::White
  $lblDec = New-Object System.Windows.Controls.TextBlock
  $lblDec.FontFamily='Consolas'; $lblDec.FontSize=12; $lblDec.Foreground=[System.Windows.Media.Brushes]::Silver
  $bar = New-Object System.Windows.Controls.ProgressBar
  $bar.Minimum=0; $bar.Maximum=255; $bar.Width=110; $bar.Height=12; $bar.Margin='0,4,0,0'; $bar.Foreground=$brBarOk
  $lblRng = New-Object System.Windows.Controls.TextBlock
  $lblRng.FontFamily='Consolas'; $lblRng.FontSize=10; $lblRng.Foreground=[System.Windows.Media.Brushes]::DimGray
  [void]$sp2.Children.Add($lblIdx); [void]$sp2.Children.Add($lblHex); [void]$sp2.Children.Add($lblDec)
  [void]$sp2.Children.Add($bar);    [void]$sp2.Children.Add($lblRng)
  $bd.Child = $sp2
  [void]$panelBytes.Children.Add($bd)
  $script:byteCtls += [pscustomobject]@{ Border=$bd; Hex=$lblHex; Dec=$lblDec; Bar=$bar; Rng=$lblRng }
}

# ---------- boucle de lecture (DispatcherTimer) ----------
$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromMilliseconds(40)
$timer.Add_Tick({
  if($script:paused){ return }
  try {
    $n = $script:sp.BytesToRead
    if($n -gt 0){
      $buf = New-Object byte[] $n; $r = $script:sp.Read($buf,0,$n)
      for($i=0;$i -lt $r;$i++){
        $b = $buf[$i]
        if($b -eq 0xFF){
          if($script:acc.Count -gt 0){
            $script:latest = $script:acc.ToArray()
            $script:frameCount++; $script:rateCount++
            if(-not $script:baseline){ $script:baseline = $script:latest.Clone() }
            for($p=0;$p -lt $script:latest.Count;$p++){
              $v=$script:latest[$p]
              if(-not $script:min.ContainsKey($p) -or $v -lt $script:min[$p]){ $script:min[$p]=$v }
              if(-not $script:max.ContainsKey($p) -or $v -gt $script:max[$p]){ $script:max[$p]=$v }
            }
            $s = Frame-ToStr $script:latest
            if($script:counts.ContainsKey($s)){ $script:counts[$s]++ } else { $script:counts[$s]=1 }
            $bl = Frame-ToStr $script:baseline
            $script:lastVals.Enqueue($s); while($script:lastVals.Count -gt $StableN){ [void]$script:lastVals.Dequeue() }
            $stable = $false
            if($script:lastVals.Count -eq $StableN){
              if((($script:lastVals | Select-Object -Unique).Count -eq 1) -and ($s -ne $bl)){ $stable=$true }
            }
            if($s -ne $script:prevStr){
              if($s -eq $bl){ $note='repos'; $brush=$brHb }
              elseif($stable){ $note='STABLE ! ' + (Diff-Desc $script:latest $script:baseline); $brush=$brStable }
              else { $note='ecart : ' + (Diff-Desc $script:latest $script:baseline); $brush=$brDiff }
              $item = [pscustomobject]@{ Time=('{0:0.00}' -f $script:sw.Elapsed.TotalSeconds); Frame=$s; Note=$note; Brush=$brush }
              $script:history.Insert(0,$item)
              while($script:history.Count -gt 1000){ $script:history.RemoveAt($script:history.Count-1) }
              if($stable){ $script:lblMsg.Text = "CHANGEMENT STABLE : $s" }
              $script:prevStr = $s
            }
            $script:acc.Clear()
          }
        } else { $script:acc.Add($b) }
      }
    }
  } catch {}

  # maj trame courante
  for($p=0;$p -lt $script:byteCtls.Count;$p++){
    $c = $script:byteCtls[$p]
    if($p -lt $script:latest.Count){
      $v = $script:latest[$p]
      $c.Border.Visibility = 'Visible'
      $c.Hex.Text = ('{0:X2}' -f $v); $c.Dec.Text = "$v"
      $c.Bar.Value = $v
      $isDiff = ($script:baseline -and $p -lt $script:baseline.Count -and $v -ne $script:baseline[$p])
      $c.Bar.Foreground = if($isDiff){ $brBarDif } else { $brBarOk }
      $c.Border.BorderBrush = if($isDiff){ $brBarDif } else { [System.Windows.Media.Brushes]::DimGray }
      $c.Hex.Foreground = if($isDiff){ [System.Windows.Media.Brushes]::OrangeRed } else { [System.Windows.Media.Brushes]::White }
      if($script:min.ContainsKey($p)){ $c.Rng.Text = ("{0}..{1}" -f $script:min[$p], $script:max[$p]) }
    } else { $c.Border.Visibility = 'Collapsed' }
  }

  # cadence 1x/s
  if($script:rateT0.Elapsed.TotalSeconds -ge 1){
    $script:rate = $script:rateCount / $script:rateT0.Elapsed.TotalSeconds
    $script:rateCount = 0; $script:rateT0.Restart()
  }
  $bl2 = Frame-ToStr $script:baseline
  $lblStats.Text = ("trames {0}   {1:0.0}/s   distinctes {2}   repos [{3}]" -f $script:frameCount, $script:rate, $script:counts.Count, $bl2)

  # tableau distinctes 1x/s
  if($script:cntT0.Elapsed.TotalSeconds -ge 1){
    $script:cntT0.Restart()
    $script:countsView.Clear()
    foreach($e in ($script:counts.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 20)){
      $script:countsView.Add([pscustomobject]@{ Frame=$e.Key; Count=$e.Value })
    }
  }
})

# ---------- boutons ----------
$btnBase.Add_Click({
  if($script:latest.Count){ $script:baseline = $script:latest.Clone(); $script:lblMsg.Text = "repos fige : " + (Frame-ToStr $script:baseline) }
})
$btnPause.Add_Click({
  $script:paused = -not $script:paused
  $btnPause.Content = if($script:paused){ 'Reprendre' } else { 'Pause' }
})
$btnClear.Add_Click({
  $script:history.Clear(); $script:counts.Clear(); $script:countsView.Clear()
  $script:frameCount=0; $script:prevStr=''; $script:lblMsg.Text=''
})
$btnExport.Add_Click({
  try{
    $dir = Join-Path $PSScriptRoot '..\captures'
    if(-not (Test-Path $dir)){ New-Item -ItemType Directory -Path $dir | Out-Null }
    $file = Join-Path $dir ("app-hist-{0}.csv" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
    "t_s,frame,note" | Out-File $file -Encoding utf8
    foreach($h in $script:history){ ('{0},{1},{2}' -f $h.Time, $h.Frame, ($h.Note -replace ',',';')) | Out-File $file -Append -Encoding utf8 }
    $script:lblMsg.Text = "exporte : $file"
  } catch { $script:lblMsg.Text = "echec export : $($_.Exception.Message)" }
})

# ---------- ouverture / fermeture ----------
try { $script:sp.Open(); $script:sp.DiscardInBuffer() }
catch {
  [System.Windows.MessageBox]::Show("Impossible d'ouvrir $Port a $Baud :`n$($_.Exception.Message)`n`n(port deja ouvert ailleurs ? mauvais COM ?)","Erreur serie") | Out-Null
  return
}
$win.Add_Closed({
  $timer.Stop()
  if($script:sp.IsOpen){ $script:sp.Close() }
  $script:sp.Dispose()
})

$timer.Start()
$win.ShowDialog() | Out-Null
