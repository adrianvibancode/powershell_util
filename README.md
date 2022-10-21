# Scripts desarrollados en PowerShell
Herramientas de uso para el mantenimiento y gestión en area de TI.

## AdminUser
    Con el uso de la tabla interactiva en una ventana separada se puede ordenar y filtrar usuarios a eliminar.

## CleanUser
    Borra carpetas de teams para liberar espacio en el disco duro.
    

> Buscan usuarios que iniciaron sesión en una computadora unida a un dominio en el contexto de administrador.

## Excepciones de uso

Cuando el equipo no esta en dominio.

1. Presiona la tecla windows + R y pega esto:

'''
powershell -Command "Start-Process PowerShell -Verb RunAs
'''
2. Pega esto en consola

'''
Set-ExecutionPolicy RemoteSigned
'''

Me encuentras en [GitHub](https://github.com/adrianvibancode)