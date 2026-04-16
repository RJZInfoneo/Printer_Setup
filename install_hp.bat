@echo off
SETLOCAL EnableDelayedExpansion

:: 1. Configuration du log
set "LOG_FILE=C:\Admin\log_installation.txt"
echo --- Debut installation %date% %time% --- > "%LOG_FILE%"

:: 2. Vérification du paramètre IP (masqué)
if "%~1"=="" (
    echo [!] ERREUR : Parametre IP manquant. >> "%LOG_FILE%"
    echo [!] Erreur : Configuration reseau non specifiee.
    exit /b
)

:: --- Configuration ---
set "URL_ZIP=https://github.com/RJZInfoneo/Printer_Setup/raw/main/Hpnew.zip"
set "FOLDER_ROOT=C:\Admin\Imprimantes\Drivers\HP\new_drivers"
set "ZIP_FILE=%FOLDER_ROOT%\drivers.zip"
set "Pilote=%FOLDER_ROOT%\HPOneDriver.4081_V3_x64.inf"
set "NomLocal=REFFYE COULEUR"
set "Imprimante=HP Smart Universal Printing"

echo [+] Etape 1/6 : Verification de l'environnement...
:: On crée le dossier s'il n'existe pas, sans rien supprimer autour
if not exist "%FOLDER_ROOT%" mkdir "%FOLDER_ROOT%" >> "%LOG_FILE%" 2>&1

echo [+] Etape 2/6 : Verification des ressources locales...
:: On ne télécharge que si le fichier INF n'est pas déjà présent
if exist "%Pilote%" (
    echo [i] Pilote deja present sur le disque. Saut du telechargement. >> "%LOG_FILE%"
) else (
    echo [+] Etape 3/6 : Recuperation des composants (Nouveau)...
    powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%URL_ZIP%' -OutFile '%ZIP_FILE%' -UseBasicParsing" >> "%LOG_FILE%" 2>&1
    
    echo [+] Extraction des archives...
    powershell -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%FOLDER_ROOT%' -Force" >> "%LOG_FILE%" 2>&1
    if exist "%ZIP_FILE%" del /q "%ZIP_FILE%" >> "%LOG_FILE%" 2>&1
)

echo [+] Etape 4/6 : Configuration de la connectivite reseau...
:: Création du port IP via PowerShell (plus robuste que vbs)
powershell -Command "$p='%~1'; if (!(Get-PrinterPort -Name \"IP_$p\" -ErrorAction SilentlyContinue)) { Add-PrinterPort -Name \"IP_$p\" -PrinterHostAddress $p }" >> "%LOG_FILE%" 2>&1

echo [+] Etape 5/6 : Enregistrement du pilote systeme (Patientez)...
:: Injection du pilote dans le magasin Windows
if exist "%Pilote%" (
    pnputil /add-driver "%Pilote%" /install >> "%LOG_FILE%" 2>&1
) else (
    echo [!] ERREUR : Fichier pilote absent >> "%LOG_FILE%"
    echo [!] Erreur critique : Le pilote n'a pas pu etre localise.
    exit /b
)

echo [+] Etape 6/6 : Finalisation de l'imprimante...
:: Création de l'objet imprimante et mise par défaut
powershell -Command "$p='%~1'; if (!(Get-Printer -Name '%NomLocal%' -ErrorAction SilentlyContinue)) { Add-Printer -Name '%NomLocal%' -DriverName '%Imprimante%' -PortName \"IP_$p\" }" >> "%LOG_FILE%" 2>&1
powershell -Command "Set-Printer -Name '%NomLocal%' -IsDefault $true" >> "%LOG_FILE%" 2>&1

echo [OK] L'installation de '%NomLocal%' est terminee.
echo --- Fin installation %date% %time% SUCCES --- >> "%LOG_FILE%"

exit /b