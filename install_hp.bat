@echo off
SETLOCAL EnableDelayedExpansion

:: Récupération de l'IP passée en paramètre
set "AdresseIP=%~1"

:: Vérification si l'IP est présente, sinon le script s'arrête
if "%AdresseIP%"=="" (
    echo Erreur : IP manquante.
    exit /b
)

:: --- Configuration ---
:: Utilisation du lien RAW de GitHub pour le ZIP
set "URL_ZIP=https://github.com/RJZInfoneo/Printer_Setup/raw/main/Hpnew.zip"
set "FOLDER_ROOT=C:\Admin\Imprimantes\Drivers\HP\new_drivers"
set "ZIP_FILE=%FOLDER_ROOT%\drivers.zip"
:: Vérifie bien que le chemin interne après extraction est correct
set "Pilote=%FOLDER_ROOT%\Driver HP new\HPOneDriver.4081_V3_x64.inf"

set "NomLocal=REFFYE COULEUR"
set "Imprimante=HP Smart Universal Printing"

:: 1. Nettoyage et création
if exist "%FOLDER_ROOT%" rd /s /q "%FOLDER_ROOT%"
mkdir "%FOLDER_ROOT%"

:: 2. Téléchargement depuis GitHub
echo Telechargement des drivers...
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%URL_ZIP%' -OutFile '%ZIP_FILE%' -UseBasicParsing"

:: 3. Extraction
if exist "%ZIP_FILE%" (
    echo Extraction des fichiers...
    powershell -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%FOLDER_ROOT%' -Force"
    del /q "%ZIP_FILE%"
) else (
    echo Erreur : Le fichier ZIP n'a pas pu etre telecharge.
    exit /b
)

:: 4. Installation du Port
echo Configuration du port IP_%AdresseIP%...
cscript //Nologo %windir%\System32\Printing_Admin_Scripts\fr-FR\prnport.vbs -a -r IP_%AdresseIP% -h %AdresseIP% -o raw -n 9100 >nul 2>&1

:: 5. Installation de l'Imprimante
echo Installation du pilote d'impression...
if exist "%Pilote%" (
    rundll32 printui.dll,PrintUIEntry /if /f "%Pilote%" /b "%NomLocal%" /r IP_%AdresseIP% /m "%Imprimante%" /q
    rundll32 printui.dll,PrintUIEntry /y /n "%NomLocal%"
    echo Installation terminee avec succes.
) else (
    echo Erreur : Fichier .inf introuvable dans %Pilote%
)

exit