//----------------------------------------------------------------------------//
// TGoogleGemini - Google Gemini API (Generative Language)
// Generación de texto, chat, análisis
// Compatible: xHarbour + Harbour 3.2 + FiveWin 2.4
// Modelo: gemini-3.8-flash
//----------------------------------------------------------------------------//

#include "FiveWin.ch"

#define GEMINI_BASE "https://generativelanguage.googleapis.com/v1beta/models"

//----------------------------------------------------------------------------//

CLASS TGoogleGemini

   DATA   oGoogle           // Referencia a TGoogle padre
   DATA   cModel            // Modelo a usar
   DATA   cApiKey           // API Key
   DATA   cServer           // URL base

   METHOD New( oGoogle )    CONSTRUCTOR
   METHOD End()

   // Generación
   METHOD GenerateText( cPrompt, cModel )
   METHOD GenerateWithImage( cPrompt, cBase64Image, cMimeType )
   METHOD Chat( aMessages, cModel )

   // Configuración
   METHOD SetModel( cModel )
   METHOD SetTemperature( nTemp )
   METHOD SetMaxTokens( nTokens )

   // Datos de configuración
   DATA   nTemperature      // 0.0 - 2.0
   DATA   nMaxOutputTokens  // Límite de tokens

   // Helpers
   METHOD BuildPayload( cPrompt, aExtra )
   METHOD ParseResponse( cResponse )

ENDCLASS

//----------------------------------------------------------------------------//

METHOD New( oGoogle ) CLASS TGoogleGemini

   ::oGoogle       := oGoogle
   ::cModel        := "gemini-3.8-flash"
   ::cApiKey       := oGoogle:cApiKey
   ::cServer       := oGoogle:cServerGemini
   ::nTemperature  := 0.7
   ::nMaxOutputTokens := 8192

return Self

//----------------------------------------------------------------------------//

METHOD End() CLASS TGoogleGemini

   ::oGoogle := NIL

return nil

//----------------------------------------------------------------------------//

METHOD SetModel( cModel ) CLASS TGoogleGemini

   ::cModel := cModel

return nil

//----------------------------------------------------------------------------//

METHOD SetTemperature( nTemp ) CLASS TGoogleGemini

   ::nTemperature := nTemp

return nil

//----------------------------------------------------------------------------//

METHOD SetMaxTokens( nTokens ) CLASS TGoogleGemini

   ::nMaxOutputTokens := nTokens

return nil

//----------------------------------------------------------------------------//

METHOD GenerateText( cPrompt, cModel ) CLASS TGoogleGemini

   local cUrl, cBody, cResponse, hJson

   DEFAULT cModel := ::cModel

   cUrl := ::cServer + cModel + ":generateContent?key=" + ::cApiKey
   cBody := ::BuildPayload( cPrompt )

   cResponse := ::oGoogle:oHttp:Post( cUrl, cBody )

return ::ParseResponse( cResponse )

//----------------------------------------------------------------------------//

METHOD GenerateWithImage( cPrompt, cBase64Image, cMimeType ) CLASS TGoogleGemini

   local cUrl, cBody, cResponse
   local cModel := ::cModel

   DEFAULT cMimeType := "image/png"

   cUrl := ::cServer + cModel + ":generateContent?key=" + ::cApiKey

   // Payload con imagen
   cBody := '{"contents":[{"parts":['
   cBody += '{"text":"' + cPrompt + '"},'
   cBody += '{"inline_data":{"mime_type":"' + cMimeType + '","data":"' + cBase64Image + '"}}'
   cBody += ']}],'
   cBody += '"generationConfig":{"temperature":' + AllTrim( Str( ::nTemperature ) ) + '}'

   cResponse := ::oGoogle:oHttp:Post( cUrl, cBody )

return ::ParseResponse( cResponse )

//----------------------------------------------------------------------------//

METHOD Chat( aMessages, cModel ) CLASS TGoogleGemini

   local cUrl, cBody, cResponse
   local cModelUse := ::cModel
   local cContents := ""
   local n, hMsg

   DEFAULT cModel := ::cModel
   DEFAULT aMessages := {}

   cUrl := ::cServer + cModelUse + ":generateContent?key=" + ::cApiKey

   // Construir contents desde mensajes
   cContents := '['
   for n := 1 to Len( aMessages )
      hMsg := aMessages[ n ]
      if n > 1
         cContents += ','
      endif
      cContents += '{"role":"' + TGoogleJSON():Get( hMsg, "role", "user" ) + '",'
      cContents += '"parts":[{"text":"' + TGoogleJSON():Get( hMsg, "text", "" ) + '"}]}'
   next
   cContents += ']'

   cBody := '{"contents":' + cContents + ','
   cBody += '"generationConfig":{"temperature":' + AllTrim( Str( ::nTemperature ) ) + '}}'

   cResponse := ::oGoogle:oHttp:Post( cUrl, cBody )

return ::ParseResponse( cResponse )

//----------------------------------------------------------------------------//

METHOD BuildPayload( cPrompt, aExtra ) CLASS TGoogleGemini

   local cPayload

   cPayload := '{"contents":[{"parts":[{"text":"' + cPrompt + '"}]}],'
   cPayload += '"generationConfig":{'
   cPayload += '"temperature":' + AllTrim( Str( ::nTemperature ) )
   cPayload += ',"maxOutputTokens":' + AllTrim( Str( ::nMaxOutputTokens ) )
   cPayload += '}}'

return cPayload

//----------------------------------------------------------------------------//

METHOD ParseResponse( cResponse ) CLASS TGoogleGemini

   local hJson, cText := ""
   local aCandidates, hCandidate, hContent, aParts

   hJson := TGoogleJSON():Decode( cResponse )

   if hJson != NIL
      // Estructura: { "candidates": [ { "content": { "parts": [ { "text": "..." } ] } } ] }
      if TGoogleJSON():HasKey( hJson, "candidates" )
         aCandidates := hJson[ "candidates" ]
         if ValType( aCandidates ) == "A" .AND. Len( aCandidates ) > 0
            hCandidate := aCandidates[ 1 ]
            if TGoogleJSON():HasKey( hCandidate, "content" )
               hContent := hCandidate[ "content" ]
               if TGoogleJSON():HasKey( hContent, "parts" )
                  aParts := hContent[ "parts" ]
                  if ValType( aParts ) == "A" .AND. Len( aParts ) > 0
                     cText := TGoogleJSON():Get( aParts[ 1 ], "text", "" )
                  endif
               endif
            endif
         endif
      endif

      // Si hay error
      if Empty( cText ) .AND. TGoogleJSON():HasKey( hJson, "error" )
         cText := "ERROR: " + TGoogleJSON():Get( hJson["error"], "message", "Error desconocido" )
      endif
   endif

return cText

//----------------------------------------------------------------------------//
// EOF
