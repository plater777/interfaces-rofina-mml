#requires -version 2
<#
.SYNOPSIS
	Script de envío de archivos MML a Rofina
	
.DESCRIPTION
	Script de envío de archivos MML a Rofina
	
.INPUTS
	None
	
.OUTPUTS
	Print to standard output, todo output to log file
	
.NOTES
	Version:		1.0
	Author:			Santiago Platero
	Creation Date:	18/01/2018
	Purpose/Change: Script inicial para envío de archivos MML a Rofina
	
.EXAMPLE
	>powershell -command ".'<absolute path>\rofina-mml.ps1'"
#>
# First error control: missing DLL, remote host error, etc.
try
{
	# Load WinSCP .NET assembly
	Add-Type -Path "c:\git\WinSCPnet.dll"

	# Set up session options
	$sessionOptions = New-Object WinSCP.SessionOptions -Property @{
		Protocol = [WinSCP.Protocol]::Sftp
		HostName = "vmftp01.eastus2.cloudapp.azure.com"
		PortNumber = 9990
		UserName = "mverde"
		SshHostKeyFingerprint = "ssh-rsa 4096 02:fb:fe:20:41:1f:01:7d:00:a1:e7:a6:01:f9:ed:7c"
		SshPrivateKeyPath = "c:\git\rofina.ppk"
	}

	$session = New-Object WinSCP.Session
	# Second error control: missing file, wrong path, transfer errors, etc.
	try
	{
		# Connect
		$session.Open($sessionOptions)
		Write-Host "[$(Get-Date -format "dd-MMM-yyyy HH:mm")] Connecting to $($sessionOptions.UserName)@$($sessionOptions.HostName):$($sessionOptions.PortNumber)"
	
		# Transfer options
		$transferOptions = New-Object WinSCP.TransferOptions
		$transferOptions.FileMask = "|*/"

		# Transfer files
		$transferFiles = $session.PutFiles("\\192.168.0.83\qad\wrkdir\aix\rofina\mtv\output\*", "/entrada/*", $False, $transferOptions)
	
		# Throw on any error
		$transferFiles.Check()
	
		# Print to standard output; todo output to log file by default
		foreach ($transfer in $transferFiles.Transfers)
		{
			$file = $transfer.FileName
		}
		# Checks variable if it's empty
		if (!$file)
		{
			Write-Host "[$(Get-Date -format "dd-MMM-yyyy HH:mm")] No files uploaded."
		}
		else
		{
			Write-Host "[$(Get-Date -format "dd-MMM-yyyy HH:mm")] Upload of $($transfer.FileName) succeeded."
		}
	}
	# Print error of second control
	catch
	{
		Write-Host "[$(Get-Date -format "dd-MMM-yyyy HH:mm")] ERROR: $($_.Exception.Message)"
		exit 1
	}
	finally
	{
		# Disconnect, clean up
		$session.Dispose()
	}
	exit 0
}
# Print error of first control
catch 
{
	Write-Host "[$(Get-Date -format "dd-MMM-yyyy HH:mm")] ERROR: $($_.Exception.Message)"
	exit 1
}
