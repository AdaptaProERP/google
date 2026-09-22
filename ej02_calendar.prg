//----------------------------------------------------------------------------//
// ej02_calendar.prg - Ejemplo de Google Calendar API
// Crear, listar, modificar y eliminar eventos
// Compilar: harbour ej02_calendar.prg /n /iC:\fw24\include;C:\harbour\include;C:\googledrive
//----------------------------------------------------------------------------//

#include "FiveWin.ch"
#include "TGOOGLE.CH"

//----------------------------------------------------------------------------//

FUNCTION Main()

   LOCAL oGoogle, oCal, oEvent, oNuevo, oFeriado, oQuick
   LOCAL aEvents, aCals, cIdNuevo := ""
   LOCAL dHoy := DATE()
   LOCAL hCal, oEvt

   CLS

   ? "============================================================"
   ? "  EJEMPLO 02: Google Calendar API"
   ? "============================================================"
   ?

   oGoogle := TGoogle():New()

   IF !oGoogle:IsAuthenticated()
      ? "Requiere autenticacion OAuth. Ejecute ej01_google_init.prg"
      RETURN NIL
   ENDIF

   oCal := oGoogle:Calendar()

   // 1. LISTAR CALENDARIOS
   ? "--- [1] Calendarios disponibles ---"
   aCals := oCal:GetCalendars()
   FOR EACH hCal IN aCals
      ? "  * " + TGoogleJSON():Get( hCal, "summary", "" )
   NEXT
   ?

   // 2. CREAR EVENTO CON HORA
   ? "--- [2] Crear evento de reunion ---"
   oEvent := TGoogleEvent():New()
   oEvent:cSummary     := "Reunion Adaptapro - Ecosistema Google"
   oEvent:cDescription := "Prueba de integracion Calendar API v3"
   oEvent:cLocation    := "Sala de reuniones, Caracas"
   oEvent:SetStart( dHoy, "14:00:00" )
   oEvent:SetEnd( dHoy, "15:00:00" )

   oNuevo := oCal:CreateEvent( oEvent )
   IF oNuevo != NIL
      cIdNuevo := oNuevo:cId
      ? "  [OK] Evento creado: " + oNuevo:cSummary
      ? "  ID: " + cIdNuevo
   ENDIF
   ?

   // 3. CREAR EVENTO TODO EL DIA
   ? "--- [3] Crear evento todo el dia ---"
   oEvent := TGoogleEvent():New()
   oEvent:cSummary := "Feriado - Adaptapro"
   oEvent:SetAllDay( dHoy + 7 )

   oFeriado := oCal:CreateEvent( oEvent )
   IF oFeriado != NIL
      ? "  [OK] Evento all-day: " + oFeriado:cSummary
   ENDIF
   ?

   // 4. LISTAR EVENTOS DE LA SEMANA
   ? "--- [4] Eventos de esta semana ---"
   aEvents := oCal:GetEvents( dHoy, dHoy + 7, 10 )
   FOR EACH oEvt IN aEvents
      ? "  " + DTOC( oEvt:dStart ) + " " + oEvt:cTimeStart + ;
        " - " + oEvt:cSummary
   NEXT
   ? "  Total: " + ALLTRIM( STR( LEN( aEvents ) ) ) + " eventos"
   ?

   // 5. MODIFICAR EVENTO
   IF !EMPTY( cIdNuevo )
      ? "--- [5] Modificar evento ---"
      oEvent:cSummary     := "Reunion Adaptapro - ACTUALIZADA"
      oEvent:cDescription := "Descripcion actualizada via API"
      oEvent:SetEnd( dHoy, "15:30:00" )

      oNuevo := oCal:UpdateEvent( cIdNuevo, oEvent )
      IF oNuevo != NIL
         ? "  [OK] Actualizado: " + oNuevo:cSummary
      ENDIF
   ENDIF
   ?

   // 6. QUICK ADD
   ? "--- [6] Quick Add ---"
   oQuick := oCal:QuickAdd( "Reunion con Juan manana a las 10am" )
   IF oQuick != NIL
      ? "  [OK] " + oQuick:cSummary
   ENDIF
   ?

   // 7. ELIMINAR
   ? "--- [7] Limpiar ---"
   IF !EMPTY( cIdNuevo )
      oCal:DeleteEvent( cIdNuevo )
      ? "  Evento principal eliminado"
   ENDIF
   IF oFeriado != NIL
      oCal:DeleteEvent( oFeriado:cId )
      ? "  Feriado eliminado"
   ENDIF
   IF oQuick != NIL
      oCal:DeleteEvent( oQuick:cId )
      ? "  Quick add eliminado"
   ENDIF
   ?

   ? "============================================================"
   ? "  Ejemplo Calendar completado"
   ? "============================================================"

   oGoogle:End()

RETURN NIL

//----------------------------------------------------------------------------//
// EOF
