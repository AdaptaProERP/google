//----------------------------------------------------------------------------//
// ej07_sheets.prg - Ejemplo de Google Sheets API
// Crear hoja, leer, escribir, append
// Compilar: harbour ej07_sheets.prg /n /iC:\fw24\include;C:\harbour\include;C:\googledrive
//----------------------------------------------------------------------------//

#include "FiveWin.ch"
#include "TGOOGLE.CH"

//----------------------------------------------------------------------------//

FUNCTION Main()

   LOCAL oGoogle, oSheets
   LOCAL hSpread, aData, aRow, aSheets, hSheet
   LOCAL cSpreadId
   LOCAL aDatos

   CLS

   ? "============================================================"
   ? "  EJEMPLO 07: Google Sheets API v4"
   ? "============================================================"
   ?

   oGoogle := TGoogle():New()

   IF !oGoogle:IsAuthenticated()
      ? "Requiere autenticacion OAuth. Ejecute ej01_google_init.prg"
      RETURN NIL
   ENDIF

   oSheets := oGoogle:Sheets()

   // 1. CREAR HOJA
   ? "--- [1] Crear hoja de calculo ---"
   hSpread := oSheets:CreateSpreadsheet( "Adaptapro_Test_" + DTOS(DATE()) )
   IF hSpread != NIL
      cSpreadId := TGoogleJSON():Get( hSpread, "spreadsheetId", "" )
      ? "  [OK] Creada"
      ? "  URL: https://docs.google.com/spreadsheets/d/" + cSpreadId
   ELSE
      ? "  [ERROR] No se pudo crear"
      RETURN NIL
   ENDIF
   ?

   // 2. HOJAS
   ? "--- [2] Hojas disponibles ---"
   aSheets := oSheets:GetSheetNames( cSpreadId )
   FOR EACH hSheet IN aSheets
      ? "  * " + TGoogleJSON():Get( hSheet, "title", "" )
   NEXT
   ?

   // 3. ENCABEZADOS
   ? "--- [3] Escribir encabezados ---"
   IF oSheets:WriteRange( cSpreadId, "Sheet1!A1:E1", ;
      { { "Fecha", "Producto", "Cantidad", "Precio", "Total" } } )
      ? "  [OK] Encabezados escritos"
   ENDIF
   ?

   // 4. DATOS
   ? "--- [4] Escribir datos ---"
   aDatos := { ;
      { DTOC(DATE()), "Laptop HP",      2, 899.99, 1799.98 }, ;
      { DTOC(DATE()), "Monitor Dell",   1, 459.00, 459.00  }, ;
      { DTOC(DATE()), "Teclado",        5, 29.99, 149.95 }, ;
      { DTOC(DATE()), "Mouse",          3, 19.99, 59.97  }, ;
      { DTOC(DATE()), "Impresora",      1, 299.00, 299.00 } ;
   }
   IF oSheets:WriteRange( cSpreadId, "Sheet1!A2:E6", aDatos )
      ? "  [OK] 5 filas escritas"
   ENDIF
   ?

   // 5. LEER
   ? "--- [5] Leer datos ---"
   aData := oSheets:ReadRange( cSpreadId, "Sheet1!A1:E6" )
   FOR EACH aRow IN aData
      ? "  " + aRow[1] + " | " + aRow[2] + " | $" + aRow[4]
   NEXT
   ?

   // 6. APPEND
   ? "--- [6] Append ---"
   IF oSheets:AppendRow( cSpreadId, "Sheet1", ;
      { DTOC(DATE()), "USB Hub", 10, 15.50, 155.00 } )
      ? "  [OK] Fila agregada"
   ENDIF
   ?

   // 7. VERIFICAR
   ? "--- [7] Verificar total ---"
   aData := oSheets:ReadRange( cSpreadId, "Sheet1!A1:E8" )
   ? "  Filas: " + ALLTRIM( STR( LEN( aData ) ) )
   ?

   // 8. LIMPIAR
   ? "--- [8] Limpiar A2:E6 ---"
   IF oSheets:ClearRange( cSpreadId, "Sheet1!A2:E6" )
      ? "  [OK] Limpiado"
   ENDIF
   ?

   ? "============================================================"
   ? "  Hoja: https://docs.google.com/spreadsheets/d/" + cSpreadId
   ? "============================================================"

   oGoogle:End()

RETURN NIL

//----------------------------------------------------------------------------//
// EOF
