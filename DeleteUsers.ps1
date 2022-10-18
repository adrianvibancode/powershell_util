
# LOG
Start-Transcript ("c:\scripts\logs\OWNER-ScriptLog{0:yyyyMMdd-HHmm}.txt" -f (Get-Date))

function ShowUsers {
    param (
        [Object[]]$User,
        [String]$Title
    )
    $ShowUsersTemp = $User | Out-GridView -PassThru -Title $Title
    return  $ShowUsersTemp
}

function RemoveUsers {
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

    if ($decision -eq 1) 
	{
        $User | Remove-WmiObject
    } else {
        Write-Host 'Cancelled'
    }
}

$accounts = Get-WmiObject -Class Win32_UserProfile | Where-Object {$_.Special -ne 'Special'}

$allusers = $accounts | Select-Object @{Name='UserName';Expression={Split-Path $_.LocalPath -Leaf}}, LocalPath, Loaded, SID, @{Name='LastUsed';Expression={$_.ConvertToDateTime($_.LastUseTime)}}

$_Selectuser = ShowUsers -User $allusers -Title "Remove Users"

$rmvuser = $accounts | Where-Object {$_.SID -in $_Selectuser.SID}

RemoveUsers -User $rmvuser -Userpath $_SelectUser.LocalPath

Stop-Transcript
