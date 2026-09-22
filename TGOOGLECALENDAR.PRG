//----------------------------------------------------------------------------//
// TGoogleCalendar - Google Calendar API v3
// CRUD de eventos y calendarios
// Compatible: xHarbour + Harbour 3.2 + FiveWin 2.4
//----------------------------------------------------------------------------//

#include "FiveWin.ch"

#define CALENDAR_API_BASE "https://www.googleapis.com/calendar/v3"

//----------------------------------------------------------------------------//

CLASS TGoogleCalendar

   DATA   oGoogle           // Referencia a TGoogle padre
   DATA   cCalendarId       // ID calendario (default: "primary")

   METHOD New( oGoogle )    CONSTRUCTOR
   METHOD End()

   // Eventos - CRUD
   METHOD GetEvents( dFrom, dTo, nMaxResults, cPageToken )
   METHOD GetEvent( cEventId )
   METHOD CreateEvent( oEvent )
   METHOD UpdateEvent( cEventId, oEvent )
   METHOD DeleteEvent( cEventId )
   METHOD QuickAdd( cText )

   // Calendarios
   METHOD GetCalendars()
   METHOD GetCalendarInfo()

   // Helpers
   METHOD ToRFC3339( dDate, cTime )
   METHOD ParseEvent( hJson )
   METHOD EventToJson( oEvent )
   METHOD ParseRFC3339Date( cDateTime )
   METHOD ParseRFC3339Time( cDateTime )

ENDCLASS

//----------------------------------------------------------------------------//

METHOD New( oGoogle ) CLASS TGoogleCalendar

   ::oGoogle     := oGoogle
   ::cCalendarId := "primary"

return Self

//----------------------------------------------------------------------------//

METHOD End() CLASS TGoogleCalendar

   ::oGoogle := NIL

return nil

//----------------------------------------------------------------------------//
// EVENTOS
//----------------------------------------------------------------------------//

METHOD GetEvents( dFrom, dTo, nMaxResults, cPageToken ) CLASS TGoogleCalendar

   local cUrl, cResponse, hJson, aEvents := {}
   local cTimeMin, cTimeMax

   DEFAULT dFrom := Date(), dTo := Date() + 7, nMaxResults := 50

   cTimeMin := ::ToRFC3339( dFrom, "00:00:00" )
   cTimeMax := ::ToRFC3339( dTo,   "23:59:59" )

   cUrl := CALENDAR_API_BASE + "/calendars/" + ::cCalendarId + "/events?" + ;
           "timeMin=" + cTimeMin + ;
           "&timeMax=" + cTimeMax + ;
           "&maxResults=" + AllTrim( Str( nMaxResults ) ) + ;
           "&singleEvents=true&orderBy=startTime"

   if !Empty( cPageToken )
      cUrl += "&pageToken=" + cPageToken
   endif

   cResponse := ::oGoogle:HttpRequest( "GET", cUrl )
   hJson     := TGoogleJSON():Decode( cResponse )

   if hJson != NIL .AND. TGoogleJSON():HasKey( hJson, "items" )
      AEVAL( hJson["items"], {|h| AADD( aEvents, ::ParseEvent( h ) ) } )
   endif

return aEvents

//----------------------------------------------------------------------------//

METHOD GetEvent( cEventId ) CLASS TGoogleCalendar

   local cUrl, cResponse, hJson

   cUrl := CALENDAR_API_BASE + "/calendars/" + ::cCalendarId + ;
           "/events/" + cEventId

   cResponse := ::oGoogle:HttpRequest( "GET", cUrl )
   hJson     := TGoogleJSON():Decode( cResponse )

   if hJson != NIL
      return ::ParseEvent( hJson )
   endif

return NIL

//----------------------------------------------------------------------------//

METHOD CreateEvent( oEvent ) CLASS TGoogleCalendar

   local cUrl, cBody, cResponse, hJson

   cUrl  := CALENDAR_API_BASE + "/calendars/" + ::cCalendarId + "/events"
   cBody := ::EventToJson( oEvent )

   cResponse := ::oGoogle:HttpRequest( "POST", cUrl, cBody )
   hJson     := TGoogleJSON():Decode( cResponse )

   if hJson != NIL .AND. TGoogleJSON():HasKey( hJson, "id" )
      return ::ParseEvent( hJson )
   endif

return NIL

//----------------------------------------------------------------------------//

METHOD UpdateEvent( cEventId, oEvent ) CLASS TGoogleCalendar

   local cUrl, cBody, cResponse, hJson

   cUrl  := CALENDAR_API_BASE + "/calendars/" + ::cCalendarId + ;
            "/events/" + cEventId
   cBody := ::EventToJson( oEvent )

   cResponse := ::oGoogle:HttpRequest( "PUT", cUrl, cBody )
   hJson     := TGoogleJSON():Decode( cResponse )

   if hJson != NIL .AND. TGoogleJSON():HasKey( hJson, "id" )
      return ::ParseEvent( hJson )
   endif

return NIL

//----------------------------------------------------------------------------//

METHOD DeleteEvent( cEventId ) CLASS TGoogleCalendar

   local cUrl, cResponse

   cUrl := CALENDAR_API_BASE + "/calendars/" + ::cCalendarId + ;
           "/events/" + cEventId

   cResponse := ::oGoogle:HttpRequest( "DELETE", cUrl )

return ::oGoogle:oHttp:nStatusCode == 204

//----------------------------------------------------------------------------//

METHOD QuickAdd( cText ) CLASS TGoogleCalendar

   local cUrl, cBody, cResponse, hJson

   cUrl  := CALENDAR_API_BASE + "/calendars/" + ::cCalendarId + "/events/quickAdd"
   cBody := '{"text":"' + cText + '"}'

   cResponse := ::oGoogle:HttpRequest( "POST", cUrl, cBody )
   hJson     := TGoogleJSON():Decode( cResponse )

   if hJson != NIL .AND. TGoogleJSON():HasKey( hJson, "id" )
      return ::ParseEvent( hJson )
   endif

return NIL

//----------------------------------------------------------------------------//
// CALENDARIOS
//----------------------------------------------------------------------------//

METHOD GetCalendars() CLASS TGoogleCalendar

   local cUrl, cResponse, hJson, aCalendars := {}

   cUrl := CALENDAR_API_BASE + "/users/me/calendarList"

   cResponse := ::oGoogle:HttpRequest( "GET", cUrl )
   hJson     := TGoogleJSON():Decode( cResponse )

   if hJson != NIL .AND. TGoogleJSON():HasKey( hJson, "items" )
      AEVAL( hJson["items"], {|h| AADD( aCalendars, h ) } )
   endif

return aCalendars

//----------------------------------------------------------------------------//

METHOD GetCalendarInfo() CLASS TGoogleCalendar

   local cUrl, cResponse, hJson

   cUrl := CALENDAR_API_BASE + "/calendars/" + ::cCalendarId

   cResponse := ::oGoogle:HttpRequest( "GET", cUrl )
   hJson     := TGoogleJSON():Decode( cResponse )

return hJson

//----------------------------------------------------------------------------//
// HELPERS
//----------------------------------------------------------------------------//

METHOD ToRFC3339( dDate, cTime ) CLASS TGoogleCalendar

   local cResult

   DEFAULT cTime := "00:00:00"

   // Formato: 2026-09-21T10:00:00-04:00 (Venezuela UTC-4)
   cResult := STR( YEAR( dDate ), 4 ) + "-" + ;
              PADL( MONTH( dDate ), 2, "0" ) + "-" + ;
              PADL( DAY( dDate ), 2, "0" ) + "T" + cTime + "-04:00"

return cResult

//----------------------------------------------------------------------------//

METHOD ParseEvent( hJson ) CLASS TGoogleCalendar

   local oEvent := TGoogleEvent():New()
   local hStart, hEnd, aAttendees

   if hJson == NIL
      return oEvent
   endif

   oEvent:cId          := TGoogleJSON():Get( hJson, "id", "" )
   oEvent:cSummary     := TGoogleJSON():Get( hJson, "summary", "" )
   oEvent:cDescription := TGoogleJSON():Get( hJson, "description", "" )
   oEvent:cLocation    := TGoogleJSON():Get( hJson, "location", "" )
   oEvent:cStatus      := TGoogleJSON():Get( hJson, "status", "" )
   oEvent:cHtmlLink    := TGoogleJSON():Get( hJson, "htmlLink", "" )
   oEvent:cICalUID     := TGoogleJSON():Get( hJson, "iCalUID", "" )

   // Fecha/hora inicio
   hStart := TGoogleJSON():Get( hJson, "start", NIL )
   if hStart != NIL
      oEvent:cDateTimeStart := TGoogleJSON():Get( hStart, "dateTime", "" )
      oEvent:cDateStart     := TGoogleJSON():Get( hStart, "date", "" )
      oEvent:lAllDay        := !Empty( oEvent:cDateStart )
      if !oEvent:lAllDay .AND. !Empty( oEvent:cDateTimeStart )
         oEvent:dStart     := ::ParseRFC3339Date( oEvent:cDateTimeStart )
         oEvent:cTimeStart := ::ParseRFC3339Time( oEvent:cDateTimeStart )
      endif
   endif

   // Fecha/hora fin
   hEnd := TGoogleJSON():Get( hJson, "end", NIL )
   if hEnd != NIL
      oEvent:cDateTimeEnd := TGoogleJSON():Get( hEnd, "dateTime", "" )
      oEvent:cDateEnd     := TGoogleJSON():Get( hEnd, "date", "" )
      if !oEvent:lAllDay .AND. !Empty( oEvent:cDateTimeEnd )
         oEvent:dEnd     := ::ParseRFC3339Date( oEvent:cDateTimeEnd )
         oEvent:cTimeEnd := ::ParseRFC3339Time( oEvent:cDateTimeEnd )
      endif
   endif

   // Asistentes
   aAttendees := TGoogleJSON():Get( hJson, "attendees", {} )
   if ValType( aAttendees ) == "A"
      AEVAL( aAttendees, {|h| ;
         oEvent:cAttendees += TGoogleJSON():Get( h, "email", "" ) + ";" } )
   endif

return oEvent

//----------------------------------------------------------------------------//

METHOD EventToJson( oEvent ) CLASS TGoogleCalendar

   local cJson := "{"
   local cSep  := ""

   if !Empty( oEvent:cSummary )
      cJson += '"summary":"' + oEvent:cSummary + '"'
      cSep := ","
   endif

   if !Empty( oEvent:cDescription )
      cJson += cSep + '"description":"' + oEvent:cDescription + '"'
      cSep := ","
   endif

   if !Empty( oEvent:cLocation )
      cJson += cSep + '"location":"' + oEvent:cLocation + '"'
      cSep := ","
   endif

   // Start
   cJson += cSep + '"start":{'
   if oEvent:lAllDay
      cJson += '"date":"' + STR(YEAR(oEvent:dStart),4) + "-" + ;
               PADL(MONTH(oEvent:dStart),2,"0") + "-" + ;
               PADL(DAY(oEvent:dStart),2,"0") + '"'
   else
      cJson += '"dateTime":"' + ::ToRFC3339( oEvent:dStart, oEvent:cTimeStart ) + '"'
   endif
   cJson += '}'
   cSep := ","

   // End
   cJson += cSep + '"end":{'
   if oEvent:lAllDay
      cJson += '"date":"' + STR(YEAR(oEvent:dEnd),4) + "-" + ;
               PADL(MONTH(oEvent:dEnd),2,"0") + "-" + ;
               PADL(DAY(oEvent:dEnd),2,"0") + '"'
   else
      cJson += '"dateTime":"' + ::ToRFC3339( oEvent:dEnd, oEvent:cTimeEnd ) + '"'
   endif
   cJson += '}'

   cJson += "}"

return cJson

//----------------------------------------------------------------------------//

METHOD ParseRFC3339Date( cDateTime ) CLASS TGoogleCalendar

   // "2026-09-21T10:00:00-04:00" -> CTOD("21/09/2026")
   local dResult := CTOD("")
   local cDate

   if !Empty( cDateTime )
      cDate := LEFT( cDateTime, 10 )  // "2026-09-21"
      dResult := CTOD( SUBSTR( cDate, 9, 2 ) + "/" + ;
                       SUBSTR( cDate, 6, 2 ) + "/" + ;
                       LEFT( cDate, 4 ) )
   endif

return dResult

//----------------------------------------------------------------------------//

METHOD ParseRFC3339Time( cDateTime ) CLASS TGoogleCalendar

   // "2026-09-21T10:00:00-04:00" -> "10:00"
   local cResult := ""

   if !Empty( cDateTime ) .AND. AT( "T", cDateTime ) > 0
      cResult := SUBSTR( cDateTime, AT( "T", cDateTime ) + 1, 5 )
   endif

return cResult

//----------------------------------------------------------------------------//
// EOF
