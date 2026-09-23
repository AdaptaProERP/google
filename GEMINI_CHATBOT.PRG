//----------------------------------------------------------------------------//
// GEMINI_CHATBOT.PRG
// Chatbot juridico con interfaz tipo WhatsApp para AdaptaPro ERP
// VENTANA NATIVA FiveWin (DEFINE WINDOW) - sin TMDI/DpMdi del ERP
// Proveedores: GEMINI (default) / MIMO (Xiaomi MiMo V2.6)
// Compatible: xHarbour 0.82 + FiveWin 2.4 (sin harbour.dll)
//----------------------------------------------------------------------------//

#include "FiveWin.ch"
#include "TGOOGLE.CH"

//----------------------------------------------------------------------------//
// Variables de modulo
//----------------------------------------------------------------------------//

STATIC oChatWnd
STATIC oChatGoogle
STATIC oChatGemini
STATIC oChatMimo
STATIC oChatBrw
STATIC oChatGet
STATIC oChatStatus
STATIC oChatInput
STATIC aChatMensajes := {}
STATIC aChatDisplay  := {}
STATIC cChatPrompt   := ""
STATIC cChatFuentes  := ""
STATIC cChatInput    := ""
STATIC cChatProvider := "GEMINI"

#define CLR_USER_BG   RGB(0xD9,0xF4,0xDD)
#define CLR_BOT_BG    RGB(0xE8,0xE8,0xE8)
#define CLR_USER_TXT  RGB(0x1B,0x1B,0x1B)
#define CLR_BOT_TXT   RGB(0x1B,0x1B,0x1B)
#define CLR_HEADER_BG RGB(0x00,0x7B,0x5E)
#define CLR_INPUT_BG  RGB(0xF0,0xF0,0xF0)
#define CLR_SEND_BTN  RGB(0x00,0xA8,0x84)

//----------------------------------------------------------------------------//
// MAIN: Interfaz chatbot tipo WhatsApp (ventana nativa FiveWin)
// cProvider: "GEMINI" (default) o "MIMO"
//----------------------------------------------------------------------------//

FUNCTION GEMINI_CHATBOT( cPrompt, cFuentes, cTitulo, cProvider )

   LOCAL aCoors, nAltoWin, nAnchoWin, nRowInput, nRowBrw, nHeightBrw
   LOCAL oFont, oFontInput, oFontTime, oFontHeader, oFontBtn
   LOCAL cStatus

   DEFAULT cPrompt   := "Eres un asistente juridico experto en derecho venezolano."
   DEFAULT cFuentes  := ""
   DEFAULT cTitulo   := "Consulta Juridica IA"
   DEFAULT cProvider := "GEMINI"

   // Dimensiones
   aCoors       := GetCoors( GetDesktopWindow() )
   nAltoWin     := aCoors[3] - 100
   nAnchoWin    := aCoors[4] - 50
   nRowInput    := nAltoWin - 120
   nRowBrw      := 60
   nHeightBrw   := nRowInput - nRowBrw - 5

   // Guardar en modulo
   cChatPrompt   := cPrompt
   cChatFuentes  := cFuentes
   cChatInput    := ""
   cChatProvider := UPPER( ALLTRIM( cProvider ) )
   IF cChatProvider != "MIMO"
      cChatProvider := "GEMINI"
   ENDIF

   // Inicializar Google / credenciales segun proveedor
   oChatGoogle := TGoogle():New()
   IF cChatProvider == "MIMO"
      IF EMPTY( oChatGoogle:cApiKeyMimo )
         MsgStop( "No se encontro API Key de MiMo. Use MIMO_SETAPIKEY( 'sk-...' )" )
         oChatGoogle:End()
         RETURN NIL
      ENDIF
      oChatGemini := NIL
      oChatMimo   := oChatGoogle:Mimo()
      oChatMimo:SetModel( oChatGoogle:cModelMimo )
      oChatMimo:SetTemperature( 0.3 )
      cStatus := "MIMO " + oChatGoogle:cModelMimo
   ELSE
      IF EMPTY( oChatGoogle:cApiKey )
         MsgStop( "No se encontro API Key de Gemini. Configure config_google.json" )
         oChatGoogle:End()
         RETURN NIL
      ENDIF
      oChatMimo   := NIL
      oChatGemini := oChatGoogle:Gemini()
      oChatGemini:SetModel( oChatGoogle:cModelGemini )
      oChatGemini:SetTemperature( 0.3 )
      cStatus := "GEMINI " + oChatGoogle:cModelGemini
   ENDIF

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

   // Ventana NATIVA FiveWin (sin TMDI/DpMdi)
   DEFINE WINDOW oChatWnd TITLE cTitulo ;
      FROM 0, 0 TO nAltoWin, nAnchoWin PIXEL

   // Header verde
   @ 0, 0 SAY "  " + cTitulo SIZE nAnchoWin, 55 PIXEL ;
       OF oChatWnd FONT oFontHeader ;
       COLOR CLR_WHITE, CLR_HEADER_BG

   @ 12, nAnchoWin - 260 SAY oChatStatus PROMPT cStatus ;
       SIZE 200, 20 PIXEL ;
       OF oChatWnd FONT oFontTime ;
       COLOR RGB(0xC8,0xFF,0xC8), CLR_HEADER_BG

   // Browse de mensajes
   oChatBrw := TXBrowse():New( oChatWnd )
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
       OF oChatWnd COLOR CLR_HEADER_BG, CLR_HEADER_BG

   // Input de texto
   oChatInput := TGet():New( nRowInput, 5, ;
       { |u| If( PCount()==0, cChatInput, cChatInput:=u ) }, ;
       oChatWnd, ;
       nAnchoWin - 110, 20, ;
       NIL, NIL, ;
       CLR_USER_TXT, CLR_INPUT_BG, ;
       oFontInput, .T. )

   // Boton Enviar
   TButton():New( nRowInput, nAnchoWin - 100, "Enviar", ;
       oChatWnd, {|| ChatbotEnviar() }, ;
       90, 20, oFontBtn, .F., .T., .F., NIL, NIL, .T. )

   // Barra inferior (nativa, sin oDp)
   @ nAltoWin - 15, 0 TO nAltoWin, nAnchoWin PIXEL ;
       OF oChatWnd

   TButton():New( nAltoWin - 13, 5, "Adjuntar", ;
       oChatWnd, {|| ChatbotAdjuntar() }, ;
       80, 12, oFontTime, .F., .T., .F., NIL, NIL, .T. )

   TButton():New( nAltoWin - 13, 90, "Limpiar", ;
       oChatWnd, {|| ChatbotLimpiar() }, ;
       80, 12, oFontTime, .F., .T., .F., NIL, NIL, .T. )

   TButton():New( nAltoWin - 13, 175, "IA", ;
       oChatWnd, {|| ChatbotCambiarIA() }, ;
       60, 12, oFontTime, .F., .T., .F., NIL, NIL, .T. )

   TButton():New( nAltoWin - 13, 240, "Config", ;
       oChatWnd, {|| ChatbotConfig() }, ;
       60, 12, oFontTime, .F., .T., .F., NIL, NIL, .T. )

   TButton():New( nAltoWin - 13, nAnchoWin - 70, "Cerrar", ;
       oChatWnd, {|| oChatWnd:End() }, ;
       60, 12, oFontTime, .F., .T., .F., NIL, NIL, .T. )

   // Activar ventana nativa
   ACTIVATE WINDOW oChatWnd

   // Cleanup
   oChatGoogle:End()
   oChatGoogle := NIL
   oChatGemini := NIL
   oChatMimo   := NIL

RETURN NIL

//----------------------------------------------------------------------------//
// TRADUCIR historial a formato OpenAI (MiMo): role model->assistant, text->content
//----------------------------------------------------------------------------//

STATIC FUNCTION ChatbotToMimo( aMsgs )

   LOCAL aOut := {}, n, cRole, cText

   FOR n := 1 TO LEN( aMsgs )
      cRole := TGoogleJSON():Get( aMsgs[n], "role", "user" )
      cText := TGoogleJSON():Get( aMsgs[n], "text", "" )
      IF cRole == "model"
         cRole := "assistant"
      ENDIF
      AADD( aOut, { {"role",cRole}, {"content",cText} } )
   NEXT

RETURN aOut

//----------------------------------------------------------------------------//
// ENVIAR MENSAJE (segun proveedor activo)
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

   // Llamar a la IA activa
   cRespuesta := ""
   BEGIN SEQUENCE
      IF cChatProvider == "MIMO"
         cRespuesta := oChatMimo:Chat( ChatbotToMimo( aChatMensajes ) )
      ELSE
         cRespuesta := oChatGemini:Chat( aChatMensajes )
      ENDIF
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
// CAMBIAR PROVEEDOR IA (GEMINI <-> MIMO)
//----------------------------------------------------------------------------//

STATIC FUNCTION ChatbotCambiarIA()

   LOCAL cNuevo

   IF cChatProvider == "MIMO"
      cNuevo := "GEMINI"
      IF EMPTY( oChatGoogle:cApiKey )
         MsgStop( "No hay API Key de Gemini configurada" )
         RETURN NIL
      ENDIF
      oChatMimo:End()
      oChatMimo   := NIL
      oChatGemini := oChatGoogle:Gemini()
      oChatGemini:SetModel( oChatGoogle:cModelGemini )
      oChatGemini:SetTemperature( 0.3 )
      oChatStatus:SetText( "GEMINI " + oChatGoogle:cModelGemini )
   ELSE
      cNuevo := "MIMO"
      IF EMPTY( oChatGoogle:cApiKeyMimo )
         MsgStop( "No hay API Key de MiMo. Use MIMO_SETAPIKEY( 'sk-...' )" )
         RETURN NIL
      ENDIF
      oChatGemini:End()
      oChatGemini := NIL
      oChatMimo   := oChatGoogle:Mimo()
      oChatMimo:SetModel( oChatGoogle:cModelMimo )
      oChatMimo:SetTemperature( 0.3 )
      oChatStatus:SetText( "MIMO " + oChatGoogle:cModelMimo )
   ENDIF

   cChatProvider := cNuevo

RETURN NIL

//----------------------------------------------------------------------------//
// CONFIGURAR MODELO (proveedor activo)
//----------------------------------------------------------------------------//

STATIC FUNCTION ChatbotConfig()

   LOCAL oDlg, oGetModel, oGetTemp, oGetTokens
   LOCAL cModel, nTemp, nTokens, oActive

   IF cChatProvider == "MIMO"
      oActive := oChatMimo
   ELSE
      oActive := oChatGemini
   ENDIF

   cModel  := oActive:cModel
   nTemp   := oActive:nTemperature
   nTokens := oActive:nMaxOutputTokens

   DEFINE DIALOG oDlg TITLE "Configuracion IA (" + cChatProvider + ")" FROM 0,0 TO 18,50 PIXEL

   @ 1, 1 SAY "Modelo:" SIZE 60, 15 PIXEL OF oDlg
   @ 1, 62 GET oGetModel VAR cModel SIZE 180, 15 PIXEL OF oDlg

   @ 3, 1 SAY "Temperatura:" SIZE 60, 15 PIXEL OF oDlg
   @ 3, 62 GET oGetTemp VAR nTemp SIZE 50, 15 PIXEL OF oDlg PICTURE "9.9"

   @ 5, 1 SAY "Max Tokens:" SIZE 60, 15 PIXEL OF oDlg
   @ 5, 62 GET oGetTokens VAR nTokens SIZE 50, 15 PIXEL OF oDlg PICTURE "99999"

   @ 7, 62 BUTTON "Aplicar" ACTION ( oActive:SetModel( cModel ), ;
       oActive:SetTemperature( nTemp ), ;
       oActive:SetMaxTokens( nTokens ), ;
       oChatStatus:SetText( cChatProvider + " " + cModel ), ;
       oDlg:End() ) SIZE 60, 18 PIXEL OF oDlg

   @ 7, 125 BUTTON "Cancelar" ACTION oDlg:End() SIZE 60, 18 PIXEL OF oDlg

   ACTIVATE DIALOG oDlg CENTERED

RETURN NIL

//----------------------------------------------------------------------------//
// CONSULTA DIRECTA SIN INTERFAZ (cProvider: "GEMINI" / "MIMO")
//----------------------------------------------------------------------------//

FUNCTION GEMINI_CONSULTA( cMensaje, cPrompt, cFuentes, cProvider )

   LOCAL oGoogle, oGemini, oMimo, aMensajes, cRespuesta

   DEFAULT cPrompt   := "Eres un asistente juridico experto en derecho venezolano."
   DEFAULT cFuentes  := ""
   DEFAULT cProvider := "GEMINI"

   aMensajes  := {}
   cRespuesta := ""

   oGoogle := TGoogle():New()

   IF UPPER( ALLTRIM( cProvider ) ) == "MIMO"
      IF EMPTY( oGoogle:cApiKeyMimo )
         oGoogle:End()
         RETURN "ERROR: No hay API Key de MiMo configurada"
      ENDIF
      oMimo := oGoogle:Mimo()
      oMimo:SetTemperature( 0.3 )
      AADD( aMensajes, {{"role","system"},{"content", "INSTRUCCION: " + cPrompt }} )
      IF !EMPTY( cFuentes )
         AADD( aMensajes, {{"role","user"},{"content", "FUENTES: " + cFuentes }} )
      ENDIF
      AADD( aMensajes, {{"role","user"},{"content", cMensaje }} )
      BEGIN SEQUENCE
         cRespuesta := oMimo:Chat( aMensajes )
      RECOVER USING oError
         cRespuesta := "ERROR: " + oError:description
      END SEQUENCE
   ELSE
      IF EMPTY( oGoogle:cApiKey )
         oGoogle:End()
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
   ENDIF

   oGoogle:End()

RETURN cRespuesta

//----------------------------------------------------------------------------//
// EOF
