//----------------------------------------------------------------------------//
// TGoogleDrive - Google Drive API v3
// Gestión de archivos, carpetas, permisos
// Compatible: xHarbour + Harbour 3.2 + FiveWin 2.4
//----------------------------------------------------------------------------//

#include "FiveWin.ch"

#define DRIVE_API_BASE "https://www.googleapis.com/drive/v3"

//----------------------------------------------------------------------------//

CLASS TGoogleDrive

   DATA   oGoogle           // Referencia a TGoogle padre
   DATA   cFolderId         // Folder ID por defecto
   DATA   cCorpora          // "user" por defecto

   METHOD New( oGoogle )    CONSTRUCTOR
   METHOD End()

   // Archivos - CRUD
   METHOD GetFiles( cQuery, nMax, cPageToken )
   METHOD GetFile( cFileId )
   METHOD CreateFile( cName, cMimeType, cParentId )
   METHOD UpdateFile( cFileId, hMetadata )
   METHOD DeleteFile( cFileId )
   METHOD TrashFile( cFileId )
   METHOD DownloadFile( cFileId, cLocalPath )
   METHOD UploadFile( cFilePath, cName, cMimeType, cParentId )

   // Carpetas
   METHOD CreateFolder( cName, cParentId )
   METHOD GetFolder( cFolderId )

   // Permisos
   METHOD GetPermissions( cFileId )
   METHOD AddPermission( cFileId, cEmail, cRole )

   // Búsqueda
   METHOD SearchByName( cName )
   METHOD SearchByMimeType( cMimeType )

   // Helpers
   METHOD BuildQuery( cClause )
   METHOD ParseFile( hJson )

ENDCLASS

//----------------------------------------------------------------------------//

METHOD New( oGoogle ) CLASS TGoogleDrive

   ::oGoogle   := oGoogle
   ::cFolderId := ""
   ::cCorpora  := "user"

return Self

//----------------------------------------------------------------------------//

METHOD End() CLASS TGoogleDrive

   ::oGoogle := NIL

return nil

//----------------------------------------------------------------------------//

METHOD GetFiles( cQuery, nMax, cPageToken ) CLASS TGoogleDrive

   local cUrl, cResponse, hJson, aFiles := {}

   DEFAULT nMax := 100

   cUrl := DRIVE_API_BASE + "/files?" + ;
           "corpora=" + ::cCorpora + "&" + ;
           "pageSize=" + AllTrim( Str( nMax ) ) + "&" + ;
           "fields=nextPageToken,files(id,name,mimeType,modifiedTime,size,parents,trashed)"

   if !Empty( cQuery )
      cUrl += "&q=" + HB_URLENCODE( cQuery )
   endif

   if !Empty( cPageToken )
      cUrl += "&pageToken=" + cPageToken
   endif

   cResponse := ::oGoogle:HttpRequest( "GET", cUrl )
   hJson     := TGoogleJSON():Decode( cResponse )

   if hJson != NIL .AND. TGoogleJSON():HasKey( hJson, "files" )
      AEVAL( hJson["files"], {|h| AADD( aFiles, ::ParseFile( h ) ) } )
   endif

return aFiles

//----------------------------------------------------------------------------//

METHOD GetFile( cFileId ) CLASS TGoogleDrive

   local cUrl, cResponse, hJson

   cUrl := DRIVE_API_BASE + "/files/" + cFileId + "?" + ;
           "fields=id,name,mimeType,modifiedTime,size,parents,trashed,webViewLink"

   cResponse := ::oGoogle:HttpRequest( "GET", cUrl )
   hJson     := TGoogleJSON():Decode( cResponse )

   if hJson != NIL
      return ::ParseFile( hJson )
   endif

return NIL

//----------------------------------------------------------------------------//

METHOD CreateFile( cName, cMimeType, cParentId ) CLASS TGoogleDrive

   local cUrl, cBody, cResponse, hJson

   DEFAULT cMimeType := "application/vnd.google-apps.folder"

   cUrl := DRIVE_API_BASE + "/files"

   cBody := '{"name":"' + cName + '",'
   cBody += '"mimeType":"' + cMimeType + '"'

   if !Empty( cParentId )
      cBody += ',"parents":["' + cParentId + '"]'
   endif

   cBody += "}"

   cResponse := ::oGoogle:HttpRequest( "POST", cUrl, cBody )
   hJson     := TGoogleJSON():Decode( cResponse )

   if hJson != NIL .AND. TGoogleJSON():HasKey( hJson, "id" )
      return ::ParseFile( hJson )
   endif

return NIL

//----------------------------------------------------------------------------//

METHOD UpdateFile( cFileId, hMetadata ) CLASS TGoogleDrive

   local cUrl, cBody, cResponse, hJson

   cUrl  := DRIVE_API_BASE + "/files/" + cFileId
   cBody := TGoogleJSON():Encode( hMetadata )

   cResponse := ::oGoogle:HttpRequest( "PATCH", cUrl, cBody )
   hJson     := TGoogleJSON():Decode( cResponse )

   if hJson != NIL .AND. TGoogleJSON():HasKey( hJson, "id" )
      return ::ParseFile( hJson )
   endif

return NIL

//----------------------------------------------------------------------------//

METHOD DeleteFile( cFileId ) CLASS TGoogleDrive

   local cUrl

   cUrl := DRIVE_API_BASE + "/files/" + cFileId
   ::oGoogle:HttpRequest( "DELETE", cUrl )

return ::oGoogle:oHttp:nStatusCode == 204

//----------------------------------------------------------------------------//

METHOD TrashFile( cFileId ) CLASS TGoogleDrive

   local cUrl, cBody

   cUrl  := DRIVE_API_BASE + "/files/" + cFileId
   cBody := '{"trashed":true}'

   ::oGoogle:HttpRequest( "PATCH", cUrl, cBody )

return ::oGoogle:oHttp:nStatusCode == 200

//----------------------------------------------------------------------------//

METHOD DownloadFile( cFileId, cLocalPath ) CLASS TGoogleDrive

   local cUrl, cResponse

   cUrl := DRIVE_API_BASE + "/files/" + cFileId + "?alt=media"

   cResponse := ::oGoogle:HttpRequest( "GET", cUrl )

   if !Empty( cResponse )
      MEMOWRIT( cLocalPath, cResponse )
      return .T.
   endif

return .F.

//----------------------------------------------------------------------------//

METHOD UploadFile( cFilePath, cName, cMimeType, cParentId ) CLASS TGoogleDrive

   local cUrl, cBody, cResponse, hJson

   DEFAULT cMimeType := "application/octet-stream"

   cUrl := DRIVE_API_BASE + "/files?uploadType=multipart"

   // Simple upload - metadata only
   cBody := '{"name":"' + cName + '"'
   if !Empty( cParentId )
      cBody += ',"parents":["' + cParentId + '"]'
   endif
   cBody += '}'

   cResponse := ::oGoogle:HttpRequest( "POST", cUrl, cBody )
   hJson     := TGoogleJSON():Decode( cResponse )

   if hJson != NIL .AND. TGoogleJSON():HasKey( hJson, "id" )
      return ::ParseFile( hJson )
   endif

return NIL

//----------------------------------------------------------------------------//

METHOD CreateFolder( cName, cParentId ) CLASS TGoogleDrive

return ::CreateFile( cName, "application/vnd.google-apps.folder", cParentId )

//----------------------------------------------------------------------------//

METHOD GetFolder( cFolderId ) CLASS TGoogleDrive

return ::GetFile( cFolderId )

//----------------------------------------------------------------------------//

METHOD GetPermissions( cFileId ) CLASS TGoogleDrive

   local cUrl, cResponse, hJson

   cUrl := DRIVE_API_BASE + "/files/" + cFileId + "/permissions"

   cResponse := ::oGoogle:HttpRequest( "GET", cUrl )
   hJson     := TGoogleJSON():Decode( cResponse )

   if hJson != NIL .AND. TGoogleJSON():HasKey( hJson, "permissions" )
      return hJson["permissions"]
   endif

return {}

//----------------------------------------------------------------------------//

METHOD AddPermission( cFileId, cEmail, cRole ) CLASS TGoogleDrive

   local cUrl, cBody, cResponse, hJson

   DEFAULT cRole := "reader"

   cUrl := DRIVE_API_BASE + "/files/" + cFileId + "/permissions"
   cBody := '{"type":"user","role":"' + cRole + '","emailAddress":"' + cEmail + '"}'

   cResponse := ::oGoogle:HttpRequest( "POST", cUrl, cBody )
   hJson     := TGoogleJSON():Decode( cResponse )

return ( hJson != NIL )

//----------------------------------------------------------------------------//

METHOD SearchByName( cName ) CLASS TGoogleDrive

return ::GetFiles( "name contains '" + cName + "' and trashed=false" )

//----------------------------------------------------------------------------//

METHOD SearchByMimeType( cMimeType ) CLASS TGoogleDrive

return ::GetFiles( "mimeType='" + cMimeType + "' and trashed=false" )

//----------------------------------------------------------------------------//

METHOD BuildQuery( cClause ) CLASS TGoogleDrive

return cClause + " and trashed=false"

//----------------------------------------------------------------------------//

METHOD ParseFile( hJson ) CLASS TGoogleDrive

   local hFile := {}

   if hJson != NIL
      TGoogleJSON():Set( hFile, "id", TGoogleJSON():Get( hJson, "id", "" ) )
      TGoogleJSON():Set( hFile, "name", TGoogleJSON():Get( hJson, "name", "" ) )
      TGoogleJSON():Set( hFile, "mimeType", TGoogleJSON():Get( hJson, "mimeType", "" ) )
      TGoogleJSON():Set( hFile, "modifiedTime", TGoogleJSON():Get( hJson, "modifiedTime", "" ) )
      TGoogleJSON():Set( hFile, "size", TGoogleJSON():Get( hJson, "size", "" ) )
      TGoogleJSON():Set( hFile, "trashed", TGoogleJSON():Get( hJson, "trashed", .F. ) )
      TGoogleJSON():Set( hFile, "parents", TGoogleJSON():Get( hJson, "parents", {} ) )
      TGoogleJSON():Set( hFile, "webViewLink", TGoogleJSON():Get( hJson, "webViewLink", "" ) )
   endif

return hFile

//----------------------------------------------------------------------------//
// EOF
