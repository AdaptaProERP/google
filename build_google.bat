@ECHO OFF
REM ================================================================
REM build_google.bat - Compilación del Ecosistema Google para FW24
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
ECHO   COMPILACION ECO GOOGLE - Adaptapro ERP
ECHO   Cuenta: micuenta@gmail.com
ECHO ================================================================
ECHO.

REM ================================================================
REM FASE 1: Compilar .PRG a .C
REM ================================================================
ECHO [1/3] Compilando archivos .PRG a .C ...
ECHO.

SET HBINC=%FWDIR%\include;%HBDIR%\include;%OUTDIR%

FOR %%F IN (TGOOGLEHTTP TGOOGLEJSON TGOOGLEAUTH TGOOGLE TGOOGLEEVENT TGOOGLECALENDAR TGOOGLEDRIVE TGOOGLETASKS TGOOGLEGMAIL TGOOGLEGEMINI TGOOGLESHEETS) DO (
    ECHO   Compilando %%F.PRG ...
    %HBDIR%\bin\harbour %%F.PRG /n /i%HBINC% /w > %OUTDIR%\%%F.log 2>&1
    IF ERRORLEVEL 1 (
        ECHO   [ERROR] %%F.PRG fallo la compilacion
        TYPE %OUTDIR%\%%F.log
        PAUSE
        GOTO :ERROR
    )
    ECHO   [OK] %%F.PRG
)

ECHO.
ECHO [OK] Todos los .PRG compilados a .C
ECHO.

REM ================================================================
REM FASE 2: Compilar .C a .OBJ con BCC32
REM ================================================================
ECHO [2/3] Compilando archivos .C a .OBJ ...
ECHO.

FOR %%F IN (TGOOGLEHTTP TGOOGLEJSON TGOOGLEAUTH TGOOGLE TGOOGLEEVENT TGOOGLECALENDAR TGOOGLEDRIVE TGOOGLETASKS TGOOGLEGMAIL TGOOGLEGEMINI TGOOGLESHEETS) DO (
    ECHO   Compilando %%F.c ...
    %BCDIR%\bin\bcc32 -M -c -O2 -I%HBDIR%\include -I%FWDIR%\include -I%OUTDIR% %%F.c > %OUTDIR%\%%F_bcc.log 2>&1
    IF ERRORLEVEL 1 (
        ECHO   [ERROR] %%F.c fallo la compilacion C
        TYPE %OUTDIR%\%%F_bcc.log
        PAUSE
        GOTO :ERROR
    )
    ECHO   [OK] %%F.obj
)

ECHO.
ECHO [OK] Todos los .OBJ generados
ECHO.

REM ================================================================
REM FASE 3: Link final - Generar EXE de prueba
REM ================================================================
ECHO [3/3] Generando EXE de prueba (google_test.exe) ...
ECHO.

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
ECHO google_test.obj, + >> %OUTDIR%\b32.bc
ECHO google_test.exe, + >> %OUTDIR%\b32.bc
ECHO google_test.map, + >> %OUTDIR%\b32.bc
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

%BCDIR%\bin\ilink32 -Gn -aa -Tpe -s @%OUTDIR%\b32.bc > %OUTDIR%\link.log 2>&1
IF ERRORLEVEL 1 (
    ECHO [ERROR] Fallo el linker
    TYPE %OUTDIR%\link.log
    PAUSE
    GOTO :ERROR
)

ECHO.
ECHO ================================================================
ECHO   COMPILACION EXITOSA
ECHO   EXE generado: %OUTDIR%\google_test.exe
ECHO ================================================================
ECHO.

REM Limpiar archivos temporales
DEL %OUTDIR%\*.c >NUL 2>&1
DEL %OUTDIR%\*.obj >NUL 2>&1
DEL %OUTDIR%\*.il? >NUL 2>&1
DEL %OUTDIR%\*.map >NUL 2>&1
DEL %OUTDIR%\b32.bc >NUL 2>&1

ECHO Presione una tecla para ejecutar la prueba...
PAUSE >NUL
%OUTDIR%\google_test.exe
GOTO :END

:ERROR
ECHO.
ECHO [ERROR] Compilacion fallida. Revise los archivos .log
PAUSE
GOTO :END

:END
