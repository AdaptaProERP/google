//----------------------------------------------------------------------------//
// TGoogleGmail - Gmail API v1
// Envío y lectura de correos
// Compatible: xHarbour + Harbour 3.2 + FiveWin 2.4
//----------------------------------------------------------------------------//

#include "FiveWin.ch"

#define GMAIL_API_BASE "https://www.googleapis.com/gmail/v1"

//----------------------------------------------------------------------------//

CLASS TGoogleGmail

   DATA   oGoogle           // Referencia a TGoogle padre
   DATA   cUserId           // "me" por defecto

   METHOD New( oGoogle )    CONSTRUCTOR
   METHOD End()

   // Mensajes
   METHOD GetMessages( cQuery, nMax, cPageToken )
   METHOD GetMessage( cMessageId )
   METHOD SendMessage( cTo, cSubject, cBody, cFrom )
   METHOD DeleteMessage( cMessageId )

   // Labels
   METHOD GetLabels()
   METHOD GetUnreadCount()

   // Helpers
   METHOD CreateMimeMessage( cTo, cFrom, cSubject, cBody )
   METHOD Base64UrlEncode( cText )
   METHOD ParseMessage( hJson )

ENDCLASS

//----------------------------------------------------------------------------//

METHOD New( oGoogle ) CLASS TGoogleGmail

   ::oGoogle := oGoogle
   ::cUserId := "me"

return Self

//----------------------------------------------------------------------------//

METHOD End() CLASS TGoogleGmail

   ::oGoogle := NIL

return nil

//----------------------------------------------------------------------------//

METHOD GetMessages( cQuery, nMax, cPageToken ) CLASS TGoogleGmail

   local cUrl, cResponse, hJson, aMessages := {}

   DEFAULT nMax := 50

   cUrl := GMAIL_API_BASE + "/users/" + ::cUserId + "/messages?" + ;
           "maxResults=" + AllTrim( Str( nMax ) )

   if !Empty( cQuery )
      cUrl += "&q=" + HB_URLENCODE( cQuery )
   endif

   if !Empty( cPageToken )
      cUrl += "&pageToken=" + cPageToken
   endif

   cResponse := ::oGoogle:HttpRequest( "GET", cUrl )
   hJson     := TGoogleJSON():Decode( cResponse )

   if hJson != NIL .AND. TGoogleJSON():HasKey( hJson, "messages" )
      AEVAL( hJson["messages"], {|h| AADD( aMessages, h ) } )
   endif

return aMessages

//----------------------------------------------------------------------------//

METHOD GetMessage( cMessageId ) CLASS TGoogleGmail

   local cUrl, cResponse, hJson

   cUrl := GMAIL_API_BASE + "/users/" + ::cUserId + "/messages/" + cMessageId

   cResponse := ::oGoogle:HttpRequest( "GET", cUrl )
   hJson     := TGoogleJSON():Decode( cResponse )

return ::ParseMessage( hJson )

//----------------------------------------------------------------------------//

METHOD SendMessage( cTo, cSubject, cBody, cFrom ) CLASS TGoogleGmail

   local cUrl, cBodyReq, cResponse, hJson
   local cMime

   DEFAULT cFrom := ::oGoogle:cCuentaGmail

   cMime := ::CreateMimeMessage( cTo, cFrom, cSubject, cBody )

   cUrl    := GMAIL_API_BASE + "/users/" + ::cUserId + "/messages/send"
   cBodyReq := '{"raw":"' + ::Base64UrlEncode( cMime ) + '"}'

   cResponse := ::oGoogle:HttpRequest( "POST", cUrl, cBodyReq )
   hJson     := TGoogleJSON():Decode( cResponse )

return ( hJson != NIL )

//----------------------------------------------------------------------------//

METHOD DeleteMessage( cMessageId ) CLASS TGoogleGmail

   local cUrl

   cUrl := GMAIL_API_BASE + "/users/" + ::cUserId + "/messages/" + cMessageId
   ::oGoogle:HttpRequest( "DELETE", cUrl )

return ::oGoogle:oHttp:nStatusCode == 204

//----------------------------------------------------------------------------//

METHOD GetLabels() CLASS TGoogleGmail

   local cUrl, cResponse, hJson

   cUrl := GMAIL_API_BASE + "/users/" + ::cUserId + "/labels"

   cResponse := ::oGoogle:HttpRequest( "GET", cUrl )
   hJson     := TGoogleJSON():Decode( cResponse )

   if hJson != NIL .AND. TGoogleJSON():HasKey( hJson, "labels" )
      return hJson["labels"]
   endif

return {}

//----------------------------------------------------------------------------//

METHOD GetUnreadCount() CLASS TGoogleGmail

   local aLabels, hLabel, nCount := 0

   aLabels := ::GetLabels()

   for each hLabel in aLabels
      if TGoogleJSON():Get( hLabel, "name", "" ) == "INBOX"
         nCount := TGoogleJSON():Get( hLabel, "messagesUnread", 0 )
         exit
      endif
   next

return nCount

//----------------------------------------------------------------------------//

METHOD CreateMimeMessage( cTo, cFrom, cSubject, cBody ) CLASS TGoogleGmail

   local cMime := ""

   cMime += "From: " + cFrom + CRLF
   cMime += "To: " + cTo + CRLF
   cMime += "Subject: " + cSubject + CRLF
   cMime += "Content-Type: text/plain; charset=UTF-8" + CRLF
   cMime += CRLF
   cMime += cBody

return cMime

//----------------------------------------------------------------------------//

METHOD Base64UrlEncode( cText ) CLASS TGoogleGmail

   // Base64 URL-safe encoding para Gmail API
   local cResult := HB_Base64Encode( cText )
   cResult := StrTran( cResult, "+", "-" )
   cResult := StrTran( cResult, "/", "_" )
   cResult := StrTran( cResult, "=", "" )

return cResult

//----------------------------------------------------------------------------//

METHOD ParseMessage( hJson ) CLASS TGoogleGmail

   local hMsg := {=>}
   local hPayload, aHeaders, hHeader, cName, cValue

   if hJson != NIL
      hMsg[ "id"       ] := TGoogleJSON():Get( hJson, "id", "" )
      hMsg[ "threadId" ] := TGoogleJSON():Get( hJson, "threadId", "" )
      hMsg[ "labelIds" ] := TGoogleJSON():Get( hJson, "labelIds", {} )
      hMsg[ "snippet"  ] := TGoogleJSON():Get( hJson, "snippet", "" )

       hPayload := TGoogleJSON():Get( hJson, "payload", NIL )
       if hPayload != NIL
          aHeaders := TGoogleJSON():Get( hPayload, "headers", {} )
          for each hHeader in aHeaders
             cName  := TGoogleJSON():Get( hHeader, "name", "" )
             cValue := TGoogleJSON():Get( hHeader, "value", "" )
            do case
               case Upper( cName ) == "SUBJECT"
                  hMsg[ "subject" ] := cValue
               case Upper( cName ) == "FROM"
                  hMsg[ "from" ] := cValue
               case Upper( cName ) == "TO"
                  hMsg[ "to" ] := cValue
               case Upper( cName ) == "DATE"
                  hMsg[ "date" ] := cValue
            endcase
         next
      endif
   endif

return hMsg

//----------------------------------------------------------------------------//
// EOF
