//----------------------------------------------------------------------------//
// ej05_gmail.prg - Ejemplo de Google Gmail API
// Leer, enviar, buscar correos
// Compilar: harbour ej05_gmail.prg /n /iC:\fw24\include;C:\harbour\include;C:\googledrive
//----------------------------------------------------------------------------//

#include "FiveWin.ch"
#include "TGOOGLE.CH"

//----------------------------------------------------------------------------//

FUNCTION Main()

   LOCAL oGoogle, oGmail
   LOCAL aMessages, aLabels, hMsg, hMail, hLabel
   LOCAL nUnread

   CLS

   ? "============================================================"
   ? "  EJEMPLO 05: Google Gmail API v1"
   ? "  Cuenta: jnadaptapro@gmail.com"
   ? "============================================================"
   ?

   oGoogle := TGoogle():New()

   IF !oGoogle:IsAuthenticated()
      ? "Requiere autenticacion OAuth. Ejecute ej01_google_init.prg"
      RETURN NIL
   ENDIF

   oGmail := oGoogle:Gmail()

   // 1. LABELS
   ? "--- [1] Labels ---"
   aLabels := oGmail:GetLabels()
   FOR EACH hLabel IN aLabels
      ? "  * " + TGoogleJSON():Get( hLabel, "name", "" )
   NEXT
   ?

   // 2. NO LEIDOS
   ? "--- [2] No leidos ---"
   nUnread := oGmail:GetUnreadCount()
   ? "  Total: " + ALLTRIM( STR( nUnread ) )
   ?

   // 3. CORREOS RECIENTES
   ? "--- [3] Ultimos 5 correos ---"
   aMessages := oGmail:GetMessages( NIL, 5 )
   FOR EACH hMsg IN aMessages
      hMail := oGmail:GetMessage( hMsg["id"] )
      ? "  * " + TGoogleJSON():Get( hMail, "subject", "(sin asunto)" )
      ? "    De: " + TGoogleJSON():Get( hMail, "from", "" )
   NEXT
   ?

   // 4. BUSCAR POR QUERY
   ? "--- [4] Buscar 'Adaptapro' ---"
   aMessages := oGmail:GetMessages( "from:adaptapro", 3 )
   ? "  Encontrados: " + ALLTRIM( STR( LEN( aMessages ) ) )
   ?

   // 5. ENVIAR CORREO
   ? "--- [5] Enviar correo de prueba ---"
   IF oGmail:SendMessage( "jnadaptapro@gmail.com", ;
                          "Test Ecosistema Google", ;
                          "Correo enviado desde TGoogleGmail" + CRLF + ;
                          "Harbour 3.2 + FiveWin 2.4" )
      ? "  [OK] Enviado a jnadaptapro@gmail.com"
   ELSE
      ? "  [ERROR] No se pudo enviar"
   ENDIF
   ?

   // 6. ENVIADOS
   ? "--- [6] Correos enviados ---"
   aMessages := oGmail:GetMessages( "in:sent", 3 )
   FOR EACH hMsg IN aMessages
      hMail := oGmail:GetMessage( hMsg["id"] )
      ? "  * " + TGoogleJSON():Get( hMail, "subject", "" )
   NEXT
   ?

   ? "============================================================"
   ? "  Ejemplo Gmail completado"
   ? "============================================================"

   oGoogle:End()

RETURN NIL

//----------------------------------------------------------------------------//
// EOF
