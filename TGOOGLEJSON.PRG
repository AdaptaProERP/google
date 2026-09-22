//----------------------------------------------------------------------------//
// TGoogleJSON - Wrapper para JSON encode/decode
// Compatible: xHarbour + Harbour 3.2 + FiveWin 2.4
//----------------------------------------------------------------------------//

#include "FiveWin.ch"

//----------------------------------------------------------------------------//

CLASS TGoogleJSON

   // Métodos de utilidad
   METHOD Decode( cJson )
   METHOD Encode( uValue )
   METHOD Get( hJson, cKey, uDefault )
   METHOD GetNested( hJson, cPath, uDefault )
   METHOD HasKey( hJson, cKey )
   METHOD ToFile( cFile, hJson )
   METHOD FromFile( cFile )

ENDCLASS

//----------------------------------------------------------------------------//

METHOD Decode( cJson ) CLASS TGoogleJSON

   local hResult := NIL

   if !Empty( cJson )
      BEGIN SEQUENCE
         hb_JsonDecode( cJson, @hResult )
      RECOVER
         hResult := NIL
      END
   endif

return hResult

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

METHOD Get( hJson, cKey, uDefault ) CLASS TGoogleJSON

   if hJson != NIL .AND. ValType( hJson ) == "H"
      if hb_HHasKey( hJson, cKey )
         return hJson[ cKey ]
      endif
   endif

return uDefault

//----------------------------------------------------------------------------//

METHOD GetNested( hJson, cPath, uDefault ) CLASS TGoogleJSON

   local aKeys, hCurrent, n, cKey

   DEFAULT uDefault := NIL

   if hJson == NIL .OR. ValType( hJson ) != "H"
      return uDefault
   endif

   aKeys   := hb_ATokens( cPath, "." )
   hCurrent := hJson

   for n := 1 to Len( aKeys )
      cKey := aKeys[ n ]
      if ValType( hCurrent ) == "H" .AND. hb_HHasKey( hCurrent, cKey )
         hCurrent := hCurrent[ cKey ]
      else
         return uDefault
      endif
   next

return hCurrent

//----------------------------------------------------------------------------//

METHOD HasKey( hJson, cKey ) CLASS TGoogleJSON

   if hJson != NIL .AND. ValType( hJson ) == "H"
      return hb_HHasKey( hJson, cKey )
   endif

return .F.

//----------------------------------------------------------------------------//

METHOD ToFile( cFile, hJson ) CLASS TGoogleJSON

   local cJson := ::Encode( hJson )

   if !Empty( cJson )
      MEMOWRIT( cFile, cJson )
   endif

return !Empty( cJson )

//----------------------------------------------------------------------------//

METHOD FromFile( cFile ) CLASS TGoogleJSON

   local cJson, hResult := NIL

   if FILE( cFile )
      cJson := MEMOREAD( cFile )
      if !Empty( cJson )
         hResult := ::Decode( cJson )
      endif
   endif

return hResult

//----------------------------------------------------------------------------//
// EOF
