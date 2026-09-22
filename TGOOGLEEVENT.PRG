//----------------------------------------------------------------------------//
// TGoogleEvent - Modelo de Evento para Google Calendar
// Compatible: xHarbour + Harbour 3.2 + FiveWin 2.4
//----------------------------------------------------------------------------//

#include "FiveWin.ch"

//----------------------------------------------------------------------------//

CLASS TGoogleEvent

   // Identificación
   DATA   cId                // ID del evento en Google
   DATA   cSummary           // Título del evento
   DATA   cDescription       // Descripción
   DATA   cLocation          // Ubicación

   // Fechas/horas
   DATA   dStart             // Fecha inicio
   DATA   cTimeStart         // Hora inicio (HH:MM:SS)
   DATA   dEnd               // Fecha fin
   DATA   cTimeEnd           // Hora fin (HH:MM:SS)
   DATA   lAllDay            // Todo el día

   // Formato crudo RFC3339
   DATA   cDateTimeStart     // Raw de Google
   DATA   cDateTimeEnd       // Raw de Google
   DATA   cDateStart         // Solo fecha (all-day)
   DATA   cDateEnd           // Solo fecha (all-day)

   // Otros
   DATA   cStatus            // confirmed, tentative, cancelled
   DATA   cHtmlLink          // URL del evento
   DATA   cICalUID           // UID iCal
   DATA   cAttendees         // Asistentes (separados por ;)
   DATA   cRecurrence        // Reglas RRULE
   DATA   nReminderMinutes   // Minutos antes del recordatorio

   METHOD New()             CONSTRUCTOR

   // Utilidades
   METHOD SetStart( dDate, cTime )
   METHOD SetEnd( dDate, cTime )
   METHOD SetAllDay( dDate )
   METHOD ToString()

ENDCLASS

//----------------------------------------------------------------------------//

METHOD New() CLASS TGoogleEvent

   ::cId            := ""
   ::cSummary       := ""
   ::cDescription   := ""
   ::cLocation      := ""
   ::dStart         := DATE()
   ::cTimeStart     := "09:00:00"
   ::dEnd           := DATE()
   ::cTimeEnd       := "10:00:00"
   ::lAllDay        := .F.
   ::cDateTimeStart := ""
   ::cDateTimeEnd   := ""
   ::cDateStart     := ""
   ::cDateEnd       := ""
   ::cStatus        := ""
   ::cHtmlLink      := ""
   ::cICalUID       := ""
   ::cAttendees     := ""
   ::cRecurrence    := ""
   ::nReminderMinutes := 30

return Self

//----------------------------------------------------------------------------//

METHOD SetStart( dDate, cTime ) CLASS TGoogleEvent

   DEFAULT cTime := "09:00:00"

   ::dStart     := dDate
   ::cTimeStart := cTime
   ::lAllDay    := .F.

return nil

//----------------------------------------------------------------------------//

METHOD SetEnd( dDate, cTime ) CLASS TGoogleEvent

   DEFAULT cTime := "10:00:00"

   ::dEnd     := dDate
   ::cTimeEnd := cTime
   ::lAllDay  := .F.

return nil

//----------------------------------------------------------------------------//

METHOD SetAllDay( dDate ) CLASS TGoogleEvent

   ::dStart     := dDate
   ::dEnd       := dDate
   ::lAllDay    := .T.
   ::cTimeStart := ""
   ::cTimeEnd   := ""

return nil

//----------------------------------------------------------------------------//

METHOD ToString() CLASS TGoogleEvent

   local cResult := ""

   cResult += "ID: "      + ::cId + CRLF
   cResult += "Title: "   + ::cSummary + CRLF
   cResult += "Start: "   + DTOC( ::dStart ) + " " + ::cTimeStart + CRLF
   cResult += "End: "     + DTOC( ::dEnd ) + " " + ::cTimeEnd + CRLF
   cResult += "Location: " + ::cLocation + CRLF
   cResult += "AllDay: "  + If( ::lAllDay, "Yes", "No" ) + CRLF

return cResult

//----------------------------------------------------------------------------//
// EOF
