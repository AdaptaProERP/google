//----------------------------------------------------------------------------//
// ej03_drive.prg - Ejemplo de Google Drive API
// Crear carpetas, buscar, permisos
// Compilar: harbour ej03_drive.prg /n /iC:\fw24\include;C:\harbour\include;C:\googledrive
//----------------------------------------------------------------------------//

#include "FiveWin.ch"
#include "TGOOGLE.CH"

//----------------------------------------------------------------------------//

FUNCTION Main()

   LOCAL oGoogle, oDrive
   LOCAL aFiles, hFile, cFolderId := ""
   LOCAL oFolder, oArch, hInfo

   CLS

   ? "============================================================"
   ? "  EJEMPLO 03: Google Drive API v3"
   ? "============================================================"
   ?

   oGoogle := TGoogle():New()

   IF !oGoogle:IsAuthenticated()
      ? "Requiere autenticacion OAuth. Ejecute ej01_google_init.prg"
      RETURN NIL
   ENDIF

   oDrive := oGoogle:Drive()

   // 1. LISTAR ARCHIVOS RECIENTES
   ? "--- [1] Archivos recientes (top 5) ---"
   aFiles := oDrive:GetFiles( NIL, 5 )
   FOR EACH hFile IN aFiles
      ? "  * " + hFile["name"]
      ? "    Tipo: " + hFile["mimeType"]
   NEXT
   ?

   // 2. CREAR CARPETA
   ? "--- [2] Crear carpeta 'Adaptapro_Test' ---"
   oFolder := oDrive:CreateFolder( "Adaptapro_Test" )
   IF oFolder != NIL
      cFolderId := oFolder["id"]
      ? "  [OK] " + oFolder["name"]
      ? "  ID: " + cFolderId
   ENDIF
   ?

   // 3. BUSCAR POR NOMBRE
   ? "--- [3] Buscar archivos '.prg' ---"
   aFiles := oDrive:SearchByName( ".prg" )
   FOR EACH hFile IN aFiles
      ? "  * " + hFile["name"]
   NEXT
   ? "  Encontrados: " + ALLTRIM( STR( LEN( aFiles ) ) )
   ?

   // 4. BUSCAR CARPETAS
   ? "--- [4] Carpetas ---"
   aFiles := oDrive:SearchByMimeType( "application/vnd.google-apps.folder" )
   FOR EACH hFile IN aFiles
      ? "  * " + hFile["name"]
   NEXT
   ?

   // 5. CREAR ARCHIVO
   IF !EMPTY( cFolderId )
      ? "--- [5] Crear archivo en carpeta ---"
      oArch := oDrive:CreateFile( "test_drive.txt", "text/plain", cFolderId )
      IF oArch != NIL
         ? "  [OK] " + oArch["name"]

         // 6. PERMISO
         ? "--- [6] Agregar permiso ---"
         IF oDrive:AddPermission( oArch["id"], "jnadaptapro@gmail.com", "reader" )
            ? "  [OK] Permiso agregado"
         ENDIF
      ENDIF
   ENDIF
   ?

   // 7. INFO
   IF !EMPTY( cFolderId )
      ? "--- [7] Info carpeta ---"
      hInfo := oDrive:GetFolder( cFolderId )
      IF hInfo != NIL
         ? "  " + hInfo["name"] + " (" + hInfo["id"] + ")"
      ENDIF
   ENDIF
   ?

   // 8. PAPELERA
   IF !EMPTY( cFolderId )
      ? "--- [8] Mover a papelera ---"
      IF oDrive:TrashFile( cFolderId )
         ? "  [OK] En papelera"
      ENDIF
   ENDIF
   ?

   ? "============================================================"
   ? "  Ejemplo Drive completado"
   ? "============================================================"

   oGoogle:End()

RETURN NIL

//----------------------------------------------------------------------------//
// EOF
