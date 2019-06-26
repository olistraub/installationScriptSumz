Write-Host "Dies ist der business horizon installer. Bitte das Skript als Administrator ausführen" -ForegroundColor Green

$input = ""
while($input -ne "q"){

    Write-Host "Verfügbare Aktionen:"
    Write-Host "Java-Backend installieren [1]"
    Write-Host "Python-Backend installieren [2]"
    Write-Host "Frontend installieren [3]"

    $input = Read-Host "Zum Ausführen einer Aktionen die entsprechende Zahl eingeben. Zum Verlassen [q] eingeben"

    if($input -eq "1"){
    
        installJavaBackend

    } elseif ($input -eq "2"){
    
        installPythonBackend
    
    }elseif ($input -eq "3"){
    
        installFrontend
    }

}

function installJavaBackend(){

    Write-Host "zu Installtion wird ein MSSQL-Server sowie ein SMTP-Server benötigt, die Verbindungsinformationen müssen eingegeben werden"

    $wantInstall = Read-Host "Möchten Sie mit der Installation des Java-Backends fortfahren? [y/n]"

    while($wantInstall -ne "y")
    {
        if ($wantInstall -eq 'n') {exit}
        $wantInstall = Read-Host "Möchten Sie mit der Installation fortfahren? [y/n]"
    }

    $dbURL = Read-Host "Bitte geben Sie die Adresse des MSSQL-Servers ein: (Drücken Sie Enter um den Standardwert [SUMZ1718] zu akzeptieren)"
    if($dbURL -eq ""){$dbURL = "SUMZ1718"}

    $dbPort = Read-Host "Bitte geben Sie den Port des MSSQL-Servers ein: (Drücken Sie Enter um den Standardwert [1433] zu akzeptieren)"
    if($dbPort -eq ""){$dbPort = "1433"}

    $dbName = Read-Host "Bitte geben Sie den Datenbanknamen des MSSQL-Servers ein: (Drücken Sie Enter um den Standardwert [sumzdb] zu akzeptieren)"
    if($dbName -eq ""){$dbName = "sumzdb"}

    $dbUsername = Read-Host "Bitte geben Sie den Benutzernamen des MSSQL-Servers ein: (Drücken Sie Enter um den Standardwert [sa] zu akzeptieren)"
    if($dbUsername -eq ""){$dbUsername = "sa"}

    $dbPassword = Read-Host "Bitte geben Sie das Password des MSSQL-Servers ein: (Drücken Sie Enter um den Standardwert [sumz1718] zu akzeptieren)"
    if($dbPassword -eq ""){$dbPassword = "sumz1718"}


    $smtpUrl = Read-Host "Bitte geben Sie die Adresse des SMTP-Servers ein: (Drücken Sie Enter um den Standardwert [smtp.dh-karlsruhe.de] zu akzeptieren)"
    if($smtpUrl -eq ""){$smtpUrl = "smtp.dh-karlsruhe.de"}

    $smtpPort = Read-Host "Bitte geben Sie den Port des SMTP-Servers ein: (Drücken Sie Enter um den Standardwert [25] zu akzeptieren)"
    if($smtpPort -eq ""){$smtpPort = "25"}

    $smtpUsername = Read-Host "Bitte geben Sie den Benutzername des SMTP-Servers ein: (Drücken Sie Enter um den Standardwert [noreplyBUSINESSHORIZON@dh-karlsruhe.de] zu akzeptieren)"
    if($smtpUsername -eq ""){$smtpUsername = "noreplyBUSINESSHORIZON@dh-karlsruhe.de"}

    $smtpPassword = Read-Host "Bitte geben Sie Password des SMTP-Servers ein: (Drücken Sie Enter um den Standardwert [] zu akzeptieren)"
    if($smtpPassword -eq ""){$smtpPassword = ""}

    $pythonURL = "--sumz.client.host='sumz1718.dh-karlsruhe.de'"

    $dbConn = "jdbc:sqlserver://$($dbURL):$($dbPort);instanceName=SQLEXPRESS;databaseName=$($dbName);integratedSecurity=false;user=$($dbUsername);password=$($dbPassword);"

    $jarPath = "./businesshorizon2-0.0.1-SNAPSHOT.jar"
    $datasource = "--spring.datasource.url='$($dbConn)'"
    $dbStrategy = "--spring.jpa.hibernate.ddl-auto='validate'"

    $mailHost = "--spring.mail.host='$($smtpUrl)'"
    $mailPort = "--spring.mail.port='$($smtpPort)'"
    $mailUser = "--spring.mail.username='$($smtpUsername)'"
    $mailPassword = "--spring.mail.password='$($smtpPassword)'"

    $args = "-jar `"$($jarPath) $($datasource) $($dbStrategy) $($mailHost) $($mailUser) $($mailPassword) $($pythonURL)`""

    $config = New-Object System.Xml.XmlDocument
    $config.Load("$(Get-Location)\JavaBackend\sumzBackendService.xml")

    $config.service.arguments = $args
    $config.Save("$(Get-Location)\JavaBackend\sumzBackendService.xml")

    $wantInstallJava = Read-Host "Das Java-Backend wird als Windows-Service installiert. Möchten Sie mit der Installation fortfahren? [y/n]"
    while($wantInstallJava -ne "y")
    {
        if ($wantInstallJava -eq 'n') {return}
        $wantInstallJava = Read-Host "Das Java-Backend wird als Windows-Service installiert. Möchten Sie mit der Installation fortfahren? [y/n]"
    }

    Write-Host "Java-Backend wird installiert"


    If(-Not(Test-Path $env:ProgramFiles\businesshorizon)){
    
        New-Item -ItemType Directory -Force -Path $env:ProgramFiles\businesshorizon\
    }


    Copy-Item -Path .\JavaBackend\* -Recurse -Destination $env:ProgramFiles\businesshorizon\ -Force

    .$env:ProgramFiles\businesshorizon\sumzBackendService.exe install

    $service = Get-Service "sumzBackendService"

    Write-Host "Java-Backend wurde erfolgreich installiert. Servicename: $($service.DisplayName)"


}


function installFrontend(){
        
    $wantInstallFrontend = Read-Host "Installation des Frontends starten? [y/n]"
    while($wantInstallFrontend -ne "y")
    {
        if ($wantInstallFrontend -eq 'n') {return}
        $wantInstallFrontend = Read-Host "Installation des Frontends starten? [y/n]"
    }

    enableIIS

    Write-Host "Erstelle Frontend"

    Import-Module WebAdministration

    Get-Website | Remove-Website

    (Get-Content .\Frontend\sumz\main*.js).Replace('http://sumz1718.dh-karlsruhe.de:8080', 'http://localhost:8080') | Set-Content .\Frontend\sumz\main*.js

    Copy-Item -Path ".\Frontend\*" -Recurse -Destination $env:HOMEDRIVE\inetpub\wwwroot -Force

    New-Website -Name "Frontend" -Port 80 -PhysicalPath $env:HOMEDRIVE\inetpub\wwwroot\sumz

    Write-Host "Das Frontend wurde erfolgreich erstellt. Verfügbar unter: http://localhost"

}


function enableIIS(){

    Write-Host "Installiere Webserver (IIS)..."

    $features = Get-WindowsOptionalFeature -Online | where FeatureName -like 'IIS-*'

    foreach($feature in $features){
      Enable-WindowsOptionalFeature -Online -FeatureName "$($feature.FeatureName)" -all
    
    }

    Write-Host "IIS installation abgeschlossen"

}


function installPythonBackend(){

    Write-Host "Für die installation wird Python benötigt. Bitte stellen Sie sicher, dass Python installiert ist und die Path Variable gesetzt ist." -ForegroundColor Red

    $wantInstallPython = Read-Host "Möchten Sie mit der Installation des Python-Backends fortfahren? [y/n]"

    while($wantInstallPython -ne "y")
    {
        if ($wantInstallPython -eq 'n') {return}
        $wantInstallPython = Read-Host "Möchten Sie mit der Installation des Python-Backends fortfahren? [y/n]"
    }

    enableIIS

    $pythonPath = [System.IO.DirectoryInfo] (Read-Host "Bitte geben Sie den Pfad zur python.exe ein")

    while($pythonPath.Name -ne "python.exe"){
    
        $pythonPath = [System.IO.DirectoryInfo] (Read-Host "Ungültige eingabe. Bitte geben Sie den Pfad zur python.exe ein")
    
    }

    Write-Host "Installiere Abhängigkeiten"

    pip install flask
    pip install numpy
    pip install statsmodels
    pip install scipy==1.2 --upgrade
    pip install pmdarima
    pip install jsonschema
    pip install jsonref
    pip isntall enum
    pip install statsmodels 

    Write-Host "Berechtige IIS User für Abhängigkeiten"
    
    $acl = Get-Acl $pythonPath.Parent.FullName
    $ar = New-Object  System.Security.AccessControl.FileSystemAccessRule("IIS_IUSRS","FullControl","ContainerInherit, ObjectInherit","None","Allow")
    $acl.SetAccessRule($ar)
    $acl |Set-Acl $pythonPath.Parent.FullName

    Write-Host "Erstelle Webseite"
  
    Copy-Item -Path .\wfastcgi.py -Destination $env:HOMEDRIVE\inetpub\wwwroot -Force

    Copy-Item -Path .\PythonBackend\* -Recurse -Destination $env:HOMEDRIVE\inetpub\wwwroot\ -Force

    New-Website -Name "Backend-Python" -Port 5000 -PhysicalPath $env:HOMEDRIVE\inetpub\wwwroot\SUMZ-2018-Backend-TSA\src

    New-WebHandler -Name "FastCgi" -PSPath "IIS:\Sites\Backend-Python" -Path "*" -Modules "FastCgiModule" -ScriptProcessor "$($pythonPath)|c:\inetpub\wwwroot\wfastcgi.py"  -ResourceType Unspecified -Verb *

    Write-Host "Webseite erstellt. Installation des Python-Backends abgeschlossen"

}