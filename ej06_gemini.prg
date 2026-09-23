//----------------------------------------------------------------------------//
// ej06_gemini.prg - Ejemplo de Google Gemini API
// Generar texto, chat, configuracion
// Compilar: harbour ej06_gemini.prg /n /iC:\fw24\include;C:\harbour\include;C:\googledrive
//----------------------------------------------------------------------------//

#include "FiveWin.ch"
#include "TGOOGLE.CH"

//----------------------------------------------------------------------------//

FUNCTION Main()

   LOCAL oGoogle, oGemini
   LOCAL cRespuesta, aMessages := {}

   CLS

   ? "============================================================"
   ? "  EJEMPLO 06: Google Gemini API"
   ? "  Modelo: gemini-3.8-flash"
   ? "============================================================"
   ?

   oGoogle := TGoogle():New()
   oGemini := oGoogle:Gemini()

   // 1. GENERACION SIMPLE
   ? "--- [1] Generacion simple ---"
   cRespuesta := oGemini:GenerateText( ;
      "Explica en 3 lineas que es un ERP" )
   ? "  Gemini: " + cRespuesta
   ?

   // 2. CAMBIAR MODELO
   ? "--- [2] Cambiar modelo ---"
   oGemini:SetModel( "gemini-2.0-flash" )
   cRespuesta := oGemini:GenerateText( "Di hola" )
   ? "  Respuesta: " + cRespuesta
   oGemini:SetModel( "gemini-3.8-flash" )
   ?

   // 3. TEMPERATURA
   ? "--- [3] Temperatura 0.2 (preciso) ---"
   oGemini:SetTemperature( 0.2 )
   cRespuesta := oGemini:GenerateText( "Capital de Venezuela? Solo nombre" )
   ? "  " + cRespuesta
   ?

   ? "--- [3b] Temperatura 1.5 (creativo) ---"
   oGemini:SetTemperature( 1.5 )
   cRespuesta := oGemini:GenerateText( "Describe Caracas en una frase" )
   ? "  " + cRespuesta
   oGemini:SetTemperature( 0.7 )
   ?

   // 4. CHAT MULTI-TURNO
   ? "--- [4] Chat ---"
   AADD( aMessages, { "role" => "user", ;
                      "text" => "Me llamo Juan y trabajo en Adaptapro" } )

   cRespuesta := oGemini:Chat( aMessages )
   ? "  [T1] Juan: " + aMessages[1]["text"]
   ? "  [T1] Gemini: " + cRespuesta

   AADD( aMessages, { "role" => "model", "text" => cRespuesta } )
   AADD( aMessages, { "role" => "user", ;
                      "text" => "En que puedo usar Gemini en Adaptapro?" } )

   cRespuesta := oGemini:Chat( aMessages )
   ? "  [T2] Gemini: " + LEFT( cRespuesta, 120 ) + "..."
   ?

   // 5. LIMITAR TOKENS
   ? "--- [5] Limitar tokens ---"
   oGemini:SetMaxTokens( 100 )
   cRespuesta := oGemini:GenerateText( "Escribe un poema largo sobre programacion" )
   ? "  Respuesta limitada: " + LEFT( cRespuesta, 100 ) + "..."
   oGemini:SetMaxTokens( 8192 )
   ?

   // 6. ANALISIS PRACTICO
   ? "--- [6] Uso pratico ---"
   cRespuesta := oGemini:GenerateText( ;
      "3 formas en que un ERP como Adaptapro podria usar IA" )
   ? "  " + cRespuesta
   ?

   ? "============================================================"
   ? "  Ejemplo Gemini completado"
   ? "============================================================"

   oGoogle:End()

RETURN NIL

//----------------------------------------------------------------------------//
// EOF
