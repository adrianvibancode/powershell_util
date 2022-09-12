#Creacion de Archivos .CSV
$CSVfile = New-Object -TypeName System.IO.StreamWriter("CSVfile.csv") #Crea un archivo .CSV.

#Agrega informacion al csv
#$CSVfile.WriteLine("String,DateTime,Integer") #Escribe la primera linea del archivo.