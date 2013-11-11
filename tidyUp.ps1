###########################################################################################################
#                                                                                                         #
# File:          tidyUp.ps1                                                                               #
#                                                                                                         #
# Purpose:       Script to tidy-up/delete old directories of status lists                                 #
#                                                                                                         #
# Author:        Sven Sperner <cethss@gmail.com>                                                          #
#                                                                                                         #
# Last edited:   08.05.2012                                                                               #
#                                                                                                         #
# Requirements:  Microsoft Windows PowerShell 2.0                                                         #
#                                                                                                         #
# Usage:                                                                                                  #
#  PowerShell -PSConsoleFile "C:\{Path2PowerCLI}\vim.psc1" -command C:\{Path2Script}\tidyUp.ps1           #
#                                                                                                         #
# Usage example:                                                                                          #
#  PowerShell -PSConsoleFile "C:\Programme\VMware\Infrastructure\vSphere PowerCLI\vim.psc1" `             #
#             -command "C:\monthlyReporting\tidyUp.ps1"                                                   #
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



# Get date:
# ---------
$aktDate = Get-Date
$LogsDir = "$($confTable["Install"]["installPath"])\$($confTable["Subdirs"]["logsDir"])"
$ReportDir = "$($confTable["Install"]["installPath"])\$($confTable["Subdirs"]["reportDir"])"
$LogsLastWrite = $aktDate.AddDays(-$($confTable["Cleanup"]["logsOlderThanDays"]))
$ReportsLastWrite = $aktDate.AddDays(-$($confTable["Cleanup"]["reportsOlderThanDays"]))



# Remove outdated log files:
# --------------------------
Write-Host "Removing all files of $LogsDir older than $($confTable["Cleanup"]["logsOlderThanDays"]) days"
ForEach( $file IN $(Get-ChildItem $LogsDir | Where {$_.LastWriteTime -le "$LogsLastWrite"}) )
{
	Write-Host "Deleting $LogsDir\$file"
	Remove-Item "$LogsDir\$file"
}



# Remove outdated report files:
# -----------------------------
Write-Host "Removing all subdirectorys of $ReportDir older than $($confTable["Cleanup"]["reportsOlderThanDays"]) days"
ForEach( $dir IN $(Get-ChildItem $ReportDir | Where {$_.LastWriteTime -le "$ReportsLastWrite"}) )
{
	Write-Host "Deleting $ReportDir\$dir"
	Remove-Item "$ReportDir\$dir" -recurse
}



# DONE !
