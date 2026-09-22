# Ecosistema Google para AdaptaPro ERP

Integracion completa de APIs Google con AdaptaPro ERP usando **Harbour 3.2** / **xHarbour 0.82** + **FiveWin 2.4**.

## APIs Integradas

| API | Archivo | Descripcion |
|-----|---------|-------------|
| Calendar | `TGOOGLECALENDAR.PRG` | CRUD de eventos, calendarios |
| Drive | `TGOOGLEDRIVE.PRG` | Archivos, carpetas, permisos |
| Tasks | `TGOOGLETASKS.PRG` | Listas y tareas |
| Gmail | `TGOOGLEGMAIL.PRG` | Enviar/correo, labels |
| Gemini | `TGOOGLEGEMINI.PRG` | Generacion de texto, chat IA |
| Sheets | `TGOOGLESHEETS.PRG` | Leer/escribir hojas de calculo |

## Archivos Principales

| Archivo | Descripcion |
|---------|-------------|
| `TGOOGLE.PRG` | Clase principal orchestrator |
| `TGOOGLE.CH` | Defines, scopes, macros |
| `TGOOGLEHTTP.PRG` | Cliente HTTP via WinHTTP OLE |
| `TGOOGLEJSON.PRG` | Wrapper JSON (Decode/Encode) |
| `TGOOGLEAUTH.PRG` | OAuth2, tokens, Chrome |
| `TGOOGLEEVENT.PRG` | Modelo de evento Calendar |
| `DRIVECHECK.PRG` | Deteccion unidad Google Drive (Win32 nativo) |

## Ejemplos

| Ejemplo | Servicio | Descripcion |
|---------|----------|-------------|
| `ej01_google_init.prg` | Todos | Inicializacion, config por parametros |
| `ej02_calendar.prg` | Calendar | Crear/modificar/eliminar eventos |
| `ej03_drive.prg` | Drive | Carpetas, archivos, permisos |
| `ej04_tasks.prg` | Tasks | Listas, tareas, completar |
| `ej05_gmail.prg` | Gmail | Leer, enviar correos |
| `ej06_gemini.prg` | Gemini | Texto, chat multi-turno |
| `ej07_sheets.prg` | Sheets | Hojas, leer/escribir datos |

## Requisitos

- **Compilador:** Harbour 3.2 (`C:\harbour\bin\harbour.exe`) o xHarbour 0.82
- **C compilador:** BCC55 (`C:\bcc55\bin\bcc32.exe`)
- **Framework:** FiveWin 2.4 (`C:\fw24\`)
- **Google Drive File Stream** instalado y montado (unidad G:)

## Instalacion

### 1. Copiar archivos a `C:\googledrive\`

```
TGOOGLE.PRG, TGOOGLE.CH, TGOOGLEHTTP.PRG, TGOOGLEJSON.PRG,
TGOOGLEAUTH.PRG, TGOOGLEEVENT.PRG, TGOOGLECALENDAR.PRG,
TGOOGLEDRIVE.PRG, TGOOGLETASKS.PRG, TGOOGLEGMAIL.PRG,
TGOOGLEGEMINI.PRG, TGOOGLESHEETS.PRG, DRIVECHECK.PRG
```

### 2. Configurar API Key

Editar `config_google.json`:
```json
{
  "api_key": "TU_API_KEY_AQUI",
  "client_id": "",
  "client_secret": "",
  "cuenta_gmail": "tu@email.com",
  "server_gemini": "https://generativelanguage.googleapis.com/v1beta/models/",
  "model_gemini": "gemini-2.5-flash-lite",
  "debug": false
}
```

### 3. Compilar

```bat
build_google.bat
```

### 4. Ejecutar prueba

```bat
google_test.exe
```

## Configuracion por Parametros

```harbour
// Default (lee config_google.json)
oGoogle := TGoogle():New()

// Solo API Key
oGoogle := TGoogle():New( "mi-api-key" )

// Configuracion completa
oGoogle := TGoogle():New( "key", "id", "secret", "user@email.com", "server", "model" )

// Sobreescribir solo cuenta
oGoogle := TGoogle():New( NIL, NIL, NIL, "otro@email.com" )
```

## Deteccion de Google Drive (DRIVECHECK.PRG)

```harbour
// Verificar G:
IF ISDRIVEG()
   USE (GETGOOGLEDRIVEPATH() + "DATOS\CLIENT.DBF") SHARED
ENDIF

// Detectar automaticamente
cUnidad := GETGOOGLEDRIVE()

// Info completa
aInfo := GETGOOGLEDRIVEINFO()
// aInfo[1]=letra, [2]=ruta, [3]=label, [4]=tipo, [5]=libre, [6]=listo

// Listar archivos
aFiles := BUSCARARCHIVOSGDRIVE("DATOS", "*.DBF")
```

## Documentacion

- `ISGOOGLEDRIVE.TXT` - Analisis de deteccion Win32 nativa
- `abrir_google_cloud_console.txt` - Como obtener credenciales
- `solicitar_apikey_google_drive.txt` - Solicitud API Key
- `validar_apikey_google_drive.txt` - Validar API Key
- `validar_estado_gdrive.txt` - Verificar estado Google Drive
- `sincronizar_google_drive_ps1.txt` - Script de sincronizacion

## Cuenta

- **Gmail:** jnadaptapro@gmail.com
- **API Key:** Ver `config_google.json`

## Licencia

AdaptaPro ERP - Juan Navas
