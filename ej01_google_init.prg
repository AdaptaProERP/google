//----------------------------------------------------------------------------//
// ej01_google_init.prg - Inicializacion del Ecosistema Google
// Ejemplo base que muestra configuracion por parametros y por JSON
// Compilar: harbour ej01_google_init.prg /n /iC:\fw24\include;C:\harbour\include;C:\googledrive
//----------------------------------------------------------------------------//

#include "FiveWin.ch"
#include "TGOOGLE.CH"

//----------------------------------------------------------------------------//

FUNCTION Main()

   LOCAL oGoogle, cTest

   CLS

   ? "============================================================"
   ? "  EJEMPLO 01: Inicializacion del Ecosistema Google"
   ? "============================================================"
   ?

   // ================================================================
   // METODO 1: Leer de config_google.json (DEFAULT)
   // ================================================================
   ? "--- [1] Desde config_google.json (default) ---"
   oGoogle := TGoogle():New()
   oGoogle:ShowConfig()
   oGoogle:End()
   ?

   // ================================================================
   // METODO 2: Pasar API Key por parametro
   // ================================================================
   ? "--- [2] Solo API Key por parametro ---"
   oGoogle := TGoogle():New( "TU_API_KEY_AQUI" )
   ? "  Cuenta (del JSON): " + oGoogle:cCuentaGmail
   ? "  Modelo (del JSON): " + oGoogle:cModelGemini
   oGoogle:End()
   ?

   // ================================================================
   // METODO 3: Configuracion completa por parametros
   // ================================================================
   ? "--- [3] Todos los parametros por parametros ---"
   oGoogle := TGoogle():New( ;
      "TU_API_KEY_AQUI", ;  // API Key
      "mi-client-id.apps.googleusercontent.com", ;     // Client ID
      "mi-client-secret", ;                             // Client Secret
      "otro_usuario@gmail.com", ;                      // Cuenta Gmail
      "https://generativelanguage.googleapis.com/v1beta/models/", ; // Server
      "gemini-2.0-flash" )                              // Modelo
   oGoogle:ShowConfig()
   oGoogle:End()
   ?

   // ================================================================
   // METODO 4: Sobreescribir solo campos especificos
   // Los demas se leen del config_google.json
   // ================================================================
   ? "--- [4] Sobreescribir cuenta y modelo ---"
   oGoogle := TGoogle():New( ;
      NIL, ;                  // API Key: usar del JSON
      NIL, ;                  // Client ID: usar del JSON
      NIL, ;                  // Client Secret: usar del JSON
      "maria@empresa.com", ;  // Cuenta: nueva
      NIL, ;                  // Server: usar del JSON
      "gemini-2.0-flash" )    // Modelo: nuevo
   ? "  Cuenta override: " + oGoogle:cCuentaGmail
   ? "  Modelo override: " + oGoogle:cModelGemini
   oGoogle:End()
   ?

   // ================================================================
   // METODO 5: Crear config_google.json para OTRO usuario
   // ================================================================
   ? "--- [5] Crear config para otro usuario ---"
   oGoogle := TGoogle():New()
   oGoogle:cApiKey       := "API_KEY_DE_OTRO_USUARIO"
   oGoogle:cClientId     := "CLIENT_ID_DE_OTRO_USUARIO"
   oGoogle:cClientSecret := "CLIENT_SECRET_DE_OTRO_USUARIO"
   oGoogle:cCuentaGmail  := "otro_usuario@gmail.com"
   oGoogle:cModelGemini  := "gemini-2.0-flash"
   oGoogle:SaveConfig()
   ? "  Config guardada para: " + oGoogle:cCuentaGmail
   oGoogle:End()

   // Restaurar config original
   oGoogle := TGoogle():New()
   oGoogle:cApiKey       := "TU_API_KEY_AQUI"
   oGoogle:cCuentaGmail  := "micuenta@gmail.com"
   oGoogle:cModelGemini  := "gemini-2.5-flash-lite"
   oGoogle:SaveConfig()
   ? "  Config restaurada para: " + oGoogle:cCuentaGmail
   oGoogle:End()
   ?

   // ================================================================
   // VERIFICACION: Probar conexion
   // ================================================================
   ? "--- [6] Verificar conexion ---"
   oGoogle := TGoogle():New()

   IF oGoogle:oHttp:CreateOle()
      ? "  [OK] HTTP conectado"
   ELSE
      ? "  [ERROR] HTTP fallo"
   ENDIF

   cTest := oGoogle:Gemini():GenerateText( "Di OK" )
   IF !EMPTY( cTest ) .AND. "ERROR" $ UPPER( cTest )
      ? "  [ERROR] API Key: " + LEFT( cTest, 50 )
   ELSE
      ? "  [OK] Gemini responde: " + LEFT( cTest, 30 )
   ENDIF

   oGoogle:End()
   ?

   ? "============================================================"
   ? "  METODOS DE CONFIGURACION:"
   ? "  1. config_google.json (default, sin parametros)"
   ? "  2. New( cApiKey ) - solo API Key"
   ? "  3. New( cApiKey, cClientId, cSecret, cCuenta, cServer, cModel )"
   ? "  4. New( NIL, NIL, NIL, 'email@x.com' ) - solo cambiar cuenta"
   ? "  5. SaveConfig() - grabar configuracion actual"
   ? "============================================================"

RETURN NIL

//----------------------------------------------------------------------------//
// EOF
