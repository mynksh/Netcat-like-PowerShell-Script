<#
.SYNOPSIS
    Minimal netcat-like tool in PowerShell.
.DESCRIPTION
    - Supports client (connect) and server (listen) mode.
    - Provides live interactive input/output.
    - For lab, debugging, and pentest use cases.
#>

param(
    [Parameter(Mandatory=$true)][string]$Mode,       # listen | connect
    [string]$Host = "127.0.0.1",                     # target host (connect mode)
    [int]$Port = 4444                                # port
)

function Start-Listener {
    param($Port)

    Write-Host "[+] Listening on 0.0.0.0:$Port ..."
    $listener = [System.Net.Sockets.TcpListener]$Port
    $listener.Start()
    $client = $listener.AcceptTcpClient()
    $stream = $client.GetStream()
    Write-Host "[+] Connection received!"

    $reader = New-Object IO.StreamReader($stream)
    $writer = New-Object IO.StreamWriter($stream)
    $writer.AutoFlush = $true

    # Start async reader
    Start-Job -ScriptBlock {
        param($reader)
        while ($true) {
            $line = $reader.ReadLine()
            if ($line -ne $null) { Write-Host "[Remote] $line" }
        }
    } -ArgumentList $reader | Out-Null

    while ($true) {
        $input = Read-Host
        $writer.WriteLine($input)
    }
}

function Start-Client {
    param($Host, $Port)

    Write-Host "[+] Connecting to $Host:$Port ..."
    $client = New-Object System.Net.Sockets.TcpClient($Host, $Port)
    $stream = $client.GetStream()

    $reader = New-Object IO.StreamReader($stream)
    $writer = New-Object IO.StreamWriter($stream)
    $writer.AutoFlush = $true

    # Start async reader
    Start-Job -ScriptBlock {
        param($reader)
        while ($true) {
            $line = $reader.ReadLine()
            if ($line -ne $null) { Write-Host "[Remote] $line" }
        }
    } -ArgumentList $reader | Out-Null

    while ($true) {
        $input = Read-Host
        $writer.WriteLine($input)
    }
}

# Main
if ($Mode -ieq "listen") {
    Start-Listener -Port $Port
}
elseif ($Mode -ieq "connect") {
    Start-Client -Host $Host -Port $Port
}
else {
    Write-Host "Usage: .\nc.ps1 -Mode listen -Port 4444"
    Write-Host "       .\nc.ps1 -Mode connect -Host 127.0.0.1 -Port 4444"
}
