//----------------------------------------------------------------------------//
// TGoogleSheets - Google Sheets API v4
// Lectura y escritura de hojas de cálculo
// Compatible: xHarbour + Harbour 3.2 + FiveWin 2.4
//----------------------------------------------------------------------------//

#include "FiveWin.ch"

#define SHEETS_API_BASE "https://sheets.googleapis.com/v4/spreadsheets"

//----------------------------------------------------------------------------//

CLASS TGoogleSheets

   DATA   oGoogle           // Referencia a TGoogle padre

   METHOD New( oGoogle )    CONSTRUCTOR
   METHOD End()

   // Hojas de cálculo
   METHOD GetSpreadsheet( cSpreadsheetId, cRanges )
   METHOD CreateSpreadsheet( cTitle )
   METHOD GetSheetNames( cSpreadsheetId )

   // Lectura
   METHOD ReadRange( cSpreadsheetId, cRange )
   METHOD ReadSheet( cSpreadsheetId, cSheetName )

   // Escritura
   METHOD WriteRange( cSpreadsheetId, cRange, aData )
   METHOD AppendRow( cSpreadsheetId, cSheetName, aRow )
   METHOD ClearRange( cSpreadsheetId, cRange )

   // Helpers
   METHOD BuildRange( cSheet, cStartCell, cEndCell )
   METHOD ParseValues( hJson )

ENDCLASS

//----------------------------------------------------------------------------//

METHOD New( oGoogle ) CLASS TGoogleSheets

   ::oGoogle := oGoogle

return Self

//----------------------------------------------------------------------------//

METHOD End() CLASS TGoogleSheets

   ::oGoogle := NIL

return nil

//----------------------------------------------------------------------------//

METHOD GetSpreadsheet( cSpreadsheetId, cRanges ) CLASS TGoogleSheets

   local cUrl, cResponse, hJson

   cUrl := SHEETS_API_BASE + "/" + cSpreadsheetId

   if !Empty( cRanges )
      cUrl += "?ranges=" + HB_URLENCODE( cRanges )
   endif

   cResponse := ::oGoogle:HttpRequest( "GET", cUrl )
   hJson     := TGoogleJSON():Decode( cResponse )

return hJson

//----------------------------------------------------------------------------//

METHOD CreateSpreadsheet( cTitle ) CLASS TGoogleSheets

   local cUrl, cBody, cResponse, hJson

   cUrl  := SHEETS_API_BASE
   cBody := '{"properties":{"title":"' + cTitle + '"}}'

   cResponse := ::oGoogle:HttpRequest( "POST", cUrl, cBody )
   hJson     := TGoogleJSON():Decode( cResponse )

return hJson

//----------------------------------------------------------------------------//

METHOD GetSheetNames( cSpreadsheetId ) CLASS TGoogleSheets

   local hSpread, aSheets := {}, hSheet

   hSpread := ::GetSpreadsheet( cSpreadsheetId )

   if hSpread != NIL .AND. TGoogleJSON():HasKey( hSpread, "sheets" )
      for each hSheet in hSpread["sheets"]
         AADD( aSheets, TGoogleJSON():Get( hSheet, "properties", {} ) )
      next
   endif

return aSheets

//----------------------------------------------------------------------------//

METHOD ReadRange( cSpreadsheetId, cRange ) CLASS TGoogleSheets

   local cUrl, cResponse, hJson

   cUrl := SHEETS_API_BASE + "/" + cSpreadsheetId + "/values/" + ;
           HB_URLENCODE( cRange )

   cResponse := ::oGoogle:HttpRequest( "GET", cUrl )
   hJson     := TGoogleJSON():Decode( cResponse )

return ::ParseValues( hJson )

//----------------------------------------------------------------------------//

METHOD ReadSheet( cSpreadsheetId, cSheetName ) CLASS TGoogleSheets

return ::ReadRange( cSpreadsheetId, cSheetName )

//----------------------------------------------------------------------------//

METHOD WriteRange( cSpreadsheetId, cRange, aData ) CLASS TGoogleSheets

   local cUrl, cBody, cResponse, hJson
   local cValues := ""
   local n, aRow

   cUrl := SHEETS_API_BASE + "/" + cSpreadsheetId + "/values/" + ;
           HB_URLENCODE( cRange ) + "?valueInputOption=USER_ENTERED"

   // Construir JSON de valores
   cValues := '['
   for n := 1 to Len( aData )
      aRow := aData[ n ]
      if n > 1
         cValues += ','
      endif
      cValues += ValToJSON( aRow )
   next
   cValues += ']'

   cBody := '{"values":' + cValues + '}'

   cResponse := ::oGoogle:HttpRequest( "PUT", cUrl, cBody )
   hJson     := TGoogleJSON():Decode( cResponse )

return ( hJson != NIL )

//----------------------------------------------------------------------------//

METHOD AppendRow( cSpreadsheetId, cSheetName, aRow ) CLASS TGoogleSheets

   local cUrl, cBody, cResponse, hJson

   cUrl := SHEETS_API_BASE + "/" + cSpreadsheetId + "/values/" + ;
           HB_URLENCODE( cSheetName ) + ":append?valueInputOption=USER_ENTERED"

   cBody := '{"values":[' + ValToJSON( aRow ) + ']}'

   cResponse := ::oGoogle:HttpRequest( "POST", cUrl, cBody )
   hJson     := TGoogleJSON():Decode( cResponse )

return ( hJson != NIL )

//----------------------------------------------------------------------------//

METHOD ClearRange( cSpreadsheetId, cRange ) CLASS TGoogleSheets

   local cUrl, cBody, cResponse

   cUrl := SHEETS_API_BASE + "/" + cSpreadsheetId + "/values/" + ;
           HB_URLENCODE( cRange ) + ":clear"

   cBody := '{}'

   cResponse := ::oGoogle:HttpRequest( "POST", cUrl, cBody )

return ::oGoogle:oHttp:nStatusCode == 200

//----------------------------------------------------------------------------//

METHOD BuildRange( cSheet, cStartCell, cEndCell ) CLASS TGoogleSheets

   local cRange := cSheet + "!"

   if !Empty( cStartCell )
      cRange += cStartCell
      if !Empty( cEndCell )
         cRange += ":" + cEndCell
      endif
   endif

return cRange

//----------------------------------------------------------------------------//

METHOD ParseValues( hJson ) CLASS TGoogleSheets

   local aData := {}, aRow

   if hJson != NIL .AND. TGoogleJSON():HasKey( hJson, "values" )
      aData := TGoogleJSON():Get( hJson, "values", {} )
   endif

return aData

//----------------------------------------------------------------------------//

// Función auxiliar para convertir array a JSON
STATIC FUNCTION ValToJSON( aRow )

   local cJson := "["
   local n, uVal

   for n := 1 to Len( aRow )
      uVal := aRow[ n ]
      if n > 1
         cJson += ","
      endif
      do case
         case ValType( uVal ) == "C"
            cJson += '"' + uVal + '"'
         case ValType( uVal ) == "N"
            cJson += AllTrim( Str( uVal ) )
         case ValType( uVal ) == "D"
            cJson += '"' + DTOC( uVal ) + '"'
         case ValType( uVal ) == "L"
            cJson += If( uVal, "true", "false" )
         otherwise
            cJson += '""'
      endcase
   next

   cJson += "]"

return cJson

//----------------------------------------------------------------------------//
// EOF
