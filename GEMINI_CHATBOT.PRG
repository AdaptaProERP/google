//----------------------------------------------------------------------------//
// GEMINI_CHATBOT.PRG
// Chatbot juridico con interfaz tipo WhatsApp para AdaptaPro ERP
// Usa TGoogleGemini para consultas multi-turno
// Compatible: xHarbour + Harbour 3.2 + FiveWin 2.4
//----------------------------------------------------------------------------//

#include "FiveWin.ch"
#include "TGOOGLE.CH"

//----------------------------------------------------------------------------//
// Variables de modulo
//----------------------------------------------------------------------------//

STATIC oChatGoogle
STATIC oChatGemini
STATIC oChatBrw
STATIC oChatGet
STATIC oChatStatus
STATIC oChatInput
STATIC aChatMensajes := {}
STATIC aChatDisplay  := {}
STATIC cChatPrompt   := ""
STATIC cChatFuentes  := ""
STATIC cChatInput    := ""

#define CLR_USER_BG   RGB(0xD9,0xF4,0xDD)
#define CLR_BOT_BG    RGB(0xE8,0xE8,0xE8)
#define CLR_USER_TXT  RGB(0x1B,0x1B,0x1B)
#define CLR_BOT_TXT   RGB(0x1B,0x1B,0x1B)
#define CLR_HEADER_BG RGB(0x00,0x7B,0x5E)
#define CLR_INPUT_BG  RGB(0xF0,0xF0,0xF0)
#define CLR_SEND_BTN  RGB(0x00,0xA8,0x84)

//----------------------------------------------------------------------------//
// MAIN: Interfaz chatbot tipo WhatsApp
//----------------------------------------------------------------------------//

FUNCTION GEMINI_CHATBOT( cPrompt, cFuentes, cTitulo )

   LOCAL aCoors, nAltoWin, nAnchoWin, nRowInput, nRowBrw, nHeightBrw
   LOCAL oFont, oFontInput, oFontTime, oFontHeader, oFontBtn
   LOCAL oBtnSend, oBtnAttach, oBtnClear, oBtnConfig

   DEFAULT cPrompt  := "Eres un asistente juridico experto en derecho venezolano."
   DEFAULT cFuentes := ""
   DEFAULT cTitulo  := "Consulta Juridica IA"

   // Dimensiones
   aCoors       := GetCoors( GetDesktopWindow() )
   nAltoWin     := aCoors[3] - 100
   nAnchoWin    := aCoors[4] - 50
   nRowInput    := nAltoWin - 120
   nRowBrw      := 60
   nHeightBrw   := nRowInput - nRowBrw - 5

   // Guardar en modulo
   cChatPrompt  := cPrompt
   cChatFuentes := cFuentes
   cChatInput   := ""

   // Inicializar Google Gemini
   oChatGoogle := TGoogle():New()
   IF EMPTY( oChatGoogle:cApiKey )
      MsgStop( "No se encontro API Key de Gemini. Configure config_google.json" )
      RETURN NIL
   ENDIF

   oChatGemini := oChatGoogle:Gemini()
   oChatGemini:SetModel( oChatGoogle:cModelGemini )
   oChatGemini:SetTemperature( 0.3 )

   // Inicializar historial
   aChatMensajes := {}
   aChatDisplay  := {}

   // Contexto del sistema
   AADD( aChatMensajes, {{"role","user"},{"text", "INSTRUCCION DEL SISTEMA: " + cPrompt }} )
   AADD( aChatMensajes, {{"role","model"},{"text", "Entendido. Actuare como asistente juridico." }} )

   IF !EMPTY( cFuentes )
      AADD( aChatMensajes, {{"role","user"},{"text", "FUENTES DE VERACIDAD:" + CRLF + cFuentes }} )
      AADD( aChatMensajes, {{"role","model"},{"text", "Fuentes recibidas. Las tendre en cuenta." }} )
      AADD( aChatDisplay, { "BOT", "Fuentes de veracidad cargadas. Estoy listo.", TIME() } )
   ENDIF

   AADD( aChatDisplay, { "BOT", "Hola! Soy su asistente juridico. Escriba su consulta.", TIME() } )

   // Fuentes
   DEFINE FONT oFont       NAME "Tahoma" SIZE 0, -11
   DEFINE FONT oFontInput  NAME "Tahoma" SIZE 0, -11
   DEFINE FONT oFontTime   NAME "Tahoma" SIZE 0, -8
   DEFINE FONT oFontHeader NAME "Tahoma" SIZE 0, -14 BOLD
   DEFINE FONT oFontBtn    NAME "Tahoma" SIZE 0, -11 BOLD

   // Ventana MDI
   DpMdi( cTitulo, "oChatBot", "" )
   oChatBot:Windows( 0, 0, nAltoWin, nAnchoWin )

   // Header verde
   @ 0, 0 SAY "  " + cTitulo SIZE nAnchoWin, 55 PIXEL ;
       OF oChatBot:oWnd FONT oFontHeader ;
       COLOR CLR_WHITE, CLR_HEADER_BG

   @ 12, nAnchoWin - 180 SAY oChatStatus PROMPT "En linea" ;
       SIZE 120, 20 PIXEL ;
       OF oChatBot:oWnd FONT oFontTime ;
       COLOR RGB(0xC8,0xFF,0xC8), CLR_HEADER_BG

   // Browse de mensajes
   oChatBrw := TXBrowse():New( oChatBot:oWnd )
   oChatBrw:SetArray( aChatDisplay, .F. )
   oChatBrw:lRecordSelector := .F.
   oChatBrw:lHeader         := .F.
   oChatBrw:lFooter         := .F.
   oChatBrw:lHScroll        := .F.
   oChatBrw:nColSel         := 2

   oChatBrw:AddCol( {|| IF( aChatDisplay[ oChatBrw:nArrayAt, 1 ] == "USER", "TU", "IA" ) } )
   oChatBrw:aCol[1]:cHeader  := ""
   oChatBrw:aCol[1]:nWidth   := 30
   oChatBrw:aCol[1]:nClrText := CLR_BOT_TXT

   oChatBrw:AddCol( {|| aChatDisplay[ oChatBrw:nArrayAt, 2 ] } )
   oChatBrw:aCol[2]:cHeader  := ""
   oChatBrw:aCol[2]:nWidth   := nAnchoWin - 120
   oChatBrw:aCol[2]:nClrText := CLR_USER_TXT

   oChatBrw:AddCol( {|| aChatDisplay[ oChatBrw:nArrayAt, 3 ] } )
   oChatBrw:aCol[3]:cHeader  := ""
   oChatBrw:aCol[3]:nWidth   := 55
   oChatBrw:aCol[3]:nClrText := RGB(0x99,0x99,0x99)

   oChatBrw:SetColor( CLR_USER_TXT, CLR_INPUT_BG )
   oChatBrw:Move( nRowBrw, 5, .T. )
   oChatBrw:SetSize( nAnchoWin - 10, nHeightBrw, .T. )
   oChatBrw:CreateFromCode()

   // Separador
   @ nRowInput - 5, 0 TO nRowInput - 3, nAnchoWin PIXEL ;
       OF oChatBot:oWnd COLOR CLR_HEADER_BG, CLR_HEADER_BG

   // Input de texto
   oChatInput := TGet():New( nRowInput, 5, ;
       { |u| If( PCount()==0, cChatInput, cChatInput:=u ) }, ;
       oChatBot:oWnd, ;
       nAnchoWin - 110, 20, ;
       NIL, NIL, ;
       CLR_USER_TXT, CLR_INPUT_BG, ;
       oFontInput, .T. )

   // Botones con TButton directo
   TButton():New( nRowInput, nAnchoWin - 100, "Enviar", ;
       oChatBot:oWnd, {|| ChatbotEnviar() }, ;
       90, 20, oFontBtn, .F., .T., .F., NIL, NIL, .T. )

   // Barra inferior
   @ nAltoWin - 15, 0 TO nAltoWin, nAnchoWin PIXEL ;
       OF oChatBot:oWnd

   TButton():New( nAltoWin - 13, 5, "Adjuntar", ;
       oChatBot:oWnd, {|| ChatbotAdjuntar() }, ;
       80, 12, oFontTime, .F., .T., .F., NIL, NIL, .T. )

   TButton():New( nAltoWin - 13, 90, "Limpiar", ;
       oChatBot:oWnd, {|| ChatbotLimpiar() }, ;
       80, 12, oFontTime, .F., .T., .F., NIL, NIL, .T. )

   TButton():New( nAltoWin - 13, 175, "Config", ;
       oChatBot:oWnd, {|| ChatbotConfig() }, ;
       60, 12, oFontTime, .F., .T., .F., NIL, NIL, .T. )

   // Activar
   oChatBot:Activate( {|| ChatbotInit() } )

   // Cleanup
   oChatGoogle:End()
   oChatGoogle := NIL
   oChatGemini := NIL

RETURN NIL

//----------------------------------------------------------------------------//
// TOOLBAR INIT
//----------------------------------------------------------------------------//

STATIC FUNCTION ChatbotInit()

   LOCAL oCursor, oBar, oBtn, oFont

   DEFINE CURSOR oCursor HAND
   DEFINE BUTTONBAR oBar SIZE 42+20, 42+20 OF oChatBot:oWnd 3D CURSOR oCursor

   DEFINE FONT oFont  NAME "Tahoma"   SIZE 0, -11 BOLD

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\XSALIR.BMP";
          TOP PROMPT "Cerrar";
          ACTION oChatBot:End()

   oBar:SetColor( CLR_BLACK, oDp:nGris )

RETURN .T.

//----------------------------------------------------------------------------//
// ENVIAR MENSAJE
//----------------------------------------------------------------------------//

STATIC FUNCTION ChatbotEnviar()

   LOCAL cTexto, cRespuesta, cHora

   cTexto := AllTrim( cChatInput )

   IF EMPTY( cTexto )
      RETURN NIL
   ENDIF

   cHora := TIME()

   // Agregar mensaje del usuario
   AADD( aChatDisplay, { "USER", cTexto, cHora } )
   AADD( aChatMensajes, {{"role","user"},{"text", cTexto }} )

   // Limpiar input
   cChatInput := ""
   oChatInput:Refresh()

   // Indicar procesando
   oChatStatus:SetColor( RGB(0xFF,0xFF,0x00), CLR_HEADER_BG )
   oChatStatus:SetText( " Procesando..." )

   // Llamar a Gemini
   cRespuesta := ""
   BEGIN SEQUENCE
      cRespuesta := oChatGemini:Chat( aChatMensajes )
   RECOVER USING oError
      cRespuesta := "ERROR: " + oError:description
   END SEQUENCE

   IF EMPTY( cRespuesta )
      cRespuesta := "No se pudo obtener respuesta."
   ENDIF

   // Agregar respuesta
   AADD( aChatDisplay, { "BOT", cRespuesta, TIME() } )
   AADD( aChatMensajes, {{"role","model"},{"text", cRespuesta }} )

   // Actualizar vista
   oChatBrw:SetArray( aChatDisplay, .F. )
   oChatBrw:Refresh()
   oChatBrw:GoBottom()

   // Restaurar estado
   oChatStatus:SetColor( RGB(0xC8,0xFF,0xC8), CLR_HEADER_BG )
   oChatStatus:SetText( " En linea" )

RETURN NIL

//----------------------------------------------------------------------------//
// ADJUNTAR ARCHIVO
//----------------------------------------------------------------------------//

STATIC FUNCTION ChatbotAdjuntar()

   LOCAL cFile, cArchB64, cTipo, cExt

   cFile := cGetFile( "Todos los archivos (*.*)|*.*|" + ;
                      "Documentos (*.txt;*.doc;*.pdf)|*.txt;*.doc;*.pdf;" + ;
                      "Imagenes (*.png;*.jpg;*.bmp)|*.png;*.jpg;*.bmp", ;
                      "Seleccionar Archivo", NIL, NIL, .T. )

   IF EMPTY( cFile )
      RETURN NIL
   ENDIF

   cExt := UPPER( ALLTRIM( RIGHT( cFile, 4 ) ) )
   cTipo := "text/plain"
   IF cExt == ".PDF"  ; cTipo := "application/pdf"
   ELSEIF cExt == ".PNG"  ; cTipo := "image/png"
   ELSEIF cExt == ".JPG"  ; cTipo := "image/jpeg"
   ELSEIF cExt == ".BMP"  ; cTipo := "image/bmp"
   ENDIF

   cArchB64 := ""
   BEGIN SEQUENCE
      cArchB64 := B64ENCODE( MEMOREAD( cFile ) )
   RECOVER
      MsgStop( "Error al leer el archivo: " + cFile )
      RETURN NIL
   END SEQUENCE

   AADD( aChatDisplay, { "USER", ;
       "[ARCHIVO: " + JUSTFILENAME( cFile ) + "] " + cTipo, ;
       TIME() } )

   AADD( aChatMensajes, {{"role","user"},{"text", ;
       "Archivo adjunto '" + JUSTFILENAME( cFile ) + "' tipo " + cTipo + ;
       ". Contenido Base64: " + LEFT( cArchB64, 500 ) + ;
       IF( LEN( cArchB64 ) > 500, "...", "" ) }} )

   oChatBrw:SetArray( aChatDisplay, .F. )
   oChatBrw:Refresh()
   oChatBrw:GoBottom()

RETURN NIL

//----------------------------------------------------------------------------//
// LIMPIAR CHAT
//----------------------------------------------------------------------------//

STATIC FUNCTION ChatbotLimpiar()

   IF MsgYesNo( "Limpiar todo el historial?" )
      aChatMensajes := {}
      aChatDisplay  := {}

      AADD( aChatMensajes, {{"role","user"},{"text", "INSTRUCCION DEL SISTEMA: " + cChatPrompt }} )
      AADD( aChatMensajes, {{"role","model"},{"text", "Entendido." }} )

      IF !EMPTY( cChatFuentes )
         AADD( aChatMensajes, {{"role","user"},{"text", "FUENTES: " + cChatFuentes }} )
         AADD( aChatMensajes, {{"role","model"},{"text", "Fuentes recibidas." }} )
      ENDIF

      AADD( aChatDisplay, { "BOT", "Chat reiniciado. Listo.", TIME() } )

      oChatBrw:SetArray( aChatDisplay, .F. )
      oChatBrw:Refresh()
   ENDIF

RETURN NIL

//----------------------------------------------------------------------------//
// CONFIGURAR MODELO
//----------------------------------------------------------------------------//

STATIC FUNCTION ChatbotConfig()

   LOCAL oDlg, oGetModel, oGetTemp, oGetTokens
   LOCAL cModel, nTemp, nTokens

   cModel  := oChatGemini:cModel
   nTemp   := oChatGemini:nTemperature
   nTokens := oChatGemini:nMaxOutputTokens

   DEFINE DIALOG oDlg TITLE "Configuracion Gemini" FROM 0,0 TO 18,50 PIXEL

   @ 1, 1 SAY "Modelo:" SIZE 60, 15 PIXEL OF oDlg
   @ 1, 62 GET oGetModel VAR cModel SIZE 180, 15 PIXEL OF oDlg

   @ 3, 1 SAY "Temperatura:" SIZE 60, 15 PIXEL OF oDlg
   @ 3, 62 GET oGetTemp VAR nTemp SIZE 50, 15 PIXEL OF oDlg PICTURE "9.9"

   @ 5, 1 SAY "Max Tokens:" SIZE 60, 15 PIXEL OF oDlg
   @ 5, 62 GET oGetTokens VAR nTokens SIZE 50, 15 PIXEL OF oDlg PICTURE "99999"

   @ 7, 62 BUTTON "Aplicar" ACTION ( oChatGemini:SetModel( cModel ), ;
       oChatGemini:SetTemperature( nTemp ), ;
       oChatGemini:SetMaxTokens( nTokens ), ;
       oDlg:End() ) SIZE 60, 18 PIXEL OF oDlg

   @ 7, 125 BUTTON "Cancelar" ACTION oDlg:End() SIZE 60, 18 PIXEL OF oDlg

   ACTIVATE DIALOG oDlg CENTERED

RETURN NIL

//----------------------------------------------------------------------------//
// CONSULTA DIRECTA SIN INTERFAZ
//----------------------------------------------------------------------------//

FUNCTION GEMINI_CONSULTA( cMensaje, cPrompt, cFuentes )

   LOCAL oGoogle, oGemini, aMensajes, cRespuesta

   DEFAULT cPrompt  := "Eres un asistente juridico experto en derecho venezolano."
   DEFAULT cFuentes := ""

   aMensajes  := {}
   cRespuesta := ""

   oGoogle := TGoogle():New()
   IF EMPTY( oGoogle:cApiKey )
      RETURN "ERROR: No hay API Key configurada"
   ENDIF

   oGemini := oGoogle:Gemini()
   oGemini:SetTemperature( 0.3 )

   AADD( aMensajes, {{"role","user"},{"text", "INSTRUCCION: " + cPrompt }} )
   AADD( aMensajes, {{"role","model"},{"text", "Entendido." }} )

   IF !EMPTY( cFuentes )
      AADD( aMensajes, {{"role","user"},{"text", "FUENTES: " + cFuentes }} )
      AADD( aMensajes, {{"role","model"},{"text", "Fuentes recibidas." }} )
   ENDIF

   AADD( aMensajes, {{"role","user"},{"text", cMensaje }} )

   BEGIN SEQUENCE
      cRespuesta := oGemini:Chat( aMensajes )
   RECOVER USING oError
      cRespuesta := "ERROR: " + oError:description
   END SEQUENCE

   oGoogle:End()

RETURN cRespuesta

//----------------------------------------------------------------------------//
// EOF
