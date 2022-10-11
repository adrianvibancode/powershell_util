
# LOG
Start-Transcript ("c:\scripts\logs\OWNER-ScriptLog{0:yyyyMMdd-HHmm}.txt" -f (Get-Date))

# CARPETA PERFILES
    $origen = "C:\Users"

# LISTAR PERFILES
    Get-ChildItem $origen | Select-Object Name | Set-Content "c:\scripts\perfiles.txt"

    # Eliminar valores
    (Get-Content "c:\scripts\perfiles.txt") -replace ("@{Name=", "") -replace ("}","") | Set-Content "c:\scripts\perfiles.txt"
    # Quitamos de la lista los usuarios que no queremos que borre
    (Get-Content "c:\scripts\perfiles.txt") -replace ("Administrador", "") -replace ("runzue","") -replace ("Public","") -replace ("Default","") -replace ("stark","") -replace ("svc_antivirus","") -replace ("user","") | Set-Content "c:\scripts\perfiles.txt"
    # Limpiamos los espacios en blanco y exportamos a TXT
    (Get-Content "c:\scripts\perfiles.txt") | ? {$_.trim() -ne "" } | Set-Content "c:\scripts\perfiles.txt"
    # Pasamos contenido a variable para tratar el dato
    $perfiles= Get-Content "c:\scripts\perfiles.txt"

# SI EXISTEN PERFILES COMIENZA BORRADO 
if ($perfiles) {
    
    # RECORRIDO DEL FICHERO
    ForEach ($p in $perfiles) {
    
    if($p){
        # BORRADO DE PERFIL
        Remove-Item -Path "C:\Users\$p" -Force -Recurse
    }
    # FINAL DEL FICHERO
    else{
        Write-Output "Todos los perfiles procesados"
    }
    }
}
else {
    Write-Output "No hay perfiles a eliminar"
}
# Borrar TXT
Remove-Item "c:\scripts\perfiles.txt"
# Paramos log
Stop-Transcript
