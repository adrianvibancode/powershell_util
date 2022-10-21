<#
.SYNOPSIS
Este Script busca los usuarios que iniciaron sesión en una computadora unida a un dominio y permite la limpieza.
.DESCRIPTION
Busca usuarios usuarios iniciaron sesión en una computadora unida a un dominio en el contexto de administrador
limpia carpetas para liberar espacio en el disco duro.
#>


<# El registro de la sesion en PowerShell se guarda en un archivo de texto ubicado en c:\scripts\logs\ #>
Start-Transcript ("c:\scripts\logs\CleanUsers\CleanUsers{0:yyyyMMdd-HHmm}.txt" -f (Get-Date))

<# Funcion que muestra informacion de disco duro#>
function ShowDisk {
    Get-WMIObject  -Class Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3} | Select-Object @{n="Unidad";e={($_.Name)}}, @{n="Etiqueta";e={($_.VolumeName)}},@{n='Tamaño (GB)';e={"{0:n2}" -f ($_.size/1gb)}}, @{n='Libre (GB)';e={"{0:n2}" -f ($_.freespace/1gb)}}, @{n='% Libre';e={"{0:n2}" -f ($_.freespace/$_.size*100)}}
}


Write-Host "Status del disco" 
ShowDisk

<# Variables de apoyo #>
$name=""
$cont=0

<# Obtener UserProfile con Get-WmiObject #>
$accounts = Get-WmiObject -Class Win32_UserProfile | Where-Object {$_.Special -ne 'Special'}
<# Seleccionde propiedad LocalPath #>
$usuarios = $accounts | Select-Object LocalPath


    if ($usuarios) {
	<# Recorre los usuarios existentes #>
        
	ForEach ($usuario in $usuarios) {
	
	$usuario=$usuario.LocalPath -replace ("@{Name=", "") -replace ("}","")
	
            try {
                
                $name=$usuario.Substring(9)	
        	    Write-Host "$($name):"

                if($name.Length.Equals(11)){
                    
                    $cont=$cont+1

                    if (Test-Path "$($usuario)\AppData\Local\Microsoft\Teams"){
                        Remove-Item -Path "$($usuario)\AppData\Local\Microsoft\Teams" -Force -Recurse
                        Write-Host "   $($name) ... Remove Local\Microsoft\Teams" -ForegroundColor Yellow
                    
                    }

                    if (Test-Path "$($usuario)\AppData\Local\Google\Chrome\User Data\Default\Cache") {
                        <# Borrado de Cache Chrome #>
                        Remove-Item -Path "$($usuario)\AppData\Local\Google\Chrome\User Data\Default\Cache" -Force -Recurse
                        Write-Host "   $($name) ... Remove \Local\Google\Chrome\User Data\Default\Cache" -ForegroundColor Yellow
                        #Remove-Item -Path "$($usuario)\AppData\Local\Google\Chrome\User Data\Default\Cache" -Force -Recurse -Confirm:$false
                    }
                   
                    if (Test-Path "$($usuario)\AppData\Local\Microsoft\TeamsMeetingAddin") {
                        <# Borrado de TeamsMeetingAddin #>
                        Remove-Item -Path "$($usuario)\AppData\Local\Microsoft\TeamsMeetingAddin" -Force -Recurse
                        Write-Host "   $($name) ... Remove Teams meeting" -ForegroundColor Yellow
                    }

                    if (Test-Path "$($usuario)\AppData\Roaming\Microsoft\Teams") {
                        <# Borrado de Roaming teams#>
                        Remove-Item -Path "$($usuario)\AppData\Roaming\Microsoft\Teams" -Force -Recurse
                        Write-Host "   $($name) ... Remove Roaming\Microsoft\Teams" -ForegroundColor Yellow
                    }
                    
                    if (Test-Path "$($usuario)\AppData\Roaming\Teams\Dictionaries") {
                        <# Borrado de diccionarios#>
                        Remove-Item -Path "$($usuario)\AppData\Roaming\Teams\Dictionaries" -Force -Recurse
                        Write-Host "   $($name) ... Remove Roaming\Teams\Dictionaries" -ForegroundColor Yellow
                    }     
                    
                    if (Test-Path "$($usuario)\Desktop") {
                        <# Borrado de Escritorio#>
                        #Remove-Item -Path "$($usuario)\Desktop\*.*" -Force -Recurse
                        Write-Host "   $($name) ... Remove Desktop" -ForegroundColor Red
                    }

                    if (Test-Path "$($usuario)\Documents") {
                        <# Borrado de documentos#>
                        #Remove-Item -Path "$($usuario)\Documents\*.*" -Force -Recurse
                        Write-Host "   $($name) ... Remove Documents" -ForegroundColor Red
                    }
                }else{
			Write-Host "   El usuario no es alumno" -ForegroundColor Yellow
		}
            }catch{
                Write-Host "Error: existe un perfil de paginacion" -ForegroundColor Red
            }
        }
    }
    Write-Host "$($cont) usuarios procesados." -ForegroundColor Green
    Clear-Variable cont

    
    Write-Host "Disco" 
    ShowDisk

    Start-Sleep -Seconds 10
   

    #New-ItemProperty -Path "HKEY_CURRENT_USER\Software\Microsoft\Office\Teams" -Name SkipUpnPrefill -Value 1
    #Test-Remove-RegistryValue -Path "HKCU:\Software\Microsoft\Office\Teams" -Name "LoggedInOnce"
    #Test-Remove-RegistryValue -Path "HKCU:\Software\Microsoft\Office\Teams" -Name "LoggedInOnce"
    #Test-Remove-RegistryValue -Path "HKCU:\Software\Microsoft\Office\Teams" -Name "DeadEnd"
    #Remove-Item -Path "HKCU:\Software\Microsoft\Office\Outlook\Addins\TeamsAddin.FastConnect" -ErrorAction SilentlyContinue    



#Ideas de limpieza
#unInstallTeams($usuario)
#New-ItemProperty -Path "HKEY_CURRENT_USER\Software\Microsoft\Office\Teams" -Name PreventInstallationFromMsi -Value 1
#Equipo\HKEY_CURRENT_USER\Software\Microsoft\Office\Teams (REG_DWORD) 0x00000001 (1).
#Get-ChildItem $origen | Select-Object Name | Set-Content "c:\scripts\users.csv"
#(Get-Content "c:\scripts\perfiles.txt") -replace ("@{Name=", "") -replace ("}","") | Set-Content "c:\scripts\perfiles.txt"
# Quitamos de la lista los usuarios que no queremos que borre
#(Get-Content "c:\scripts\perfiles.txt") -replace ("Administrador", "") -replace ("runzue","") -replace ("Public","") -replace ("Default","") -replace ("stark","") -replace ("svc_antivirus","") -replace ("user","") | Set-Content "c:\scripts\perfiles.txt"
# Limpiamos los espacios en blanco y exportamos a TXT
#(Get-Content "c:\scripts\perfiles.txt") | ? {$_.trim() -ne "" } | Set-Content "c:\scripts\perfiles.txt"
# Pasamos contenido a variable para tratar el dato
#$perfiles= Get-Content "c:\scripts\perfiles.txt"
#Set-Location $p.LocalPath -replace ("@{Name=", "") -replace ("}","")
#RemoveUsers -User $rmvuser -Userpath $_SelectUser.LocalPath

Stop-Transcript
