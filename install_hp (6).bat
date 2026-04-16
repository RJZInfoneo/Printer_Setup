@echo off
SETLOCAL EnableDelayedExpansion

:: Récupération de l'IP passée en paramètre
set "AdresseIP=%~1"

:: Vérification si l'IP est présente, sinon le script s'arrête
if "%AdresseIP%"=="" (
    exit
)

:: --- Configuration ---
set "FILE_ID=1g53AWO32taUflEjKPqsd5i7FHxUj8GBN"
set "URL_ZIP=https://drive.google.com/uc?export=download&id=%FILE_ID%"
set "FOLDER_ROOT=C:\Admin\Imprimantes\Drivers\HP\new_drivers"
set "ZIP_FILE=%FOLDER_ROOT%\drivers.zip"
set "Pilote=%FOLDER_ROOT%\Driver HP new\HPOneDriver.4081_V3_x64.inf"

set "NomLocal=REFFYE COULEUR"
set "Imprimante=HP Smart Universal Printing"

:: 1. Nettoyage et création
if exist "%FOLDER_ROOT%" rd /s /q "%FOLDER_ROOT%"
mkdir "%FOLDER_ROOT%"

:: 2. Téléchargement (Silencieux)
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $ua = 'Mozilla/5.0'; Invoke-WebRequest -Uri '%URL_ZIP%' -OutFile '%ZIP_FILE%' -UserAgent $ua -UseBasicParsing"

:: 3. Extraction (Silencieux)
if exist "%ZIP_FILE%" (
    powershell -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%FOLDER_ROOT%' -Force"
    del /q "%ZIP_FILE%"
)

:: 4. Installation du Port (Silencieux)
cscript //Nologo %windir%\System32\Printing_Admin_Scripts\fr-FR\prnport.vbs -a -r IP_%AdresseIP% -h %AdresseIP% -o raw -n 9100 >nul 2>&1

:: 5. Installation de l'Imprimante (Silencieux)
if exist "%Pilote%" (
    rundll32 printui.dll,PrintUIEntry /if /f "%Pilote%" /b "%NomLocal%" /r IP_%AdresseIP% /m "%Imprimante%" /q
    rundll32 printui.dll,PrintUIEntry /y /n "%NomLocal%"
)

exit