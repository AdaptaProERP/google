//----------------------------------------------------------------------------//
// ej04_tasks.prg - Ejemplo de Google Tasks API
// Crear listas, tareas, completar
// Compilar: harbour ej04_tasks.prg /n /iC:\fw24\include;C:\harbour\include;C:\googledrive
//----------------------------------------------------------------------------//

#include "FiveWin.ch"
#include "TGOOGLE.CH"

//----------------------------------------------------------------------------//

FUNCTION Main()

   LOCAL oGoogle, oTasks, oTask
   LOCAL aTasks, aLists, hList, hTask
   LOCAL cNewListId := ""
   LOCAL hNewList

   CLS

   ? "============================================================"
   ? "  EJEMPLO 04: Google Tasks API v1"
   ? "============================================================"
   ?

   oGoogle := TGoogle():New()

   IF !oGoogle:IsAuthenticated()
      ? "Requiere autenticacion OAuth. Ejecute ej01_google_init.prg"
      RETURN NIL
   ENDIF

   oTasks := oGoogle:Tasks()

   // 1. LISTAR LISTAS
   ? "--- [1] Listas de tareas ---"
   aLists := oTasks:GetTaskLists()
   FOR EACH hList IN aLists
      ? "  * " + TGoogleJSON():Get( hList, "title", "" )
   NEXT
   ?

   // 2. CREAR LISTA
   ? "--- [2] Crear lista 'Adaptapro_Tasks' ---"
   hNewList := oTasks:CreateTaskList( "Adaptapro_Tasks" )
   IF hNewList != NIL
      cNewListId := TGoogleJSON():Get( hNewList, "id", "" )
      ? "  [OK] Lista creada"
   ENDIF
   ?

   // 3. AGREGAR TAREAS
   IF !EMPTY( cNewListId )
      ? "--- [3] Agregar tareas ---"

      oTask := TGoogleEvent():New()
      oTask:cTitle := "Configurar API Key Gemini"
      oTask:cNotes := "Obtener desde Google Cloud Console"
      hTask := oTasks:CreateTask( oTask, cNewListId )
      IF hTask != NIL
         ? "  [OK] " + hTask["title"]
      ENDIF

      oTask := TGoogleEvent():New()
      oTask:cTitle := "Completar integracion Google Drive"
      oTask:cNotes := "Archivos en C:\googledrive\"
      hTask := oTasks:CreateTask( oTask, cNewListId )
      IF hTask != NIL
         ? "  [OK] " + hTask["title"]
      ENDIF

      oTask := TGoogleEvent():New()
      oTask:cTitle := "Verificar compilacion Harbour 3.2"
      hTask := oTasks:CreateTask( oTask, cNewListId )
      IF hTask != NIL
         ? "  [OK] " + hTask["title"]
      ENDIF
   ENDIF
   ?

   // 4. LISTAR TAREAS
   IF !EMPTY( cNewListId )
      ? "--- [4] Tareas pendientes ---"
      aTasks := oTasks:GetTasks( cNewListId )
      FOR EACH hTask IN aTasks
         ? "  * [" + hTask["status"] + "] " + hTask["title"]
      NEXT
   ENDIF
   ?

   // 5. COMPLETAR
   IF !EMPTY( cNewListId )
      aTasks := oTasks:GetTasks( cNewListId )
      IF LEN( aTasks ) > 0
         ? "--- [5] Completar primera tarea ---"
         IF oTasks:CompleteTask( aTasks[1]["id"], cNewListId )
            ? "  [OK] " + aTasks[1]["title"]
         ENDIF
      ENDIF
   ENDIF
   ?

   // 6. VERIFICAR
   IF !EMPTY( cNewListId )
      ? "--- [6] Estado actualizado ---"
      aTasks := oTasks:GetTasks( cNewListId )
      FOR EACH hTask IN aTasks
         ? "  * [" + hTask["status"] + "] " + hTask["title"]
      NEXT
   ENDIF
   ?

   // 7. LIMPIAR
   IF !EMPTY( cNewListId )
      ? "--- [7] Eliminar lista ---"
      IF oTasks:DeleteTaskList( cNewListId )
         ? "  [OK] Eliminada"
      ENDIF
   ENDIF
   ?

   ? "============================================================"
   ? "  Ejemplo Tasks completado"
   ? "============================================================"

   oGoogle:End()

RETURN NIL

//----------------------------------------------------------------------------//
// EOF
