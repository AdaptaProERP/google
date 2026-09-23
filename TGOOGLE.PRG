//----------------------------------------------------------------------------//
// TGoogle - Clase Principal Orchestrator para Google APIs
// Gestiona: Calendar, Drive, Tasks, Gmail, Gemini, Sheets
// Compatible: xHarbour + Harbour 3.2 + FiveWin 2.4
//
// PARAMETROS CONFIGURABLES POR USUARIO:
//   New( cApiKey, cClientId, cClientSecret, cCuenta, cServer, cModel )
//   Todos opcionales - si se pasan NV, lee de config_google.json
//   Si el JSON no existe, usa valores por defecto de TGOOGLE.CH
//----------------------------------------------------------------------------//

#include "FiveWin.ch"

//----------------------------------------------------------------------------//

CLASS TGoogle

   // Configuracion
   DATA   cApiKey            // API Key Gemini/Drive
   DATA   cClientId          // OAuth Client ID
   DATA   cClientSecret      // OAuth Client Secret
   DATA   cCuentaGmail       // Cuenta Gmail (default: micuenta@gmail.com)
   DATA   cServerGemini      // URL servidor Gemini
   DATA   cModelGemini       // Modelo Gemini

   // OAuth
   DATA   oAuth              // Objeto TGoogleAuth

   // Servicios (lazy init)
   DATA   oCalendar          // TGoogleCalendar
   DATA   oDrive             // TGoogleDrive
   DATA   oTasks             // TGoogleTasks
   DATA   oGmail             // TGoogleGmail
   DATA   oGemini            // TGoogleGemini
   DATA   oSheets            // TGoogleSheets

   // HTTP compartido
   DATA   oHttp              // TGoogleHTTP

   // Estado
   DATA   cLastError
   DATA   lDebug

   METHOD New( cApiKey, cClientId, cClientSecret, ;
               cCuenta, cServer, cModel )  CONSTRUCTOR
   METHOD End()

   // Configuracion
   METHOD LoadConfig()
   METHOD SaveConfig()
   METHOD ShowConfig()
   METHOD SetApiKey( cKey )
   METHOD ResetApiKey()

   // OAuth
   METHOD Authenticate()
   METHOD IsAuthenticated()
   METHOD GetAuthHeader()

   // Servicios (lazy init)
   METHOD Calendar()
   METHOD Drive()
   METHOD Tasks()
   METHOD Gmail()
   METHOD Gemini()
   METHOD Sheets()

   // HTTP helper
   METHOD HttpRequest( cMethod, cUrl, cBody, aHeaders )

ENDCLASS

//----------------------------------------------------------------------------//

METHOD New( cApiKey, cClientId, cClientSecret, ;
            cCuenta, cServer, cModel ) CLASS TGoogle

   // Defaults iniciales (sobreescribir con config_google.json si existe)
   ::cApiKey       := ""
   ::cClientId     := ""
   ::cClientSecret := ""
   ::cCuentaGmail  := ""
   ::cServerGemini := ""
   ::cModelGemini  := ""

   ::cLastError := ""
   ::lDebug     := .F.

   // Crear objetos internos
   ::oHttp := TGoogleHTTP():New()

   // Cargar configuracion del JSON primero
   ::LoadConfig()

   // Si el usuario paso parametros, se sobreescriben
   // Esto permite: oGoogle := TGoogle():New( "mi-apikey", NIL, NIL, "mi@email.com" )
   if cApiKey != NIL .AND. !EMPTY( cApiKey )
      ::cApiKey := cApiKey
   endif

   if cClientId != NIL .AND. !EMPTY( cClientId )
      ::cClientId := cClientId
   endif

   if cClientSecret != NIL .AND. !EMPTY( cClientSecret )
      ::cClientSecret := cClientSecret
   endif

   if cCuenta != NIL .AND. !EMPTY( cCuenta )
      ::cCuentaGmail := cCuenta
   endif

   if cServer != NIL .AND. !EMPTY( cServer )
      ::cServerGemini := cServer
   endif

   if cModel != NIL .AND. !EMPTY( cModel )
      ::cModelGemini := cModel
   endif

   // Si quedaron vacios, usar defaults de TGOOGLE.CH
   if EMPTY( ::cCuentaGmail )
      ::cCuentaGmail := TGOOGLE_DEFAULT_EMAIL
   endif
   if EMPTY( ::cServerGemini )
      ::cServerGemini := TGOOGLE_GEMINI_URL
   endif
   if EMPTY( ::cModelGemini )
      ::cModelGemini := TGOOGLE_DEFAULT_MODEL
   endif

   // Crear OAuth con credenciales cargadas
   ::oAuth := TGoogleAuth():New( ::cClientId, ::cClientSecret )

return Self

//----------------------------------------------------------------------------//

METHOD End() CLASS TGoogle

   // Liberar servicios
   if ::oCalendar != NIL
      ::oCalendar:End()
   endif
   if ::oDrive != NIL
      ::oDrive:End()
   endif
   if ::oTasks != NIL
      ::oTasks:End()
   endif
   if ::oGmail != NIL
      ::oGmail:End()
   endif
   if ::oGemini != NIL
      ::oGemini:End()
   endif
   if ::oSheets != NIL
      ::oSheets:End()
   endif

   // Liberar OAuth
   if ::oAuth != NIL
      ::oAuth:End()
   endif

   // Liberar HTTP
   if ::oHttp != NIL
      ::oHttp:End()
   endif

return nil

//----------------------------------------------------------------------------//

METHOD LoadConfig() CLASS TGoogle

   local cFile := TGOOGLE_CONFIG_FILE
   local hConfig

   // 1. Intentar desde oDp:GEMINIAPIKEY (Adaptapro ERP)
   if Type( "oDp" ) == "O" .AND. __ObjHasData( oDp, "GEMINIAPIKEY" )
      if !EMPTY( oDp:GEMINIAPIKEY )
         ::cApiKey := oDp:GEMINIAPIKEY
      endif
   endif

   // 2. Intentar desde config JSON
   if FILE( cFile )
      hConfig := TGoogleJSON():FromFile( cFile )

      if hConfig != NIL
         if EMPTY( ::cApiKey )
            ::cApiKey       := TGoogleJSON():Get( hConfig, "api_key", "" )
         endif
         ::cClientId     := TGoogleJSON():Get( hConfig, "client_id", "" )
         ::cClientSecret := TGoogleJSON():Get( hConfig, "client_secret", "" )
         ::cCuentaGmail  := TGoogleJSON():Get( hConfig, "cuenta_gmail", "" )
         ::cServerGemini := TGoogleJSON():Get( hConfig, "server_gemini", "" )
         ::cModelGemini  := TGoogleJSON():Get( hConfig, "model_gemini", "" )
         ::lDebug        := TGoogleJSON():Get( hConfig, "debug", .F. )
      endif
   endif

return nil

//----------------------------------------------------------------------------//

METHOD SaveConfig() CLASS TGoogle

   local hConfig := Hash()

   hConfig[ "api_key"       ] := ::cApiKey
   hConfig[ "client_id"     ] := ::cClientId
   hConfig[ "client_secret" ] := ::cClientSecret
   hConfig[ "cuenta_gmail"  ] := ::cCuentaGmail
   hConfig[ "server_gemini" ] := ::cServerGemini
   hConfig[ "model_gemini"  ] := ::cModelGemini
   hConfig[ "debug"         ] := ::lDebug

return TGoogleJSON():ToFile( TGOOGLE_CONFIG_FILE, hConfig )

//----------------------------------------------------------------------------//

METHOD ShowConfig() CLASS TGoogle

   ? "  API Key:      " + IF( EMPTY( ::cApiKey ), "(no configurada)", LEFT( ::cApiKey, 15 ) + "..." )
   ? "  Client ID:    " + IF( EMPTY( ::cClientId ), "(no configurado)", LEFT( ::cClientId, 20 ) + "..." )
   ? "  Client Secret:" + IF( EMPTY( ::cClientSecret ), "(no configurado)", "****" )
   ? "  Cuenta:       " + ::cCuentaGmail
   ? "  Server Gemini:" + ::cServerGemini
   ? "  Modelo:       " + ::cModelGemini
   ? "  Debug:        " + IF( ::lDebug, "ON", "OFF" )

return nil

//----------------------------------------------------------------------------//
// SetApiKey: cambia la key en memoria + oDp:GEMINIAPIKEY + JSON
//----------------------------------------------------------------------------//

METHOD SetApiKey( cKey ) CLASS TGoogle

   if cKey == NIL
      return .F.
   endif

   ::cApiKey := AllTrim( cKey )

   // Sincronizar con oDp:GEMINIAPIKEY (Adaptapro ERP)
   BEGIN SEQUENCE
      if Type( "oDp" ) == "O"
         oDp:GEMINIAPIKEY := ::cApiKey
      endif
   RECOVER
   END SEQUENCE

   // Persistir en config JSON
   ::SaveConfig()

return .T.

//----------------------------------------------------------------------------//
// ResetApiKey: borra la key en memoria + oDp:GEMINIAPIKEY + JSON
//----------------------------------------------------------------------------//

METHOD ResetApiKey() CLASS TGoogle

   ::cApiKey := ""

   BEGIN SEQUENCE
      if Type( "oDp" ) == "O"
         oDp:GEMINIAPIKEY := ""
      endif
   RECOVER
   END SEQUENCE

   ::SaveConfig()

return .T.

//----------------------------------------------------------------------------//

METHOD Authenticate() CLASS TGoogle

   local cCode

   if ::oAuth == NIL
      ::oAuth := TGoogleAuth():New( ::cClientId, ::cClientSecret )
   endif

   if ::oAuth:IsValidToken()
      return .T.
   endif

   if !Empty( ::oAuth:cRefreshToken )
      ::oAuth:RefreshAccessToken()
      if ::oAuth:lAuthenticated
         return .T.
      endif
   endif

   ::oAuth:OpenChromeForAuth()
   cCode := ::oAuth:WaitForCode()

   if !Empty( cCode )
      ::oAuth:ExchangeCode( cCode )
   endif

return ::oAuth:lAuthenticated

//----------------------------------------------------------------------------//

METHOD IsAuthenticated() CLASS TGoogle

   if ::oAuth != NIL
      return ::oAuth:IsValidToken()
   endif

return .F.

//----------------------------------------------------------------------------//

METHOD GetAuthHeader() CLASS TGoogle

   if ::oAuth != NIL
      return ::oAuth:GetAuthHeader()
   endif

return ""

//----------------------------------------------------------------------------//
// Servicios Lazy Init
//----------------------------------------------------------------------------//

METHOD Calendar() CLASS TGoogle

   if ::oCalendar == NIL
      ::oCalendar := TGoogleCalendar():New( Self )
   endif

return ::oCalendar

//----------------------------------------------------------------------------//

METHOD Drive() CLASS TGoogle

   if ::oDrive == NIL
      ::oDrive := TGoogleDrive():New( Self )
   endif

return ::oDrive

//----------------------------------------------------------------------------//

METHOD Tasks() CLASS TGoogle

   if ::oTasks == NIL
      ::oTasks := TGoogleTasks():New( Self )
   endif

return ::oTasks

//----------------------------------------------------------------------------//

METHOD Gmail() CLASS TGoogle

   if ::oGmail == NIL
      ::oGmail := TGoogleGmail():New( Self )
   endif

return ::oGmail

//----------------------------------------------------------------------------//

METHOD Gemini() CLASS TGoogle

   if ::oGemini == NIL
      ::oGemini := TGoogleGemini():New( Self )
   endif

return ::oGemini

//----------------------------------------------------------------------------//

METHOD Sheets() CLASS TGoogle

   if ::oSheets == NIL
      ::oSheets := TGoogleSheets():New( Self )
   endif

return ::oSheets

//----------------------------------------------------------------------------//
// HTTP Helper
//----------------------------------------------------------------------------//

METHOD HttpRequest( cMethod, cUrl, cBody, aHeaders ) CLASS TGoogle

   local aAllHeaders := {}
   local cAuth

   // Agregar Authorization si hay token
   cAuth := ::GetAuthHeader()
   if !Empty( cAuth )
      AADD( aAllHeaders, { "Authorization", cAuth } )
   endif

   // Agregar headers adicionales
   if aHeaders != NIL
      AEVAL( aHeaders, {|h| AADD( aAllHeaders, h ) } )
   endif

   do case
      case Upper( cMethod ) == "GET"
         return ::oHttp:Get( cUrl, aAllHeaders )

      case Upper( cMethod ) == "POST"
         return ::oHttp:Post( cUrl, cBody, aAllHeaders )

      case Upper( cMethod ) == "PUT"
         return ::oHttp:Put( cUrl, cBody, aAllHeaders )

      case Upper( cMethod ) == "PATCH"
         return ::oHttp:Patch( cUrl, cBody, aAllHeaders )

      case Upper( cMethod ) == "DELETE"
         return ::oHttp:Delete( cUrl, aAllHeaders )
   endcase

return ""

//----------------------------------------------------------------------------//
// Funciones de cambio/reset de API key de Gemini
// Uso: GEMINI_SETAPIKEY( "AIza..." ) / GEMINI_RESETAPIKEY()
// Prioridad de lectura: oDp:GEMINIAPIKEY > config_google.json
//----------------------------------------------------------------------------//

FUNCTION GEMINI_SETAPIKEY( cKey )

   local oGoogle

   if cKey == NIL .OR. Empty( cKey )
      return .F.
   endif

   oGoogle := TGoogle():New()
   oGoogle:SetApiKey( cKey )
   oGoogle:End()

return .T.

FUNCTION GEMINI_RESETAPIKEY()

   local oGoogle := TGoogle():New()

   oGoogle:ResetApiKey()
   oGoogle:End()

return .T.

FUNCTION GEMINI_GETAPIKEY()

   local oGoogle := TGoogle():New()
   local cKey := oGoogle:cApiKey

   oGoogle:End()

return cKey

//----------------------------------------------------------------------------//
// EOF
