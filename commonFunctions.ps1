###########################################################################################################
#                                                                                                         #
# File:          commonFunctions.ps1                                                                      #
#                                                                                                         #
# Purpose:       Shared functions for the other PowerShell scripts                                        #
#                                                                                                         #
# Author:        Sven Sperner <cethss@gmail.com>                                                          #
#                                                                                                         #
# Last edited:   08.05.2012                                                                               #
#                                                                                                         #
# Requirements:  Microsoft Windows PowerShell 2.0 + VMware PowerCLI 5.0.1                                 #
#                                                                                                         #
# Usage:                                                                                                  #
#         This file must be dot sourced from another script file, then the functions are available        #
#         . .\commonfunctions.ps1                                                                         #
#                                                                                                         #
#                    This program is distributed in the hope that it will be useful,                      #
#                    but WITHOUT ANY WARRANTY; without even the implied warranty of                       #
#                    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                                 #
#                                                                                                         #
###########################################################################################################



# Get name of configuration file:
# -------------------------------
Function getConfigurationFile()
{
	$configurationFile = Get-ChildItem -Filter *.ini
	IF( $configurationFile.Count -gt 1 )
	{
		Write-Host -ForegroundColor Yellow "Warning: More than one configuration file found - using first"
		$configurationFile = $configurationFile[0]
	}
	IF( Test-Path $configurationFile )
	{
		return $configurationFile.FullName
	}
	ELSE
	{
		Write-Host -ForegroundColor Red "ERROR: No Configuration file found!"
		exit -1
	}
}

# Read configuration file:
# ------------------------
Function readConfiguration( $configurationFile=$(getConfigurationFile) )
{
	IF( Test-Path $configurationFile )
	{
		Write-Host "`nLoading configuration from $configurationFile ..." -noNewLine
		$configurationTable = @{}
		SWITCH -regex -file "$configurationFile"
		{
			 "^\[(.+)\]$" {
			 $configurationSection = $matches[1]
			 $configurationTable[$configurationSection] = @{} 
			 }
			 "(.+)=(.+)" {
			 $configurationName,$configurationValue = $matches[1..2]
			 $configurationTable[$configurationSection][$configurationName] = $configurationValue
			 }
		}
		Write-Host -ForegroundColor Green " OK"
	}
	ELSE
	{
		Write-Host "Configuration file $configurationFile not found"
		exit -1
	}
	return $configurationTable
}

# Read connection credentials:
# ----------------------------
Function readCredentials( [Parameter(Mandatory=$true)]$credentialFile )
{
	IF( Test-Path $credentialFile )
	{
		Write-Host "Loading credentials from $credentialFile ..." -noNewLine
		try
		{
			$credentials = Get-VICredentialStoreItem -file "$credentialFile" -errorAction "Stop"
		}
		catch
		{
			Write-Host -ForegroundColor Red "failed"
			Write-Host "Error loading credentials from $credentialFile"
			exit -1
		}
		Write-Host -ForegroundColor Green " OK"
	}
	ELSE
	{
		Write-Host "Credential file $credentialFile not found"
		exit -1
	}
	return $credentials
}

# Open connection to server:
# --------------------------
Function connect2Server( [Parameter(Mandatory=$true)]$credentials )
{
	IF( $credentials )
	{
		$serverName = $($credentials.Host.ToString())
		Write-Host "Connecting to $serverName ..." -noNewLine
		# Disable certificate warnings - they always come up and get logged
		Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false >$null
		try
		{
			$connectedServer = Connect-VIServer -Server $credentials.Host `
							-User $credentials.User `
							-Password $credentials.Password `
							-errorAction "Stop"
		}
		catch
		{
			Write-Host -ForegroundColor Red "failed"
			Write-Host "Error connecting to server $serverName"
			exit -1
		}
		Write-Host -ForegroundColor Green " OK"
	}
	ELSE
	{
		Write-Host "No credentials to connect to given"
		exit -1
	}
	return $connectedServer
}

# Close connection to server:
# ---------------------------
Function disconnectFromServer( [Parameter(Mandatory=$true)]$connectedServer )
{
	IF( $connectedServer )
	{
		$serverName = $($connectedServer.Name)
		Write-Host "Disconnecting from $serverName ..." -noNewLine
		try
		{
			disconnect-VIServer -Server $connectedServer -confirm:$false
		}
		catch
		{
			Write-Host -ForegroundColor Red "failed"
			Write-Host "Error disconnecting from server $serverName"
			exit -1
		}
		Write-Host -ForegroundColor Green " OK"
	}
	ELSE
	{
		Write-Host "No server to disconnect from given"
		exit -1
	}
}



# End