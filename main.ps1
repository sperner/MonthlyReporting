###########################################################################################################
#                                                                                                         #
# File:          main.ps1                                                                                 #
#                                                                                                         #
# Purpose:       Script to get monthly status lists from VMware vCenter(s) about                          #
#                - available datastores and their usage                                                   #
#                - virtual machines and which datastores they use                                         #
#                - installed virtual machine hosts (ESX/ESXi)                                             #
#                - installed virtual machines                                                             #
#                - available virtual networks                                                             #
#                - virtual machines and to which networks they are connected                              #
#                - virtual machine hosts and to which networks they are connected                         #
#                - installed virtual machine templates                                                    #
#                                                                                                         #
# Author:        Sven Sperner <cethss@gmail.com>                                                          #
#                                                                                                         #
# Last edited:   08.05.2012                                                                               #
#                                                                                                         #
# Requirements:  Microsoft Windows PowerShell 2.0 + VMware PowerCLI 5.0.1                                 #
#                                                                                                         #
# Usage:                                                                                                  #
#  PowerShell -PSConsoleFile "C:\{Path2PowerCLI}\vim.psc1" -command C:\{Path2Script}\main.ps1             #
#                                                                                                         #
# Parameters:                                                                                             #
#  1. '-vCenter'     vCenter Server Wildcard (smv, cvc, pvc, svc, tvc, iaas, ...)                         #
#  2. '-reportType'  report Type (datastores, hosts, machines, networks, templates)                       #
#  3. '-onlySend'    only send actual (from today) report list(s)                                         #
#  4. '-onlyTidy'    only tidy up outdated report files and folders                                       #
#  5. '-dontSend'    do not send report mails                                                             #
#  6. '-dontTidy'    do not tidy up outdated files and folders                                            #
#                                                                                                         #
# Usage example:                                                                                          #
#  PowerShell -PSConsoleFile "C:\Programme\VMware\Infrastructure\vSphere PowerCLI\vim.psc1" `             #
#             -command "C:\monthlyReporting\main.ps1 -vCenter iaas -reportType machines"                  #
#             -->> fetches information of virtual machines from all (4) iaas vcenter servers              #
#                                                                                                         #
#                    This program is distributed in the hope that it will be useful,                      #
#                    but WITHOUT ANY WARRANTY; without even the implied warranty of                       #
#                    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                                 #
#                                                                                                         #
###########################################################################################################

param( [String]$vCenter, [String]$reportType, [Switch]$onlySend ,[Switch]$onlyTidy, [Switch]$dontSend ,[Switch]$dontTidy )



# Get date/time of start:
# -----------------------
$startTime = Get-Date
$date = Get-Date -UFormat "%Y-%m-%d"
Write-Host "$($MyInvocation.Line) started at $startTime"



# Source file with common function:
# ---------------------------------
. .\commonFunctions.ps1



# Read configuration file:
# ------------------------
$confTable = readConfiguration



# Do the work:
# ------------
IF( !$onlySend -and !$onlyTidy )
{
	# Get connection credentials:
	# ---------------------------
	IF( $vCenter )
	{
		$credFiles = Get-ChildItem "$($confTable["Install"]["installPath"])\$($confTable["Subdirs"]["credsDir"])" `
			| Where {$_.Name -match "$vCenter"}
		IF( !$credFiles )
		{
			Write-Host -ForegroundColor Red "ERROR: Cannot find credentials for " -NoNewLine
			Write-Host -ForegroundColor Cyan "$vCenter"
			exit -1
		}
	}
	ELSE
	{
		$credFiles = Get-ChildItem "$($confTable["Install"]["installPath"])\$($confTable["Subdirs"]["credsDir"])" `
	}



	# Which information should get fetched:
	# -------------------------------------
	SWITCH( $reportType )
	{
		"Datastores"	{$datastores=$true; $hosts=$false;$machines=$false;$networks=$false;$templates=$false}
		"Hosts"		{$datastores=$false;$hosts=$true; $machines=$false;$networks=$false;$templates=$false}
		"Machines"	{$datastores=$false;$hosts=$false;$machines=$true; $networks=$false;$templates=$false}
		"Networks"	{$datastores=$false;$hosts=$false;$machines=$false;$networks=$true; $templates=$false}
		"Templates"	{$datastores=$false;$hosts=$false;$machines=$false;$networks=$false;$templates=$true}
		default		{$datastores=$true; $hosts=$true; $machines=$true; $networks=$true; $templates=$true}
	}



	# Fetch information from every server:
	# ------------------------------------
	$aktServer = 1
	ForEach( $credFile IN $credFiles )
	{
		Write-Host -ForegroundColor White "`nServer No.$aktServer of $($credFiles.count) @ $(New-TimeSpan $startTime $(Get-Date))"
		$creds = readCredentials $credFile.FullName
		Set-Variable -Name server -Value $(connect2Server $creds) -Scope Script
		IF( $datastores )	{	.\fetchDatastores.ps1	}
		IF( $hosts )		{	.\fetchHosts.ps1	}
		IF( $machines )		{	.\fetchMachines.ps1	}
		IF( $networks )		{	.\fetchNetworks.ps1	}
		IF( $templates )	{	.\fetchTemplates.ps1	}
		disconnectFromServer $server
		$aktServer++
	}
	Write-Host
}



# Send generated list(s) via email:
# ---------------------------------
IF( ($onlySend -or !$onlyTidy) -and !$dontSend )
{
	.\sendReports.ps1
}



# Remove outdated report files and folders:
# -----------------------------------------
IF( (!$onlySend -or $onlyTidy) -and !$dontTidy )
{
	.\tidyUp.ps1
}



# Get date/time of end:
# ---------------------
$endTime = Get-Date
Write-Host "`n$($MyInvocation.Line) finished at $endTime"
Write-Host "Time elapsed: $(New-TimeSpan $startTime $endTime)`n"



# DONE !