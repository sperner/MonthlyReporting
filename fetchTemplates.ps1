###########################################################################################################
#                                                                                                         #
# File:          fetchTemplates.ps1                                                                       #
#                                                                                                         #
# Purpose:       Script to get monthly status lists from a VMware vCenter about installed Templates       #
#                from a connected vCenter Server                                                          #
#                                                                                                         #
# Author:        Sven Sperner <cethss@gmail.com>                                                          #
#                                                                                                         #
# Last edited:   08.05.2012                                                                               #
#                                                                                                         #
# Requirements:  Microsoft Windows PowerShell 2.0 + VMware PowerCLI 5.0.1                                 #
#                                                                                                         #
# Usage:                                                                                                  #
#  PowerShell -PSConsoleFile "C:\{Path2PowerCLI}\vim.psc1" -command C:\{Path2Script}\fetchTemplates.ps1   #
#                                                                                                         #
# Usage example:                                                                                          #
#  PowerShell -PSConsoleFile "C:\Programme\VMware\Infrastructure\vSphere PowerCLI\vim.psc1" `             #
#             -command "C:\monthlyReporting\fetchTemplates.ps1"                                           #
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



# Create array for machineslist:
# ------------------------------
$list = @()

# Create counters for OSes:
# -------------------------
$fbsd32 = 0; $fbsd64 = 0
$w03e32 = 0; $w03e64 = 0
$w03s32 = 0; $w03s64 = 0
$w08r32 = 0; $w08r64 = 0
$w08_32 = 0; $w08_64 = 0
$wxpp32 = 0; $wxpp64 = 0
$rh5_32 = 0; $rh5_64 = 0
$rh6_32 = 0; $rh6_64 = 0
$so1032 = 0; $so1064 = 0
$su8932 = 0; $su8964 = 0
$su1032 = 0; $su1064 = 0
$su1132 = 0; $su1164 = 0
$ubu_32 = 0; $ubu_64 = 0
$otherOS = 0;



# Get Template information row by row:
# ------------------------------------
Write-Host ""
Write-Host "Collecting Template information from $($server.Name) :"
$templatecount = 0
ForEach( $template in Get-Template|Sort Name )
{
	$view = Get-View( $template )
	$runtime = $view.Runtime
	$summary = $view.Summary
	$storage = $summary.Storage
	$guest = $summary.Guest
	$config = $view.Config
	$hardware = $config.Hardware
	$row = "" | Select Name,Id,State,Status,Host,GuestOS,Provisioned,Used,NumCPU,MaxMem,Uptime, `
			NumNic,IP,DNSname,Tools,Notizen,Ansprechpartner,Telefon,Typ,Wartungszeit,Datastore
	$row.Name =		$template.Name
	$row.Id =		$template.Id
	$row.State =		$runtime.PowerState
	$row.Status =		$summary.OverallStatus
	#$row.Host =		$template.VMHost
	$row.GuestOS =		$config.GuestFullName
	$row.Provisioned =	[System.Convert]::ToString("{0:f2}" -f (($storage.Committed `
				+ $storage.Uncommitted)/1GB)) + " GB"
	$row.Used =		[System.Convert]::ToString("{0:f2}" -f ($storage.Committed/1GB)) + " GB"
	$row.NumCPU =		$hardware.NumCPU
	$row.MaxMem = 		[System.Convert]::ToString($hardware.MemoryMB) + " MB"
	IF( $runtime.bootTime )
	{
		$row.Uptime = New-TimeSpan $runtime.BootTime $(get-date)
	}
	ELSE
	{
		$row.Uptime = "not available"
	}
	$row.NumNic =		$summary.Config.NumEthernetCards
	$row.IP =		$guest.IpAddress
	$row.DNSname =		$guest.HostName
	$row.Tools =		$config.Tools.ToolsVersion
	$row.Notizen =		$template.Notes
	IF( $creds.Host.Contains("smc")  )
	{
		$row.Ansprechpartner =	($template | Get-Annotation -CustomAttribute "Ansprechpartner").Value
		$row.Telefon =		($template | Get-Annotation -CustomAttribute "Telefon").Value
		$row.Typ =		($template | Get-Annotation -CustomAttribute "Typ").Value
		$row.Wartungszeit =	($template | Get-Annotation -CustomAttribute "Wartungszeit").Value
	}
	ELSEIF( $creds.Host.Contains("tvc")  )
	{
		$row.Ansprechpartner =	($template | Get-Annotation -CustomAttribute "Bearbeiter").Value
		$row.Telefon =		""
		$row.Typ =		""
		$row.Wartungszeit =	""
	}
	ELSE
	{
		$row.Ansprechpartner =	""
		$row.Telefon =		""
		$row.Typ =		""
		$row.Wartungszeit =	""
	}
	$row.Datastore =	$(Get-Datastore -Id $template.DatastoreIdList).Name
	$list += $row

	# Count OS for summary
	SWITCH -wildcard ( $row.GuestOS )
	{
		"*FreeBSD*32*"			{ $fbsd32 += 1; break	}
		"*FreeBSD*64*"			{ $fbsd64 += 1; break	}
		"*Windows*2003*Enterprise*32*"	{ $w03e32 += 1; break	}
		"*Windows*2003*Enterprise*64*"	{ $w03e64 += 1; break	}
		"*Windows*2003*Standard*32*"	{ $w03s32 += 1; break	}
		"*Windows*2003*Standard*64*"	{ $w03s64 += 1; break	}
		"*Windows*2008*R2*32*"		{ $w08r32 += 1; break	}
		"*Windows*2008*R2*64*"		{ $w08r64 += 1; break	}
		"*Windows*2008*32*"		{ $w08_32 += 1; break	}
		"*Windows*2008*64*"		{ $w08_64 += 1; break	}
		"*Windows*XP*Pro*32*"		{ $wxpp32 += 1; break	}
		"*Windows*XP*Pro*64*"		{ $wxpp64 += 1; break	}
		"*Red*Hat*Enter*5*32*"		{ $rh5_32 += 1; break	}
		"*Red*Hat*Enter*5*64*"		{ $rh5_64 += 1; break	}
		"*Red*Hat*Enter*6*32*"		{ $rh6_32 += 1; break	}
		"*Red*Hat*Enter*6*64*"		{ $rh6_64 += 1; break	}
		"*Solaris*10*32*"		{ $so1032 += 1; break	}
		"*Solaris*10*64*"		{ $so1064 += 1; break	}
		"*Suse*Enter*8*32*"		{ $su8932 += 1; break	}
		"*Suse*Enter*8*64*"		{ $su8964 += 1; break	}
		"*Suse*Enter*10*32*"		{ $su1032 += 1; break	}
		"*Suse*Enter*10*64*"		{ $su1064 += 1; break	}
		"*Suse*Enter*11*32*"		{ $su1132 += 1; break	}
		"*Suse*Enter*11*64*"		{ $su1164 += 1; break	}
		"*Ubuntu*32*"			{ $ubu_32 += 1; break	}
		"*Ubuntu*64*"			{ $ubu_64 += 1; break	}
		default				{ $otherOS +=1 }
	}

	$templatecount += 1
	Write-Host -noNewLine " $templatecount"
	# Limit scanned VMs (for debugging, testing)
	#if( $templatecount -eq 3 ) {break}
}
Write-Host ""
Write-Host "Collected information of $templatecount Templates from $($server.Name)"



# Build output filename:
# ----------------------
$date = Get-Date -UFormat "%Y-%m-%d_%H-%M-%S"
$aktReportDir = "$($confTable["Subdirs"]["reportDir"])\$(Get-Date -UFormat "%Y-%m-%d")"
IF( !$(Test-Path "$aktReportDir") )
{
	mkdir "$aktReportDir" > $null
}
$outfile = "$aktReportDir\TemplatesList_" + $($server.Name) + "_" + $date + ".csv"



# Export statuslist as csv-file:
# ------------------------------
$list | Export-Csv "$outfile" -noTypeInformation -Delimiter ";"
Write-Host ""
Write-Host "Saved list in $outfile"



# Create and export summary as txt-file:
# --------------------------------------
$summary = "$aktReportDir\TemplatesList_" + $($server.Name) + "_" + $date + ".summary.txt"
"Number of all scanned Templates: $templatecount" | Add-Content $summary
"" | Add-Content $summary
"Number of FreeBSD 32-Bit: $fbsd32" | Add-Content $summary
"Number of FreeBSD 64-Bit: $fbsd64" | Add-Content $summary
"" | Add-Content $summary
"Number of RedHat Enterprise Linux 5 32-Bit: $rh5_32" | Add-Content $summary
"Number of RedHat Enterprise Linux 5 64-Bit: $rh5_64" | Add-Content $summary
"Number of RedHat Enterprise Linux 6 32-Bit: $rh6_32" | Add-Content $summary
"Number of RedHat Enterprise Linux 6 64-Bit: $rh6_64" | Add-Content $summary
"" | Add-Content $summary
"Number of Sun Solaris 10 32-Bit: $so1032" | Add-Content $summary
"Number of Sun Solaris 10 64-Bit: $so1064" | Add-Content $summary
"" | Add-Content $summary
"Number of Suse Enterprise Linux 8/9 32-Bit: $su8932" | Add-Content $summary
"Number of Suse Enterprise Linux 8/9 64-Bit: $su8964" | Add-Content $summary
"Number of Suse Enterprise Linux 10 32-Bit: $su1032" | Add-Content $summary
"Number of Suse Enterprise Linux 10 64-Bit: $su1064" | Add-Content $summary
"Number of Suse Enterprise Linux 11 32-Bit: $su1132" | Add-Content $summary
"Number of Suse Enterprise Linux 11 64-Bit: $su1164" | Add-Content $summary
"" | Add-Content $summary
"Number of Ubuntu Linux 32-Bit: $ubu_32" | Add-Content $summary
"Number of Ubuntu Linux 64-Bit: $ubu_64" | Add-Content $summary
"" | Add-Content $summary
"Number of Microsoft Windows Server 2003 Enterprise 32-Bit: $w03e32" | Add-Content $summary
"Number of Microsoft Windows Server 2003 Enterprise 64-Bit: $w03e64" | Add-Content $summary
"Number of Microsoft Windows Server 2003 Standard 32-Bit: $w03s32" | Add-Content $summary
"Number of Microsoft Windows Server 2003 Standard 64-Bit: $w03s64" | Add-Content $summary
"Number of Microsoft Windows Server 2008 32-Bit: $w08_32" | Add-Content $summary
"Number of Microsoft Windows Server 2008 64-Bit: $w08_64" | Add-Content $summary
"Number of Microsoft Windows Server 2008 R2 32-Bit: $w08r32" | Add-Content $summary
"Number of Microsoft Windows Server 2008 R2 64-Bit: $w08r64" | Add-Content $summary
"Number of Microsoft Windows XP Professional 32-Bit: $wxpp32" | Add-Content $summary
"Number of Microsoft Windows XP Professional 64-Bit: $wxpp64" | Add-Content $summary
"" | Add-Content $summary
"Number of other OperatingSystems: $otherOS" | Add-Content $summary
"" | Add-Content $summary
$known = ($fbsd32 + $fbsd64 + $w03e32 + $w03e64 + $w03s32 + $w03s64 + $w08r32 + $w08r64 + $w08_32 + $w08_64 `
		+ $wxp_32 + $wxp_64 + $rh5_32 + $rh5_64 + $rh6_32 + $rh6_64 + $so1032 + $so1064 + $su8932 + $su8964 `
		+ $su1032 + $su1064 + $su1132 + $su1164 + $ubu_32 + $ubu_64 )
"Got $known known OperatingSystems, with unknown they are $($known + $otherOS)" | Add-Content $summary
"Which leads to a difference of $($templatecount - $known -$otherOS) to all scanned Templates" | Add-Content $summary
Write-Host "Saved summary in $summary"



# DONE!
