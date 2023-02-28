# Ask the user to select the network to scan
Write-Host "Running ipconfig..."
$ipconfig = ipconfig /all
$networks = $ipconfig | Select-String "IPv4 Address.*: (\d{1,3}\.\d{1,3}\.\d{1,3}\.)" | ForEach-Object { $_.Matches.Groups[1].Value } | Where-Object { $_ -ne "127.0.0." } | Select-Object -Unique

if ($networks.Count -eq 0) {
    Write-Host "No networks found to scan."
    return
}

Write-Host "The following networks were found:"
for ($i = 0; $i -lt $networks.Count; $i++) {
    Write-Host "  $i. $($networks[$i])"
}

do {
    $selectedNetwork = Read-Host "Please select the network you want to scan (0-$($networks.Count - 1)):"
} while (-not [int]::TryParse($selectedNetwork, [ref]$null) -or [int]$selectedNetwork -lt 0 -or [int]$selectedNetwork -ge $networks.Count)

$network = $networks[$selectedNetwork]

# Scan for hosts
Write-Host "Scanning hosts on network $network..."
for ($i = 1; $i -le 255; $i++) {
    $host = $network + $i
    $ping = New-Object System.Net.NetworkInformation.Ping
    $result = $ping.Send($host, 1000)
    if ($result.Status -eq "Success") {
        Write-Host "Host $host is online."
        # Scan for TCP ports
        Write-Host "Scanning TCP ports on host $host..."
        for ($port = 1; $port -le 65535; $port++) {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $connect = $tcpClient.BeginConnect($host, $port, $null, $null)
            $wait = $connect.AsyncWaitHandle.WaitOne(100)
            if (!$wait) {
                $tcpClient.Close()
            } else {
                Write-Host "Port $port is open on host $host (TCP)."
                $tcpClient.Close()
            }
        }
        # Scan for UDP ports
        Write-Host "Scanning UDP ports on host $host..."
        for ($port = 1; $port -le 65535; $port++) {
            $udpClient = New-Object System.Net.Sockets.UdpClient
            $result = $udpClient.BeginReceive($null, $null)
            $wait = $result.AsyncWaitHandle.WaitOne(100)
            if (!$wait) {
                $udpClient.Close()
            } else {
                Write-Host "Port $port is open on host $host (UDP)."
                $udpClient.Close()
            }
        }
    } else {
        Write-Host "Host $host is offline."
    }
}
