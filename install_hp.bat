@echo off
:: Force la console en UTF-8 pour eviter les plantages d'ESET
chcp 65001 >nul
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

:: CORRECTION 1 : Ajout du (V3) obligatoire
set "Imprimante=HP Smart Universal Printing (V3)"

echo [+] Dossiers...
if not exist "%FOLDER_ROOT%" mkdir "%FOLDER_ROOT%" >nul 2>&1

echo [+] Verification...
if exist "%Pilote%" goto :SKIP_DOWNLOAD

echo [+] Telechargement...
powershell -Command "$ProgressPreference='SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%URL_ZIP%' -OutFile '%ZIP_FILE%' -UseBasicParsing" >nul 2>&1

echo [+] Extraction...
powershell -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%FOLDER_ROOT%' -Force" >nul 2>&1
if exist "%ZIP_FILE%" del /q "%ZIP_FILE%" >nul 2>&1

:SKIP_DOWNLOAD
echo [+] Port...
powershell -Command "if (-not (Get-PrinterPort -Name \"IP_%IP%\" -ErrorAction SilentlyContinue)) { Add-PrinterPort -Name \"IP_%IP%\" -PrinterHostAddress \"%IP%\" }" >nul 2>&1

echo [+] Pilote (Staging)...
if exist "%Pilote%" (
    pnputil /add-driver "%Pilote%" /install >nul 2>&1
) else (
    echo [!] ERREUR : Pilote introuvable.
    exit /b
)

:: CORRECTION 2 : Injection officielle du pilote dans le spooler Windows
echo [+] Pilote (Injection Spooler)...
powershell -Command "Add-PrinterDriver -Name '%Imprimante%' -InfPath '%Pilote%' -ErrorAction SilentlyContinue" >nul 2>&1

echo [+] Imprimante...
powershell -Command "if (-not (Get-Printer -Name '%NomLocal%' -ErrorAction SilentlyContinue)) { Add-Printer -Name '%NomLocal%' -DriverName '%Imprimante%' -PortName \"IP_%IP%\" }" >nul 2>&1

timeout /t 1 /nobreak >nul

echo [+] Mise par defaut...
rundll32 printui.dll,PrintUIEntry /y /n "%NomLocal%" /q >nul 2>&1

echo [OK] Termine.
exit /b
