
<#
.SYNOPSIS
Este Script busca los usuarios que iniciaron sesión en una computadora unida a un dominio y permite la eliminación.
.DESCRIPTION
Busca usuarios usuarios iniciaron sesión en una computadora unida a un dominio en el contexto de administrador
Apoyo de interfaz para ordenar y filtrar usuarios a eliminar.
#>


<# El registro de la sesion en PowerShell se guarda en un archivo de texto ubicado en c:\scripts\logs\ #>
Start-Transcript ("c:\scripts\logs\AdminUsers\AdminUsers{0:yyyyMMdd-HHmm}.txt" -f (Get-Date))

<#Esta funcion envía la salida a una tabla interactiva en una ventana separada #>
function ShowUsers {
    param (
        [Object[]]$User,
        [String]$Title
    )
    $ShowUsersTemp = $User | Out-GridView -PassThru -Title $Title
    return  $ShowUsersTemp
}



function RemoveUsers {
    <#Funcion para eliminacion de usuarios con Remove-WmiObject#>
    param (
        [Object[]]$User,
        [Object[]]$Userpath
    )

    $title    = 'Eliminar Usuarios'
    $question1 = "Los siguientes usuarios seran eliminados"
    $question2 = $Userpath -Join "`r"
    $question3 = "¿Estas seguro que deseas continuar?"
    $question = "$question1{0}$question2{0}$question3" -f [environment]::NewLine
    $choices  = '&Yes', '&No'

	$popup = New-Object -ComObject wscript.shell
	$decision = $popup.Popup("$question",0,"$title",64+1)

    if ($decision -eq 1){
        $User | Remove-WmiObject
    } else {
        Write-Host 'Cancelado'
    }
}

<# Obtener UserProfile con Get-WmiObject #>
$accounts = Get-WmiObject -Class Win32_UserProfile | Where-Object {$_.Special -ne 'Special'}
<# Split-path para tratar la informacion del usuario Nombre. LocalPath, SID#>
$allusers = $accounts | Select-Object @{Name='UserName';Expression={Split-Path $_.LocalPath -Leaf}}, LocalPath, Loaded, SID, @{Name='LastUsed';Expression={$_.ConvertToDateTime($_.LastUseTime)}}
<# Se muestra en la tabla interactiva para la de la seleccion de usuarios el resultado se manda a una variable #>
$_Selectuser = ShowUsers -User $allusers -Title "Remove Users"
$rmvuser = $accounts | Where-Object {$_.SID -in $_Selectuser.SID}

<#Se manda el resultado a la funcion Remove Users#>
RemoveUsers -User $rmvuser -Userpath $_SelectUser.LocalPath

Stop-Transcript

Start-Sleep -Seconds 10
