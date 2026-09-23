//----------------------------------------------------------------------------//
// EJ08_GEMINI_CHATBOT.PRG
// Ejemplo: Chatbot juridico con interfaz WhatsApp
// Compatible: xHarbour + Harbour 3.2 + FiveWin 2.4
//----------------------------------------------------------------------------//

#include "TGOOGLE.CH"

// Prompt base del chatbot juridico
#define PROMPT_JURIDICO ;
   "Eres un abogado experto en derecho venezolano. " + ;
   "Especialista en: " + ;
   "- Derecho Mercantil (Codigo de Comercio) " + ;
   "- Derecho Laboral (Ley Organica del Trabajo) " + ;
   "- Derecho Civil (Codigo Civil) " + ;
   "- Derecho Penal (Codigo Penal) " + ;
   "- Derecho Tributario (Ley de ISR, IVA) " + ;
   "- Derecho Administrativo " + ;
   "Responde SIEMPRE citando los articulos y leyes aplicables. " + ;
   "Si no estas seguro, indica que necesita investigacion adicional. " + ;
   "Sé preciso, fundamentado y objetivo."

// Fuentes de veracidad
#define FUENTES_JURIDICAS ;
   "1. Codigo de Comercio Venezolano - Articulos 1 al 1000+ " + ;
   "2. Ley Organica del Trabajo, Trabajadoras y Trabajadores - 2012 " + ;
   "3. Codigo Civil Venezolano - Articulos 1 al 2000+ " + ;
   "4. Codigo Penal Venezolano - Actualizado 2023 " + ;
   "5. Ley de Impuesto Sobre la Renta - 2023 " + ;
   "6. Ley del Impuesto al Valor Agregado - 2023 " + ;
   "7. Ley Orgánica de Procedimientos Administrativos " + ;
   "8. Constitución de la República Bolivariana de Venezuela"

//----------------------------------------------------------------------------//
// PROGRAMA PRINCIPAL
//----------------------------------------------------------------------------//

PROCE MAIN()

   // Ejecutar chatbot con interfaz WhatsApp
   GEMINI_CHATBOT( PROMPT_JURIDICO, FUENTES_JURIDICAS, "Consulta Juridica IA" )

RETURN .T.

//----------------------------------------------------------------------------//
// EJEMPLO: Consulta directa sin interfaz
//----------------------------------------------------------------------------//

FUNCTION EJEMPLO_CONSULTA_DIRECTA()

   LOCAL cRespuesta

   cRespuesta := GEMINI_CONSULTA( ;
       "Cuales son los requisitos para constituir una empresa en Venezuela?", ;
       PROMPT_JURIDICO, ;
       FUENTES_JURIDICAS )

   ? "RESPUESTA:"
   ? cRespuesta

RETURN NIL

//----------------------------------------------------------------------------//
// EJEMPLO: Chat con historial persistente
//----------------------------------------------------------------------------//

FUNCTION EJEMPLO_CHAT_PERSISTENTE()

   LOCAL oGoogle, oGemini
   LOCAL aMensajes := {}
   LOCAL cResp1, cResp2, cResp3

   oGoogle := TGoogle():New()
   oGemini := oGoogle:Gemini()
   oGemini:SetTemperature( 0.3 )

   // Primera pregunta
   AADD( aMensajes, { {"role","user"}, ;
       {"text","INSTRUCCION: Eres experto en derecho mercantil venezolano."} } )
   AADD( aMensajes, { {"role","model"}, ;
       {"text","Entendido. Estoy listo."} } )

   AADD( aMensajes, { {"role","user"}, ;
       {"text","Que es una sociedad mercantil?"} } )

   cResp1 := oGemini:Chat( aMensajes )
   ? "Pregunta 1: Que es una sociedad mercantil?"
   ? "Respuesta:", cResp1

   // Segunda pregunta (multi-turno)
   AADD( aMensajes, { {"role","model"}, {"text",cResp1} } )
   AADD( aMensajes, { {"role","user"}, ;
       {"text","Y que tipos de sociedades existen?"} } )

   cResp2 := oGemini:Chat( aMensajes )
   ? "Pregunta 2: Que tipos de sociedades existen?"
   ? "Respuesta:", cResp2

   // Tercera pregunta
   AADD( aMensajes, { {"role","model"}, {"text",cResp2} } )
   AADD( aMensajes, { {"role","user"}, ;
       {"text","Cual es el procedimiento para constituir una S.R.L.?"} } )

   cResp3 := oGemini:Chat( aMensajes )
   ? "Pregunta 3: Procedimiento para constituir una S.R.L.?"
   ? "Respuesta:", cResp3

   oGoogle:End()

RETURN NIL

//----------------------------------------------------------------------------//
// EJEMPLO: Analisis de contrato
//----------------------------------------------------------------------------//

FUNCTION EJEMPLO_ANALISIS_CONTRATO()

   LOCAL cContrato := "CONTRATO DE ARRENDAMIENTO DE LOCAL COMERCIAL" + CRLF + ;
       "Entre las partes: ARRENDADOR: Juan Perez (V-12.345.678) y " + ;
       "ARRENDATARIA: Empresa ABC, C.A. (J-40.123.456), " + ;
       "se celebran las siguientes clausulas:" + CRLF + ;
       "PRIMERA: El arrendador cede en arrendamiento el local comercial " + ;
       "situado en Av. Principal, Edif. X, Piso 2, local 2-3, " + ;
       "para ser destinado a actividad comercial de venta al por menor." + CRLF + ;
       "SEGUNDA: La duracion sera de 3 anos a partir de la fecha de suscripcion." + CRLF + ;
       "TERCERA: El canon de arrendamiento sera de Bs. 5.000 mensuales, " + ;
       "pagaderos por anticipado antes del dia 5 de cada mes."

   LOCAL cRespuesta

   cRespuesta := GEMINI_CONSULTA( ;
       "Analiza este contrato y senala:" + CRLF + ;
       "1. Aspectos legales validos" + CRLF + ;
       "2. Posibles problemas o puntos a mejorar" + CRLF + ;
       "3. Articulos de ley aplicables" + CRLF + ;
       "4. Recomendaciones" + CRLF + CRLF + ;
       cContrato, ;
       PROMPT_JURIDICO, ;
       FUENTES_JURIDICAS )

   ? "ANALISIS DEL CONTRATO:"
   ? cRespuesta

RETURN NIL

//----------------------------------------------------------------------------//
// EOF
