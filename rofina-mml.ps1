# requires -version 2
<#
.SYNOPSIS
	Script de envío de archivos MML a Rofina
	
.DESCRIPTION
	Script de envío de archivos MML a Rofina
	
.INPUTS
	None
	
.OUTPUTS
	Función Write-Log reemplaza llamadas a Write-Host
	Write-Host se usa únicamente para las excepciones en conjunto con la función Write-Log
		
.NOTES
	Version:		1.1
	Author:			Santiago Platero
	Creation Date:	18/01/2018
	Purpose/Change: Script inicial para envío de archivos MML a Rofina
	
.EXAMPLE
	>powershell -command ".'<absolute path>\rofina-mml.ps1'"
#>

#---------------------------------------------------------[Inicializaciones]--------------------------------------------------------

# Inicializaciones de variables
$fileSourceMTV = "\\192.168.0.83\qad\wrkdir\aix\rofina\mtv\output\*"
$fileSourceCopiedMTV = "\\192.168.0.83\qad\wrkdir\aix\rofina\mtv\output\backup\"
$fileSourceRFO = "\\192.168.0.83\qad\wrkdir\aix\rofina\raffo\output\*"
$fileSourceCopiedRFO = "\\192.168.0.83\qad\wrkdir\aix\rofina\raffo\output\backup\"
$fileDestination = "/entrada/*"
$fileMask = "|*/"
$dateFormat = "dd-MMM-yyyy HH:mm:ss"

#----------------------------------------------------------[Declaraciones]----------------------------------------------------------

# Información del script
$scriptVersion = "1.0"
$scriptName = $MyInvocation.MyCommand.Name

# Información de archivos de logs
$logPath = "C:\logs"
$logName = "$($scriptName).log"
$logFile = Join-Path -Path $logPath -ChildPath $logName

#-----------------------------------------------------------[Funciones]------------------------------------------------------------

#Función para hacer algo (?) de logueo
Function Write-Log
{
	Param ([string]$logstring)	
	Add-Content $logFile -value $logstring
}

Function Write-Exception
{
	Write-Host "[$(Get-Date -format $($dateFormat))] ERROR: $($_.Exception.Message)"
	Write-Log "[$(Get-Date -format $($dateFormat))] ERROR: $($_.Exception.Message)"
	Write-Log "[$(Get-Date -format $($dateFormat))] FIN DE EJECUCION DE $($scriptName)"
	Write-Log " "
	exit 1
}

#-----------------------------------------------------------[Ejecución]------------------------------------------------------------

# Primer control de errores: falta DDL, errores del servidor remoto, etc.
Write-Log "[$(Get-Date -format $($dateFormat))] INICIO DE EJECUCION DE $($scriptName)"
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
		Write-Log "[$(Get-Date -format $($dateFormat))] Conectando a $($sessionOptions.UserName)@$($sessionOptions.HostName):$($sessionOptions.PortNumber)"
	
		# Opciones de transferencia
		$transferOptions = New-Object WinSCP.TransferOptions
		$transferOptions.FileMask = $fileMask
		
		# Envío de archivos MTV
		$transferFiles = $session.PutFiles($fileSourceMTV, $fileDestination, $False, $transferOptions)
			
			# Arrojar cualquier error
			$transferFiles.Check()
	
			# Loopeamos por cada archivo que se transfiera de MTV
			foreach ($transfer in $transferFiles.Transfers)
			{
				$file = $transfer.FileName
			}
			# Antes de mandar al log, verificamos que la variable no sea nula
			if (!$file)
			{
				Write-Log "[$(Get-Date -format $($dateFormat))] Ningún archivo de Monte Verde fue encontrado/transferido"
			}
			else
			{
				Write-Log "[$(Get-Date -format $($dateFormat))] Transferencia de $($transfer.FileName) (Monte Verde) exitosa"
				Move-Item $transfer.FileName $fileSourceCopiedMTV
			}
				
		# Envío de archivos RFO
		$transferFiles = $session.PutFiles($fileSourceRFO, $fileDestination, $False, $transferOptions)
			
			# Arrojar cualquier error
			$transferFiles.Check()
	
			# Loopeamos por cada archivo que se transfiera de RFO
			foreach ($transfer in $transferFiles.Transfers)
			{
				$file = $transfer.FileName
			}
			# Antes de mandar al log, verificamos que la variable no sea nula
			if (!$file)
			{
				Write-Log "[$(Get-Date -format $($dateFormat))] Ningún archivo de Raffo fue encontrado/transferido"
			}
			else
			{
				Write-Log "[$(Get-Date -format $($dateFormat))] Transferencia de $($transfer.FileName) (Raffo) exitosa"
				Move-Item $transfer.FileName $fileSourceCopiedRFO
			}
	}
	# Impresión en caso de error en el segundo control
	catch
	{
		Write-Exception
	}
	finally
	{
		# Desconexión, limpieza
		$session.Dispose()
	}
	Write-Log "[$(Get-Date -format $($dateFormat))] FIN DE EJECUCION DE $($scriptName)"
	Write-Log " "
	exit 0
}
# Impresión en caso de error en el primer control
catch 
{
	Write-Exception
}
