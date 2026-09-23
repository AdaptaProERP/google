//----------------------------------------------------------------------------//
// ej09_mimo.prg - Ejemplo de Xiaomi MiMo API (OpenAI compatible)
// Modelos: mimo-v2.6-flash (default), mimo-v2.6-pro
// Key: oDp:MIMOAPIKEY > config_google.json (mimo_api_key)
//      o sin key: MIMO_SETAPIKEY( 'sk-...' )
// Compatible: xHarbour 0.82 + FiveWin 2.4 (sin harbour.dll)
//----------------------------------------------------------------------------//

#include "FiveWin.ch"
#include "TGOOGLE.CH"

//----------------------------------------------------------------------------//

FUNCTION Main()

   LOCAL oGoogle, oMimo
   LOCAL cRespuesta, aMessages := {}

   CLS

   ? "============================================================"
   ? "  EJEMPLO 09: Xiaomi MiMo API"
   ? "  Modelo: mimo-v2.6-flash"
   ? "============================================================"
   ?

   oGoogle := TGoogle():New()

   IF EMPTY( oGoogle:cApiKeyMimo )
      ? '  Sin MIMO API key. Use: MIMO_SETAPIKEY( "sk-..." )'
      ? "  o configure mimo_api_key en config_google.json"
      ?
      oGoogle:End()
      RETURN NIL
   ENDIF

   oMimo := oGoogle:Mimo()

   // 1. GENERACION SIMPLE
   ? "--- [1] Generacion simple ---"
   cRespuesta := oMimo:GenerateText( ;
      "Explica en 3 lineas que es un ERP" )
   ? "  MiMo: " + cRespuesta
   ?

   // 2. CAMBIAR MODELO
   ? "--- [2] Cambiar a Pro ---"
   oMimo:SetModel( MIMO_MODEL_PRO )
   cRespuesta := oMimo:GenerateText( "Di hola" )
   ? "  Respuesta: " + cRespuesta
   oMimo:SetModel( MIMO_MODEL_FLASH )
   ?

   // 3. CHAT MULTI-TURNO (pares rol/contenido estilo OpenAI)
   ? "--- [3] Chat ---"
   AADD( aMessages, { {"role","system"}, ;
                      {"content","Eres un asistente de Adaptapro ERP."} } )
   AADD( aMessages, { {"role","user"}, ;
                      {"content","Me llamo Juan y trabajo en Adaptapro"} } )

   cRespuesta := oMimo:Chat( aMessages )
   ? "  [T1] MiMo: " + cRespuesta

   AADD( aMessages, { {"role","assistant"}, {"content",cRespuesta} } )
   AADD( aMessages, { {"role","user"}, ;
                      {"content","En que puedo usar IA en Adaptapro?"} } )

   cRespuesta := oMimo:Chat( aMessages )
   ? "  [T2] MiMo: " + LEFT( cRespuesta, 120 ) + "..."
   ?

   ? "============================================================"
   ? "  Ejemplo MiMo completado"
   ? "============================================================"

   oGoogle:End()

RETURN NIL

//----------------------------------------------------------------------------//
// EOF
