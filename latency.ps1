param (
	[Parameter(Mandatory=$true)][string]$process,
	[switch]$q = $false,
	[switch]$ping = $false,
	[switch]$server = $false
	)

$ProcessName = $process
$ProcessPID = Get-Process $ProcessName -ErrorAction SilentlyContinue
if ($ProcessPID) {
	$ProcessServer = Get-NetTCPConnection -OwningProcess (get-process $ProcessName -ErrorAction SilentlyContinue|select -expand id) -ErrorAction 	SilentlyContinue|? RemoteAddress -notlike 0.0*|? RemoteAddress -notlike 127* |Select-Object -Last 1|select -expand RemoteAddress -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
	$ProcessPort = Get-NetTCPConnection -OwningProcess (get-process $ProcessName -ErrorAction SilentlyContinue|select -expand id) -ErrorAction SilentlyContinue|? RemoteAddress -notlike 0.0*|? RemoteAddress -notlike 127*|Select-Object -Last 1|select -expand RemotePort -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
	$ProcessPing = ./nping.exe --tcp -q -c 1 -p $ProcessPort $ProcessServer | Select-String -Pattern "Avg\srtt:\s(\d+)" -allmatches | foreach-object {$_.matches} | foreach {$_.groups[1].value} | Select-Object -Unique
	$ProcessServerHost = [System.Net.Dns]::GetHostByAddress($ProcessServer).Hostname
} Else {
	$ProcessPing = 0
	$ProcessServer = "Not Connected"
}

if ($q) {
if ($server) {
		if ($ProcessServerHost) {
			write-host "$ProcessServerHost"
		} Else {
			write-host "$ProcessServer"
		}
	}
	if ($ping) {
		write-output "$ProcessPing ms"
	}
} Else {
	if ($server) {
		if ($ProcessServerHost) {
			write-host "Server : $ProcessServerHost"
		} Else {
			write-host "Server : $ProcessServer"
		}
	}
	if ($ping) {
		write-output "Ping : $ProcessPing ms"
	}
}