#Instalar modulos de SQL Server y IIS
Import-Module sqlps -DisableNameChecking
Import-Module WebAdministration
$Ubicación_de_variables = "C:\Tsol_Ambiente_nuevo\Archivos_configuracion" #Colocar la ubicación de los scripts  (Variables_cliente.txt y Variables_configuracion.txt)
$Contents_variables_clientes = Get-Content $Ubicación_de_variables\Variables_cliente.txt <#Ubicación donde se encuentra el txt de variables de los clientes#>

#registro en nota
$ubicaciondelog="$Ubicación_de_variables\Registro.txt" 
if (test-path $ubicaciondelog) 
{
Remove-Item $ubicaciondelog -Recurse -force 
}

Foreach ($LINE in $Contents_variables_clientes) 
{
Write-Output "Script ejecutado: $LINE" #Variables de cliente
$url_cliente = $LINE.split(",")[0]
$nombre_comercial = $LINE.split(",")[1]
$version_update = $LINE.split(",")[2]
$puerto = $LINE.split(",")[3]

$Contents_variable_configuracion = Get-Content $Ubicación_de_variables\Variables_configuracion.txt #Variables de configuración

$ubicación_desplegado = $Contents_variable_configuracion[0].split("|")[1]
$ubicación_codigo_siges = $Contents_variable_configuracion[1].split("|")[1]
$BackupFolder = $Contents_variable_configuracion[2].split("|")[1]
$serverName = $Contents_variable_configuracion[3].split("|")[1]
$Comentarios = $Contents_variable_configuracion[4].split("|")[1]
$ubicación_script_deshabilitar_parametro = $Contents_variable_configuracion[5].split("|")[1]
$ubicación_script_cambiar_password = $Contents_variable_configuracion[6].split("|")[1]
$Comentarios = $Contents_variable_configuracion[7].split("|")[1]
$Web_config_nombre_reemplazar_servidor = $Contents_variable_configuracion[8].split("|")[1]
$Web_config_nombre_reemplazar_usuario_bd = $Contents_variable_configuracion[9].split("|")[1]
$Web_config_nombre_reemplazar_contraseña_bd = $Contents_variable_configuracion[10].split("|")[1]
$Comentarios = $Contents_variable_configuracion[11].split("|")[1]
$Web_config_nombre_buscar_basedatos = $Contents_variable_configuracion[12].split("|")[1]
$Web_config_nombre_buscar_servidor = $Contents_variable_configuracion[13].split("|")[1]
$Web_config_nombre_buscar_usuario_bd = $Contents_variable_configuracion[14].split("|")[1]
$Web_config_nombre_buscar_contraseña_bd = $Contents_variable_configuracion[15].split("|")[1]
$Comentarios = $Contents_variable_configuracion[16].split("|")[1]
$nombredebdcalidad = $Contents_variable_configuracion[17].split("|")[1]

$Comentarios = $Contents_variable_configuracion[18].split("|")[1]
$Horario_bk = $Contents_variable_configuracion[19].split("|")[1]
$Ubicacion_script_bk = $Contents_variable_configuracion[20].split("|")[1]
$Carpeta_de_BK = $Contents_variable_configuracion[21].split("|")[1]

$cambio1 = $nombredebdcalidad
$cambio2 = $nombre_comercial

$script_bk="$($Ubicacion_script_bk)$("\")$nombre_comercial.ps1"

#$ubicación_de_logs = $Contents_variable_configuracion[6].split("|")[1]

#--------------------------------------------------------------------------------------------------
#**************************************************************************************************
#--------------------------------------------------------------------------------------------------
#crear ambiente de calidad en IIS
$get_items="IIS:\AppPools\"+$url_cliente
New-WebAppPool -name $url_cliente -force
$appPool = Get-Item $get_items
$appPool.processModel.identityType = “ApplicationPoolIdentity”
$appPool.enable32BitAppOnWin64 = 0
$appPool.managedRuntimeVersion = ‘v4.0’
$appPool.autoStart = ‘true’
$appPool | Set-Item
$ambiente_cliente = $ubicación_desplegado+"\"+$url_cliente
$sitio_prueba = $ubicación_desplegado+"\"+$url_cliente+"\index.html"
#------------------------------------------------------------------------------
$ip = Test-Connection -ComputerName(hostname) -Count 1 | Select-Object ipv4address
$direccion= $ip.IPV4Address.ToString()


#------------------------------------------------------------------------------
New-WebSite -name $url_cliente -PhysicalPath $ambiente_cliente -Port $puerto  -ApplicationPool $url_cliente -HostHeader $url_cliente -IPAddress $direccion -force 
New-WebBinding -Name $url_cliente   -IPAddress $direccion -Port $puerto -HostHeader "www.$url_cliente" -Protocol "http"

#Crear carpeta
$web = New-Item $ambiente_cliente –ItemType directory -Force
"<html>Hello Tsol</html>" | Out-File $sitio_prueba
#--------------------------------------------------------------------------------------------------
#**************************************************************************************************
#--------------------------------------------------------------------------------------------------
#Descarga de base de datos
<#
$ambiente_cliente = $BackupFolder+"\"+$url_cliente

New-Item $ambiente_cliente –ItemType directory -Force

$employess = Get-Content $Ubicación_de_variables\Enlaces_descarga_Bk.txt
$url =  $employess | Select-String -Pattern "tsolperu_siges_efactura_$($nombre_comercial)"
$url_efactura = $url.tostring().split("|")[1]
$bddescargado="$($BackupFolder)$("\")$($url_cliente)$("\")$($DataBase_efactura).zip"
Invoke-WebRequest -Uri $url_efactura -OutFile $bddescargado

$url =  $employess | Select-String -Pattern "tsolperu_siges_principal_$($nombre_comercial)"
$url_principal = $url.tostring().split("|")[1]
$bddescargado="$($BackupFolder)$("\")$($url_cliente)$("\")$($DataBase_principal).zip"
Invoke-WebRequest -Uri $url_principal -OutFile $bddescargado

$url =  $employess | Select-String -Pattern "tsolperu_siges_seguridad_$($nombre_comercial)"
$url_seguridad = $url.tostring().split("|")[1]
$bddescargado="$($BackupFolder)$("\")$($url_cliente)$("\")$($DataBase_seguridad).zip"
Invoke-WebRequest -Uri $url_seguridad -OutFile $bddescargado
#>
#--------------------------------------------------------------------------------------------------
#**************************************************************************************************
#--------------------------------------------------------------------------------------------------
#Detener el IIS
Stop-Website $url_cliente  #Detener la aplicación del cliente
#--------------------------------------------------------------------------------------------------
#**************************************************************************************************
#--------------------------------------------------------------------------------------------------
#Importar base de datos

$srv = New-Object Microsoft.SqlServer.Management.Smo.Server $serverName
$tipodebdprincipal="_principal_"
$tipodebdefactura="_efactura_"
$tipodebdseguridad="_seguridad_"
$tipodebdarray = $tipodebdprincipal,$tipodebdefactura,$tipodebdseguridad
foreach ($tipodebd in $tipodebdarray)
{
$DataBase = "tsolperu_siges$($tipodebd)$($cambio1)" 
$carpeta_bk_cliente = $BackupFolder+"\"+$url_cliente
$FilePath ="$($carpeta_bk_cliente)$("\")$($DataBase).bak"
$DestinationPath="$($BackupFolder)$("\")$($DataBase).zip"
Expand-Archive -LiteralPath $DestinationPath -DestinationPath $carpeta_bk_cliente #Descomprimir seguridad
#----------------
$DataBase_calidad = "tsolperu_siges$($tipodebd)$($cambio2)"
$FilePath_calidad ="$($carpeta_bk_cliente)$("\")$($DataBase_calidad).bak"
Rename-Item -Path $FilePath $FilePath_calidad
Write-Output "renombrar--------"
#----------------
$srv = New-Object Microsoft.SqlServer.Management.Smo.Server $serverName
if ($srv.Databases.name -like  $DataBase_calidad ){
    $srv.KillAllProcesses($DataBase_calidad)   #mata las conexiones en dicha base de datos
    $srv.Databases[$DataBase_calidad].UserAccess = [Microsoft.SqlServer.Management.Smo.DatabaseUserAccess]::Single #configurado para un solo usuario
    $srv.ConnectionContext.StatementTimeout = 0;  #para que la restauración no se agote
    Restore-SqlDatabase -InputObject $srv -Database $DataBase_calidad -BackupFile $FilePath_calidad -ReplaceDatabase
    Write-Output "restaurar--------"
}
else {
    # Get the default file and log locations
    # (If DefaultFile and DefaultLog are empty, use the MasterDBPath and MasterDBLogPath values)
    $fileloc = $srv.Settings.DefaultFile
    $logloc = $srv.Settings.DefaultLog
    if ($fileloc.Length -eq 0) {
        $fileloc = $srv.Information.MasterDBPath
        }
    if ($logloc.Length -eq 0) {
        $logloc = $srv.Information.MasterDBLogPath
        }
    # Identify the backup file to use, and the name of the database copy to create
    $bckfile = $FilePath_calidad
    $dbname = $DataBase_calidad
    # Build the physical file names for the database copy
    $dbfile = $fileloc + '\'+ $dbname + '_Data.mdf'
    $logfile = $logloc + '\'+ $dbname + '_Log.ldf'
    # Use the backup file name to create the backup device
    $bdi = new-object ('Microsoft.SqlServer.Management.Smo.BackupDeviceItem') ($bckfile, 'File')
    # Create the new restore object, set the database name and add the backup device
    $rs = new-object('Microsoft.SqlServer.Management.Smo.Restore')
    $rs.Database = $dbname
    $rs.Devices.Add($bdi)
    # Get the file list info from the backup file
    $fl = $rs.ReadFileList($srv)
    foreach ($fil in $fl) {
        $rsfile = new-object('Microsoft.SqlServer.Management.Smo.RelocateFile')
        $rsfile.LogicalFileName = $fil.LogicalName
        if ($fil.Type -eq 'D'){
           $rsfile.PhysicalFileName = $dbfile
           }
       else {
           $rsfile.PhysicalFileName = $logfile
           }
       $rs.RelocateFiles.Add($rsfile)
       }
    # Restore the database
    $rs.SqlRestore($srv) 
    Write-Output "crear--------"       
}
Remove-Item $FilePath_calidad #Eliminar temporal de BK
}
#--------------------------------------------------------------------------------------------------
#**************************************************************************************************
#--------------------------------------------------------------------------------------------------
#Correr script de deshabilitar Parametros de facturación electronica

$srv = New-Object Microsoft.SqlServer.Management.Smo.Server $serverName

    $deshabilitarparametrofac ="tsolperu_siges_principal_$($cambio2)"
    if ($srv.Databases.name -like  $deshabilitarparametrofac )
        {
         $InputFile=$ubicación_script_deshabilitar_parametro
         Invoke-Sqlcmd -InputFile $InputFile -ServerInstance $serverName -Database $deshabilitarparametrofac
         Write-Output "deshabilitar parametro fac--------"
        }
    $cambiarcontraseña = "tsolperu_siges_seguridad_$($cambio2)"
    if ($srv.Databases.name -like  $cambiarcontraseña )
        {
         $InputFile= $ubicación_script_cambiar_password
         Invoke-Sqlcmd -InputFile $InputFile -ServerInstance $serverName -Database $cambiarcontraseña
         Write-Output "cambiar contraseña--------"
        }

#--------------------------------------------------------------------------------------------------
#**************************************************************************************************
#--------------------------------------------------------------------------------------------------
#Importar codigo fuente
#Descarga de codigo fuente
<#
$ambiente_cliente = $ubicación_codigo_siges+"\"+$url_cliente
New-Item $ambiente_cliente –ItemType directory -Force
$employess = Get-Content $Ubicación_de_variables\Enlaces_descarga_Codigo.txt
$url =  $employess | Select-String -Pattern "$($version_update)"
$url_efactura = $url.tostring().split("|")[1]
$bddescargado="$($ubicación_codigo_siges)$("\")$($url_cliente)$("\")$($version_update).zip"
Invoke-WebRequest -Uri $url_efactura -OutFile $bddescargado
#>
Stop-Website $url_cliente 
#Importar codigo fuente
$ambiente_cliente = $ubicación_desplegado+"\"+$url_cliente
Remove-Item $ambiente_cliente -Recurse
New-Item $ambiente_cliente –ItemType directory -Force
$codigo =$ubicación_codigo_siges+"\"+$version_update+".zip"
Expand-Archive -LiteralPath $codigo -DestinationPath $ambiente_cliente


#Cambiar el webconfig nombre  de la base de datos del cliente
$editar_webconfig = $ubicación_desplegado+"\"+$url_cliente+"\Web.config"
$buscar= $Web_config_nombre_buscar_basedatos
$reemplazar1= "$cambio2"
[xml]$webConfig = Get-Content $editar_webconfig | ForEach-Object { $_ -replace "$buscar","$reemplazar1" } 
$webConfig.Save($editar_webconfig)
$resultado=Get-Content $editar_webconfig

#Cambiar el nombre_reemplazar_servidor
$editar_webconfig = $ubicación_desplegado+"\"+$url_cliente+"\Web.config"
$buscar= $Web_config_nombre_buscar_servidor
$reemplazar2= $Web_config_nombre_reemplazar_servidor
[xml]$webConfig = Get-Content $editar_webconfig | ForEach-Object { $_ -replace "$buscar","$reemplazar2" } 
$webConfig.Save($editar_webconfig)
$resultado=Get-Content $editar_webconfig

#Cambiar el nombre_reemplazar_usuario_bd
$editar_webconfig = $ubicación_desplegado+"\"+$url_cliente+"\Web.config"
$buscar= $Web_config_nombre_buscar_usuario_bd
$reemplazar3= $Web_config_nombre_reemplazar_usuario_bd
[xml]$webConfig = Get-Content $editar_webconfig | ForEach-Object { $_ -replace "$buscar","$reemplazar3" } 
$webConfig.Save($editar_webconfig)
$resultado=Get-Content $editar_webconfig

#Cambiar el Web_config_nombre_reemplazar_contraseña_bd
#-------------------------------------------------
$editar_webconfig = $ubicación_desplegado+"\"+$url_cliente+"\Web.config"
#Eliminando el caracter especial ($)
[xml]$webConfig =(Get-Content $editar_webconfig  ) | ForEach-Object { $_  -replace '\$'  ,''  }  
$webConfig.Save($editar_webconfig)
$resultado=Get-Content $editar_webconfig
#Reemplazando el valor sin el dolar
$buscar= $Web_config_nombre_buscar_contraseña_bd 
$datosincaracterespecial= $buscar -replace '\$',''
$reemplazar4= $Web_config_nombre_reemplazar_contraseña_bd
[xml]$webConfig =(Get-Content $editar_webconfig  ) | ForEach-Object { $_  -replace "$datosincaracterespecial","$reemplazar4"  }  
$webConfig.Save($editar_webconfig)
$resultado=Get-Content $editar_webconfig

#-------------------------------------------------
#corregir archivos dañados al descomprimir
$carpeta_bin = $ubicación_desplegado+"\"+$url_cliente+"\bin"
get-childitem $carpeta_bin -filter "*.dll"| rename-item  -NewName {$_.name -replace “§§”,”ºº” } 
get-childitem $carpeta_bin -filter "*.pdb"| rename-item  -NewName {$_.name -replace “§§”,”ºº” } 
get-childitem $carpeta_bin -filter "*.config"| rename-item  -NewName {$_.name -replace “§§”,”ºº” } 
#--------------------------------------------------------------------------------------------------
#**************************************************************************************************
#--------------------------------------------------------------------------------------------------
#Iniciar el IIS
Start-Website $url_cliente #Iniciar aplicación
#--------------------------------------------------------------------------------------------------
#**************************************************************************************************
#--------------------------------------------------------------------------------------------------
#Crear el URL Rewrite Rules
# Then the script defines your IIS website - in this case, the default site.
$site = 'IIS:\Sites\' + $url_cliente
# Then the sript will create the property for our rule
Add-WebConfigurationProperty -pspath $site -filter "system.webserver/rewrite/rules" -name "." -value @{name='HTTPS Redirect'; patternSyntax='ECMAScript'; stopProcessing='True'}
# The script ill set it to match any incoming request
Set-WebConfigurationProperty -pspath $site -filter "system.webserver/rewrite/rules/rule[@name='HTTPS Redirect']/match" -name url -value "(.*)"
# And finally, add the familiar condition to only match HTTP requests (and not HTTPS).
Add-WebConfigurationProperty -pspath $site -filter "system.webserver/rewrite/rules/rule[@name='HTTPS Redirect']/conditions" -name "." -value @{input="{HTTPS}"; pattern='^OFF$'}
# The last 3 commandlets set the values for type, URL and appendQueryString-parameter for the action itself, “Rewrite”, “https://{HTTP_HOST}/{REQUEST_URI}” and “false”, respectively.
Set-WebConfigurationProperty -pspath $site -filter "system.webServer/rewrite/rules/rule[@name='HTTPS Redirect']/action" -name "type" -value "Redirect"
Set-WebConfigurationProperty -pspath $site -filter "system.webServer/rewrite/rules/rule[@name='HTTPS Redirect']/action" -name "url" -value "https://{HTTP_HOST}/{REQUEST_URI}"
Set-WebConfigurationProperty -pspath $site -filter "system.webServer/rewrite/rules/rule[@name='HTTPS Redirect']/action" -name "appendQueryString" -value "false"
#--------------------------------------------------------------------------------------------------
#**************************************************************************************************
#--------------------------------------------------------------------------------------------------
#Programar Bk automaticos
'$nombredebdcalidad =""' >> $script_bk
'$nombre_comercial ="'+$nombre_comercial+'"' >> $script_bk  #se tiene que jalar los valores que parametros 
'$BackupFolder ="'+$Carpeta_de_BK +'"'>> $script_bk
'$url_cliente ="'+$url_cliente +'"' >> $script_bk
'$serverName ="'+$serverName +'"'>> $script_bk

'Import-Module sqlps -DisableNameChecking 
Import-Module WebAdministration 

#Realizar copia de respaldo de las base de datos 
$DataBase_efactura = "tsolperu_siges_efactura_$($nombredebdcalidad)$($nombre_comercial)"  
$DataBase_principal = "tsolperu_siges_principal_$($nombredebdcalidad)$($nombre_comercial)" 
$DataBase_seguridad = "tsolperu_siges_seguridad_$($nombredebdcalidad)$($nombre_comercial)" 
$carpeta_bk_cliente = $BackupFolder+"\"+$url_cliente
$existecarpeta_carpeta_bk_cliente= $carpeta_bk_cliente
$fecha = Get-Date -format "yyyyMMddHHmm"
if (test-path $existecarpeta_carpeta_bk_cliente) 
{
#Remove-Item $carpeta_bk_cliente -Recurse #EXISTE LA CARPETA
}
$carpeta_bk_cliente = $BackupFolder+"\"+$url_cliente #NO EXISTE LA CARPETA
New-Item $carpeta_bk_cliente –ItemType directory -Force
$FilePath_efactura ="$($carpeta_bk_cliente)$("\")$($DataBase_efactura).bak"
$FilePath_principal ="$($carpeta_bk_cliente)$("\")$($DataBase_principal).bak"
$FilePath_seguridad ="$($carpeta_bk_cliente)$("\")$($DataBase_seguridad).bak"
$DestinationPath_efactura="$($carpeta_bk_cliente)$("\")$($DataBase_efactura)$($fecha).zip"
$DestinationPath_principal="$($carpeta_bk_cliente)$("\")$($DataBase_principal)$($fecha).zip"
$DestinationPath_seguridad="$($carpeta_bk_cliente)$("\")$($DataBase_seguridad)$($fecha).zip"
Backup-SqlDatabase -ServerInstance $serverName -Database $DataBase_efactura -BackupFile $FilePath_efactura ##Generar nuevos BK
Compress-Archive -Path $FilePath_efactura -CompressionLevel Optimal -DestinationPath $DestinationPath_efactura
Remove-Item $FilePath_efactura
Backup-SqlDatabase -ServerInstance $serverName -Database $DataBase_principal -BackupFile $FilePath_principal
Compress-Archive -Path $FilePath_principal -CompressionLevel Optimal -DestinationPath $DestinationPath_principal
Remove-Item $FilePath_principal
Backup-SqlDatabase -ServerInstance $serverName -Database $DataBase_seguridad -BackupFile $FilePath_seguridad
Compress-Archive -Path $FilePath_seguridad -CompressionLevel Optimal -DestinationPath $DestinationPath_seguridad
Remove-Item $FilePath_seguridad' >> $script_bk
#--------------------------------------------------------------------------------------------------
#**************************************************************************************************
#$Trigger= New-ScheduledTaskTrigger -At '10:00 AM' -Daily
$Trigger= New-ScheduledTaskTrigger -At $Horario_bk -Daily
$User= (Get-WMIObject -ClassName Win32_ComputerSystem).Username
$Action= New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "$($Ubicacion_script_bk)$("\")$nombre_comercial.ps1"
Register-ScheduledTask -TaskName "Backup-$nombre_comercial" -Trigger $Trigger -User $User -Action $Action -RunLevel Highest –Force
#--------------------------------------------------------------------------------------------------
#**************************************************************************************************
#--------------------------------------------------------------------------------------------------
#Registrar el ambiente creado
Write-Output "Ambiente creado: $url_cliente" >> $ubicaciondelog
}
