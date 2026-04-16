@echo off
SETLOCAL EnableDelayedExpansion

:: Vérification de la présence du paramètre sans l'afficher
if "%~1"=="" exit /b

:: --- Configuration ---
set "URL_ZIP=https://github.com/RJZInfoneo/Printer_Setup/raw/main/Hpnew.zip"
set "FOLDER_ROOT=C:\Admin\Imprimantes\Drivers\HP\new_drivers"
set "ZIP_FILE=%FOLDER_ROOT%\drivers.zip"
set "Pilote=%FOLDER_ROOT%\HPOneDriver.4081_V3_x64.inf"

set "NomLocal=REFFYE COULEUR"
set "Imprimante=HP Smart Universal Printing"

:: 1. Nettoyage et création
if exist "%FOLDER_ROOT%" rd /s /q "%FOLDER_ROOT%"
mkdir "%FOLDER_ROOT%" >nul 2>&1

:: 2. Téléchargement
echo [+] Preparation des composants...
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%URL_ZIP%' -OutFile '%ZIP_FILE%' -UseBasicParsing"

:: 3. Extraction
if exist "%ZIP_FILE%" (
    powershell -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%FOLDER_ROOT%' -Force"
    del /q "%ZIP_FILE%"
) else (
    exit /b
)

:: 4. Configuration du port (Utilisation du paramètre masqué)
echo [+] Configuration du point d'acces...
powershell -Command "$p='%~1'; if (!(Get-PrinterPort -Name \"IP_$p\" -ErrorAction SilentlyContinue)) { Add-PrinterPort -Name \"IP_$p\" -PrinterHostAddress $p }" >nul 2>&1

:: 5. Injection du pilote
echo [+] Initialisation du pilote...
pnputil /add-driver "%Pilote%" /install >nul 2>&1

:: 6. Installation de l'imprimante
echo [+] Finalisation de l'installation...
if exist "%Pilote%" (
    powershell -Command "$p='%~1'; if (!(Get-Printer -Name '%NomLocal%' -ErrorAction SilentlyContinue)) { Add-Printer -Name '%NomLocal%' -DriverName '%Imprimante%' -PortName \"IP_$p\" }" >nul 2>&1
    
    :: Définition par défaut
    powershell -Command "Set-Printer -Name '%NomLocal%' -IsDefault $true" >nul 2>&1
    
    echo [OK] Termine.
)

exit /b