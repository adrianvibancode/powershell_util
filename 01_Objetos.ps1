<# 
Este es un comentario 
de multiples líneas 
#>

Set-ExecutionPolicy RemoteSigned Se recomienda el uso de RemoteSigned porque permite el código almacenado y escrito localmente, y requiere que el código adquirido de forma remota se firme con un certificado de una raíz confiable.

Write-Host "Hola mundo" #Escribe un mensaje en la pantalla. El mensaje se muestra solo en stdout es decir en la consola.
Write-Output "Hola mundo" > saludo.txt #Escribe un archivo con el texto que se le pasa como parámetro.

$variable = Write-Output "Hola mundo" #Declara una variable y la asigna con el texto que se le pasa como parámetro.



Get-ChildItem | ? { $_.Name -eq "saludo.txt" } #Obtiene una lista de archivos que coincidan con el criterio de búsqueda. El simbolo ? es un alias para el operador de condición tipo Donde-Objeto.   

#Uso de biblioteca .Net estatica.
[System.IO.Path]::GetFileName("saludo.txt") #Obtiene el nombre del archivo.

#Uso de metodos no estáticos.
$Object = New-Object -TypeName System.DateTime #Crea una instancia de la clase DateTime.
$Object.ToString("yyyy-MM-dd") #Obtiene la fecha en formato yyyy-MM-dd.

#Creacion de objetos 

$Object = New-Object -TypeName PSObject -Property @{
    Name = "Hola mundo"
    Age = "23"
}

