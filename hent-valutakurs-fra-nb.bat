@echo off
setlocal

set "SCRIPT_DIR=C:\Users\rka\OneDrive - PEOPLEGROUP AS\repos\hent-valutakurs-fra-nb"
if not exist "%SCRIPT_DIR%\fetch_fx.py" set "SCRIPT_DIR=P:\Employees\Rasmus\Python\repos\hent-valutakurs-fra-nb"
if not exist "%SCRIPT_DIR%\fetch_fx.py" (
    echo Kunne ikke finde fetch_fx.py i hverken lokal sti eller P:-stien.
    pause
    goto end
)

set "PYTHON=python"
python --version >nul 2>&1
if not errorlevel 1 goto pyfound
set "PYTHON=py"
py --version >nul 2>&1
if not errorlevel 1 goto pyfound
echo Python blev ikke fundet paa denne maskine.
echo Installer Python 3 fra https://www.python.org/downloads/ og koer programmet igen.
pause
goto end
:pyfound

%PYTHON% -c "import pyodbc" >nul 2>&1
if not errorlevel 1 goto depsok
echo Nogle noedvendige Python-pakker mangler (pyodbc).
set /p "doinstall=Vil du installere dem nu? (J/N): "
if /i "%doinstall%"=="J" goto doinstall
if /i "%doinstall%"=="Y" goto doinstall
echo Kan ikke fortsaette uden de noedvendige pakker.
pause
goto end
:doinstall
echo Installerer noedvendige pakker ...
%PYTHON% -m pip install -r "%SCRIPT_DIR%\requirements.txt"
if errorlevel 1 (
    echo Installationen mislykkedes. Tjek din internetforbindelse og proev igen.
    pause
    goto end
)
:depsok

echo Valutakurs-opslag (Nationalbanken)
echo Tryk Enter for i dag / EUR. Skriv 'exit' eller 'q' for at afslutte.
echo.

:loop
set "rdate="
set "currency="
set /p "rdate=Dato (YYYY-MM-DD, Enter = i dag, 'q' = afslut): "
if /i "%rdate%"=="exit" goto end
if /i "%rdate%"=="quit" goto end
if /i "%rdate%"=="q" goto end
if "%rdate%"=="" for /f %%d in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd"') do set "rdate=%%d"

set /p "currency=Valuta f.eks. EUR, GBP, USD (Enter = EUR, 'q' = afslut): "
if /i "%currency%"=="exit" goto end
if /i "%currency%"=="quit" goto end
if /i "%currency%"=="q" goto end
if "%currency%"=="" set "currency=EUR"

echo.
echo Henter %currency% for %rdate% ...
%PYTHON% "%SCRIPT_DIR%\fetch_fx.py" %rdate% %currency%
echo.
goto loop

:end
endlocal
