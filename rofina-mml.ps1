# requires -version 2
<#
.SYNOPSIS
	Script de envío de archivos MML a Rofina
	
.DESCRIPTION
	Script de envío de archivos MML a Rofina
	
.INPUTS
	None
	
.OUTPUTS
	Función LogWrite reemplaza llamadas a Write-Host
	Write-Host se usa únicamente para las excepciones en conjunto con la función LogWrite
		
.NOTES
	Version:		1.0
	Author:			Santiago Platero
	Creation Date:	18/01/2018
	Purpose/Change: Script inicial para envío de archivos MML a Rofina
	
.EXAMPLE
	>powershell -command ".'<absolute path>\rofina-mml.ps1'"
#>

#---------------------------------------------------------[Inicializaciones]--------------------------------------------------------

#----------------------------------------------------------[Declaraciones]----------------------------------------------------------

# Información del script
$scriptVersion = "1.0"
$scriptName = $MyInvocation.MyCommand.Name

# Información de archivos de logs
$logPath = "C:\logs"
$logName = "$($scriptName).log"
$logFile = Join-Path -Path $logPath -ChildPath $logName

#-----------------------------------------------------------[Funciones]------------------------------------------------------------

#Función para hacer algo (?) de logueop
Function LogWrite
{
	Param ([string]$logstring)
	
	Add-Content $logFile -value $logstring
}

#-----------------------------------------------------------[Ejecución]------------------------------------------------------------

# Primer control de errores: falta DDL, errores del servidor remoto, etc.
try
{
	# Carga de DLL de WinSCP .NET
	Add-Type -Path "c:\git\WinSCPnet.dll"

	# Configuración de opciones de sesión
	$sessionOptions = New-Object WinSCP.SessionOptions -Property @{
		Protocol = [WinSCP.Protocol]::Sftp
		HostName = "vmftp01.eastus2.cloudapp.azure.com"
		PortNumber = 9990
		UserName = "mverde"
		SshHostKeyFingerprint = "ssh-rsa 4096 02:fb:fe:20:41:1f:01:7d:00:a1:e7:a6:01:f9:ed:7c"
		SshPrivateKeyPath = "c:\git\rofina.ppk"
	}

	$session = New-Object WinSCP.Session
	# Segundo control de errores: falta archivo, ruta incorrecta, errores de transferencia, etc.
	try
	{
		# Conexión y generamos log
		$session.Open($sessionOptions)
		LogWrite "[$(Get-Date -format "dd-MMM-yyyy HH:mm")] Connecting to $($sessionOptions.UserName)@$($sessionOptions.HostName):$($sessionOptions.PortNumber)"
	
		# Opciones de transferencia
		$transferOptions = New-Object WinSCP.TransferOptions
		$transferOptions.FileMask = "|*/"
		$transferFiles = $session.PutFiles("\\192.168.0.83\qad\wrkdir\aix\rofina\mtv\output\*", "/entrada/*", $False, $transferOptions)
	
		# Arrojar cualquier error
		$transferFiles.Check()
	
		# Loopeamos por cada archivo que se transfiera
		foreach ($transfer in $transferFiles.Transfers)
		{
			$file = $transfer.FileName
		}
		# Antes de mandar al log, verificamos que la variable no sea nula
		if (!$file)
		{
			LogWrite "[$(Get-Date -format "dd-MMM-yyyy HH:mm")] No files uploaded."
		}
		else
		{
			LogWrite "[$(Get-Date -format "dd-MMM-yyyy HH:mm")] Upload of $($transfer.FileName) succeeded."
		}
	}
	# Impresión en caso de error en el segundo control
	catch
	{
		Write-Host "[$(Get-Date -format "dd-MMM-yyyy HH:mm")] ERROR: $($_.Exception.Message)"
		LogWrite "[$(Get-Date -format "dd-MMM-yyyy HH:mm")] ERROR: $($_.Exception.Message)"
		exit 1
	}
	finally
	{
		# Desconexión, limpieza
		$session.Dispose()
	}
	exit 0
}
# Impresión en caso de error en el primer control
catch 
{
	Write-Host "[$(Get-Date -format "dd-MMM-yyyy HH:mm")] ERROR: $($_.Exception.Message)"
	LogWrite "[$(Get-Date -format "dd-MMM-yyyy HH:mm")] ERROR: $($_.Exception.Message)"
	exit 1
}
