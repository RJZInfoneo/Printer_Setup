@echo off
SETLOCAL

:: Verification du parametre IP
set "IP=%~1"
if "%IP%"=="" (
    echo [!] ERREUR : IP manquante.
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
if not exist "%FOLDER_ROOT%" mkdir "%FOLDER_ROOT%"

echo [+] Verification...
if exist "%Pilote%" goto :SKIP_DOWNLOAD

echo [+] Telechargement...
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%URL_ZIP%' -OutFile '%ZIP_FILE%' -UseBasicParsing"

echo [+] Extraction...
powershell -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%FOLDER_ROOT%' -Force"
if exist "%ZIP_FILE%" del /q "%ZIP_FILE%"

:SKIP_DOWNLOAD
echo [+] Port...
powershell -Command "if (-not (Get-PrinterPort -Name \"IP_%IP%\" -ErrorAction SilentlyContinue)) { Add-PrinterPort -Name \"IP_%IP%\" -PrinterHostAddress \"%IP%\" }"

echo [+] Pilote...
if exist "%Pilote%" (
    pnputil /add-driver "%Pilote%" /install
) else (
    echo [!] ERREUR : Pilote introuvable.
    exit /b
)

echo [+] Imprimante...
powershell -Command "if (-not (Get-Printer -Name '%NomLocal%' -ErrorAction SilentlyContinue)) { Add-Printer -Name '%NomLocal%' -DriverName '%Imprimante%' -PortName \"IP_%IP%\" }"

echo [+] Mise par defaut...
rundll32 printui.dll,PrintUIEntry /y /n "%NomLocal%"

echo [OK] Termine.
exit /b
