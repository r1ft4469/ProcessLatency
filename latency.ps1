param (
	[Parameter(Mandatory=$true)][string]$process,
	[switch]$q = $false,
	[switch]$ping = $false,
	[switch]$server = $false
	)

$gameName = $process
$gameProcess = Get-Process $gameName -ErrorAction SilentlyContinue
if ($gameProcess) {
	$gameServer = Get-NetTCPConnection -OwningProcess (get-process $gameName -ErrorAction SilentlyContinue|select -expand id) -ErrorAction 	SilentlyContinue|? RemoteAddress -notlike 0.0*|? RemoteAddress -notlike 127* |Select-Object -Last 1|select -expand RemoteAddress -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
	$gamePort = Get-NetTCPConnection -OwningProcess (get-process $gameName -ErrorAction SilentlyContinue|select -expand id) -ErrorAction SilentlyContinue|? RemoteAddress -notlike 0.0*|? RemoteAddress -notlike 127*|Select-Object -Last 1|select -expand RemotePort -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
	$gamePing = ./nping.exe --tcp -q -c 1 -p $gamePort $gameServer | Select-String -Pattern "Avg\srtt:\s(\d+)" -allmatches | foreach-object {$_.matches} | foreach {$_.groups[1].value} | Select-Object -Unique
	$gameServerHost = [System.Net.Dns]::GetHostByAddress($gameServer).Hostname
} Else {
	$gamePing = 0
	$gameServer = "Not Connected"
}

if ($q) {
if ($server) {
		if ($gameServerHost) {
			write-host "$gameServerHost"
		} Else {
			write-host "$gameServer"
		}
	}
	if ($ping) {
		write-output "$gamePing ms"
	}
} Else {
	if ($server) {
		if ($gameServerHost) {
			write-host "Server : $gameServerHost"
		} Else {
			write-host "Server : $gameServer"
		}
	}
	if ($ping) {
		write-output "Ping : $gamePing ms"
	}
}