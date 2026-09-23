//----------------------------------------------------------------------------//
// TGoogleTasks - Google Tasks API v1
// Gestión de tareas y listas
// Compatible: xHarbour + Harbour 3.2 + FiveWin 2.4
//----------------------------------------------------------------------------//

#include "FiveWin.ch"

#define TASKS_API_BASE "https://www.googleapis.com/tasks/v1"

//----------------------------------------------------------------------------//

CLASS TGoogleTasks

   DATA   oGoogle           // Referencia a TGoogle padre
   DATA   cTaskList         // ID lista por defecto ("@default")

   METHOD New( oGoogle )    CONSTRUCTOR
   METHOD End()

   // Tareas
   METHOD GetTasks( cTaskList, nMax, cPageToken )
   METHOD GetTask( cTaskId, cTaskList )
   METHOD CreateTask( oTask, cTaskList )
   METHOD UpdateTask( cTaskId, oTask, cTaskList )
   METHOD DeleteTask( cTaskId, cTaskList )
   METHOD CompleteTask( cTaskId, cTaskList )

   // Listas
   METHOD GetTaskLists()
   METHOD CreateTaskList( cTitle )
   METHOD DeleteTaskList( cTaskListId )

   // Helpers
   METHOD ParseTask( hJson )

ENDCLASS

//----------------------------------------------------------------------------//

METHOD New( oGoogle ) CLASS TGoogleTasks

   ::oGoogle   := oGoogle
   ::cTaskList := "@default"

return Self

//----------------------------------------------------------------------------//

METHOD End() CLASS TGoogleTasks

   ::oGoogle := NIL

return nil

//----------------------------------------------------------------------------//

METHOD GetTasks( cTaskList, nMax, cPageToken ) CLASS TGoogleTasks

   local cUrl, cResponse, hJson, aTasks := {}

   DEFAULT cTaskList := ::cTaskList, nMax := 100

   cUrl := TASKS_API_BASE + "/lists/" + cTaskList + "/tasks?" + ;
           "maxResults=" + AllTrim( Str( nMax ) )

   if !Empty( cPageToken )
      cUrl += "&pageToken=" + cPageToken
   endif

   cResponse := ::oGoogle:HttpRequest( "GET", cUrl )
   hJson     := TGoogleJSON():Decode( cResponse )

   if hJson != NIL .AND. TGoogleJSON():HasKey( hJson, "items" )
      AEVAL( hJson["items"], {|h| AADD( aTasks, ::ParseTask( h ) ) } )
   endif

return aTasks

//----------------------------------------------------------------------------//

METHOD GetTask( cTaskId, cTaskList ) CLASS TGoogleTasks

   local cUrl, cResponse, hJson

   DEFAULT cTaskList := ::cTaskList

   cUrl := TASKS_API_BASE + "/lists/" + cTaskList + "/tasks/" + cTaskId

   cResponse := ::oGoogle:HttpRequest( "GET", cUrl )
   hJson     := TGoogleJSON():Decode( cResponse )

   if hJson != NIL
      return ::ParseTask( hJson )
   endif

return NIL

//----------------------------------------------------------------------------//

METHOD CreateTask( oTask, cTaskList ) CLASS TGoogleTasks

   local cUrl, cBody, cResponse, hJson

   DEFAULT cTaskList := ::cTaskList

   cUrl := TASKS_API_BASE + "/lists/" + cTaskList + "/tasks"

   cBody := '{"title":"' + oTask:cTitle + '"'

   if !Empty( oTask:cNotes )
      cBody += ',"notes":"' + oTask:cNotes + '"'
   endif

   if !Empty( oTask:cDue )
      cBody += ',"due":"' + oTask:cDue + '"'
   endif

   cBody += "}"

   cResponse := ::oGoogle:HttpRequest( "POST", cUrl, cBody )
   hJson     := TGoogleJSON():Decode( cResponse )

   if hJson != NIL .AND. TGoogleJSON():HasKey( hJson, "id" )
      return ::ParseTask( hJson )
   endif

return NIL

//----------------------------------------------------------------------------//

METHOD UpdateTask( cTaskId, oTask, cTaskList ) CLASS TGoogleTasks

   local cUrl, cBody, cResponse, hJson

   DEFAULT cTaskList := ::cTaskList

   cUrl  := TASKS_API_BASE + "/lists/" + cTaskList + "/tasks/" + cTaskId
   cBody := '{"title":"' + oTask:cTitle + '"'

   if !Empty( oTask:cNotes )
      cBody += ',"notes":"' + oTask:cNotes + '"'
   endif

   cBody += "}"

   cResponse := ::oGoogle:HttpRequest( "PUT", cUrl, cBody )
   hJson     := TGoogleJSON():Decode( cResponse )

   if hJson != NIL .AND. TGoogleJSON():HasKey( hJson, "id" )
      return ::ParseTask( hJson )
   endif

return NIL

//----------------------------------------------------------------------------//

METHOD DeleteTask( cTaskId, cTaskList ) CLASS TGoogleTasks

   local cUrl

   DEFAULT cTaskList := ::cTaskList

   cUrl := TASKS_API_BASE + "/lists/" + cTaskList + "/tasks/" + cTaskId
   ::oGoogle:HttpRequest( "DELETE", cUrl )

return ::oGoogle:oHttp:nStatusCode == 204

//----------------------------------------------------------------------------//

METHOD CompleteTask( cTaskId, cTaskList ) CLASS TGoogleTasks

   local cUrl, cBody

   DEFAULT cTaskList := ::cTaskList

   cUrl  := TASKS_API_BASE + "/lists/" + cTaskList + "/tasks/" + cTaskId
   cBody := '{"status":"completed"}'

   ::oGoogle:HttpRequest( "PATCH", cUrl, cBody )

return ::oGoogle:oHttp:nStatusCode == 200

//----------------------------------------------------------------------------//

METHOD GetTaskLists() CLASS TGoogleTasks

   local cUrl, cResponse, hJson, aLists := {}

   cUrl := TASKS_API_BASE + "/users/@me/lists"

   cResponse := ::oGoogle:HttpRequest( "GET", cUrl )
   hJson     := TGoogleJSON():Decode( cResponse )

   if hJson != NIL .AND. TGoogleJSON():HasKey( hJson, "items" )
      AEVAL( hJson["items"], {|h| AADD( aLists, h ) } )
   endif

return aLists

//----------------------------------------------------------------------------//

METHOD CreateTaskList( cTitle ) CLASS TGoogleTasks

   local cUrl, cBody, cResponse, hJson

   cUrl  := TASKS_API_BASE + "/users/@me/lists"
   cBody := '{"title":"' + cTitle + '"}'

   cResponse := ::oGoogle:HttpRequest( "POST", cUrl, cBody )
   hJson     := TGoogleJSON():Decode( cResponse )

return hJson

//----------------------------------------------------------------------------//

METHOD DeleteTaskList( cTaskListId ) CLASS TGoogleTasks

   local cUrl

   cUrl := TASKS_API_BASE + "/users/@me/lists/" + cTaskListId
   ::oGoogle:HttpRequest( "DELETE", cUrl )

return ::oGoogle:oHttp:nStatusCode == 204

//----------------------------------------------------------------------------//

METHOD ParseTask( hJson ) CLASS TGoogleTasks

   local hTask := {}

   if hJson != NIL
      TGoogleJSON():Set( hTask, "id", TGoogleJSON():Get( hJson, "id", "" ) )
      TGoogleJSON():Set( hTask, "title", TGoogleJSON():Get( hJson, "title", "" ) )
      TGoogleJSON():Set( hTask, "notes", TGoogleJSON():Get( hJson, "notes", "" ) )
      TGoogleJSON():Set( hTask, "status", TGoogleJSON():Get( hJson, "status", "needsAction" ) )
      TGoogleJSON():Set( hTask, "due", TGoogleJSON():Get( hJson, "due", "" ) )
      TGoogleJSON():Set( hTask, "updated", TGoogleJSON():Get( hJson, "updated", "" ) )
      TGoogleJSON():Set( hTask, "position", TGoogleJSON():Get( hJson, "position", "" ) )
      TGoogleJSON():Set( hTask, "completed", TGoogleJSON():Get( hJson, "completed", "" ) )
   endif

return hTask

//----------------------------------------------------------------------------//
// EOF
