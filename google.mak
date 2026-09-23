#=============================================================
# google.mak - Compila Ecosistema Google para AdaptaPro ERP
# Compatible: xHarbour 0.82 / Harbour 3.2 + BCC55 + FiveWin 2.4
# Cuenta: micuenta@gmail.com
#=============================================================

HBDIR=c:\xharbour
XHBDIR=c:\xharbour
BCDIR=c:\bcc55
FWDIR=c:\fw24
GOOGLEDIR=c:\googledrive

.path.OBJ = $(GOOGLEDIR)\obj
.path.PRG = $(GOOGLEDIR)
.path.CH  = $(FWDIR)\include;$(HBDIR)\include;$(XHBDIR)\include;$(GOOGLEDIR)
.path.C   = $(GOOGLEDIR)

#-------------------------------------------------------------
# Modulos principales del ecosistema Google
#-------------------------------------------------------------
PRG = \
  $(GOOGLEDIR)\TGOOGLE.PRG          \
  $(GOOGLEDIR)\TGOOGLEHTTP.PRG      \
  $(GOOGLEDIR)\TGOOGLEJSON.PRG      \
  $(GOOGLEDIR)\TGOOGLEAUTH.PRG      \
  $(GOOGLEDIR)\TGOOGLEEVENT.PRG     \
  $(GOOGLEDIR)\TGOOGLECALENDAR.PRG  \
  $(GOOGLEDIR)\TGOOGLEDRIVE.PRG     \
  $(GOOGLEDIR)\TGOOGLETASKS.PRG     \
  $(GOOGLEDIR)\TGOOGLEGMAIL.PRG     \
  $(GOOGLEDIR)\TGOOGLEGEMINI.PRG    \
  $(GOOGLEDIR)\TGOOGLESHEETS.PRG    \
  $(GOOGLEDIR)\DRIVECHECK.PRG       \
  $(GOOGLEDIR)\GEMINI_CHATBOT.PRG   \
  $(GOOGLEDIR)\ej08_gemini_chatbot.prg

C = \
  $(GOOGLEDIR)\hb_compat.c

#-------------------------------------------------------------
# Objetos del linker (solo modulos Google)
#-------------------------------------------------------------
GOOGLE_OBJ = \
  $(GOOGLEDIR)\obj\TGOOGLE.OBJ          \
  $(GOOGLEDIR)\obj\TGOOGLEHTTP.OBJ      \
  $(GOOGLEDIR)\obj\TGOOGLEJSON.OBJ      \
  $(GOOGLEDIR)\obj\TGOOGLEAUTH.OBJ      \
  $(GOOGLEDIR)\obj\TGOOGLEEVENT.OBJ     \
  $(GOOGLEDIR)\obj\TGOOGLECALENDAR.OBJ  \
  $(GOOGLEDIR)\obj\TGOOGLEDRIVE.OBJ     \
  $(GOOGLEDIR)\obj\TGOOGLETASKS.OBJ     \
  $(GOOGLEDIR)\obj\TGOOGLEGMAIL.OBJ     \
  $(GOOGLEDIR)\obj\TGOOGLEGEMINI.OBJ    \
  $(GOOGLEDIR)\obj\TGOOGLESHEETS.OBJ    \
  $(GOOGLEDIR)\obj\DRIVECHECK.OBJ       \
  $(GOOGLEDIR)\obj\GEMINI_CHATBOT.OBJ   \
  $(GOOGLEDIR)\obj\ej08_gemini_chatbot.OBJ \
  $(GOOGLEDIR)\obj\hb_compat.OBJ

#-------------------------------------------------------------
# Target principal: compila todos los .PRG a .OBJ
#-------------------------------------------------------------
all: $(GOOGLE_OBJ)
	@echo.
	@echo ==========================================
	@echo  Ecosistema Google compilado correctamente
	@echo  Objetos en: $(GOOGLEDIR)\obj\
	@echo ==========================================

#-------------------------------------------------------------
# Regla de compilacion C -> OBJ
#-------------------------------------------------------------
.C.OBJ:
	@echo Compilando C: $<
	$(BCDIR)\bin\bcc32 -c -tWM -I$(XHBDIR)\include -I$(FWDIR)\include -I$(GOOGLEDIR) -o$(GOOGLEDIR)\obj\$& $<

#-------------------------------------------------------------
# Regla de compilacion PRG -> OBJ
# Usa Harbour 3.2 (recomendado)
#-------------------------------------------------------------
.PRG.OBJ:
	@echo Compilando $<
	$(HBDIR)\bin\harbour $< /N /W /O$(GOOGLEDIR)\obj\ /I$(FWDIR)\include;$(HBDIR)\include;$(XHBDIR)\include;$(GOOGLEDIR)
	$(BCDIR)\bin\bcc32 -c -tWM -I$(HBDIR)\include -I$(FWDIR)\include -I$(XHBDIR)\include -I$(GOOGLEDIR) -o$(GOOGLEDIR)\obj\$& $(GOOGLEDIR)\obj\$&.c
	@del $(GOOGLEDIR)\obj\$&.c 2>nul

#-------------------------------------------------------------
# Regla alternativa: compila con xHarbour 0.82
# Descomentar si se necesita xHarbour en vez de Harbour
#-------------------------------------------------------------
#.PRG.OBJ:
#	@echo Compilando $< (xHarbour)
#	$(XHBDIR)\bin\harbour $< /N /W /O$(GOOGLEDIR)\obj\ /I$(FWDIR)\include;$(XHBDIR)\include;$(GOOGLEDIR)
#	$(BCDIR)\bin\bcc32 -c -tWM -I$(XHBDIR)\include -I$(FWDIR)\include -I$(GOOGLEDIR) -o$(GOOGLEDIR)\obj\$& $(GOOGLEDIR)\obj\$&.c
#	@del $(GOOGLEDIR)\obj\$&.c 2>nul

#-------------------------------------------------------------
# Compilar un solo archivo
#-------------------------------------------------------------
single:
	@echo Compilando TGOOGLE.PRG...
	$(HBDIR)\bin\harbour $(GOOGLEDIR)\TGOOGLE.PRG /N /W /O$(GOOGLEDIR)\obj\ /I$(FWDIR)\include;$(HBDIR)\include;$(XHBDIR)\include;$(GOOGLEDIR)
	$(BCDIR)\bin\bcc32 -c -tWM -I$(HBDIR)\include -I$(FWDIR)\include -I$(XHBDIR)\include -I$(GOOGLEDIR) -o$(GOOGLEDIR)\obj\TGOOGLE $(GOOGLEDIR)\obj\TGOOGLE.c
	@del $(GOOGLEDIR)\obj\TGOOGLE.c 2>nul
	@echo OK

#-------------------------------------------------------------
# Compilar todo el ecosistema Google + ejemplos
#-------------------------------------------------------------
full: all
	@echo.
	@echo Compilando ejemplos...
	$(HBDIR)\bin\harbour $(GOOGLEDIR)\ej01_google_init.prg /N /W /O$(GOOGLEDIR)\obj\ /I$(FWDIR)\include;$(HBDIR)\include;$(XHBDIR)\include;$(GOOGLEDIR)
	$(BCDIR)\bin\bcc32 -c -tWM -I$(HBDIR)\include -I$(FWDIR)\include -I$(XHBDIR)\include -I$(GOOGLEDIR) -o$(GOOGLEDIR)\obj\ej01_google_init $(GOOGLEDIR)\obj\ej01_google_init.c
	@del $(GOOGLEDIR)\obj\ej01_google_init.c 2>nul

	$(HBDIR)\bin\harbour $(GOOGLEDIR)\ej02_calendar.prg /N /W /O$(GOOGLEDIR)\obj\ /I$(FWDIR)\include;$(HBDIR)\include;$(XHBDIR)\include;$(GOOGLEDIR)
	$(BCDIR)\bin\bcc32 -c -tWM -I$(HBDIR)\include -I$(FWDIR)\include -I$(XHBDIR)\include -I$(GOOGLEDIR) -o$(GOOGLEDIR)\obj\ej02_calendar $(GOOGLEDIR)\obj\ej02_calendar.c
	@del $(GOOGLEDIR)\obj\ej02_calendar.c 2>nul

	$(HBDIR)\bin\harbour $(GOOGLEDIR)\ej03_drive.prg /N /W /O$(GOOGLEDIR)\obj\ /I$(FWDIR)\include;$(HBDIR)\include;$(XHBDIR)\include;$(GOOGLEDIR)
	$(BCDIR)\bin\bcc32 -c -tWM -I$(HBDIR)\include -I$(FWDIR)\include -I$(XHBDIR)\include -I$(GOOGLEDIR) -o$(GOOGLEDIR)\obj\ej03_drive $(GOOGLEDIR)\obj\ej03_drive.c
	@del $(GOOGLEDIR)\obj\ej03_drive.c 2>nul

	$(HBDIR)\bin\harbour $(GOOGLEDIR)\ej04_tasks.prg /N /W /O$(GOOGLEDIR)\obj\ /I$(FWDIR)\include;$(HBDIR)\include;$(XHBDIR)\include;$(GOOGLEDIR)
	$(BCDIR)\bin\bcc32 -c -tWM -I$(HBDIR)\include -I$(FWDIR)\include -I$(XHBDIR)\include -I$(GOOGLEDIR) -o$(GOOGLEDIR)\obj\ej04_tasks $(GOOGLEDIR)\obj\ej04_tasks.c
	@del $(GOOGLEDIR)\obj\ej04_tasks.c 2>nul

	$(HBDIR)\bin\harbour $(GOOGLEDIR)\ej05_gmail.prg /N /W /O$(GOOGLEDIR)\obj\ /I$(FWDIR)\include;$(HBDIR)\include;$(XHBDIR)\include;$(GOOGLEDIR)
	$(BCDIR)\bin\bcc32 -c -tWM -I$(HBDIR)\include -I$(FWDIR)\include -I$(XHBDIR)\include -I$(GOOGLEDIR) -o$(GOOGLEDIR)\obj\ej05_gmail $(GOOGLEDIR)\obj\ej05_gmail.c
	@del $(GOOGLEDIR)\obj\ej05_gmail.c 2>nul

	$(HBDIR)\bin\harbour $(GOOGLEDIR)\ej06_gemini.prg /N /W /O$(GOOGLEDIR)\obj\ /I$(FWDIR)\include;$(HBDIR)\include;$(XHBDIR)\include;$(GOOGLEDIR)
	$(BCDIR)\bin\bcc32 -c -tWM -I$(HBDIR)\include -I$(FWDIR)\include -I$(XHBDIR)\include -I$(GOOGLEDIR) -o$(GOOGLEDIR)\obj\ej06_gemini $(GOOGLEDIR)\obj\ej06_gemini.c
	@del $(GOOGLEDIR)\obj\ej06_gemini.c 2>nul

	$(HBDIR)\bin\harbour $(GOOGLEDIR)\ej07_sheets.prg /N /W /O$(GOOGLEDIR)\obj\ /I$(FWDIR)\include;$(HBDIR)\include;$(XHBDIR)\include;$(GOOGLEDIR)
	$(BCDIR)\bin\bcc32 -c -tWM -I$(HBDIR)\include -I$(FWDIR)\include -I$(XHBDIR)\include -I$(GOOGLEDIR) -o$(GOOGLEDIR)\obj\ej07_sheets $(GOOGLEDIR)\obj\ej07_sheets.c
	@del $(GOOGLEDIR)\obj\ej07_sheets.c 2>nul

	$(HBDIR)\bin\harbour $(GOOGLEDIR)\ej08_gemini_chatbot.prg /N /W /O$(GOOGLEDIR)\obj\ /I$(FWDIR)\include;$(HBDIR)\include;$(XHBDIR)\include;$(GOOGLEDIR)
	$(BCDIR)\bin\bcc32 -c -tWM -I$(HBDIR)\include -I$(FWDIR)\include -I$(XHBDIR)\include -I$(GOOGLEDIR) -o$(GOOGLEDIR)\obj\ej08_gemini_chatbot $(GOOGLEDIR)\obj\ej08_gemini_chatbot.c
	@del $(GOOGLEDIR)\obj\ej08_gemini_chatbot.c 2>nul

	@echo.
	@echo ==========================================
	@echo  TODO compilado correctamente
	@echo ==========================================

#-------------------------------------------------------------
# Limpiar archivos temporales
#-------------------------------------------------------------
clean:
	@del $(GOOGLEDIR)\obj\*.OBJ 2>nul
	@del $(GOOGLEDIR)\obj\*.c 2>nul
	@echo Objetos eliminados

#-------------------------------------------------------------
# Info
#-------------------------------------------------------------
info:
	@echo.
	@echo Ecosistema Google para AdaptaPro ERP v3.0
	@echo ------------------------------------------------
	@echo Compilador: $(HBDIR)\bin\harbour.exe
	@echo C:         $(BCDIR)\bin\bcc32.exe
	@echo Framework: $(FWDIR)
	@echo Directorio: $(GOOGLEDIR)
	@echo.
	@echo Modulos:
	@echo   TGOOGLE.PRG          - Clase principal
	@echo   TGOOGLEHTTP.PRG      - HTTP client
	@echo   TGOOGLEJSON.PRG      - JSON wrapper
	@echo   TGOOGLEAUTH.PRG      - OAuth2
	@echo   TGOOGLEEVENT.PRG     - Evento Calendar
	@echo   TGOOGLECALENDAR.PRG  - Calendar API
	@echo   TGOOGLEDRIVE.PRG     - Drive API
	@echo   TGOOGLETASKS.PRG     - Tasks API
	@echo   TGOOGLEGMAIL.PRG     - Gmail API
	@echo   TGOOGLEGEMINI.PRG    - Gemini API
	@echo   TGOOGLESHEETS.PRG    - Sheets API
	@echo   DRIVECHECK.PRG       - Deteccion Google Drive
	@echo   GEMINI_CHATBOT.PRG   - Chatbot WhatsApp-like
	@echo.
	@echo Ejemplos:
	@echo   ej01_google_init.prg - Inicializacion
	@echo   ej02_calendar.prg    - Calendar
	@echo   ej03_drive.prg       - Drive
	@echo   ej04_tasks.prg       - Tasks
	@echo   ej05_gmail.prg       - Gmail
	@echo   ej06_gemini.prg      - Gemini
	@echo   ej07_sheets.prg      - Sheets
	@echo   ej08_gemini_chatbot - Chatbot juridico
