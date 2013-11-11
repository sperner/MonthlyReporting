###########################################################################################################
#                                                                                                         #
# File:          fetchDatastores.ps1                                                                      #
#                                                                                                         #
# Purpose:       Script to get monthly status lists from a VMware vCenter about                           #
#                - available datastores and their usage                                                   #
#                - virtual machines and which datastores they use                                         #
#                from a connected vCenter Server                                                          #
#                                                                                                         #
# Author:        Sven Sperner <cethss@gmail.com>                                                          #
#                                                                                                         #
# Last edited:   08.05.2012                                                                               #
#                                                                                                         #
# Requirements:  Microsoft Windows PowerShell 2.0 + VMware PowerCLI 5.0.1                                 #
#                                                                                                         #
# Usage:                                                                                                  #
#  PowerShell -PSConsoleFile "C:\{Path2PowerCLI}\vim.psc1" -command C:\{Path2Script}\fetchDatastores.ps1  #
#                                                                                                         #
# Usage example:                                                                                          #
#  PowerShell -PSConsoleFile "C:\Programme\VMware\Infrastructure\vSphere PowerCLI\vim.psc1" `             #
#             -command "C:\monthlyReporting\fetchDatastores.ps1"                                          #
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



# Create array for datastoreslist:
# --------------------------------
$datastoresList = @()
$driveSpreadList = @()

# Create counters for summary:
# ----------------------------
$sumUsed = 0
$sumCapacity = 0
$sumFree = 0



# Get Datastore information row by row:
# -------------------------------------
Write-Host ""
Write-Host "Collecting Datastore information from $($server.Name):"
$datastorecount = 0
#$datastores = Get-Datastore|Sort Name|Where { $_.Name -NotLike "*local*" }
$datastores = Get-Datastore|Sort Name
ForEach( $datastore IN $datastores )
{
	$row = "" | Select Name,UsedSpace,Capacity,FreeSpace,Type,Datacenter,Url
	$row.Name =		$datastore.Name
	$row.UsedSpace =	[System.Convert]::ToString("{0:f2}" -f ($datastore.CapacityGB-$datastore.FreeSpaceGB)) + " GB"
	$row.Capacity =		[System.Convert]::ToString("{0:f2}" -f $datastore.CapacityGB) + " GB"
	$row.FreeSpace =	[System.Convert]::ToString("{0:f2}" -f $datastore.FreeSpaceGB) + " GB"
	$row.Type =		$datastore.Type
	$row.Datacenter =	$datastore.Datacenter
	$row.Url =		$datastore.ExtensionData.Summary.Url

	$sumUsed += 		$datastore.CapacityGB-$datastore.FreeSpaceGB
	$sumCapacity +=		$datastore.CapacityGB
	$sumFree +=		$datastore.FreeSpaceGB

	$datastoresList += $row

	$datastorecount += 1
	Write-Host -noNewLine " $datastorecount"
	# Limit scanned Datastores (for debugging, testing)
	#if( $datastorecount -eq 5 ) {break}
}
$row = "" | Select Name,UsedSpace,Capacity,FreeSpace
$row.Name =		"Summary"
$row.UsedSpace =	[System.Convert]::ToString("{0:n2}" -f $sumUsed) + " GB"
$row.Capacity =		[System.Convert]::ToString("{0:n2}" -f $sumCapacity) + " GB"
$row.FreeSpace =	[System.Convert]::ToString("{0:n2}" -f $sumFree) + " GB"
$datastoresList += $row
Write-Host ""
Write-Host "Collected information of $datastorecount Datastores from $($server.Name)"



# Use datastore names as driveSpreadList column header:
# -----------------------------------------------------
#$lunColumns = (0..$($datastorecount-1))
$lunColumns = (0..$($datastorecount+5))
$lunColumns[0] = "Name"
$lunColumns[1] = "Notizen"
$lunColumns[2] = "SMCDR"
$lunColumns[3] = "Provisioned"
$lunColumns[4] = "DiscSpace"
$lunColumns[5] = "LUN"
$numHardCoded = 6
FOR( $index = $numHardCoded; $index -lt $lunColumns.length; $index++ )
{
	$lunColumns[$index] = $datastoresList[$index-$numHardCoded].Name
}



# Get VirtualMachine information row by row:
# ------------------------------------------
Write-Host ""
Write-Host "Collecting VirtualMachine information from $($server.Name) :"
$vmcount = 0
ForEach( $vm IN Get-VM|Sort Name )
{
	$row = "" | Select $lunColumns
	$row.Name =		$vm.Name
	$row.Notizen =		$vm.Notes
	$row.SMCDR =		""
	$row.Provisioned =	[System.Convert]::ToString("{0:f2}" -f $vm.ProvisionedSpaceGB) + " GB"
	$row.LUN =		""
	ForEach( $harddisk IN $(Get-HardDisk $vm) )
	{
		$datastore =		$datastores|where {$_.id -eq $harddisk.ExtensionData.Backing.Datastore}
		$datastoreName =	$datastore.Name
		IF( $row.$datastoreName )
		{
			$row.$datastoreName += " + "
			$row.$datastoreName +=	[System.Convert]::ToString("{0:f2}" -f ($harddisk.CapacityKB/(1024*1024))) + " GB"
		}
		ELSE
		{
			$row.$datastoreName =	[System.Convert]::ToString("{0:f2}" -f ($harddisk.CapacityKB/(1024*1024))) + " GB"
		}
		IF( ($row.LUN -ne "") -and ($row.LUN -ne $datastoreName) )
		{
			$row.LUN +=		" + "
			$row.LUN +=		$datastoreName
		}
		ELSE
		{
			$row.LUN =		$datastoreName
		}
	}
	$discSpace = ""
	ForEach( $datastore IN $datastores )
	{
		$datastoreName =	$datastore.Name
		IF( $row.$datastoreName )
		{
			IF( $discSpace -eq "" )
			{
				$discSpace =		$row.$datastoreName
			}
			ELSE
			{
				$discSpace +=		" ; "
				$discSpace +=		$row.$datastoreName
			}
		}
	}
	$row.DiscSpace =	$discSpace

	$driveSpreadList += $row

	$vmcount += 1
	Write-Host -noNewLine " $vmcount"
	# Limit scanned VMs (for debugging, testing)
	#if( $vmcount -eq 5 ) {break}
}
Write-Host ""
Write-Host "Collected information of $vmcount VirtualMachines on $datastorecount Datastores from $($server.Name)"



# Build output filenames:
# -----------------------
$date = Get-Date -UFormat "%Y-%m-%d_%H-%M-%S"
$aktReportDir = "$($confTable["Subdirs"]["reportDir"])\$(Get-Date -UFormat "%Y-%m-%d")"
IF( !$(Test-Path "$aktReportDir") )
{
	mkdir "$aktReportDir" > $null
}
$datastoresFile = "$aktReportDir\DatastoreList_" + $($server.Name) + "_" + $date + ".csv"
$driveSpreadsFile = "$aktReportDir\DriveSpreadList_" + $($server.Name) + "_" + $date + ".csv"



# Export statuslists as csv-file:
# -------------------------------
$datastoresList | Export-Csv "$datastoresFile" -noTypeInformation -Delimiter ";"
$driveSpreadList | Export-Csv "$driveSpreadsFile" -noTypeInformation -Delimiter ";"
Write-Host ""
Write-Host "Saved datastores list in $datastoresFile"
Write-Host "Saved drive spread list in $driveSpreadsFile"



# DONE!
