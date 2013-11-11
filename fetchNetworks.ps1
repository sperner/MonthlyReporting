###########################################################################################################
#                                                                                                         #
# File:          fetchNetworks.ps1                                                                        #
#                                                                                                         #
# Purpose:       Script to get monthly status lists from a VMware vCenter about                           #
#                - available virtual networks                                                             #
#                - virtual machines and to which networks they are connected                              #
#                - virtual machine hosts and to which networks they are connected                         #
#                from a connected vCenter Server                                                          #
#                                                                                                         #
# Author:        Sven Sperner <cethss@gmail.com>                                                          #
#                                                                                                         #
# Last edited:   08.05.2012                                                                               #
#                                                                                                         #
# Requirements:  Microsoft Windows PowerShell 2.0 + VMware PowerCLI 5.0.1                                 #
#                                                                                                         #
# Usage:                                                                                                  #
#  PowerShell -PSConsoleFile "C:\{Path2PowerCLI}\vim.psc1" -command C:\{Path2Script}\fetchNetworks.ps1    #
#                                                                                                         #
# Usage example:                                                                                          #
#  PowerShell -PSConsoleFile "C:\Programme\VMware\Infrastructure\vSphere PowerCLI\vim.psc1" `             #
#             -command "C:\monthlyReporting\fetchNetworks.ps1"                                            #
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



# Get ip address by host name:
# ----------------------------
Function resolveIP( $hostname )
{
	$null,$null,$null,$null,$ipadr = $(nslookup $hostname) 2>$null
	$ipadr = $ipadr -replace "Address:\s+",""
	return [String] $ipadr
}



# Create array for networkslist:
# ------------------------------
$networksList = @()
$netSpreadList = @()
$netHostList = @()



# Get Networks information row by row:
# ------------------------------------
Write-Host ""
Write-Host "Collecting Networks information from $($server.Name) :"
$networkscount = 0
#$networks = Get-VirtualPortGroup|Sort Name,VlanId|Get-Unique|Where {-not $_.Port}
$networks = Get-VirtualPortGroup|Sort Name,VlanId|Get-Unique
ForEach( $network IN $networks )
{
	$row = "" | Select Name, Key, VLanId, NumPorts, Switch
	$row.Name =		$network.Name
	$row.Key =		$network.Key
	$row.VLanId =		$network.VLanId
	$row.NumPorts =		$network.NumPorts
	$row.Switch =		$network.VirtualSwitchName

	$networksList += $row

	$networkscount += 1
	Write-Host -noNewLine " $networkscount"
	# Limit scanned Networks (for debugging, testing)
	#if( $networkscount -eq 5 ) {break}
}
Write-Host ""
Write-Host "Collected information of $networkscount Networks from $($server.Name)"



# Use network names as netSpreadList column header:
# -------------------------------------------------
$numHardCoded = 5
$netSpreadColumns = (0..$($networkscount+($numHardCoded-1)))
$netSpreadColumns[0] = "Name"
$netSpreadColumns[1] = "Host"
$netSpreadColumns[2] = "DNSname"
$netSpreadColumns[3] = "IPaddress"
$netSpreadColumns[4] = "NumNic"
FOR( $index = $numHardCoded; $index -lt $netSpreadColumns.length; $index++ )
{
	$netSpreadColumns[$index] = $networksList[$index-$numHardCoded].Name + " : " + $networksList[$index-$numHardCoded].VlanId
}



# Get VirtualMachine information row by row:
# ------------------------------------------
Write-Host ""
Write-Host "Collecting VirtualMachine information from $($server.Name) :"
$vmcount = 0
$vmInNetCounter = "" | Select $netSpreadColumns
$vmInNetCounter.Name = "Summary"
ForEach( $vm IN Get-VM|Sort Name )
{
	$view = Get-View( $vm )
	$config = $view.Summary.Config
	$guestSum = $view.Summary.Guest
	$guest = $vm.Guest
	$row = "" | Select $netSpreadColumns
	$row.Name =		$vm.Name
	$row.Host =		$vm.VMHost
	$row.DNSname =		$guestSum.HostName
	$row.IPaddress =	$guestSum.IPAddress
	$row.NumNic =		$config.numEthernetCards
	$nicCount = 0
	ForEach( $adapter IN $(get-networkadapter $vm) )
	{
		$network = $networks|where {$_.Name -eq $adapter.NetworkName}
		$networkName =	$network.Name + " : " + $network.VlanId
		IF( $networkName -ne " : " )
		{
			IF( $guest.IPAddress[$nicCount] )
			{
				$insert =		$guest.IPAddress[$nicCount]
			}
			ELSE
			{
				$insert =		"Tools: " + $guest.ToolsRunningStatus
			}
			IF( $row."$networkName" )
			{
				$row."$networkName" +=	" + "
				$row."$networkName" +=	$insert
			}
			ELSE
			{
				$row."$networkName" =	$insert
			}
			IF( $vmInNetCounter."$networkName" -gt 0 )
			{
				$vmInNetCounter."$networkName"++
			}
			ELSE
			{
				$vmInNetCounter."$networkName" = 1
			}
			$nicCount++
		}
	}

	$netSpreadList += $row

	$vmcount += 1
	Write-Host -noNewLine " $vmcount"
	# Limit scanned VMs (for debugging, testing)
	#if( $vmcount -eq 5 ) {break}
}
$netSpreadList += $vmInNetCounter
Write-Host ""
Write-Host "Collected information of $vmcount VirtualMachines on $networkscount Networks from $($server.Name)"



# Use network names as netHostList column header:
# -------------------------------------------------
$numHardCoded = 5
$netHostColumns = (0..$($networkscount+($numHardCoded-1)))
$netHostColumns[0] = "Name"
$netHostColumns[1] = "Cluster"
$netHostColumns[2] = "Domain"
$netHostColumns[3] = "IPaddress"
$netHostColumns[4] = "NumNic"
FOR( $index = $numHardCoded; $index -lt $netHostColumns.length; $index++ )
{
	$netHostColumns[$index] = $networksList[$index-$numHardCoded].Name + " : " + $networksList[$index-$numHardCoded].VlanId
}



# Get VM-Host information row by row:
# -----------------------------------
Write-Host ""
Write-Host "Collecting VM-Host information from $($server.Name) :"
$hostcount = 0
$hostInNetCounter = "" | Select $netHostColumns
$hostInNetCounter.Name = "Summary"
ForEach( $vmhost IN Get-VMHost|Sort Name )
{
	$netInfo = $vmhost.NetworkInfo
	$row = "" | Select $netHostColumns
	$row.Name =		$vmhost.Name
	$row.Cluster =		$vmhost.Parent.Name
	$row.Domain =		$vmhost.NetworkInfo.DomainName
	$row.IPaddress =	resolveIP( $vmhost.Name )
	$row.NumNIC =		$netInfo.ConsoleNic.count
	#ForEach( $portgroup in $netInfo.ExtensionData2.NetworkInfo.Portgroup|Where {-not $_.Port} )
	ForEach( $portgroup in $netInfo.ExtensionData2.NetworkInfo.Portgroup )
	{
		$network =		$networks | Where { $_.Key -eq $portgroup.Key }
		$networkName =		$network.Name + " : " + $network.VlanId
		IF( $networkName -ne " : " )
		{
			$row."$networkName" =	$vmhost.ConnectionState
			IF( $hostInNetCounter."$networkName" -gt 0 )
			{
				$hostInNetCounter."$networkName"++
			}
			ELSE
			{
				$hostInNetCounter."$networkName" = 1
			}
		}
	}

	$netHostList += $row

	$hostcount += 1
	Write-Host -noNewLine " $hostcount"
	# Limit scanned VMs (for debugging, testing)
	#if( $hostcount -eq 5 ) {break}
}
$netHostList += $hostInNetCounter
Write-Host ""
Write-Host "Collected information of $hostcount VM-Hosts on $networkscount Networks from $($server.Name)"



# Build output filenames:
# -----------------------
$date = Get-Date -UFormat "%Y-%m-%d_%H-%M-%S"
$aktReportDir = "$($confTable["Subdirs"]["reportDir"])\$(Get-Date -UFormat "%Y-%m-%d")"
IF( !$(Test-Path "$aktReportDir") )
{
	mkdir "$aktReportDir" > $null
}
$networksFile = "$aktReportDir\NetworksList_" + $($server.Name) + "_" + $date + ".csv"
$netSpreadFile = "$aktReportDir\NetSpreadList_" + $($server.Name) + "_" + $date + ".csv"
$netHostFile = "$aktReportDir\NetHostList_" + $($server.Name) + "_" + $date + ".csv"



# Export statuslists as csv-file:
# -------------------------------
$networksList | Export-Csv "$networksFile" -noTypeInformation -Delimiter ";"
$netSpreadList | Export-Csv "$netSpreadFile" -noTypeInformation -Delimiter ";"
$netHostList | Export-Csv "$netHostFile" -noTypeInformation -Delimiter ";"
Write-Host ""
Write-Host "Saved networks list in $networksFile"
Write-Host "Saved net spread list in $netSpreadFile"
Write-Host "Saved net host list in $netHostFile"



# DONE!
