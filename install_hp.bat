@echo off
SETLOCAL EnableDelayedExpansion

:: 1. Configuration du log
set "LOG_FILE=C:\Admin\log_installation.txt"
echo --- Debut %date% %time% --- > "%LOG_FILE%"

:: 2. Verification du parametre IP
if "%~1"=="" (
    echo [!] ERREUR : IP manquante. >> "%LOG_FILE%"
    exit /b
)

:: --- Configuration ---
set "URL_ZIP=https://github.com/RJZInfoneo/Printer_Setup/raw/main/Hpnew.zip"
set "FOLDER_ROOT=C:\Admin\Imprimantes\Drivers\HP\new_drivers"
set "ZIP_FILE=%FOLDER_ROOT%\drivers.zip"
set "Pilote=%FOLDER_ROOT%\HPOneDriver.4081_V3_x64.inf"
set "NomLocal=REFFYE COULEUR"
set "Imprimante=HP Smart Universal Printing"

echo [+] Dossiers...
if not exist "%FOLDER_ROOT%" mkdir "%FOLDER_ROOT%" >> "%LOG_FILE%" 2>&1

echo [+] Verification...
if exist "%Pilote%" goto :SKIP_DOWNLOAD

echo [+] Telechargement...
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%URL_ZIP%' -OutFile '%ZIP_FILE%' -UseBasicParsing" >> "%LOG_FILE%" 2>&1

echo [+] Extraction...
powershell -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%FOLDER_ROOT%' -Force" >> "%LOG_FILE%" 2>&1
if exist "%ZIP_FILE%" del /q "%ZIP_FILE%" >> "%LOG_FILE%" 2>&1

:SKIP_DOWNLOAD
echo [+] Port...
powershell -Command "$p='%~1'; if (!(Get-PrinterPort -Name \"IP_$p\" -ErrorAction SilentlyContinue)) { Add-PrinterPort -Name \"IP_$p\" -PrinterHostAddress $p }" >> "%LOG_FILE%" 2>&1

echo [+] Pilote...
if exist "%Pilote%" (
    pnputil /add-driver "%Pilote%" /install >> "%LOG_FILE%" 2>&1
) else (
    echo [!] ERREUR : Pilote introuvable. >> "%LOG_FILE%"
    exit /b
)

echo [+] Imprimante...
powershell -Command "$p='%~1'; if (!(Get-Printer -Name '%NomLocal%' -ErrorAction SilentlyContinue)) { Add-Printer -Name '%NomLocal%' -DriverName '%Imprimante%' -PortName \"IP_$p\" }" >> "%LOG_FILE%" 2>&1
powershell -Command "Set-Printer -Name '%NomLocal%' -IsDefault $true" >> "%LOG_FILE%" 2>&1

echo [OK] Termine.
echo --- Fin SUCCES --- >> "%LOG_FILE%"

exit /b
