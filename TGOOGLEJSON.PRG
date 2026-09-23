 //----------------------------------------------------------------------------//
 // TGoogleJSON - Wrapper para JSON encode/decode
 // Compatible: xHarbour 0.82 (SIN harbour.dll) + Harbour 3.2 + FiveWin 2.4
 //
 // Modelo de datos: los objetos JSON se representan como arrays de pares:
 //    { {"clave1", valor1}, {"clave2", valor2}, ... }
 // Los arrays JSON se representan como arrays normales.
 // No se usan hashes para que el EXE sea autocontenido (xHarbour 0.82
 // solo trae hashes en harbour.dll).
 //----------------------------------------------------------------------------//

 #include "FiveWin.ch"

 //----------------------------------------------------------------------------//

 CLASS TGoogleJSON

    // Métodos de utilidad
    METHOD Decode( cJson )
    METHOD Encode( uValue )
    METHOD Get( aObj, cKey, uDefault )
    METHOD Set( aObj, cKey, uValue )
    METHOD GetNested( aObj, cPath, uDefault )
    METHOD HasKey( aObj, cKey )
    METHOD IsObj( aObj )
    METHOD NewObj()
    METHOD Pair( cKey, uValue )
    METHOD ToFile( cFile, aObj )
    METHOD FromFile( cFile )

 ENDCLASS

 //----------------------------------------------------------------------------//

 METHOD Decode( cJson ) CLASS TGoogleJSON

    local aResult := NIL

    if !Empty( cJson )
       BEGIN SEQUENCE
          hb_JsonDecode( cJson, @aResult )
       RECOVER
          aResult := NIL
       END
    endif

 return aResult

 //----------------------------------------------------------------------------//

 METHOD Encode( uValue ) CLASS TGoogleJSON

    local cResult := ""

    if uValue != NIL
       BEGIN SEQUENCE
          cResult := hb_JsonEncode( uValue )
       RECOVER
          cResult := ""
       END
    endif

 return cResult

 //----------------------------------------------------------------------------//
 // IsObj: .T. si es array de pares { {clave,valor}, ... } (objeto JSON)
 //----------------------------------------------------------------------------//

 METHOD IsObj( aObj ) CLASS TGoogleJSON

    local n

    if ValType( aObj ) != "A"
       return .F.
    endif

    if Len( aObj ) == 0
       return .T.
    endif

    for n := 1 to Len( aObj )
       if ValType( aObj[n] ) != "A" .OR. Len( aObj[n] ) != 2 .OR. ;
          ValType( aObj[n][1] ) != "C"
          return .F.
       endif
    next

 return .T.

 //----------------------------------------------------------------------------//

 METHOD Get( aObj, cKey, uDefault ) CLASS TGoogleJSON

    local n

    if aObj != NIL .AND. ValType( aObj ) == "A"
       for n := 1 to Len( aObj )
          if ValType( aObj[n] ) == "A" .AND. Len( aObj[n] ) == 2 .AND. ;
             ValType( aObj[n][1] ) == "C" .AND. aObj[n][1] == cKey
             return aObj[n][2]
          endif
       next
    endif

 return uDefault

 //----------------------------------------------------------------------------//
 // Set: actualiza la clave si existe, la agrega si no (por referencia)
 //----------------------------------------------------------------------------//

 METHOD Set( aObj, cKey, uValue ) CLASS TGoogleJSON

    local n

    if aObj != NIL .AND. ValType( aObj ) == "A"
       for n := 1 to Len( aObj )
          if ValType( aObj[n] ) == "A" .AND. Len( aObj[n] ) == 2 .AND. ;
             ValType( aObj[n][1] ) == "C" .AND. aObj[n][1] == cKey
             aObj[n][2] := uValue
             return aObj
          endif
       next
       AADD( aObj, { cKey, uValue } )
    endif

 return aObj

 //----------------------------------------------------------------------------//

 METHOD GetNested( aObj, cPath, uDefault ) CLASS TGoogleJSON

    local aKeys, aCurrent, n, cKey

    DEFAULT uDefault := NIL

    if aObj == NIL .OR. !::IsObj( aObj )
       return uDefault
    endif

    aKeys    := hb_ATokens( cPath, "." )
    aCurrent := aObj

    for n := 1 to Len( aKeys )
       cKey := aKeys[ n ]
       if ::IsObj( aCurrent ) .AND. ::HasKey( aCurrent, cKey )
          aCurrent := ::Get( aCurrent, cKey )
       else
          return uDefault
       endif
    next

 return aCurrent

 //----------------------------------------------------------------------------//

 METHOD HasKey( aObj, cKey ) CLASS TGoogleJSON

    local n

    if aObj != NIL .AND. ValType( aObj ) == "A"
       for n := 1 to Len( aObj )
          if ValType( aObj[n] ) == "A" .AND. Len( aObj[n] ) == 2 .AND. ;
             ValType( aObj[n][1] ) == "C" .AND. aObj[n][1] == cKey
             return .T.
          endif
       next
    endif

 return .F.

 //----------------------------------------------------------------------------//
 // NewObj: objeto vacio. Pair: par {clave,valor} para construir literales.
 //----------------------------------------------------------------------------//

 METHOD NewObj() CLASS TGoogleJSON

 return {}

 METHOD Pair( cKey, uValue ) CLASS TGoogleJSON

 return { cKey, uValue }

 //----------------------------------------------------------------------------//

 METHOD ToFile( cFile, aObj ) CLASS TGoogleJSON

    local cJson := ::Encode( aObj )

    if !Empty( cJson )
       MEMOWRIT( cFile, cJson )
    endif

 return !Empty( cJson )

 //----------------------------------------------------------------------------//

 METHOD FromFile( cFile ) CLASS TGoogleJSON

    local cJson, aResult := NIL

    if FILE( cFile )
       cJson := MEMOREAD( cFile )
       if !Empty( cJson )
          aResult := ::Decode( cJson )
       endif
    endif

 return aResult

 //----------------------------------------------------------------------------//
 // EOF
