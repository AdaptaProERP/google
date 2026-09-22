//----------------------------------------------------------------------------//
// DRIVECHECK.PRG - Deteccion nativa Win32 de Google Drive
// Compatible: xHarbour 0.82 + Harbour 3.2 + FiveWin 2.4 + BCC55
// Para: Adaptapro ERP
//
// Funciones:
//   ISDRIVEG()              - Verifica si G: esta activa
//   ISDRIVEAVAILABLE(cPath) - Verifica cualquier unidad
//   GETDRIVETYPETEXT(cPath) - Tipo de unidad en texto
//   GETGOOGLEDRIVE()        - Detecta letra de Google Drive (A-Z)
//   ISDRIVE(cPath)          - Verifica si es Google Drive
//   GETGOOGLEDRIVEPATH()    - Retorna "G:\" completa
//   GETDRIVEPATH(cFile)     - Construye ruta: "G:\datos\arch.dbf"
//   GETGOOGLEDRIVEINFO()    - Info detallada (hash)
//
// Nota: Usa #pragma BEGINDUMP para funciones C nativas Win32.
//       SetErrorMode evita bloqueos de E/S y dialogos del SO.
//----------------------------------------------------------------------------//

#include "FiveWin.ch"

// Drive types (Windows API)
#define DRIVE_UNKNOWN     0
#define DRIVE_NO_ROOT     1
#define DRIVE_REMOVABLE   2
#define DRIVE_FIXED       3
#define DRIVE_REMOTE      4
#define DRIVE_CDROM       5
#define DRIVE_RAMDISK     6

//----------------------------------------------------------------------------//
// FUNCIONES PUBLICAS PARA ADAPTAPRO
//----------------------------------------------------------------------------//

//----------------------------------------------------------------------------//
// ISDRIVEG() - Verifica si la unidad G: esta disponible
// Retorna: .T. si existe y responde, .F. si no
// Ejemplo: IF ISDRIVEG() ... USE DATOS ... ENDIF
//----------------------------------------------------------------------------//

FUNCTION ISDRIVEG()
RETURN ISDRIVEAVAILABLE( "G:" )

//----------------------------------------------------------------------------//
// ISDRIVEAVAILABLE( cDrive ) - Verifica cualquier unidad
// Parametros:
//   cDrive  - "G:", "G:\", "G:\datos\", etc.
// Retorna: .T. si la unidad responde, .F. si no
// Ejemplo: IF ISDRIVEAVAILABLE("G:") ... ENDIF
//          IF ISDRIVEAVAILABLE("C:") ... ENDIF
//----------------------------------------------------------------------------//

FUNCTION ISDRIVEAVAILABLE( cDrive )

   LOCAL lOk := .F.

   DEFAULT cDrive := "G:"
   cDrive := ALLTRIM( UPPER( cDrive ) )

   IF Empty( cDrive )
      RETURN .F.
   ENDIF

   // Normalizar a formato "X:\"
   IF !(":" $ cDrive)
      cDrive := LEFT( cDrive, 1 ) + ":"
   ENDIF

   IF !(RIGHT( cDrive, 1 ) == "\")
      cDrive += "\"
   ENDIF

   lOk := WIN_ISDRIVEREADY( cDrive )

RETURN lOk

//----------------------------------------------------------------------------//
// GETDRIVETYPETEXT( cDrive ) - Tipo de unidad en texto
// Retorna: "RED/REMOTO", "FIJO", "REMOVIBLE", etc.
// Util para: diagnosticos, log, mensajes al usuario
//----------------------------------------------------------------------------//

FUNCTION GETDRIVETYPETEXT( cDrive )

   LOCAL nType
   LOCAL aTipos := { "DESCONOCIDO", ;   // DRIVE_UNKNOWN     = 0
                     "NO_EXISTE",   ;   // DRIVE_NO_ROOT_DIR = 1
                     "REMOVIBLE",   ;   // DRIVE_REMOVABLE   = 2
                     "FIJO",        ;   // DRIVE_FIXED       = 3
                     "RED/REMOTO",  ;   // DRIVE_REMOTE      = 4
                     "CDROM",       ;   // DRIVE_CDROM       = 5
                     "RAMDISK" }        // DRIVE_RAMDISK     = 6

   DEFAULT cDrive := "G:\"
   IF !(RIGHT( cDrive, 1 ) == "\")
      cDrive := ALLTRIM( cDrive ) + "\"
   ENDIF

   nType := WIN_GETDRIVETYPE( cDrive )

   IF nType >= 0 .AND. nType < LEN( aTipos )
      RETURN aTipos[ nType + 1 ]
   ENDIF

RETURN "DESCONOCIDO"

//----------------------------------------------------------------------------//
// GETGOOGLEDRIVE() - Detecta la unidad de Google Drive
// Escanea A-Z, busca unidad tipo RED con label "Google"
// Retorna: "G" (letra) o "" si no encuentra
// Ejemplo: cUnidad := GETGOOGLEDRIVE()
//----------------------------------------------------------------------------//

FUNCTION GETGOOGLEDRIVE()

   LOCAL nDrive, cLetter, cPath
   LOCAL cLabel, nType

   FOR nDrive := 65 TO 90   // ASCII "A" a "Z"
      cLetter := CHR( nDrive )
      cPath   := cLetter + ":\"

      // Solo verificar unidades que existan
      IF DISKSPACE( nDrive ) < 0
         LOOP
      ENDIF

      nType := WIN_GETDRIVETYPE( cPath )

      // Google Drive File Stream se monta como DRIVE_REMOTE (4)
      IF nType == DRIVE_REMOTE
         cLabel := WIN_GETVOLUMELABEL( cPath )
         IF !EMPTY( cLabel ) .AND. "GOOGLE" $ UPPER( cLabel )
            RETURN cLetter
         ENDIF
      ENDIF
   NEXT

RETURN ""

//----------------------------------------------------------------------------//
// ISDRIVE( cPath ) - Verifica si una ruta es Google Drive
// Parametros:
//   cPath  - "G:", "G:\", "G:\datos\archivo.dbf"
// Retorna: .T. si es Google Drive, .F. si no
// Ejemplo: IF ISDRIVE("G:") ... ENDIF
//----------------------------------------------------------------------------//

FUNCTION ISDRIVE( cPath )

   LOCAL cLetter

   IF cPath == NIL .OR. EMPTY( cPath )
      RETURN .F.
   ENDIF

   cLetter := UPPER( LEFT( ALLTRIM( cPath ), 1 ) )

   IF cLetter < "A" .OR. cLetter > "Z"
      RETURN .F.
   ENDIF

RETURN cLetter == GETGOOGLEDRIVE()

//----------------------------------------------------------------------------//
// GETGOOGLEDRIVEPATH() - Ruta raiz de Google Drive
// Retorna: "G:\" o "" si no encuentra
// Ejemplo: USE (GETGOOGLEDRIVEPATH() + "DATOS\CLIENT.DBF")
//----------------------------------------------------------------------------//

FUNCTION GETGOOGLEDRIVEPATH()

   LOCAL cDrive := GETGOOGLEDRIVE()

   IF !EMPTY( cDrive )
      RETURN cDrive + ":\"
   ENDIF

RETURN ""

//----------------------------------------------------------------------------//
// GETDRIVEPATH( cFile ) - Construye ruta en Google Drive
// Parametros:
//   cFile  - "datos\arch.dbf" o "facturas\"
// Retorna: "G:\datos\arch.dbf" o ""
// Ejemplo: USE (GETDRIVEPATH("DATOS\CLIENT.DBF"))
//          COPY TO (GETDRIVEPATH("BACKUP\CLIENT.BAK"))
//----------------------------------------------------------------------------//

FUNCTION GETDRIVEPATH( cFile )

   LOCAL cDrive := GETGOOGLEDRIVE()

   IF EMPTY( cDrive ) .OR. cFile == NIL
      RETURN ""
   ENDIF

RETURN cDrive + ":\" + ALLTRIM( cFile )

//----------------------------------------------------------------------------//
// GETGOOGLEDRIVEINFO() - Info detallada de la unidad
// Retorna: Array { letra, ruta, label, tipo, bytes_libres, listo } o NIL
//   aInfo[1]  - "G"         (letra)
//   aInfo[2]  - "G:\"       (ruta)
//   aInfo[3]  - "Google Drive" (label)
//   aInfo[4]  - "RED/REMOTO"   (tipo)
//   aInfo[5]  - 3892019200     (bytes libres)
//   aInfo[6]  - .T.            (listo)
// Ejemplo:
//   aInfo := GETGOOGLEDRIVEINFO()
//   IF aInfo != NIL
//      ? "Unidad:", aInfo[1]
//      ? "Libre:", aInfo[5]
//   ENDIF
//----------------------------------------------------------------------------//

FUNCTION GETGOOGLEDRIVEINFO()

   LOCAL cDrive, cLabel, cType, nFree
   LOCAL aInfo

   cDrive := GETGOOGLEDRIVE()

   IF EMPTY( cDrive )
      RETURN NIL
   ENDIF

   cLabel := WIN_GETVOLUMELABEL( cDrive + ":\" )
   cType  := GETDRIVETYPETEXT( cDrive + ":\" )
   nFree  := DISKSPACE( ASC( cDrive ) - 64 )

   // Array: { letra, ruta, label, tipo, bytes_libres, listo }
   aInfo := { cDrive, cDrive + ":\", cLabel, cType, nFree, nFree >= 0 }

RETURN aInfo

//----------------------------------------------------------------------------//
// BUSCARARCHIVOSGDRIVE( cDir, cMask ) - Lista archivos en Google Drive
// Parametros:
//   cDir   - Directorio relativo: "facturas" o "" para raiz
//   cMask  - Mascara: "*.DBF" o "*.*"
// Retorna: Array de archivos (mismo formato DIRECTORY())
// Ejemplo: aFiles := BUSCARARCHIVOSGDRIVE( "DATOS", "*.DBF" )
//----------------------------------------------------------------------------//

FUNCTION BUSCARARCHIVOSGDRIVE( cDir, cMask )

   LOCAL cPath, aFiles := {}

   DEFAULT cDir := "", cMask := "*.*"

   cPath := GETDRIVEPATH( cDir )

   IF EMPTY( cPath )
      RETURN {}
   ENDIF

   aFiles := DIRECTORY( cPath + cMask )

RETURN aFiles

//----------------------------------------------------------------------------//
// VERIFICARGDRIVE() - Verificacion completa con diagnóstico
// Retorna: .T. si Google Drive esta listo para usar
// Muestra: Tipo de unidad, label, espacio libre
// Util para: Menu principal de Adaptapro al iniciar
//----------------------------------------------------------------------------//

FUNCTION VERIFICARGDRIVE()

   LOCAL aInfo

   aInfo := GETGOOGLEDRIVEINFO()

   IF aInfo == NIL
      ? "Google Drive: NO DETECTADO"
      RETURN .F.
   ENDIF

   IF !aInfo[6]
      ? "Google Drive: UNIDAD NO RESPONDE"
      RETURN .F.
   ENDIF

RETURN .T.

//============================================================================//
// WRAPPER NATIVO Win32 API - #pragma BEGINDUMP
// Compatible: xHarbour 0.82 + Harbour 3.2 + BCC55
//============================================================================//

#pragma BEGINDUMP

#include <windows.h>
#include <hbapi.h>

/*
 * WIN_ISDRIVEREADY( cRootPath ) -> .T. / .F.
 * Verifica si la unidad esta montada y responde a I/O.
 * Usa SetErrorMode para evitar bloqueos y dialogos del SO.
 */
HB_FUNC( WIN_ISDRIVEREADY )
{
   const char * lpRootPathName;
   UINT uDriveType;
   UINT uOldErrorMode;
   char szVolName[ MAX_PATH + 1 ];
   char szFSName[ 32 ];
   DWORD dwVolSerial = 0;
   DWORD dwMaxCompLen = 0;
   DWORD dwFSFlags = 0;
   BOOL bReady = FALSE;

   if( hb_pcount() < 1 || hb_param( 1, HB_IT_STRING ) == NULL )
   {
      hb_retl( 0 );
      return;
   }

   lpRootPathName = hb_parc( 1 );

   /* Suprimir dialogos criticos del SO */
   uOldErrorMode = SetErrorMode( SEM_FAILCRITICALERRORS | SEM_NOOPENFILEERRORBOX );

   uDriveType = GetDriveTypeA( lpRootPathName );

   if( uDriveType > DRIVE_NO_ROOT_DIR )
   {
      if( GetVolumeInformationA(
            lpRootPathName,
            szVolName,
            sizeof( szVolName ),
            &dwVolSerial,
            &dwMaxCompLen,
            &dwFSFlags,
            szFSName,
            sizeof( szFSName ) ) )
      {
         bReady = TRUE;
      }
   }

   SetErrorMode( uOldErrorMode );

   hb_retl( bReady ? 1 : 0 );
}

/*
 * WIN_GETDRIVETYPE( cRootPath ) -> nType (0-6)
 * Retorna el tipo de unidad segun GetDriveTypeA.
 */
HB_FUNC( WIN_GETDRIVETYPE )
{
   if( hb_pcount() >= 1 && hb_param( 1, HB_IT_STRING ) != NULL )
   {
      hb_retni( ( int ) GetDriveTypeA( hb_parc( 1 ) ) );
   }
   else
   {
      hb_retni( 1 );
   }
}

/*
 * WIN_GETVOLUMELABEL( cRootPath ) -> cLabel
 * Retorna el label del volumen o string vacio.
 */
HB_FUNC( WIN_GETVOLUMELABEL )
{
   char szVolName[ MAX_PATH + 1 ];
   char szFSName[ 32 ];
   DWORD dwVolSerial = 0;
   DWORD dwMaxCompLen = 0;
   DWORD dwFSFlags = 0;

   szVolName[ 0 ] = '\0';

   if( hb_pcount() >= 1 && hb_param( 1, HB_IT_STRING ) != NULL )
   {
      GetVolumeInformationA(
         hb_parc( 1 ),
         szVolName,
         sizeof( szVolName ),
         &dwVolSerial,
         &dwMaxCompLen,
         &dwFSFlags,
         szFSName,
         sizeof( szFSName ) );
   }

   hb_retc( szVolName );
}

#pragma ENDDUMP

//----------------------------------------------------------------------------//
// EOF
