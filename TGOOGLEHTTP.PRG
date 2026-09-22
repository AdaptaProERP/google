//----------------------------------------------------------------------------//
// TGoogleHTTP - Cliente HTTP para Google APIs via WinHTTP OLE
// Patron: CreateObject("WINHTTP.WinHttpRequest.5.1")
// Compatible: Harbour 3.2 + FiveWin 2.4
// Cuenta: jnadaptapro@gmail.com
//----------------------------------------------------------------------------//

#include "FiveWin.ch"

//----------------------------------------------------------------------------//

CLASS TGoogleHTTP

   DATA   oOle
   DATA   cLastError
   DATA   nStatusCode
   DATA   cResponseText
   DATA   nTimeout

   METHOD New()             CONSTRUCTOR
   METHOD End()
   METHOD Get( cUrl, aHeaders )
   METHOD Post( cUrl, cBody, aHeaders )
   METHOD Put( cUrl, cBody, aHeaders )
   METHOD Patch( cUrl, cBody, aHeaders )
   METHOD Delete( cUrl, aHeaders )
   METHOD CreateOle()

ENDCLASS

//----------------------------------------------------------------------------//

METHOD New() CLASS TGoogleHTTP

   ::cLastError    := ""
   ::nStatusCode   := 0
   ::cResponseText := ""
   ::nTimeout      := 30
   ::CreateOle()

return Self

//----------------------------------------------------------------------------//

METHOD End() CLASS TGoogleHTTP

   ::oOle := NIL

return nil

//----------------------------------------------------------------------------//

METHOD CreateOle() CLASS TGoogleHTTP

   BEGIN SEQUENCE
      ::oOle := CreateObject( "WINHTTP.WinHttpRequest.5.1" )
   RECOVER
      BEGIN SEQUENCE
         ::oOle := CreateObject( "MSXML2.ServerXMLHTTP.6.0" )
      RECOVER
         BEGIN SEQUENCE
            ::oOle := CreateObject( "Microsoft.XMLHTTP" )
         RECOVER
            ::cLastError := "No se pudo crear objeto HTTP"
            ::oOle := NIL
         END
      END
   END

return (::oOle != NIL)

//----------------------------------------------------------------------------//

METHOD Get( cUrl, aHeaders ) CLASS TGoogleHTTP

   local cRet := ""

   if ::oOle == NIL
      ::cLastError := "Objeto HTTP no inicializado"
      return cRet
   endif

   CursorWait()

   BEGIN SEQUENCE
      ::oOle:Open( "GET", cUrl, .F. )
      ::oOle:SetRequestHeader( "Cache-Control", "no-cache" )
      ::oOle:SetRequestHeader( "Accept", "application/json" )

      if aHeaders != NIL
         AEVAL( aHeaders, {|h| ::oOle:SetRequestHeader( h[1], h[2] ) } )
      endif

      ::oOle:Send()
      ::oOle:WaitForResponse( ::nTimeout * 1000 )
      ::nStatusCode   := ::oOle:Status
      ::cResponseText := ::oOle:ResponseText
      cRet            := ::cResponseText
   RECOVER
      ::cLastError  := "GET Error"
      ::nStatusCode := 0
   END

   CursorArrow()

return cRet

//----------------------------------------------------------------------------//

METHOD Post( cUrl, cBody, aHeaders ) CLASS TGoogleHTTP

   local cRet := ""

   if ::oOle == NIL
      ::cLastError := "Objeto HTTP no inicializado"
      return cRet
   endif

   CursorWait()

   BEGIN SEQUENCE
      ::oOle:Open( "POST", cUrl, .F. )
      ::oOle:SetRequestHeader( "Content-Type", "application/json" )
      ::oOle:SetRequestHeader( "Cache-Control", "no-cache" )
      ::oOle:SetRequestHeader( "Accept", "application/json" )

      if aHeaders != NIL
         AEVAL( aHeaders, {|h| ::oOle:SetRequestHeader( h[1], h[2] ) } )
      endif

      ::oOle:Send( cBody )
      ::oOle:WaitForResponse( ::nTimeout * 1000 )
      ::nStatusCode   := ::oOle:Status
      ::cResponseText := ::oOle:ResponseText
      cRet            := ::cResponseText
   RECOVER
      ::cLastError  := "POST Error"
      ::nStatusCode := 0
   END

   CursorArrow()

return cRet

//----------------------------------------------------------------------------//

METHOD Put( cUrl, cBody, aHeaders ) CLASS TGoogleHTTP

   local cRet := ""

   if ::oOle == NIL
      ::cLastError := "Objeto HTTP no inicializado"
      return cRet
   endif

   CursorWait()

   BEGIN SEQUENCE
      ::oOle:Open( "PUT", cUrl, .F. )
      ::oOle:SetRequestHeader( "Content-Type", "application/json" )
      ::oOle:SetRequestHeader( "Cache-Control", "no-cache" )
      ::oOle:SetRequestHeader( "Accept", "application/json" )

      if aHeaders != NIL
         AEVAL( aHeaders, {|h| ::oOle:SetRequestHeader( h[1], h[2] ) } )
      endif

      ::oOle:Send( cBody )
      ::oOle:WaitForResponse( ::nTimeout * 1000 )
      ::nStatusCode   := ::oOle:Status
      ::cResponseText := ::oOle:ResponseText
      cRet            := ::cResponseText
   RECOVER
      ::cLastError  := "PUT Error"
      ::nStatusCode := 0
   END

   CursorArrow()

return cRet

//----------------------------------------------------------------------------//

METHOD Patch( cUrl, cBody, aHeaders ) CLASS TGoogleHTTP

   local cRet := ""

   if ::oOle == NIL
      ::cLastError := "Objeto HTTP no inicializado"
      return cRet
   endif

   CursorWait()

   BEGIN SEQUENCE
      ::oOle:Open( "PATCH", cUrl, .F. )
      ::oOle:SetRequestHeader( "Content-Type", "application/json" )
      ::oOle:SetRequestHeader( "Cache-Control", "no-cache" )
      ::oOle:SetRequestHeader( "Accept", "application/json" )

      if aHeaders != NIL
         AEVAL( aHeaders, {|h| ::oOle:SetRequestHeader( h[1], h[2] ) } )
      endif

      ::oOle:Send( cBody )
      ::oOle:WaitForResponse( ::nTimeout * 1000 )
      ::nStatusCode   := ::oOle:Status
      ::cResponseText := ::oOle:ResponseText
      cRet            := ::cResponseText
   RECOVER
      ::cLastError  := "PATCH Error"
      ::nStatusCode := 0
   END

   CursorArrow()

return cRet

//----------------------------------------------------------------------------//

METHOD Delete( cUrl, aHeaders ) CLASS TGoogleHTTP

   local cRet := ""

   if ::oOle == NIL
      ::cLastError := "Objeto HTTP no inicializado"
      return cRet
   endif

   CursorWait()

   BEGIN SEQUENCE
      ::oOle:Open( "DELETE", cUrl, .F. )
      ::oOle:SetRequestHeader( "Cache-Control", "no-cache" )
      ::oOle:SetRequestHeader( "Accept", "application/json" )

      if aHeaders != NIL
         AEVAL( aHeaders, {|h| ::oOle:SetRequestHeader( h[1], h[2] ) } )
      endif

      ::oOle:Send()
      ::oOle:WaitForResponse( ::nTimeout * 1000 )
      ::nStatusCode   := ::oOle:Status
      ::cResponseText := ::oOle:ResponseText
      cRet            := ::cResponseText
   RECOVER
      ::cLastError  := "DELETE Error"
      ::nStatusCode := 0
   END

   CursorArrow()

return cRet

//----------------------------------------------------------------------------//
// EOF
