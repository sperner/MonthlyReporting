###########################################################################################################
#                                                                                                         #
# File:          sendReports.ps1                                                                          #
#                                                                                                         #
# Purpose:       Script to send the status lists to one or more specified mail address(es)                #
#                                                                                                         #
# Author:        Sven Sperner <cethss@gmail.com>                                                          #
#                                                                                                         #
# Last edited:   08.05.2012                                                                               #
#                                                                                                         #
# Requirements:  Microsoft Windows PowerShell 2.0                                                         #
#                                                                                                         #
# Usage:                                                                                                  #
#  PowerShell -PSConsoleFile "C:\{Path2PowerCLI}\vim.psc1" -command C:\{Path2Script}\sendReports.ps1      #
#                                                                                                         #
# Usage example:                                                                                          #
#  PowerShell -PSConsoleFile "C:\Programme\VMware\Infrastructure\vSphere PowerCLI\vim.psc1" `             #
#             -command "C:\monthlyReporting\sendReports.ps1"                                              #
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
$date = Get-Date -UFormat "%Y-%m-%d"
$time = [int]$(Get-Date -UFormat "%H")
IF( $time -lt 6 )
{	$daytime = "night"	}
ELSEIF( $time -lt 12 )
{	$daytime = "morning"	}
ELSEIF( $time -lt 14 )
{	$daytime = "noon"	}
ELSEIF( $time -lt 17 )
{	$daytime = "day"	}
ELSEIF( $time -lt 20 )
{	$daytime = "evening"	}
ELSE
{	$daytime = "night"	}



# Generate mail body parts:
# -------------------------
$bodyHead  = "Good $daytime recipient,<br/><br/>"

$bodyHead += "this is an automatic generated mail - do _not_ reply!<br/><br/>"

$bodyHead += "As attachments you will find list(s) of installed<br/>"
$bodyVirt  = "VirtualMachines (VMsList_{vCenter}_{Date}.csv)<br/>"
$bodyVirt += "VirtualMachine-Summaries (VMsList_{vCenter}_{Date}.summary.txt)<br/>"
$bodyTemp  = "Templates (TemplatesList_{vCenter}_{Date}.csv)<br/>"
$bodyTemp += "Template-Summaries (TemplatesList_{vCenter}_{Date}.summary.txt)<br/>"
$bodyHost  = "VM-Hosts (HostsList_{vCenter}_{Date}.csv)<br/>"
$bodyData  = "Datastores (DatastoreList_{vCenter}_{Date}.csv)<br/>"
$bodyData += "Datastoreusage of VMs (DriveSpreadList_{vCenter}_{Date}.csv)<br/>"
$bodyNetw  = "Networks (NetworksList_{vCenter}_{Date}.csv)<br/>"
$bodyNetw += "Networkaffiliation of VMs (NetSpreadList_{vCenter}_{Date}.csv)<br/>"
$bodyNetw += "Networkaffiliation of Hosts (NetHostList_{vCenter}_{Date}.csv)<br/>"
$bodyTail  = "available in SMC/IAAS environments<br/>"
$bodyTail += "at $date.<br/><br/><br/>"

$bodyTail += "<font size=-1>To sort a CSV-file, open it in Excel<br/>"
$bodyTail += "-> right-click SELECT-ALL-Button -> Sort... -> Custom Sort...<br/>"
$bodyTail += "-> Sort by: Column (A) -> Then by: Column (B)</font><br/><br/>"

$bodyTail += "<font size=-1>Outlook can automatically move dedicated mails<br/>"
$bodyTail += "-> Extras -> Rules and Alerts -> E-mail Rules -> New Rule...<br/>"
$bodyTail += "-> Move messages from someone to a folder<br/>"
$bodyTail += "-> from person: IAAS-Reporting_DoNotRreply@ts.fujitsu.com<br/>"
$bodyTail += "-> move to folder: [(personal) folder of your choice]</font><br/><br/><br/>"

$bodyTail += "Best regards<br/>Your automatic reporter"



# Generate attachments:
# ---------------------
$installPath = $confTable["Install"]["installPath"]
$reportDir = "$($confTable["Subdirs"]["reportDir"])\$date"
$logsDir = $confTable["Subdirs"]["logsDir"]
$attachAll = @(Get-ChildItem "$installPath\$reportDir\*")
$attachAll += @(Get-ChildItem "$installPath\$logsDir\*$date*")
$attachHosts = @(Get-ChildItem "$installPath\$reportDir\Host*")
$attachMachines = @(Get-ChildItem "$installPath\$reportDir\VMs*")
$attachReports = @(Get-ChildItem "$installPath\$reportDir\VMsList_smc*")
$attachReports += @(Get-ChildItem "$installPath\$reportDir\VMsList_iaas-p*")
$attachReports += @(Get-ChildItem "$installPath\$reportDir\VMsList_iaas-s*")
$attachReports += @(Get-ChildItem "$installPath\$reportDir\VMsList_iaas-t*")
$attachTemplates = @(Get-ChildItem "$installPath\$reportDir\Temp*")
$attachDatastores = @(Get-ChildItem "$installPath\$reportDir\D*")
$attachNetworks = @(Get-ChildItem "$installPath\$reportDir\N*")



# Send eMail with files attached:
# -------------------------------
$mailServer = "$($confTable["Mail"]["server"])"
$mailFrom = "$($confTable["Mail"]["from"])"

# With everything attached
$body = $bodyHead + $bodyVirt +$bodyTemp + $bodyData + $bodyNetw + $bodyHost + $bodyTail
ForEach( $recipient in $($confTable["Recipient-All"].Values) )
{
	Send-MailMessage -To		"Reporter <$recipient>" `
			 -From		"$mailFrom" `
			 -Subject	"IAAS-Report of $date - Complete with logfile" `
			 -BodyAsHtml	"$body" `
			 -SmtpServer	"$mailServer" `
			 -Attachments	( $attachAll )
	Write-Host "Sent mail with all attachments to $recipient via $mailServer"
}

# With hostlists attached
$body = $bodyHead + $bodyHost + $bodyTail
ForEach( $recipient in $($confTable["Recipient-Hosts"].Values) )
{
	Send-MailMessage -To		"Reporter <$recipient>" `
			 -From		"$mailFrom" `
			 -Subject	"IAAS-Report of $date - Installed VM-Hosts" `
			 -BodyAsHtml	"$body" `
			 -SmtpServer	"$mailServer" `
			 -Attachments	( $attachHosts )
	Write-Host "Sent mail with attached informations of vm hosts to $recipient via $mailServer"
}

# With machinelists attached
$body = $bodyHead + $bodyVirt + $bodyTail
ForEach( $recipient in $($confTable["Recipient-Machines"].Values) )
{
	Send-MailMessage -To		"Reporter <$recipient>" `
			 -From		"$mailFrom" `
			 -Subject	"IAAS-Report of $date - Installed VirtualMachines" `
			 -BodyAsHtml	"$body" `
			 -SmtpServer	"$mailServer" `
			 -Attachments	( $attachMachines )
	Write-Host "Sent mail with attached informations of virtual machines to $recipient via $mailServer"
}

# With machinelists for reporting (without cvc) attached
$body = $bodyHead + $bodyVirt + $bodyTail
ForEach( $recipient in $($confTable["Recipient-VMreport"].Values) )
{
	Send-MailMessage -To		"Reporter <$recipient>" `
			 -From		"$mailFrom" `
			 -Subject	"IAAS-Report of $date - Lists of VirtualMachines" `
			 -BodyAsHtml	"$body" `
			 -SmtpServer	"$mailServer" `
			 -Attachments	( $attachReports )
	Write-Host "Sent mail with attached informations for reporting to $recipient via $mailServer"
}

# With templatelists attached
$body = $bodyHead + $bodyTemp + $bodyTail
ForEach( $recipient in $($confTable["Recipient-Templates"].Values) )
{
	Send-MailMessage -To		"Reporter <$recipient>" `
			 -From		"$mailFrom" `
			 -Subject	"IAAS-Report of $date - Installed Templates" `
			 -BodyAsHtml	"$body" `
			 -SmtpServer	"$mailServer" `
			 -Attachments	( $attachTemplates )
	Write-Host "Sent mail with attached informations of templates to $recipient via $mailServer"
}

# With datastorelists attached
$body = $bodyHead + $bodyData + $bodyTail
ForEach( $recipient in $($confTable["Recipient-Datastores"].Values) )
{
	Send-MailMessage -To		"Reporter <$recipient>" `
			 -From		"$mailFrom" `
			 -Subject	"IAAS-Report of $date - Installed Datastores" `
			 -BodyAsHtml	"$body" `
			 -SmtpServer	"$mailServer" `
			 -Attachments	( $attachDatastores )
	Write-Host "Sent mail with attached informations of datastores to $recipient via $mailServer"
}

# With networklists attached
$body = $bodyHead + $bodyNetw + $bodyTail
ForEach( $recipient in $($confTable["Recipient-Networks"].Values) )
{
	Send-MailMessage -To		"Reporter <$recipient>" `
			 -From		"$mailFrom" `
			 -Subject	"IAAS-Report of $date - Installed Networks" `
			 -BodyAsHtml	"$body" `
			 -SmtpServer	"$mailServer" `
			 -Attachments	( $attachNetworks )
	Write-Host "Sent mail with attached informations of networks to $recipient via $mailServer"
}



# DONE!
