@echo off
setlocal

set "SCRIPT_DIR=C:\Users\rka\OneDrive - PEOPLEGROUP AS\repos\hent-valutakurs-fra-nb"

echo Valutakurs-oppslag (Nationalbanken)
echo La feltene staa tomme for aa avslutte.
echo.

:loop
set "rdate="
set "currency="
set /p "rdate=Dato (YYYY-MM-DD eller YYYYMMDD): "
if "%rdate%"=="" goto end
set /p "currency=Valuta (f.eks. EUR): "
if "%currency%"=="" goto end

echo.
python "%SCRIPT_DIR%\fetch_fx.py" %rdate% %currency%
echo.
goto loop

:end
endlocal
