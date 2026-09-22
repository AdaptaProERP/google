@ECHO OFF
REM ================================================================
REM build_ejemplos.bat - Compila los 7 ejemplos del Ecosistema Google
REM Adaptapro ERP - Cuenta: micuenta@gmail.com
REM
REM Requisitos:
REM   - Harbour 3.2 en C:\harbour\bin\harbour.exe
REM   - BCC55 en C:\bcc55\bin\bcc32.exe
REM   - FiveWin 2.4 en C:\fw24\lib\
REM ================================================================

SET HBDIR=c:\harbour
SET BCDIR=c:\bcc55
SET FWDIR=c:\fw24
SET OUTDIR=c:\googledrive

ECHO ================================================================
ECHO   COMPILACION DE EJEMPLOS - Ecosistema Google Adaptapro
ECHO ================================================================
ECHO.

SET HBINC=%FWDIR%\include;%HBDIR%\include;%OUTDIR%

FOR %%F IN (ej01_google_init ej02_calendar ej03_drive ej04_tasks ej05_gmail ej06_gemini ej07_sheets) DO (
    ECHO Compilando %%F.PRG ...
    %HBDIR%\bin\harbour %%F.PRG /n /i%HBINC% /w > %OUTDIR%\%%F.log 2>&1
    IF ERRORLEVEL 1 (
        ECHO   [ERROR] %%F.PRG fallo
        TYPE %OUTDIR%\%%F.log
        PAUSE
        GOTO :ERROR
    )
    ECHO   [OK] %%F.c generado

    %BCDIR%\bin\bcc32 -M -c -O2 -I%HBDIR%\include -I%FWDIR%\include -I%OUTDIR% %%F.c > %OUTDIR%\%%F_bcc.log 2>&1
    IF ERRORLEVEL 1 (
        ECHO   [ERROR] %%F.c fallo en BCC32
        TYPE %OUTDIR%\%%F_bcc.log
        PAUSE
        GOTO :ERROR
    )
    ECHO   [OK] %%F.obj generado

    REM Link individual para cada ejemplo
    DEL %OUTDIR%\b32.bc >NUL 2>&1
    ECHO c0w32.obj + > %OUTDIR%\b32.bc
    ECHO TGOOGLEHTTP.obj + >> %OUTDIR%\b32.bc
    ECHO TGOOGLEJSON.obj + >> %OUTDIR%\b32.bc
    ECHO TGOOGLEAUTH.obj + >> %OUTDIR%\b32.bc
    ECHO TGOOGLE.obj + >> %OUTDIR%\b32.bc
    ECHO TGOOGLEEVENT.obj + >> %OUTDIR%\b32.bc
    ECHO TGOOGLECALENDAR.obj + >> %OUTDIR%\b32.bc
    ECHO TGOOGLEDRIVE.obj + >> %OUTDIR%\b32.bc
    ECHO TGOOGLETASKS.obj + >> %OUTDIR%\b32.bc
    ECHO TGOOGLEGMAIL.obj + >> %OUTDIR%\b32.bc
    ECHO TGOOGLEGEMINI.obj + >> %OUTDIR%\b32.bc
    ECHO TGOOGLESHEETS.obj + >> %OUTDIR%\b32.bc
    ECHO %%F.obj, + >> %OUTDIR%\b32.bc
    ECHO %%F.exe, + >> %OUTDIR%\b32.bc
    ECHO %%F.map, + >> %OUTDIR%\b32.bc
    ECHO %FWDIR%\lib\FiveH.lib %FWDIR%\lib\FiveHC.lib + >> %OUTDIR%\b32.bc
    ECHO %HBDIR%\lib\rtl.lib + >> %OUTDIR%\b32.bc
    ECHO %HBDIR%\lib\vm.lib + >> %OUTDIR%\b32.bc
    ECHO %HBDIR%\lib\gtwin.lib + >> %OUTDIR%\b32.bc
    ECHO %HBDIR%\lib\lang.lib + >> %OUTDIR%\b32.bc
    ECHO %HBDIR%\lib\macro.lib + >> %OUTDIR%\b32.bc
    ECHO %HBDIR%\lib\rdd.lib + >> %OUTDIR%\b32.bc
    ECHO %HBDIR%\lib\dbfntx.lib + >> %OUTDIR%\b32.bc
    ECHO %HBDIR%\lib\dbfcdx.lib + >> %OUTDIR%\b32.bc
    ECHO %HBDIR%\lib\debug.lib + >> %OUTDIR%\b32.bc
    ECHO %HBDIR%\lib\common.lib + >> %OUTDIR%\b32.bc
    ECHO %BCDIR%\lib\cw32.lib + >> %OUTDIR%\b32.bc
    ECHO %BCDIR%\lib\import32.lib + >> %OUTDIR%\b32.bc
    ECHO %BCDIR%\lib\psdk\odbc32.lib, >> %OUTDIR%\b32.bc

    %BCDIR%\bin\ilink32 -Gn -aa -Tpe -s @%OUTDIR%\b32.bc > %OUTDIR%\link_%%F.log 2>&1
    IF ERRORLEVEL 1 (
        ECHO   [ERROR] %%F.exe fallo el linker
        TYPE %OUTDIR%\link_%%F.log
        PAUSE
        GOTO :ERROR
    )
    ECHO   [OK] %%F.exe generado
    ECHO.
)

ECHO ================================================================
ECHO   TODOS LOS EJEMPLOS COMPILADOS
ECHO ================================================================
ECHO.
ECHO   Ejemplos generados:
ECHO     ej01_google_init.exe  - Inicializacion del ecosistema
ECHO     ej02_calendar.exe     - Google Calendar API
ECHO     ej03_drive.exe        - Google Drive API
ECHO     ej04_tasks.exe        - Google Tasks API
ECHO     ej05_gmail.exe        - Google Gmail API
ECHO     ej06_gemini.exe       - Google Gemini API
ECHO     ej07_sheets.exe       - Google Sheets API
ECHO.
ECHO   Para ejecutar: ejXX_nombre.exe
ECHO.
ECHO   IMPORTANTE: Los ejemplos 02-07 requieren autenticacion OAuth.
ECHO   Ejecute primero ej01_google_init.exe para configurar.
ECHO.
ECHO ================================================================

REM Limpiar
DEL %OUTDIR%\*.c >NUL 2>&1
DEL %OUTDIR%\*.obj >NUL 2>&1
DEL %OUTDIR%\*.il? >NUL 2>&1
DEL %OUTDIR%\*.map >NUL 2>&1
DEL %OUTDIR%\b32.bc >NUL 2>&1

PAUSE
GOTO :END

:ERROR
ECHO.
ECHO [ERROR] Compilacion fallida. Revise los archivos .log
PAUSE

:END
