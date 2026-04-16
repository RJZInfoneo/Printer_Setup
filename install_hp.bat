@echo off
SETLOCAL EnableDelayedExpansion

:: Création du fichier de log
set "LOG_FILE=C:\Admin\log_installation.txt"
echo --- Debut installation %date% %time% --- > "%LOG_FILE%"

if "%~1"=="" (
    echo [!] ERREUR : Pas d'IP fournie >> "%LOG_FILE%"
    exit /b
)

:: --- Configuration ---
set "URL_ZIP=https://github.com/RJZInfoneo/Printer_Setup/raw/main/Hpnew.zip"
set "FOLDER_ROOT=C:\Admin\Imprimantes\Drivers\HP\new_drivers"
set "ZIP_FILE=%FOLDER_ROOT%\drivers.zip"
set "Pilote=%FOLDER_ROOT%\HPOneDriver.4081_V3_x64.inf"
set "NomLocal=REFFYE COULEUR"
set "Imprimante=HP Smart Universal Printing"

echo [+] Etape 1 : Nettoyage dossier...
echo [+] Nettoyage dossier >> "%LOG_FILE%"
if exist "%FOLDER_ROOT%" rd /s /q "%FOLDER_ROOT%"
mkdir "%FOLDER_ROOT%"

echo [+] Etape 2 : Telechargement du ZIP...
echo [+] Telechargement ZIP >> "%LOG_FILE%"
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%URL_ZIP%' -OutFile '%ZIP_FILE%' -UseBasicParsing" >> "%LOG_FILE%" 2>&1

echo [+] Etape 3 : Extraction...
echo [+] Extraction ZIP >> "%LOG_FILE%"
if exist "%ZIP_FILE%" (
    powershell -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%FOLDER_ROOT%' -Force" >> "%LOG_FILE%" 2>&1
    del /q "%ZIP_FILE%"
) else (
    echo [!] Erreur Telechargement >> "%LOG_FILE%"
    exit /b
)

echo [+] Etape 4 : Configuration du port...
echo [+] Configuration Port >> "%LOG_FILE%"
powershell -Command "$p='%~1'; if (!(Get-PrinterPort -Name \"IP_$p\" -ErrorAction SilentlyContinue)) { Add-PrinterPort -Name \"IP_$p\" -PrinterHostAddress $p }" >> "%LOG_FILE%" 2>&1

echo [+] Etape 5 : Injection du pilote (Cette etape peut etre longue)...
echo [+] Injection Pilote via Pnputil >> "%LOG_FILE%"
pnputil /add-driver "%Pilote%" /install >> "%LOG_FILE%" 2>&1

echo [+] Etape 6 : Creation de l'imprimante...
echo [+] Creation Imprimante >> "%LOG_FILE%"
if exist "%Pilote%" (
    powershell -Command "$p='%~1'; if (!(Get-Printer -Name '%NomLocal%' -ErrorAction SilentlyContinue)) { Add-Printer -Name '%NomLocal%' -DriverName '%Imprimante%' -PortName \"IP_$p\" }" >> "%LOG_FILE%" 2>&1
    
    echo [+] Mise par defaut...
    powershell -Command "Set-Printer -Name '%NomLocal%' -IsDefault $true" >> "%LOG_FILE%" 2>&1
    
    echo [OK] Installation Terminee.
    echo --- Fin installation SUCCES --- >> "%LOG_FILE%"
) else (
    echo [!] Pilote INF introuvable >> "%LOG_FILE%"
)

exit /b