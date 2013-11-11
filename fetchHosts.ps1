###########################################################################################################
#                                                                                                         #
# File:          fetchHosts.ps1                                                                           #
#                                                                                                         #
# Purpose:       Script to get monthly status lists from a VMware vCenter about VM-Hosts (ESX/ESXi)       #
#                from a connected vCenter Server                                                          #
#                                                                                                         #
# Author:        Sven Sperner <cethss@gmail.com>                                                          #
#                                                                                                         #
# Last edited:   08.05.2012                                                                               #
#                                                                                                         #
# Requirements:  Microsoft Windows PowerShell 2.0 + VMware PowerCLI 5.0.1                                 #
#                                                                                                         #
# Usage:                                                                                                  #
#  PowerShell -PSConsoleFile "C:\{Path2PowerCLI}\vim.psc1" -command C:\{Path2Script}\fetchHosts.ps1       #
#                                                                                                         #
# Usage example:                                                                                          #
#  PowerShell -PSConsoleFile "C:\Programme\VMware\Infrastructure\vSphere PowerCLI\vim.psc1" `             #
#             -command "C:\monthlyReporting\fetchHosts.ps1"                                               #
#                                                                                                         #
#                    This program is distributed in the hope that it will be useful,                      #
#                    but WITHOUT ANY WARRANTY; without even the implied warranty of                       #
#                    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                                 #
#                                                                                                         #
###########################################################################################################



# Source file with common function:
# ---------------------------------
. .\commonFunctions.ps1



# Read configuration file:
# ------------------------
$confTable = readConfiguration



# Get ip address <==> host name:
# ------------------------------
Function resolveIP( $hostname )
{
	$null,$null,$null,$null,$ipadr = $(nslookup $hostname) 2>$null
	$ipadr = $ipadr -replace "Address:\s+",""
	return [String] $ipadr
}
Function resolveName( $hostname )
{
	$null,$null,$null,$name,$null = $(nslookup $hostname) 2>$null
	$name = $name -replace "Name:\s+",""
	return [String] $name
}



# Create Array for hostslist:
# ---------------------------
$list = @()

# Get informations row by row:
# ----------------------------
Write-Host ""
Write-Host "Collecting VM-Host information from $($server.Name):"
$hostcount = 0
ForEach( $vmhost in Get-VMHost|Sort Name )
{
	$view = Get-View( $vmhost )
	$parent = $vmhost.Parent
	$netInfo = $vmhost.NetworkInfo
	$row = "" | Select Cluster,Domain,Name,IPAddress,IRMCname,IRMCip,ConnectionState,PowerState, `
		NumCpu,ProcessorType,HyperThreading,CpuUsage,CpuTotal,MemoryUsage,MemoryTotal,NumNIC, `
		HA,Drs,DrsAutoLevel,ESXVersion,Gebaeude,Seriennummer,Gateway,DNSAddress,Manufacturer, `
		Model,BIOS,TimeZone,Id,Uptime
	$row.Cluster =		$parent.Name
	$row.Domain =		$netInfo.DomainName
	$row.Name =		$vmhost.Name
	$row.IPAddress =	resolveIP( $vmhost.Name )	# gets just one of all addresses
	#ForEach( $consoleNic in $netInfo.ConsoleNic )		# only resolvable ip is needed
	#{
	#	$row.IPAddress +=	$consoleNic.IP
	#	if( !($consoleNic.IP -eq $netInfo.ConsoleNic[$netInfo.ConsoleNic.count-1].IP) )
	#	{
	#		$row.IPAddress +=	", "
	#	}
	#}
	$irmcIP = 		$($row.IPAddress).split( "." )
	$irmcIP[2] =		[String]($([int]$irmcIP[2])+1)
	$irmcIP =		$irmcIP -join "."
	$irmcName =		resolveName( $irmcIP )
	if( $irmcName.contains("irmc") )
	{
		$row.IRMCname =		$irmcName
		$row.IRMCip =		$irmcIP
	}
	else
	{
		$row.IRMCname =		"not found"
		$row.IRMCip =		"not found"
	}
	$row.ConnectionState =	$vmhost.ConnectionState
	$row.PowerState =	$vmhost.PowerState
	$row.NumCpu =		$vmhost.NumCpu
	$row.ProcessorType =	$vmhost.ProcessorType
	$row.HyperThreading =	$vmhost.HyperThreadingActive
	$row.CpuUsage =		[System.Convert]::ToString( $vmhost.CpuUsageMHz ) + " MHz"
	$row.CpuTotal =		[System.Convert]::ToString( $vmhost.CpuTotalMHz ) + " MHz"
	$row.MemoryUsage =	[System.Convert]::ToString( $vmhost.MemoryUsageMB ) + " MB"
	$row.MemoryTotal =	[System.Convert]::ToString( $vmhost.MemoryTotalMB ) + " MB"
	$row.NumNIC =		$netInfo.ConsoleNic.count				#obsolete - gets ethernet nics
	#$row.NumNIC =		$( Get-VMHostNetworkAdapter -vmhost $vmhost ).count	#gets all nics -> exmpl. 13 not 3
	$row.HA =		$parent.HAEnabled
	$row.Drs =		$parent.DrsEnabled
	$row.DrsAutoLevel =	$parent.DrsAutomationLevel
	$row.ESXVersion =	[System.Convert]::ToString( $vmhost.Version ) + "-" + [System.Convert]::ToString( $vmhost.Build )
	IF( $creds.Host.Contains("smc")  )
	{
		$row.Gebaeude =		($vmhost | Get-Annotation -CustomAttribute "RZ Gebaeude").Value
		$row.Seriennummer =	($vmhost | Get-Annotation -CustomAttribute "Seriennummer").Value
	}
	ELSEIF( $creds.Host.Contains("pvc")  )
	{
		$row.Gebaeude =		($vmhost | Get-Annotation -CustomAttribute "Gebäude").Value
		$row.Seriennummer =	($vmhost | Get-Annotation -CustomAttribute "Seriennummer").Value
	}
	ELSEIF( $creds.Host.Contains("svc")  )
	{
		$row.Gebaeude =		($vmhost | Get-Annotation -CustomAttribute "RZ-Gebäude").Value
		$row.Seriennummer =	($vmhost | Get-Annotation -CustomAttribute "Seriennummer").Value
	}
	ELSEIF( $creds.Host.Contains("tvc")  )
	{
		$row.Gebaeude =		($vmhost | Get-Annotation -CustomAttribute "RZ-Gebäude").Value
		$row.Seriennummer =	($vmhost | Get-Annotation -CustomAttribute "Seriennummer").Value
	}
	ELSE
	{
		$row.Gebaeude =		""
		$row.Seriennummer =	""
	}
	$row.Gateway =			$netInfo.ConsoleGateway
	ForEach( $nameserver in $netInfo.DnsAddress )
	{
		$row.DNSAddress +=	$nameserver
		if( !($nameserver -eq $netInfo.DnsAddress[$netInfo.DnsAddress.count-1]) )
		{
			$row.DNSAddress +=	", "
		}
	}
	$row.Manufacturer =	$vmhost.Manufacturer
	$row.Model =		$vmhost.Model
	$row.BIOS =		($view.Runtime.HealthSystemRuntime.SystemHealthInfo.NumericSensorInfo | Where {$_.Name -like "*BIOS*"}).Name
	$row.TimeZone =		$vmhost.TimeZone.Description
	$row.Id =		$vmhost.Id
	IF( $view.runtime.bootTime )
	{
		$row.Uptime = New-TimeSpan $view.Runtime.BootTime $(get-date)
	}
	ELSE
	{
		$row.Uptime = "not available"
	}
	$list += $row

	$hostcount += 1
	Write-Host -noNewLine " $hostcount"
	# Limit scanned Hosts (for debugging, testing)
	#if( $vmcount -eq 3 ) {break}
}
Write-Host ""
Write-Host "Collected informations of $hostcount VM-Hosts from $($server.Name)"



# Build output filename:
# ----------------------
$date = Get-Date -UFormat "%Y-%m-%d_%H-%M-%S"
$aktReportDir = "$($confTable["Subdirs"]["reportDir"])\$(Get-Date -UFormat "%Y-%m-%d")"
IF( !$(Test-Path "$aktReportDir") )
{
	mkdir "$aktReportDir" > $null
}
$outfile = "$aktReportDir\HostsList_" + $($server.Name) + "_" + $date + ".csv"



# Export statuslist as csv-file:
# ------------------------------
$list | Export-Csv "$outfile" -noTypeInformation -Delimiter ";"
Write-Host ""
Write-Host "Saved list in $outfile"



# DONE !
