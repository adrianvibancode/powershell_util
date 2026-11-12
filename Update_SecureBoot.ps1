<#
.SYNOPSIS
  Diagnostico y piloto de actualizacion de certificados Secure Boot 2023
  (HP 280 G3 SFF y equipos similares). UAT - Soporte TI.

.DESCRIPTION
  Basado en la guia tecnica de HP (rev. 30-oct-2026) y Microsoft KB5068202.

  -Mode Diagnose (default): SOLO LECTURA. Seguro para toda la flota.
  -Mode Apply             : SOLO PILOTO. Respalda variables, solicita
                            AvailableUpdates=0x5944 y lanza la tarea.
                            NO reinicia el equipo.
  -Mode Verify            : Despues del reinicio. Relanza la tarea y valida el
                            resultado.

  Este script NO revoca DBX ni elimina certificados de 2011.
  Si aparece el evento 1803 (KEK sin firma de la PK de HP) se detiene:
  en ese caso se necesita el paquete firmado por HP.

.EXAMPLE
  .\SecureBoot-HP280G3.ps1
  .\SecureBoot-HP280G3.ps1 -ReportShare \\servidor\reportes$\secureboot
  .\SecureBoot-HP280G3.ps1 -Mode Apply
  .\SecureBoot-HP280G3.ps1 -Mode Verify
#>
#Requires -RunAsAdministrator
[CmdletBinding()]
param(
    [ValidateSet('Diagnose','Apply','Verify')][string]$Mode = 'Diagnose',
    [string]$LogDir = 'C:\SB_Logs',
    [string]$ReportShare = '',
    [int]$WaitSeconds = 120
)

$ErrorActionPreference = 'Continue'
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$logFile = Join-Path $LogDir ("SB_{0}_{1}_{2}.log" -f $env:COMPUTERNAME, $Mode, $stamp)
Start-Transcript -Path $logFile | Out-Null

$SBKey    = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot'
$SrvKey   = "$SBKey\Servicing"
$TaskName = '\Microsoft\Windows\PI\Secure-Boot-Update'
$EventIds = 1032,1043,1044,1045,1795,1799,1800,1801,1802,1803,1808

# ---------------------------------------------------------------- helpers
function Get-Reg($path, $name) {
    try { (Get-ItemProperty -Path $path -Name $name -ErrorAction Stop).$name } catch { $null }
}

# Comprobacion ORIENTATIVA (busqueda de texto en binario), no es validacion criptografica.
function Test-SBString($var, $text) {
    try {
        $bytes = (Get-SecureBootUEFI -Name $var -ErrorAction Stop).Bytes
        return ([System.Text.Encoding]::ASCII.GetString($bytes) -match [regex]::Escape($text))
    } catch { return $null }
}

function Get-SBState {
    $bios = Get-CimInstance Win32_BIOS
    $cs   = Get-CimInstance Win32_ComputerSystem
    $sbOn = try { Confirm-SecureBootUEFI -ErrorAction Stop } catch { $null }
    $avail = Get-Reg $SBKey 'AvailableUpdates'
    $task = Get-ScheduledTask -TaskPath '\Microsoft\Windows\PI\' -TaskName 'Secure-Boot-Update' -ErrorAction SilentlyContinue

    $ev = @(Get-WinEvent -FilterHashtable @{ LogName='System'; ProviderName='Microsoft-Windows-TPM-WMI'; Id=$EventIds } -MaxEvents 50 -ErrorAction SilentlyContinue)
    $evIds = ($ev | Select-Object -ExpandProperty Id -Unique | Sort-Object) -join ','

    $s = [pscustomobject][ordered]@{
        Fecha            = (Get-Date -Format 's')
        Equipo           = $env:COMPUTERNAME
        Modelo           = $cs.Model
        Serie            = (Get-CimInstance Win32_BIOS).SerialNumber
        ProductNumber    = $cs.SystemSKUNumber
        BIOS             = $bios.SMBIOSBIOSVersion
        BIOSFecha        = $bios.ReleaseDate
        SecureBootOn     = $sbOn
        DB_CA2023        = (Test-SBString 'db'  'Windows UEFI CA 2023')
        KEK_CA2023       = (Test-SBString 'KEK' 'Microsoft Corporation KEK 2K CA 2023')
        UEFICA2023Status = (Get-Reg $SrvKey 'UEFICA2023Status')
        UEFICA2023Error  = (Get-Reg $SrvKey 'UEFICA2023Error')
        AvailableUpdates = $(if ($null -ne $avail) { '0x{0:X}' -f $avail } else { $null })
        TareaHabilitada  = [bool]($task -and $task.State -ne 'Disabled')
        EventosTPMWMI    = $evIds
        Recomendacion    = ''
    }
    $s.Recomendacion = Get-Recommendation $s
    return $s
}

function Get-Recommendation($s) {
    if ($s.UEFICA2023Status -eq 'Updated' -and $s.SecureBootOn -eq $true) { return 'OK: transicion completada. No tocar.' }
    if ($s.EventosTPMWMI -match '1803') { return 'Evento 1803: KEK sin firma de la PK de HP. Pedir paquete a HP; no aplicar mas cambios.' }
    if ($s.EventosTPMWMI -match '1802') { return 'Evento 1802: bloqueado por problema conocido de firmware. Consultar HP.' }
    if ($null -eq $s.SecureBootOn)      { return 'No se pudo leer Secure Boot (BIOS Legacy / no UEFI?).' }
    if ($s.SecureBootOn -eq $false)     { return 'Secure Boot desactivado: Apply no aplica. Ver recuperacion en KB5085046 / pedir paquete a HP.' }
    if (-not $s.TareaHabilitada)        { return 'Falta o esta deshabilitada la tarea Secure-Boot-Update. Resolver primero (KB5085046).' }
    return 'Candidato a piloto (Apply) tras validar el BIOS minimo en el articulo de HP.'
}

# Respaldo de REFERENCIA de PK/KEK/db/dbx (no es directamente restaurable sin firma).
function Backup-SBVars {
    $dir = Join-Path $LogDir ("Backup_{0}_{1}" -f $env:COMPUTERNAME, $stamp)
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    foreach ($v in 'PK','KEK','db','dbx') {
        try {
            [IO.File]::WriteAllBytes((Join-Path $dir "$v.bin"), (Get-SecureBootUEFI -Name $v -ErrorAction Stop).Bytes)
        } catch {
            Write-Warning "No se pudo respaldar $v : $_"
            return $false
        }
    }
    Write-Host "Respaldo en: $dir"
    return $true
}

function Wait-SBTask([int]$sec) {
    $end = (Get-Date).AddSeconds($sec)
    do {
        Start-Sleep -Seconds 5
        $a = Get-Reg $SBKey 'AvailableUpdates'
        Write-Host ("  AvailableUpdates = 0x{0:X}" -f $a)
    } while ((Get-Date) -lt $end -and $a -ne 0x4100 -and $a -ne 0x4000)
    return $a
}

function Write-Report($s) {
    $s | Export-Csv -Path (Join-Path $LogDir 'SB_estado.csv') -Append -NoTypeInformation -Encoding UTF8
    if ($ReportShare) {
        try {
            $s | Export-Csv -Path (Join-Path $ReportShare ("{0}.csv" -f $env:COMPUTERNAME)) -NoTypeInformation -Encoding UTF8
        } catch { Write-Warning "No se pudo escribir en $ReportShare" }
    }
}

# ---------------------------------------------------------------- main
try {
    switch ($Mode) {

        'Diagnose' {
            $s = Get-SBState
            $s | Format-List
            Write-Report $s
        }

        'Apply' {
            $s = Get-SBState
            $s | Format-List

            if ($s.UEFICA2023Status -eq 'Updated') { Write-Host 'Ya actualizado. Nada que hacer.'; return }
            if ($s.SecureBootOn -ne $true)         { Write-Warning 'Secure Boot no esta habilitado. Abortando.'; Write-Report $s; return }
            if (-not $s.TareaHabilitada)           { Write-Warning 'Tarea Secure-Boot-Update no disponible. Abortando.'; Write-Report $s; return }
            if ($s.EventosTPMWMI -match '1802|1803') { Write-Warning 'Eventos 1802/1803 presentes. Abortando; contactar a HP.'; Write-Report $s; return }

            Write-Host ''
            Write-Host 'CONFIRME: este es un equipo PILOTO.'
            if ((Read-Host 'Escriba SI para continuar') -ne 'SI') { Write-Host 'Cancelado.'; return }

            if (-not (Backup-SBVars)) { Write-Warning 'Sin respaldo no se continua.'; return }

            Write-Host 'Solicitando AvailableUpdates = 0x5944 ...'
            Set-ItemProperty -Path $SBKey -Name 'AvailableUpdates' -Type DWord -Value 0x5944
            Start-ScheduledTask -TaskName $TaskName
            $a = Wait-SBTask $WaitSeconds

            $s2 = Get-SBState
            $s2 | Format-List
            Write-Report $s2

            if ($a -eq 0x4100) {
                Write-Host ''
                Write-Host 'LISTO PARA REINICIAR: reinicie el equipo MANUALMENTE y luego ejecute: -Mode Verify'
            } else {
                Write-Warning 'No se alcanzo 0x4100. Revise UEFICA2023Error y eventos TPM-WMI. NO repita el valor en bucle.'
            }
        }

        'Verify' {
            Write-Host 'Relanzando tarea Secure-Boot-Update...'
            Start-ScheduledTask -TaskName $TaskName
            [void](Wait-SBTask $WaitSeconds)

            $s = Get-SBState
            $s | Format-List
            Write-Report $s

            if ($s.UEFICA2023Status -eq 'Updated' -and $s.EventosTPMWMI -match '1808') {
                Write-Host 'OK: UEFICA2023Status = Updated y evento 1808 presente.'
                Write-Host 'Reinicie una vez mas y confirme arranque normal sin Secure Boot Violation.'
            } else {
                Write-Warning 'Aun no hay evidencia de actualizacion completa. Revise UEFICA2023Error y eventos; no repita Apply sin analizar.'
            }
        }
    }
}
finally {
    Stop-Transcript | Out-Null
}
