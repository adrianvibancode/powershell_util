<#
.SYNOPSIS
Este Script busca los usuarios que iniciaron sesión en una computadora unida a un dominio y permite la limpieza.
.DESCRIPTION
Busca usuarios usuarios iniciaron sesión en una computadora unida a un dominio en el contexto de administrador
Apoyo de interfaz para ordenar y filtrar usuarios a eliminar.
#>

function ShowDisk {
    Get-WMIObject  -Class Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3}  `
       | Select-Object @{n="Unidad";e={($_.Name)}}, 
                       @{n="Etiqueta";e={($_.VolumeName)}}, 
                       @{n='Tamaño (GB)';e={"{0:n2}" -f ($_.size/1gb)}}, 
                       @{n='Libre (GB)';e={"{0:n2}" -f ($_.freespace/1gb)}}, 
                       @{n='% Libre';e={"{0:n2}" -f ($_.freespace/$_.size*100)}}
                       
   }

Start-Transcript ("c:\scripts\logs\CleanUsers\CleanUsers{0:yyyyMMdd-HHmm}.txt" -f (Get-Date))

Write-host "Estado del espacio de disco duro al inicio de la sesion:" -ForegroundColor Red
ShowDisk


$accounts = Get-WmiObject -Class Win32_UserProfile | Where-Object {$_.Special -ne 'Special'}
$usuarios = $accounts | Select-Object LocalPath
$name=""
$cont=0

    if ($usuarios) {
        ForEach ($usuario in $usuarios) {
		
            $cont=$cont+1

            $usuario=$usuario.LocalPath -replace ("@{Name=", "") -replace ("}","")
            
            try {
                $name=$usuario.Substring(9)
                "$($name):"

                if($name.Length.Equals(11)){
            
                    if (Test-Path "$($usuario)\AppData\Roaming\Microsoft\Teams") {
                        <# Action to perform if the condition is true #>
                        Remove-Item -Path "$($usuario)\AppData\Roaming\Microsoft\Teams" -Force -Recurse
                        Write-Host "   Roaming $($usuario.Substring(9,11))" -ForegroundColor Red
                    }
                    
                    if (Test-Path "$($usuario)\AppData\Local\Microsoft\TeamsMeetingAddin") {
                        <# Action to perform if the condition is true #>
                        Remove-Item -Path "$($usuario)\AppData\Local\Microsoft\TeamsMeetingAddin" -Force -Recurse
                        Write-Host "   Teams meeting en $($name)" -ForegroundColor Red
                    }
                
                    if (Test-Path "$($usuario)\AppData\Roaming\Teams\Dictionaries") {
                            <# Action to perform if the condition is true #>
                            Remove-Item -Path "$($usuario)\AppData\Roaming\Teams\Dictionaries" -Force -Recurse
                            Write-Host "   Roaming $($name)" -ForegroundColor Red
                    }

                    if (Test-Path "$($usuario)\AppData\Local\Google\Chrome\User Data\Default\Cache") {
                            <# Action to perform if the condition is true #>
                            Remove-Item -Path "$($usuario)\AppData\Local\Google\Chrome\User Data\Default\Cache" -Force -Recurse
                            Write-Host "   Roaming $($name)" -ForegroundColor Red
                            #Remove-Item -Path "$($usuario)\AppData\Local\Google\Chrome\User Data\Default\Cache" -Force -Recurse -Confirm:$false
                    }
                            
                    if (Test-Path "$($usuario)\AppData\Local\Microsoft\Teams"){
                            Remove-Item -Path "$($usuario)\AppData\Local\Microsoft\Teams" -Force -Recurse
                            Write-Host "   Update.exe $($name)" -ForegroundColor Red
                    
                    }
                    
                    if (Test-Path "$($usuario)\Desktop") {
                        <# Action to perform if the condition is true #>
                        Remove-Item -Path "$($usuario)\Desktop\*.*" -Force -Recurse
                        Write-Host "   Roaming $($name)" -ForegroundColor Red
                    }

                    if (Test-Path "$($usuario)\Documents") {
                        <# Action to perform if the condition is true #>
                        Remove-Item -Path "$($usuario)\Documents\*.*" -Force -Recurse
                        Write-Host "   Roaming $($name)" -ForegroundColor Red
                    }
                }
            }catch{
                "El usuario $($usuario)) no es alumno `n"+$Error[0]
            }
        }
    
    Write-Output "$($cont) usuarios procesados."

    
    Write-host "Estado del espacio de disco duro al final de la sesion:" -ForegroundColor Green
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