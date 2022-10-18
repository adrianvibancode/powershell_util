$clearCache = Read-Host "Eliminaras Cache de Teams (Y/N)?"
$clearCache = $clearCache.ToUpper()
$uninstall= Read-Host "Desinstalaras teams (Y/N)?"
$uninstall= $uninstall.ToUpper()


if ($clearCache -eq "Y"){
    Write-Host "Deteniendo proceso de Teams" -ForegroundColor Yellow
    try{
        Get-Process -ProcessName Teams | Stop-Process -Force
        Start-Sleep -Seconds 3
        Write-Host "Proceso de Teams detenido" -ForegroundColor Green
    }catch{
        echo $_
    }
    
    Write-Host "Limpiando Teams Disk Cache" -ForegroundColor Yellow
    try{
        Get-ChildItem -Path $env:APPDATA\"Microsoft\teams\application cache\cache" | Remove-Item -Confirm:$false
        Get-ChildItem -Path $env:APPDATA\"Microsoft\teams\blob_storage" | Remove-Item -Confirm:$false
        Get-ChildItem -Path $env:APPDATA\"Microsoft\teams\databases" | Remove-Item -Confirm:$false
        Get-ChildItem -Path $env:APPDATA\"Microsoft\teams\cache" | Remove-Item -Confirm:$false
        Get-ChildItem -Path $env:APPDATA\"Microsoft\teams\gpucache" | Remove-Item -Confirm:$false
        Get-ChildItem -Path $env:APPDATA\"Microsoft\teams\Indexeddb" | Remove-Item -Confirm:$false
        Get-ChildItem -Path $env:APPDATA\"Microsoft\teams\Local Storage" | Remove-Item -Confirm:$false
        Get-ChildItem -Path $env:APPDATA\"Microsoft\teams\tmp" | Remove-Item -Confirm:$false
        Write-Host "Cache de Teams eliminado del usuario" -ForegroundColor Green
    }catch{
        echo $_
    }
    Write-Host "Procesos de Chrome Detenidos" -ForegroundColor Yellow
    try{
        Get-Process -ProcessName Chrome| Stop-Process -Force
        Start-Sleep -Seconds 3
        Write-Host "Proceso de Chrome detenido" -ForegroundColor Green
    }catch{
        echo $_
    }
    Write-Host "Limpiando Cache de Chrome " -ForegroundColor Yellow
    
    try{
        Get-ChildItem -Path $env:LOCALAPPDATA"\Google\Chrome\User Data\Default\Cache" | Remove-Item -Confirm:$false
        Get-ChildItem -Path $env:LOCALAPPDATA"\Google\Chrome\User Data\Default\Cookies" -File | Remove-Item -Confirm:$false
        Get-ChildItem -Path $env:LOCALAPPDATA"\Google\Chrome\User Data\Default\Web Data" -File | Remove-Item -Confirm:$false
        Write-Host "Cache de Chrome Limpio" -ForegroundColor Green
    }catch{
        echo $_
    }
    
    Write-Host "IE detenido" -ForegroundColor Yellow
    
    try{
        Get-Process -ProcessName MicrosoftEdge | Stop-Process -Force
        Get-Process -ProcessName IExplore | Stop-Process -Force
        Write-Host "Procesos de edge detenidos..." -ForegroundColor Green
    }catch{
        echo $_
    }
    Write-Host "Cache de IE" -ForegroundColor Yellow
    
    try{
        RunDll32.exe InetCpl.cpl, ClearMyTracksByProcess 8
        RunDll32.exe InetCpl.cpl, ClearMyTracksByProcess 2
        Write-Host "Cache de Edge limpio" -ForegroundColor Green
    }catch{
        echo $_
    }
    Write-Host "Limpieza completa..." -ForegroundColor Green
}



if ($uninstall -eq "Y"){
    Write-Host "Eliminando Teams Machine-wide Installer" -ForegroundColor Yellow
    $MachineWide = Get-WmiObject -Class Win32_Product | Where-Object{$_.Name -eq "Teams Machine-Wide Installer"}
    $MachineWide.Uninstall()


    function unInstallTeams($path) {
    $clientInstaller = "$($path)\Update.exe"
  
        try {
            $process = Start-Process -FilePath "$clientInstaller" -ArgumentList "--uninstall /s" -PassThru -Wait -ErrorAction STOP
            if ($process.ExitCode -ne 0)
            {
                Write-Error "La desinstalacion a fallado con codigo $($process.ExitCode)."
            }
        }
        catch {
            Write-Error $_.Exception.Message
        }
    }

    #Locate installation folder
    $localAppData = "$($env:LOCALAPPDATA)\Microsoft\Teams"
    $programData = "$($env:ProgramData)\$($env:USERNAME)\Microsoft\Teams"
    
    If (Test-Path "$($localAppData)\Current\Teams.exe") 
    {
        unInstallTeams($localAppData)
    }
    elseif (Test-Path "$($programData)\Current\Teams.exe") {
        unInstallTeams($programData)
    }
    else {
        Write-Warning  "No existe la instalacion de teams"
    }


    

    Get-AppxPackage -name '*teams' | Remove-AppxPackage

    Write-Host "Appx Teams eliminado" -ForegroundColor Green
    Start-Sleep -Seconds 10
}