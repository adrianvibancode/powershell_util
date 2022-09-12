#Crear carpeta
New-Item -Path 'C:\carpeta' -ItemType Directory
#Copiar
Copy-Item carpetaroot\*.* -Destination C:\carpeta\
#Nueva caracteristica
DISM /Online /Enable-Feature /FeatureName:NetFx3 /All /LimitAccess /Source:c:\sxs
#Operador de llamada
& 'run\AsistenteParaLaInstalacionDeTestingProgram.exe'