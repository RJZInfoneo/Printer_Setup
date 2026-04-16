@echo off
SETLOCAL EnableDelayedExpansion

set "LOG_FILE=C:\Admin\log_installation.txt"
echo --- Debut installation %date% %time% --- > "%LOG_FILE%"

if "%~1" == "" (
    echo [!] ERREUR : Parametre IP manquant >> "%LOG_FILE%"
    exit /b
)

set "URL_ZIP=https://github.com/RJZInfoneo/Printer_Setup/raw/main/Hpnew.zip"
set "FOLDER_ROOT=C:\Admin\Imprimantes\Drivers\HP\new_drivers"
set "ZIP_FILE=%FOLDER_ROOT%\drivers.zip"
set "Pilote=%FOLDER_ROOT%\HPOneDriver.4081_V3_x64.inf"
set "NomLocal=REFFYE COULEUR"
set "Imprimante=HP Smart Universal Printing"

echo [+] Etape 1/6 : Preparation environnement
if not exist "%FOLDER_ROOT%" mkdir "%FOLDER_ROOT%" >> "%LOG_FILE%" 2>&1

echo [+] Etape 2/6 : Verification ressources locales
if exist "%Pilote%" (
    echo [i] Pilote deja present sur le disque >> "%LOG_FILE%"
) else (
    echo [+] Etape 3/6 : Telechargement des pilotes
    powershell -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%URL_ZIP%' -OutFile '%ZIP_FILE%' -UseBasicParsing" >> "%LOG_FILE%" 2>&1
    
    echo [+] Extraction...
    powershell -ExecutionPolicy Bypass -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%FOLDER_ROOT%' -Force" >> "%LOG_FILE%" 2>&1
    if exist "%ZIP_FILE%" del /q "%ZIP_FILE%" >> "%LOG_FILE%" 2>&1
)

echo [+] Etape 4/6 : Configuration port reseau
powershell -ExecutionPolicy Bypass -Command "$p='%~1'; if (!(Get-PrinterPort -Name \"IP_$p\" -ErrorAction SilentlyContinue)) { Add-PrinterPort -Name \"IP_$p\" -PrinterHostAddress $p }" >> "%LOG_FILE%" 2>&1

echo [+] Etape 5/6 : Installation pilote (Patientez)
if exist "%Pilote%" (
    pnputil /add-driver "%Pilote%" /install >> "%LOG_FILE%" 2>&1
) else (
    echo [!] ERREUR : Pilote absent >> "%LOG_FILE%"
    exit /b
)

echo [+] Etape 6/6 : Finalisation imprimante
powershell -ExecutionPolicy Bypass -Command "$p='%~1'; if (!(Get-Printer -Name '%NomLocal%' -ErrorAction SilentlyContinue)) { Add-Printer -Name '%NomLocal%' -DriverName '%Imprimante%' -PortName \"IP_$p\" }" >> "%LOG_FILE%" 2>&1
powershell -ExecutionPolicy Bypass -Command "Set-Printer -Name '%NomLocal%' -IsDefault $true" >> "%LOG_FILE%" 2>&1

echo [OK] Installation de '%NomLocal%' terminee.
echo --- Fin installation SUCCES --- >> "%LOG_FILE%"

exit /b
