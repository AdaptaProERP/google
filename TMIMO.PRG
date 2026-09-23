 //----------------------------------------------------------------------------//
 // TMimo - Xiaomi MiMo API (OpenAI Chat Completions compatible)
 // Modelos: mimo-v2.6-flash (default), mimo-v2.6-pro, mimo-v2.6-pro-ultraspeed
 // Endpoint: POST {server}/chat/completions  Header: api-key: <MIMO_API_KEY>
 // Body: {"model":"...","messages":[{"role":"...","content":"..."}],...}
 // Compatible: xHarbour 0.82 (SIN harbour.dll) + Harbour 3.2 + FiveWin 2.4
 // Sin hashes: mensajes como arrays de pares { {"role",r}, {"content",c} }
 //----------------------------------------------------------------------------//

 #include "FiveWin.ch"

 //----------------------------------------------------------------------------//

 CLASS TMimo

    DATA   oGoogle           // Referencia a TGoogle padre
    DATA   cModel            // Modelo a usar
    DATA   cApiKey           // API Key MiMo (sk-... / tp-...)
    DATA   cServer           // URL base (sin /chat/completions)

    METHOD New( oGoogle )    CONSTRUCTOR
    METHOD End()

    // Generación
    METHOD GenerateText( cPrompt, cModel )
    METHOD Chat( aMessages, cModel )

    // Configuración
    METHOD SetModel( cModel )
    METHOD SetTemperature( nTemp )
    METHOD SetMaxTokens( nTokens )

    // Datos de configuración
    DATA   nTemperature      // 0.0 - 2.0
    DATA   nMaxOutputTokens  // Límite de tokens

    // Helpers
    METHOD BuildPayload( aMessages )
    METHOD AuthHeaders()
    METHOD ParseResponse( cResponse )

 ENDCLASS

 //----------------------------------------------------------------------------//

 METHOD New( oGoogle ) CLASS TMimo

    ::oGoogle       := oGoogle
    ::cModel        := "mimo-v2.6-flash"
    ::cApiKey       := oGoogle:cApiKeyMimo
    ::cServer       := oGoogle:cServerMimo
    ::nTemperature  := 0.7
    ::nMaxOutputTokens := 4096

    if Empty( ::cServer )
       ::cServer := MIMO_API_BASE
    endif

 return Self

 //----------------------------------------------------------------------------//

 METHOD End() CLASS TMimo

    ::oGoogle := NIL

 return nil

 //----------------------------------------------------------------------------//

 METHOD SetModel( cModel ) CLASS TMimo

    ::cModel := cModel

 return nil

 //----------------------------------------------------------------------------//

 METHOD SetTemperature( nTemp ) CLASS TMimo

    ::nTemperature := nTemp

 return nil

 //----------------------------------------------------------------------------//

 METHOD SetMaxTokens( nTokens ) CLASS TMimo

    ::nMaxOutputTokens := nTokens

 return nil

 //----------------------------------------------------------------------------//
 // Headers: MiMo usa "api-key: <key>" (no Bearer)
 //----------------------------------------------------------------------------//

 METHOD AuthHeaders() CLASS TMimo

    local aHeaders := {}

    AADD( aHeaders, { "api-key", ::cApiKey } )

 return aHeaders

 //----------------------------------------------------------------------------//

 METHOD GenerateText( cPrompt, cModel ) CLASS TMimo

    local cUrl, cBody, cResponse
    local aMessages := {}

    DEFAULT cModel := ::cModel

    AADD( aMessages, { {"role","user"}, {"content",cPrompt} } )

    cUrl  := ::cServer + "/chat/completions"
    cBody := ::BuildPayload( aMessages, cModel )

    cResponse := ::oGoogle:oHttp:Post( cUrl, cBody, ::AuthHeaders() )

 return ::ParseResponse( cResponse )

 //----------------------------------------------------------------------------//

 METHOD Chat( aMessages, cModel ) CLASS TMimo

    local cUrl, cBody, cResponse

    DEFAULT cModel := ::cModel
    DEFAULT aMessages := {}

    cUrl  := ::cServer + "/chat/completions"
    cBody := ::BuildPayload( aMessages, cModel )

    cResponse := ::oGoogle:oHttp:Post( cUrl, cBody, ::AuthHeaders() )

 return ::ParseResponse( cResponse )

 //----------------------------------------------------------------------------//
 // BuildPayload: serializa con hb_JsonEncode (escapa comillas/saltos)
 // aMessages: { { {"role",r}, {"content",c} }, ... }
 //----------------------------------------------------------------------------//

 METHOD BuildPayload( aMessages, cModel ) CLASS TMimo

    local aBody := {}
    local cModelUse := ::cModel

    if cModel != NIL .AND. !Empty( cModel )
       cModelUse := cModel
    endif

    AADD( aBody, { "model", cModelUse } )
    AADD( aBody, { "messages", aMessages } )
    AADD( aBody, { "temperature", ::nTemperature } )
    AADD( aBody, { "max_completion_tokens", ::nMaxOutputTokens } )
    AADD( aBody, { "stream", .F. } )

 return TGoogleJSON():Encode( aBody )

 //----------------------------------------------------------------------------//
 // ParseResponse: OpenAI shape
 // { "choices": [ { "message": { "content": "..." } } ] }
 // Error: { "error": { "message": "..." } }
 //----------------------------------------------------------------------------//

 METHOD ParseResponse( cResponse ) CLASS TMimo

    local hJson, cText := ""
    local aChoices, hChoice, hMessage

    hJson := TGoogleJSON():Decode( cResponse )

    if hJson != NIL
       if TGoogleJSON():HasKey( hJson, "choices" )
          aChoices := TGoogleJSON():Get( hJson, "choices", {} )
          if ValType( aChoices ) == "A" .AND. Len( aChoices ) > 0
             hChoice := aChoices[ 1 ]
             if TGoogleJSON():IsObj( hChoice ) .AND. ;
                TGoogleJSON():HasKey( hChoice, "message" )
                hMessage := TGoogleJSON():Get( hChoice, "message" )
                cText := TGoogleJSON():Get( hMessage, "content", "" )
             endif
          endif
       endif

       // Si hay error
       if Empty( cText ) .AND. TGoogleJSON():HasKey( hJson, "error" )
          cText := "ERROR: " + TGoogleJSON():Get( TGoogleJSON():Get( hJson, "error" ), "message", "Error desconocido" )
       endif
    endif

 return cText

 //----------------------------------------------------------------------------//
 // EOF
