param (
	[Parameter(Mandatory=$true)][string]$process,
	[switch]$q = $false,
	[switch]$ping = $false,
	[switch]$server = $false,
	[switch]$plot = $false
	)

Function Show-Graph {
    [cmdletbinding()]
    [alias("Graph")]
    Param(
            # Parameter help description
            [Parameter(Mandatory=$true)]
            [int[]] $Datapoints,
            [String] $XAxisTitle = 'X-Axis',
            [String] $YAxisTitle = 'Y Axis'
    )
            
    $NumOfDatapoints = $Datapoints.Count
    $NumOfLabelsOnYAxis = 10
    $XAxis = "   "+"-"*($NumOfDatapoints+3) 
    $YAxisTitleAlphabetCounter = 0
    $YAxisTitleStartIdx = 1
    $YAxisTitleEndIdx = $YAxisTitleStartIdx + $YAxisTitle.Length -1
    
    If($YAxisTitle.Length -gt $NumOfLabelsOnYAxis){
        Write-Warning "No. Alphabets in YAxisTitle [$($YAxisTitle.Length)] can't be greator than no. of Labels on Y-Axis [$NumOfLabelsOnYAxis]"
        Write-Warning "YAxisTitle will be cropped"
    }

    If($XAxisTitle.Length -gt $XAxis.length-3){
        $XAxisLabel = "   "+$XAxisTitle
    }else{
        $XAxisLabel = "   "+(" "*(($XAxis.Length - $XAxisTitle.Length)/2))+$XAxisTitle
    }
    
    # Create a 2D Array to save datapoints  in a 2D format
    $Array = New-Object 'object[,]' ($NumOfLabelsOnYAxis+1),$NumOfDatapoints
    $Count = 0
    $Datapoints | ForEach-Object {
        $r = [Math]::Floor($_/10)
        $Array[$r,$Count] = [char] 9608
        1..$R | ForEach-Object {$Array[$_,$Count] = [char] 9608}
        $Count++
    }
 
    # Draw graph
    For($i=10;$i -gt 0;$i--){
        $Row = ''
        For($j=0;$j -lt $NumOfDatapoints;$j++){
            $Cell = $Array[$i,$j]
            $String = If([String]::IsNullOrWhiteSpace($Cell)){' '}else{$Cell}
            $Row = [string]::Concat($Row,$String)          
        }
        
        $YAxisLabel = $i*10
        
        # Condition to fix the spacing issue of a 3 digit vs 2 digit number [like 100 vs 90]  on the Y-Axis
        If("$YAxisLabel".length -lt 3){$YAxisLabel = (" "*(3-("$YAxisLabel".length)))+$YAxisLabel}
        
        If($i -in $YAxisTitleStartIdx..$YAxisTitleEndIdx){
            $YAxisLabelAlphabet = $YAxisTitle[$YAxisTitleAlphabetCounter]+" "
            $YAxisTitleAlphabetCounter++
        }
        else {
            $YAxisLabelAlphabet = '  '
        }

        # To color the graph depending upon the datapoint value
        If ($i -gt 7) {Write-Host $YAxisLabelAlphabet -ForegroundColor DarkYellow -NoNewline  ;Write-Host "$YAxisLabel|" -NoNewline; Write-Host $Row -ForegroundColor Red}
        elseif ($i -le 7 -and $i -gt 4) {Write-Host $YAxisLabelAlphabet -ForegroundColor DarkYellow -NoNewline ;Write-Host "$YAxisLabel|" -NoNewline; Write-Host $Row -ForegroundColor Yellow}
        elseif($i -le 4 -and $i -ge 1) {Write-Host $YAxisLabelAlphabet -ForegroundColor DarkYellow -NoNewline ;Write-Host "$YAxisLabel|" -NoNewline; Write-Host $Row -ForegroundColor Green}
        else {Write-Host "$YAxisLabel|"}
    }

    $XAxis # Prints X-Axis horizontal line
    Write-Host $XAxisLabel -ForegroundColor DarkYellow # Prints XAxisTitle
}

$ProcessName = $process
$ProcessPID = Get-Process $ProcessName -ErrorAction SilentlyContinue
if ($ProcessPID) {
	$ProcessServer = Get-NetTCPConnection -OwningProcess (get-process $ProcessName -ErrorAction SilentlyContinue|select -expand id) -ErrorAction 	SilentlyContinue|? RemoteAddress -notlike 0.0*|? RemoteAddress -notlike 127* |Select-Object -Last 1|select -expand RemoteAddress -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
	$ProcessPort = Get-NetTCPConnection -OwningProcess (get-process $ProcessName -ErrorAction SilentlyContinue|select -expand id) -ErrorAction SilentlyContinue|? RemoteAddress -notlike 0.0*|? RemoteAddress -notlike 127*|Select-Object -Last 1|select -expand RemotePort -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
	if ($ProcessServer) {
		$ProcessServerHost = ([System.Net.Dns]::GetHostByAddress($ProcessServer)).Hostname
	}
	if ($plot) {
		While ($ProcessPID) {
			$ProcessPing = ./nping.exe --tcp -q -c 1 -p $ProcessPort $ProcessServer | Select-String -Pattern "Avg\srtt:\s(\d+)" -allmatches | foreach-object {$_.matches} | foreach {$_.groups[1].value} | Select-Object -Unique | Out-File -FilePath .\log -Append
			$Datapoints = gc ".\log"
			$ProcessPingOutput = Get-Content ".\log" | select -Last 1
			clear
			if ($ProcessServerHost) {
				Show-Graph -Datapoints $Datapoints -XAxisTitle "$ProcessServerHost - $ProcessPingOutput ms" -YAxisTitle "Ping"
			} Else {
				Show-Graph -Datapoints $Datapoints -XAxisTitle "$ProcessServer - $ProcessPingOutput ms" -YAxisTitle "Ping"
			}
			Start-Sleep -Milliseconds 500
		}
		Remove-Item .\log
	} Else {
		$ProcessPing = ./nping.exe --tcp -q -c 1 -p $ProcessPort $ProcessServer | Select-String -Pattern "Avg\srtt:\s(\d+)" -allmatches | foreach-object {$_.matches} | foreach {$_.groups[1].value} | Select-Object -Unique
	}
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