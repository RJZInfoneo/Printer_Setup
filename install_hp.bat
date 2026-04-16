@echo off
SETLOCAL EnableDelayedExpansion
set "IP=%~1"
if "%IP%"=="" exit /b
set "URL_ZIP=https://github.com/RJZInfoneo/Printer_Setup/raw/main/Hpnew.zip"
set "ROOT=C:\Admin\Imprimantes\Drivers\HP\new_drivers"
set "ZIP=%ROOT%\drivers.zip"
set "INF=%ROOT%\HPOneDriver.4081_V3_x64.inf"
set "NAME=REFFYE COULEUR"
set "DRV=HP Smart Universal Printing"
if not exist "%ROOT%" mkdir "%ROOT%"
if not exist "%INF%" (
echo [+] Telechargement des pilotes...
powershell -Command "Invoke-WebRequest -Uri '%URL_ZIP%' -OutFile '%ZIP%'"
powershell -Command "Expand-Archive -Path '%ZIP%' -DestinationPath '%ROOT%' -Force"
if exist "%ZIP%" del /q "%ZIP%"
)
echo [+] Configuration du port...
powershell -Command "if(!(Get-PrinterPort -Name 'IP_%IP%' -ErrorAction SilentlyContinue)){Add-PrinterPort -Name 'IP_%IP%' -PrinterHostAddress '%IP%'}"
echo [+] Installation du pilote...
pnputil /add-driver "%INF%" /install
echo [+] Creation de l'imprimante...
powershell -Command "if(!(Get-Printer -Name '%NAME%' -ErrorAction SilentlyContinue)){Add-Printer -Name '%NAME%' -DriverName '%DRV%' -PortName 'IP_%IP%'}"
powershell -Command "Set-Printer -Name '%NAME%' -IsDefault $true"
echo [OK] Termine.
exit /b
