//----------------------------------------------------------------------------//
// TGoogleAuth - OAuth2 Flow para Google APIs
// Manejo de tokens: Access Token + Refresh Token
// Compatible: xHarbour + Harbour 3.2 + FiveWin 2.4
//----------------------------------------------------------------------------//

#include "FiveWin.ch"
#include "TGOOGLE.CH"

// Scopes de Google (alias locales)
#define SCOPE_CALENDAR      "https://www.googleapis.com/auth/calendar"
#define SCOPE_DRIVE         "https://www.googleapis.com/auth/drive"
#define SCOPE_GMAIL         "https://www.googleapis.com/auth/gmail.modify"
#define SCOPE_TASKS         "https://www.googleapis.com/auth/tasks"
#define SCOPE_SHEETS        "https://www.googleapis.com/auth/spreadsheets"
#define SCOPE_USERINFO      "https://www.googleapis.com/auth/userinfo.email"

//----------------------------------------------------------------------------//

CLASS TGoogleAuth

   DATA   cClientId          // OAuth Client ID
   DATA   cClientSecret      // OAuth Client Secret
   DATA   cRedirectUri       // URI de redireccionamiento
   DATA   cScope             // Scopes solicitados

   // Tokens
   DATA   cAccessToken       // Token de acceso (2h)
   DATA   cRefreshToken      // Token de refresh (largo plazo)
   DATA   cTokenType         // Tipo: "Bearer"
   DATA   nExpiresIn         // Segundos hasta expiración
   DATA   dTokenDate         // Fecha de emisión
   DATA   cTokenTime         // Hora de emisión

   // Estado
   DATA   cLastError
   DATA   lAuthenticated

   // Archivo de persistencia
   DATA   cTokenFile

   METHOD New( cClientId, cClientSecret, cScope ) CONSTRUCTOR
   METHOD End()

   // OAuth2 Flow
   METHOD GetAuthUrl( cState )
   METHOD ExchangeCode( cCode )
   METHOD RefreshAccessToken()
   METHOD RevokeToken()

   // Persistencia
   METHOD SaveTokens()
   METHOD LoadTokens()
   METHOD ClearTokens()

   // Utilidades
   METHOD IsValidToken()
   METHOD GetAuthHeader()
   METHOD GetAuthUrlForBrowser()

   // Interacción con Chrome
   METHOD OpenChromeForAuth()
   METHOD WaitForCode()

ENDCLASS

//----------------------------------------------------------------------------//

METHOD New( cClientId, cClientSecret, cScope ) CLASS TGoogleAuth

   DEFAULT cScope := SCOPE_CALENDAR + " " + SCOPE_DRIVE + " " + ;
                     SCOPE_GMAIL + " " + SCOPE_TASKS + " " + ;
                     SCOPE_SHEETS + " " + SCOPE_USERINFO

   ::cClientId     := cClientId
   ::cClientSecret := cClientSecret
   ::cRedirectUri  := "urn:ietf:wg:oauth:2.0:oob"
   ::cScope        := cScope

   ::cAccessToken  := ""
   ::cRefreshToken := ""
   ::cTokenType    := "Bearer"
   ::nExpiresIn    := 0
   ::dTokenDate    := CTOD("")
   ::cTokenTime    := ""

   ::cLastError    := ""
   ::lAuthenticated := .F.

   ::cTokenFile := "c:\googledrive\tokens_google.json"

   // Cargar tokens previos si existen
   ::LoadTokens()

return Self

//----------------------------------------------------------------------------//

METHOD End() CLASS TGoogleAuth

   ::SaveTokens()

return nil

//----------------------------------------------------------------------------//

METHOD GetAuthUrl( cState ) CLASS TGoogleAuth

   local cUrl

   DEFAULT cState := "adaptapro_" + HB_TSTAMP()

   cUrl := GOOGLE_AUTH_URL + "?" + ;
           "client_id=" + ::cClientId + "&" + ;
           "redirect_uri=" + ::cRedirectUri + "&" + ;
           "response_type=code&" + ;
           "scope=" + HB_URLENCODE( ::cScope ) + "&" + ;
           "access_type=offline&" + ;
           "prompt=consent&" + ;
           "state=" + cState

return cUrl

//----------------------------------------------------------------------------//

METHOD ExchangeCode( cCode ) CLASS TGoogleAuth

   local oHttp, cBody, cResponse, hJson
   local cRet := ""

   oHttp := TGoogleHTTP():New()

   cBody := "code=" + cCode + "&" + ;
            "client_id=" + ::cClientId + "&" + ;
            "client_secret=" + ::cClientSecret + "&" + ;
            "redirect_uri=" + ::cRedirectUri + "&" + ;
            "grant_type=authorization_code"

   cResponse := oHttp:Post( GOOGLE_TOKEN_URL, cBody, ;
               { {"Content-Type", "application/x-www-form-urlencoded"} } )

   hJson := TGoogleJSON():Decode( cResponse )

   if hJson != NIL .AND. TGoogleJSON():HasKey( hJson, "access_token" )
      ::cAccessToken  := TGoogleJSON():Get( hJson, "access_token", "" )
      ::cRefreshToken := TGoogleJSON():Get( hJson, "refresh_token", "" )
      ::cTokenType    := TGoogleJSON():Get( hJson, "token_type", "" )
      ::nExpiresIn    := TGoogleJSON():Get( hJson, "expires_in", 0 )
      ::dTokenDate    := DATE()
      ::cTokenTime    := TIME()
      ::lAuthenticated := .T.

      ::SaveTokens()
      cRet := ::cAccessToken
   else
      ::cLastError := "Error intercambiando código"
      if hJson != NIL .AND. TGoogleJSON():HasKey( hJson, "error" )
         ::cLastError := TGoogleJSON():Get( hJson, "error", "" )
         if TGoogleJSON():IsObj( TGoogleJSON():Get( hJson, "error" ) ) .AND. ;
            TGoogleJSON():HasKey( TGoogleJSON():Get( hJson, "error" ), "description" )
            ::cLastError := TGoogleJSON():Get( TGoogleJSON():Get( hJson, "error" ), "description", "" )
         endif
      endif
   endif

return cRet

//----------------------------------------------------------------------------//

METHOD RefreshAccessToken() CLASS TGoogleAuth

   local oHttp, cBody, cResponse, hJson
   local cRet := ""

   if Empty( ::cRefreshToken )
      ::cLastError := "No hay Refresh Token disponible"
      return cRet
   endif

   oHttp := TGoogleHTTP():New()

   cBody := "client_id=" + ::cClientId + "&" + ;
            "client_secret=" + ::cClientSecret + "&" + ;
            "refresh_token=" + ::cRefreshToken + "&" + ;
            "grant_type=refresh_token"

   cResponse := oHttp:Post( GOOGLE_TOKEN_URL, cBody, ;
               { {"Content-Type", "application/x-www-form-urlencoded"} } )

   hJson := TGoogleJSON():Decode( cResponse )

   if hJson != NIL .AND. TGoogleJSON():HasKey( hJson, "access_token" )
      ::cAccessToken  := TGoogleJSON():Get( hJson, "access_token", "" )
      ::cTokenType    := TGoogleJSON():Get( hJson, "token_type", "" )
      ::nExpiresIn    := TGoogleJSON():Get( hJson, "expires_in", 0 )
      ::dTokenDate    := DATE()
      ::cTokenTime    := TIME()
      ::lAuthenticated := .T.

      ::SaveTokens()
      cRet := ::cAccessToken
   else
      ::cLastError := "Error refrescando token"
      ::lAuthenticated := .F.
   endif

return cRet

//----------------------------------------------------------------------------//

METHOD RevokeToken() CLASS TGoogleAuth

   local oHttp, cUrl, cResponse

   if Empty( ::cAccessToken )
      return .F.
   endif

   oHttp := TGoogleHTTP():New()
   cUrl  := GOOGLE_REVOKE_URL + "?token=" + ::cAccessToken
   cResponse := oHttp:Get( cUrl )

   ::ClearTokens()

return .T.

//----------------------------------------------------------------------------//

METHOD SaveTokens() CLASS TGoogleAuth

   local hTokens := {}

   if !Empty( ::cAccessToken ) .OR. !Empty( ::cRefreshToken )
      TGoogleJSON():Set( hTokens, "access_token", ::cAccessToken )
      TGoogleJSON():Set( hTokens, "refresh_token", ::cRefreshToken )
      TGoogleJSON():Set( hTokens, "token_type", ::cTokenType )
      TGoogleJSON():Set( hTokens, "expires_in", ::nExpiresIn )
      TGoogleJSON():Set( hTokens, "token_date", DTOC( ::dTokenDate ) )
      TGoogleJSON():Set( hTokens, "token_time", ::cTokenTime )
      TGoogleJSON():Set( hTokens, "client_id", ::cClientId )

      TGoogleJSON():ToFile( ::cTokenFile, hTokens )
   endif

return nil

//----------------------------------------------------------------------------//

METHOD LoadTokens() CLASS TGoogleAuth

   local hTokens
   local cDate

   if FILE( ::cTokenFile )
      hTokens := TGoogleJSON():FromFile( ::cTokenFile )

      if hTokens != NIL
         ::cAccessToken  := TGoogleJSON():Get( hTokens, "access_token", "" )
         ::cRefreshToken := TGoogleJSON():Get( hTokens, "refresh_token", "" )
         ::cTokenType    := TGoogleJSON():Get( hTokens, "token_type", "Bearer" )
         ::nExpiresIn    := TGoogleJSON():Get( hTokens, "expires_in", 0 )

          cDate := TGoogleJSON():Get( hTokens, "token_date", "" )
          if !Empty( cDate )
             ::dTokenDate := CTOD( cDate )
          endif
         ::cTokenTime := TGoogleJSON():Get( hTokens, "token_time", "" )

         ::lAuthenticated := !Empty( ::cAccessToken )
      endif
   endif

return nil

//----------------------------------------------------------------------------//

METHOD ClearTokens() CLASS TGoogleAuth

   ::cAccessToken  := ""
   ::cRefreshToken := ""
   ::cTokenType    := "Bearer"
   ::nExpiresIn    := 0
   ::dTokenDate    := CTOD("")
   ::cTokenTime    := ""
   ::lAuthenticated := .F.

   if FILE( ::cTokenFile )
      FErase( ::cTokenFile )
   endif

return nil

//----------------------------------------------------------------------------//

METHOD IsValidToken() CLASS TGoogleAuth

   local nElapsed

   if Empty( ::cAccessToken )
      return .F.
   endif

   // Calcular tiempo transcurrido
   nElapsed := (DATE() - ::dTokenDate) * 86400 + ;
               (HB_TTOSEC(TIME()) - HB_TTOSEC(::cTokenTime))

   // Token válido si no ha expirado (con margen de 5 min)
   if nElapsed < (::nExpiresIn - 300)
      return .T.
   endif

return .F.

//----------------------------------------------------------------------------//

METHOD GetAuthHeader() CLASS TGoogleAuth

   if ::IsValidToken()
      return ::cTokenType + " " + ::cAccessToken
   endif

   // Intentar refrescar
   if !Empty( ::cRefreshToken )
      ::RefreshAccessToken()
      if ::lAuthenticated
         return ::cTokenType + " " + ::cAccessToken
      endif
   endif

return ""

//----------------------------------------------------------------------------//

METHOD OpenChromeForAuth() CLASS TGoogleAuth

   local cUrl := ::GetAuthUrl()
   local cChromeExe := "C:\Program Files\Google\Chrome\Application\chrome.exe"

   if FILE( cChromeExe )
      WinExec( cChromeExe + ' "' + cUrl + '"' )
   else
      ShellExecute( 0, "open", cUrl )
   endif

return nil

//----------------------------------------------------------------------------//

METHOD GetAuthUrlForBrowser() CLASS TGoogleAuth

return ::GetAuthUrl()

//----------------------------------------------------------------------------//

METHOD WaitForCode() CLASS TGoogleAuth

   local cCode := ""

   MsgInfo( "Se abrió Chrome para autorización." + CRLF + ;
            "Copie el código de autorización y péguelo." + CRLF + CRLF + ;
            "URL: " + ::GetAuthUrl(), "Autorización Google" )

   cCode := InputBox( "Código de autorización:", "Google OAuth2" )

return cCode

//----------------------------------------------------------------------------//
// EOF
