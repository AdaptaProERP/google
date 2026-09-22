//----------------------------------------------------------------------------//
// google_test.prg - Test del Ecosistema Google para Adaptapro ERP
// Cuenta: jnadaptapro@gmail.com
// Compilar: build_google.bat google_test
//----------------------------------------------------------------------------//

#include "FiveWin.ch"
#include "TGOOGLE.CH"

//----------------------------------------------------------------------------//

Function Main()

   LOCAL oGoogle, nOpcion := 1
   LOCAL oFont, oWnd

   SET DATE FORMAT TO "DD/MM/YYYY"
   SET SCOREBOARD OFF

   DEFINE FONT oFont NAME "Tahoma" SIZE 0, -12

   CLS

   ? "================================================================"
   ? "  ECO GOOGLE - Adaptapro ERP v" + TGOOGLE_VERSION
   ? "  Cuenta: jnadaptapro@gmail.com"
   ? "  Compilado: " + TGOOGLE_BUILD
   ? "================================================================"
   ?

   // Crear instancia principal
   ? "[1] Creando instancia TGoogle..."
   oGoogle := TGoogle():New()

   ? "  API Key:     " + If( !Empty( oGoogle:cApiKey ), LEFT( oGoogle:cApiKey, 10 ) + "...", "NO CONFIGURADA" )
   ? "  Client ID:   " + If( !Empty( oGoogle:cClientId ), LEFT( oGoogle:cClientId, 20 ) + "...", "NO CONFIGURADO" )
   ? "  Cuenta:      " + oGoogle:cCuentaGmail
   ? "  Servidor:    " + oGoogle:cServerGemini
   ? "  Modelo:      " + oGoogle:cModelGemini
   ?

   // Menú de prueba
   DO WHILE nOpcion != 0
      ?
      ? "========================================================"
      ? "  MENU DE PRUEBA"
      ? "========================================================"
      ? "  1. Probar HTTP (conexión)"
      ? "  2. Probar JSON (decode/encode)"
      ? "  3. Probar Gemini (generar texto)"
      ? "  4. Probar Calendar (obtener eventos)"
      ? "  5. Probar Drive (buscar archivos)"
      ? "  6. Probar Tasks (listar tareas)"
      ? "  7. Probar Gmail (contar no leídos)"
      ? "  8. Probar Sheets (leer hoja)"
      ? "  9. Configuración completa"
      ? "  0. Salir"
      ? "========================================================"
      ?

      nOpcion := VAL( INPUTBOX( "Seleccione opción (0-9):", "Test Google", "1" ) )

      DO CASE
         CASE nOpcion == 1
            TestHTTP( oGoogle )

         CASE nOpcion == 2
            TestJSON()

         CASE nOpcion == 3
            TestGemini( oGoogle )

         CASE nOpcion == 4
            TestCalendar( oGoogle )

         CASE nOpcion == 5
            TestDrive( oGoogle )

         CASE nOpcion == 6
            TestTasks( oGoogle )

         CASE nOpcion == 7
            TestGmail( oGoogle )

         CASE nOpcion == 8
            TestSheets( oGoogle )

         CASE nOpcion == 9
            TestConfig( oGoogle )

         CASE nOpcion == 0
            ? "Saliendo..."

         OTHERWISE
            ? "Opción no válida"
      ENDCASE
   ENDDO

   // Liberar recursos
   oGoogle:End()

   ? ""
   ? "================================================================"
   ? "  Prueba finalizada"
   ? "================================================================"

RETURN NIL

//----------------------------------------------------------------------------//
// TEST: HTTP
//----------------------------------------------------------------------------//
STATIC FUNCTION TestHTTP( oGoogle )

   LOCAL oHttp, cResponse

   ? ""
   ? "--- TEST HTTP ---"

   oHttp := TGoogleHTTP():New()

   ? "Probando conexión a Google..."
   cResponse := oHttp:Get( "https://httpbin.org/get" )

   ? "Status Code: " + AllTrim( Str( oHttp:nStatusCode ) )
   ? "Respuesta:   " + LEFT( cResponse, 100 )

   IF oHttp:nStatusCode == 200
      ? "[OK] Conexión exitosa"
   ELSE
      ? "[ERROR] Código: " + AllTrim( Str( oHttp:nStatusCode ) )
   ENDIF

   oHttp:End()

RETURN NIL

//----------------------------------------------------------------------------//
// TEST: JSON
//----------------------------------------------------------------------------//
STATIC FUNCTION TestJSON()

   LOCAL hJson, cJson

   ? ""
   ? "--- TEST JSON ---"

   cJson := '{"name":"Adaptapro","version":"3.0","features":["calendar","drive","gmail"]}'

   ? "JSON: " + cJson

   hJson := TGoogleJSON():Decode( cJson )

   IF hJson != NIL
      ? "[OK] Decodificado exitosamente"
      ? "  name:    " + TGoogleJSON():Get( hJson, "name", "" )
      ? "  version: " + TGoogleJSON():Get( hJson, "version", "" )
   ELSE
      ? "[ERROR] No se pudo decodificar"
   ENDIF

RETURN NIL

//----------------------------------------------------------------------------//
// TEST: GEMINI
//----------------------------------------------------------------------------//
STATIC FUNCTION TestGemini( oGoogle )

   LOCAL cPrompt, cResult

   ? ""
   ? "--- TEST GEMINI ---"
   ? "Modelo: " + oGoogle:cModelGemini

   cPrompt := INPUTBOX( "Ingrese un prompt:", "Gemini Test", "Di hola en español" )

   IF !Empty( cPrompt )
      ? "Prompt: " + cPrompt
      ? "Generando respuesta..."

      cResult := oGoogle:Gemini():GenerateText( cPrompt )

      IF !Empty( cResult )
         ? "[OK] Respuesta:"
         ? cResult
      ELSE
         ? "[ERROR] Sin respuesta"
      ENDIF
   ENDIF

RETURN NIL

//----------------------------------------------------------------------------//
// TEST: CALENDAR
//----------------------------------------------------------------------------//
STATIC FUNCTION TestCalendar( oGoogle )

   LOCAL aEvents, oEvent, n := 0

   ? ""
   ? "--- TEST CALENDAR ---"

   ? "Obteniendo eventos de hoy a 7 días..."

   aEvents := oGoogle:Calendar():GetEvents( DATE(), DATE() + 7 )

   ? "Eventos encontrados: " + AllTrim( Str( Len( aEvents ) ) )

   FOR EACH oEvent IN aEvents
      n++
      ? "  " + AllTrim( Str( n ) ) + ". " + oEvent:cSummary
      ? "     Fecha: " + DTOC( oEvent:dStart ) + " " + oEvent:cTimeStart
      IF !Empty( oEvent:cLocation )
         ? "     Lugar: " + oEvent:cLocation
      ENDIF
   NEXT

   IF Len( aEvents ) == 0
      ? "  No hay eventos en el rango seleccionado"
   ENDIF

RETURN NIL

//----------------------------------------------------------------------------//
// TEST: DRIVE
//----------------------------------------------------------------------------//
STATIC FUNCTION TestDrive( oGoogle )

   LOCAL aFiles, hFile, n := 0

   ? ""
   ? "--- TEST DRIVE ---"

   ? "Buscando archivos en Google Drive..."

   aFiles := oGoogle:Drive():GetFiles( , 10 )

   ? "Archivos encontrados: " + AllTrim( Str( Len( aFiles ) ) )

   FOR EACH hFile IN aFiles
      n++
      ? "  " + AllTrim( Str( n ) ) + ". " + hFile[ "name" ]
      ? "     Tipo: " + hFile[ "mimeType" ]
   NEXT

RETURN NIL

//----------------------------------------------------------------------------//
// TEST: TASKS
//----------------------------------------------------------------------------//
STATIC FUNCTION TestTasks( oGoogle )

   LOCAL aTasks, hTask, n := 0

   ? ""
   ? "--- TEST TASKS ---"

   ? "Obteniendo tareas..."

   aTasks := oGoogle:Tasks():GetTasks()

   ? "Tareas encontradas: " + AllTrim( Str( Len( aTasks ) ) )

   FOR EACH hTask IN aTasks
      n++
      ? "  " + AllTrim( Str( n ) ) + ". " + hTask[ "title" ]
      ? "     Estado: " + hTask[ "status" ]
   NEXT

RETURN NIL

//----------------------------------------------------------------------------//
// TEST: GMAIL
//----------------------------------------------------------------------------//
STATIC FUNCTION TestGmail( oGoogle )

   LOCAL nUnread

   ? ""
   ? "--- TEST GMAIL ---"

   nUnread := oGoogle:Gmail():GetUnreadCount()

   ? "Mensajes no leídos: " + AllTrim( Str( nUnread ) )

   IF nUnread > 0
      ? "Hay mensajes pendientes en la bandeja de entrada"
   ELSE
      ? "Bandeja de entrada limpia"
   ENDIF

RETURN NIL

//----------------------------------------------------------------------------//
// TEST: SHEETS
//----------------------------------------------------------------------------//
STATIC FUNCTION TestSheets( oGoogle )

   LOCAL cSheetId, aData

   ? ""
   ? "--- TEST SHEETS ---"

   cSheetId := INPUTBOX( "Ingrese ID de hoja de cálculo:", "Sheets Test" )

   IF !Empty( cSheetId )
      ? "Leyendo hoja: " + cSheetId

      aData := oGoogle:Sheets():ReadSheet( cSheetId, "A1:Z10" )

      ? "Filas leídas: " + AllTrim( Str( Len( aData ) ) )
   ENDIF

RETURN NIL

//----------------------------------------------------------------------------//
// TEST: CONFIG
//----------------------------------------------------------------------------//
STATIC FUNCTION TestConfig( oGoogle )

   ? ""
   ? "--- CONFIGURACIÓN ---"

   oGoogle:SaveConfig()

   ? "Configuración guardada en: " + TGOOGLE_CONFIG_FILE
   ? "  API Key:     " + If( !Empty( oGoogle:cApiKey ), "Configurada", "Pendiente" )
   ? "  Client ID:   " + If( !Empty( oGoogle:cClientId ), "Configurado", "Pendiente" )
   ? "  Cuenta:      " + oGoogle:cCuentaGmail
   ? "  Modelo:      " + oGoogle:cModelGemini

RETURN NIL

//----------------------------------------------------------------------------//
// EOF
