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
	
		# Print
		foreach ($transfer in $transferFiles.Transfers)
		{
			$file = $transfer.FileName
		}
		if (!$file)
		{
			Write-Host "[$(Get-Date -format "dd-MMM-yyyy HH:mm")] No files uploaded."
		}
		else
		{
			Write-Host "[$(Get-Date -format "dd-MMM-yyyy HH:mm")] Upload of $($transfer.FileName) succeeded."
		}
	}
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
catch 
{
	Write-Host "[$(Get-Date -format "dd-MMM-yyyy HH:mm")] ERROR: $($_.Exception.Message)"
	exit 1
}
