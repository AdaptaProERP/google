//----------------------------------------------------------------------------//
// TGOOGLE.CH - Header para Ecosistema Google Adaptapro
// Define, funciones macros y traducciones
// Compatible: xHarbour + Harbour 3.2 + FiveWin 2.4
//----------------------------------------------------------------------------//

#ifndef _TGOOGLE_CH
#define _TGOOGLE_CH

//----------------------------------------------------------------------------//
// Version
//----------------------------------------------------------------------------//
#define TGOOGLE_VERSION      "3.0.0"
#define TGOOGLE_BUILD        "20260921"
#define TGOOGLE_AUTHOR       "Adaptapro ERP - Juan Navas"

//----------------------------------------------------------------------------//
// Google API Endpoints
//----------------------------------------------------------------------------//
#define GOOGLE_API_BASE      "https://www.googleapis.com"
#define GEMINI_API_BASE      "https://generativelanguage.googleapis.com"

// Calendar
#define GOOGLE_CALENDAR_URL  "https://www.googleapis.com/calendar/v3"

// Drive
#define GOOGLE_DRIVE_URL     "https://www.googleapis.com/drive/v3"

// Tasks
#define GOOGLE_TASKS_URL     "https://www.googleapis.com/tasks/v1"

// Gmail
#define GOOGLE_GMAIL_URL     "https://www.googleapis.com/gmail/v1"

// Sheets
#define GOOGLE_SHEETS_URL    "https://sheets.googleapis.com/v4"

// Gemini
#define GOOGLE_GEMINI_URL    "https://generativelanguage.googleapis.com/v1beta/models"

// Xiaomi MiMo (OpenAI Chat Completions compatible, Sep-2026)
// API key: sk-... (pay-as-you-go) / tp-... (token plan). Header: api-key: <key>
#define MIMO_API_BASE        "https://api.xiaomimimo.com/v1"
#define MIMO_MODEL_FLASH     "mimo-v2.6-flash"
#define MIMO_MODEL_PRO       "mimo-v2.6-pro"
#define MIMO_MODEL_ULTRA     "mimo-v2.6-pro-ultraspeed"

//----------------------------------------------------------------------------//
// OAuth2
//----------------------------------------------------------------------------//
#define GOOGLE_AUTH_URL      "https://accounts.google.com/o/oauth2/v2/auth"
#define GOOGLE_TOKEN_URL     "https://oauth2.googleapis.com/token"
#define GOOGLE_REVOKE_URL    "https://oauth2.googleapis.com/revoke"

// Scopes
#define GSCOPE_CALENDAR      "https://www.googleapis.com/auth/calendar"
#define GSCOPE_DRIVE         "https://www.googleapis.com/auth/drive"
#define GSCOPE_GMAIL         "https://www.googleapis.com/auth/gmail.modify"
#define GSCOPE_TASKS         "https://www.googleapis.com/auth/tasks"
#define GSCOPE_SHEETS        "https://www.googleapis.com/auth/spreadsheets"
#define GSCOPE_USERINFO      "https://www.googleapis.com/auth/userinfo.email"

//----------------------------------------------------------------------------//
// Calendar - Event Status
//----------------------------------------------------------------------------//
#define GCAL_STATUS_CONFIRMED   "confirmed"
#define GCAL_STATUS_TENTATIVE   "tentative"
#define GCAL_STATUS_CANCELLED   "cancelled"

//----------------------------------------------------------------------------//
// Drive - MIME Types
//----------------------------------------------------------------------------//
#define GDRIVE_MIME_FOLDER      "application/vnd.google-apps.folder"
#define GDRIVE_MIME_FILE        "application/vnd.google-apps.file"
#define GDRIVE_MIME_GOOGLE_DOC  "application/vnd.google-apps.document"
#define GDRIVE_MIME_GOOGLE_SHEET "application/vnd.google-apps.spreadsheet"

//----------------------------------------------------------------------------//
// Tasks - Status
//----------------------------------------------------------------------------//
#define GTASK_STATUS_NEEDS_ACTION  "needsAction"
#define GTASK_STATUS_COMPLETED     "completed"

//----------------------------------------------------------------------------//
// Gmail - Labels
//----------------------------------------------------------------------------//
#define GMAIL_LABEL_INBOX       "INBOX"
#define GMAIL_LABEL_SENT        "SENT"
#define GMAIL_LABEL_TRASH       "TRASH"
#define GMAIL_LABEL_UNREAD      "UNREAD"

//----------------------------------------------------------------------------//
// Config Files
//----------------------------------------------------------------------------//
#define TGOOGLE_CONFIG_FILE     "c:\googledrive\config_google.json"
#define TGOOGLE_TOKEN_FILE      "c:\googledrive\tokens_google.json"
#define TGOOGLE_LOG_FILE        "c:\googledrive\google_api.log"

//----------------------------------------------------------------------------//
// Defaults por usuario (sobreescribir via New() o config_google.json)
//----------------------------------------------------------------------------//
#define TGOOGLE_DEFAULT_EMAIL   "micuenta@gmail.com"
#define TGOOGLE_DEFAULT_MODEL   "gemini-3.8-flash"
#define TGOOGLE_DEFAULT_SERVER  "https://generativelanguage.googleapis.com/v1beta/models/"

//----------------------------------------------------------------------------//
// Timeouts
//----------------------------------------------------------------------------//
#define TGOOGLE_HTTP_TIMEOUT    30      // segundos
#define TGOOGLE_TOKEN_EXPIRES   7200    // 2 horas

//----------------------------------------------------------------------------//
// Logging
//----------------------------------------------------------------------------//
#define TGOOGLE_LOG_NONE        0
#define TGOOGLE_LOG_ERROR       1
#define TGOOGLE_LOG_WARNING     2
#define TGOOGLE_LOG_INFO        3
#define TGOOGLE_LOG_DEBUG       4

//----------------------------------------------------------------------------//
// Macros de conveniencia
//----------------------------------------------------------------------------//

// Crear instancia rápida de Google
#xcommand DEFINE GOOGLE <oGoogle> ;
         [ APIKEY <cApiKey> ] ;
         [ CLIENTID <cClientId> ] ;
         [ CLIENTSECRET <cClientSecret> ] ;
         [ CUENTA <cCuenta> ] ;
      => ;
         <oGoogle> := TGoogle():New( <cApiKey>, <cClientId>, ;
                      <cClientSecret>, <cCuenta> )

// Acceso rápido a Calendar
#xcommand CALENDAR GET EVENTS <oGoogle> FROM <dFrom> TO <dTo> ;
         [ RESULT <aEvents> ] ;
      => ;
         <aEvents> := <oGoogle>:Calendar():GetEvents( <dFrom>, <dTo> )

// Acceso rápido a Drive
#xcommand DRIVE SEARCH <oGoogle> NAME <cName> ;
         [ RESULT <aFiles> ] ;
      => ;
         <aFiles> := <oGoogle>:Drive():SearchByName( <cName> )

// Acceso rápido a Gemini
#xcommand GEMINI ASK <oGoogle> PROMPT <cPrompt> ;
         [ RESULT <cResult> ] ;
      => ;
         <cResult> := <oGoogle>:Gemini():GenerateText( <cPrompt> )

//----------------------------------------------------------------------------//
// Funciones de utilidad
//----------------------------------------------------------------------------//

// Verificar si una API key es válida
#xcommand VALIDATE APIKEY <cApiKey> ;
         [ RESULT <lValid> ] ;
      => ;
         <lValid> := TGoogle():ValidateApiKey( <cApiKey> )

//----------------------------------------------------------------------------//

#endif // _TGOOGLE_CH

// EOF
