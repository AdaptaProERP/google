/*
 * HB_COMPAT.C - Funciones faltantes en xHarbour 0.82 para Google API
 * Compila con BCC55 + xHarbour 0.82, SOLO libs estaticas (sin harbour.dll)
 *
 * Los objetos JSON se representan como arrays de pares:
 *    { {"clave1", valor1}, {"clave2", valor2}, ... }
 * Los arrays JSON como arrays normales. Sin hashes.
 */

#include "hbapi.h"
#include "hbapiitm.h"
#include "hbdate.h"
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

/* ============================================================ */
/* HB_TSTAMP - Timestamp ISO 8601                               */
/* ============================================================ */
HB_FUNC( HB_TSTAMP )
{
   char szBuf[ 24 ];
   char szTime[ 16 ];
   long nYear, nMonth, nDay;

   hb_dateToday( &nYear, &nMonth, &nDay );
   hb_dateTimeStr( szTime );

   sprintf( szBuf, "%04ld-%02ld-%02ldT%.8sZ",
            nYear, nMonth, nDay, szTime );

   hb_retc( szBuf );
}

/* ============================================================ */
/* HB_TTOSEC - Hora HH:MM:SS a segundos                         */
/* ============================================================ */
HB_FUNC( HB_TTOSEC )
{
   const char * cTime = hb_parc( 1 );
   long nSec = 0;

   if( cTime )
   {
      int h = 0, m = 0, s = 0;
      sscanf( cTime, "%d:%d:%d", &h, &m, &s );
      nSec = (long)h * 3600L + (long)m * 60L + (long)s;
   }

   hb_retnl( nSec );
}

/* ============================================================ */
/* HB_URLENCODE                                                 */
/* ============================================================ */
HB_FUNC( HB_URLENCODE )
{
   const char * cStr = hb_parc( 1 );
   ULONG nLen = hb_parclen( 1 );

   if( cStr && nLen > 0 )
   {
      ULONG nOut = nLen * 3 + 1;
      char * cResult = ( char * ) hb_xgrab( nOut );
      ULONG i, j = 0;

      for( i = 0; i < nLen; i++ )
      {
         unsigned char c = ( unsigned char ) cStr[ i ];
         if( isalnum( c ) || c == '-' || c == '_' || c == '.' || c == '~' )
         {
            cResult[ j++ ] = ( char ) c;
         }
         else if( c == ' ' )
         {
            cResult[ j++ ] = '+';
         }
         else
         {
            cResult[ j++ ] = '%';
            cResult[ j++ ] = "0123456789ABCDEF"[ c >> 4 ];
            cResult[ j++ ] = "0123456789ABCDEF"[ c & 0x0F ];
         }
      }
      cResult[ j ] = '\0';
      hb_retc_buffer( cResult );
   }
   else
      hb_retc( "" );
}

/* ============================================================ */
/* HB_BASE64ENCODE                                              */
/* ============================================================ */
static const char b64chars[] =
   "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

HB_FUNC( HB_BASE64ENCODE )
{
   const char * cData = hb_parc( 1 );
   ULONG nLen = hb_parclen( 1 );

   if( cData && nLen > 0 )
   {
      ULONG nOut = (( nLen + 2 ) / 3) * 4;
      char * cResult = ( char * ) hb_xgrab( nOut + 1 );
      ULONG i, j = 0;
      unsigned char a3[3];
      int a3i = 0;

      for( i = 0; i < nLen; i++ )
      {
         a3[ a3i++ ] = ( unsigned char ) cData[ i ];
         if( a3i == 3 )
         {
            cResult[ j++ ] = b64chars[ ( a3[0] >> 2 ) & 0x3F ];
            cResult[ j++ ] = b64chars[ (( a3[0] & 0x03 ) << 4 ) | (( a3[1] >> 4 ) & 0x0F ) ];
            cResult[ j++ ] = b64chars[ (( a3[1] & 0x0F ) << 2 ) | (( a3[2] >> 6 ) & 0x03 ) ];
            cResult[ j++ ] = b64chars[ a3[2] & 0x3F ];
            a3i = 0;
         }
      }
      if( a3i > 0 )
      {
         for( ; a3i < 3; a3i++ ) a3[ a3i ] = 0;
         cResult[ j++ ] = b64chars[ ( a3[0] >> 2 ) & 0x3F ];
         cResult[ j++ ] = b64chars[ (( a3[0] & 0x03 ) << 4 ) | (( a3[1] >> 4 ) & 0x0F ) ];
         if( a3i == 2 )
            cResult[ j++ ] = b64chars[ (( a3[1] & 0x0F ) << 2 ) ];
         else
            cResult[ j++ ] = '=';
         cResult[ j++ ] = '=';
      }
      cResult[ j ] = '\0';
      hb_retc_buffer( cResult );
   }
   else
      hb_retc( "" );
}

/* ============================================================ */
/* JUSTFILENAME - nombre de archivo de una ruta                 */
/* ============================================================ */
HB_FUNC( JUSTFILENAME )
{
   const char * cPath = hb_parc( 1 );

   if( cPath )
   {
      const char * cSlash = strrchr( cPath, '\\' );
      const char * cFwd = strrchr( cPath, '/' );
      const char * cName;

      if( cSlash && cFwd )
         cName = ( cSlash > cFwd ) ? cSlash + 1 : cFwd + 1;
      else if( cSlash )
         cName = cSlash + 1;
      else if( cFwd )
         cName = cFwd + 1;
      else
         cName = cPath;

      hb_retc( cName );
   }
   else
      hb_retc( "" );
}

/* ============================================================ */
/* INPUTBOX - retorna el default (modo desatendido)             */
/* ============================================================ */
HB_FUNC( INPUTBOX )
{
   const char * cDefault = ( hb_pcount() >= 3 ) ? hb_parc( 3 ) : "";
   hb_retc( cDefault );
}

/* ============================================================ */
/* HB_JSONENCODE - array de pares -> string JSON                */
/* Objeto = array donde TODO elemento es {string, valor}.       */
/* Vacio = {} (solo codificamos objetos de config/tokens).      */
/* ============================================================ */
static int json_is_obj( PHB_ITEM pItem )
{
   ULONG n, nCount;

   if( pItem == NULL || ! HB_IS_ARRAY( pItem ) )
      return 0;

   nCount = hb_arrayLen( pItem );
   if( nCount == 0 )
      return 1;

   for( n = 1; n <= nCount; n++ )
   {
      PHB_ITEM pEl = hb_arrayGetItemPtr( pItem, n );
      if( pEl == NULL || ! HB_IS_ARRAY( pEl ) || hb_arrayLen( pEl ) != 2 )
         return 0;
      {
         PHB_ITEM pK = hb_arrayGetItemPtr( pEl, 1 );
         if( pK == NULL || ! HB_IS_STRING( pK ) )
            return 0;
      }
   }

   return 1;
}

static void json_encode_item( char ** ppBuf, ULONG * pnPos, ULONG * pnSize, PHB_ITEM pItem )
{
   char szNum[ 64 ];
   ULONG nLen;

   if( pItem == NULL || HB_IS_NIL( pItem ) )
   {
      if( *pnPos + 4 >= *pnSize )
      {
         *pnSize = ( *pnSize + 260 ) * 2;
         *ppBuf = ( char * ) hb_xrealloc( *ppBuf, *pnSize );
      }
      memcpy( *ppBuf + *pnPos, "null", 4 );
      *pnPos += 4;
   }
   else if( HB_IS_LOGICAL( pItem ) )
   {
      const char * cBool = hb_itemGetL( pItem ) ? "true" : "false";
      nLen = strlen( cBool );
      if( *pnPos + nLen >= *pnSize )
      {
         *pnSize = ( *pnSize + nLen + 256 ) * 2;
         *ppBuf = ( char * ) hb_xrealloc( *ppBuf, *pnSize );
      }
      memcpy( *ppBuf + *pnPos, cBool, nLen );
      *pnPos += nLen;
   }
   else if( HB_IS_NUMERIC( pItem ) )
   {
      double dVal = hb_itemGetND( pItem );
      long lVal = hb_itemGetNL( pItem );
      if( dVal == ( double ) lVal )
         nLen = sprintf( szNum, "%ld", lVal );
      else
         nLen = sprintf( szNum, "%g", dVal );
      if( *pnPos + nLen >= *pnSize )
      {
         *pnSize = ( *pnSize + nLen + 256 ) * 2;
         *ppBuf = ( char * ) hb_xrealloc( *ppBuf, *pnSize );
      }
      memcpy( *ppBuf + *pnPos, szNum, nLen );
      *pnPos += nLen;
   }
   else if( HB_IS_STRING( pItem ) )
   {
      const char * cStr = hb_itemGetCPtr( pItem );
      ULONG i;
      nLen = hb_itemGetCLen( pItem );
      if( *pnPos + nLen * 6 + 2 >= *pnSize )
      {
         *pnSize = ( *pnSize + nLen * 6 + 256 ) * 2;
         *ppBuf = ( char * ) hb_xrealloc( *ppBuf, *pnSize );
      }
      (*ppBuf)[ (*pnPos)++ ] = '"';
      for( i = 0; i < nLen; i++ )
      {
         char c = cStr[ i ];
         if( c == '"' )       { memcpy( *ppBuf + *pnPos, "\\\"", 2 ); *pnPos += 2; }
         else if( c == '\\' ) { memcpy( *ppBuf + *pnPos, "\\\\", 2 ); *pnPos += 2; }
         else if( c == '\n' ) { memcpy( *ppBuf + *pnPos, "\\n", 2 ); *pnPos += 2; }
         else if( c == '\r' ) { memcpy( *ppBuf + *pnPos, "\\r", 2 ); *pnPos += 2; }
         else if( c == '\t' ) { memcpy( *ppBuf + *pnPos, "\\t", 2 ); *pnPos += 2; }
         else (*ppBuf)[ (*pnPos)++ ] = c;
      }
      (*ppBuf)[ (*pnPos)++ ] = '"';
   }
   else if( HB_IS_ARRAY( pItem ) && json_is_obj( pItem ) )
   {
      ULONG n, nCount = hb_arrayLen( pItem );
      (*ppBuf)[ (*pnPos)++ ] = '{';
      for( n = 1; n <= nCount; n++ )
      {
         PHB_ITEM pPair = hb_arrayGetItemPtr( pItem, n );
         if( n > 1 ) (*ppBuf)[ (*pnPos)++ ] = ',';
         json_encode_item( ppBuf, pnPos, pnSize, hb_arrayGetItemPtr( pPair, 1 ) );
         (*ppBuf)[ (*pnPos)++ ] = ':';
         json_encode_item( ppBuf, pnPos, pnSize, hb_arrayGetItemPtr( pPair, 2 ) );
      }
      (*ppBuf)[ (*pnPos)++ ] = '}';
   }
   else if( HB_IS_ARRAY( pItem ) )
   {
      ULONG n, nCount = hb_arrayLen( pItem );
      (*ppBuf)[ (*pnPos)++ ] = '[';
      for( n = 1; n <= nCount; n++ )
      {
         if( n > 1 ) (*ppBuf)[ (*pnPos)++ ] = ',';
         json_encode_item( ppBuf, pnPos, pnSize, hb_arrayGetItemPtr( pItem, n ) );
      }
      (*ppBuf)[ (*pnPos)++ ] = ']';
   }
   else
   {
      if( *pnPos + 4 >= *pnSize )
      {
         *pnSize = ( *pnSize + 260 ) * 2;
         *ppBuf = ( char * ) hb_xrealloc( *ppBuf, *pnSize );
      }
      memcpy( *ppBuf + *pnPos, "null", 4 );
      *pnPos += 4;
   }
}

HB_FUNC( HB_JSONENCODE )
{
   PHB_ITEM pItem = hb_param( 1, HB_IT_ANY );
   ULONG nSize = 1024;
   ULONG nPos = 0;
   char * cBuf;

   if( pItem == NULL )
   {
      hb_retc( "" );
      return;
   }

   cBuf = ( char * ) hb_xgrab( nSize );
   cBuf[ 0 ] = '\0';

   json_encode_item( &cBuf, &nPos, &nSize, pItem );
   cBuf[ nPos ] = '\0';

   hb_retc_buffer( cBuf );
}

/* ============================================================ */
/* HB_JSONDECODE - string JSON -> arrays / arrays de pares      */
/* Uso PRG: hb_JsonDecode( cJson, @aResult )                    */
/* ============================================================ */
static PHB_ITEM json_decode_value( const char * cJson, ULONG * piPos, ULONG nLen );
static PHB_ITEM json_decode_string( const char * cJson, ULONG * piPos, ULONG nLen );

static void json_skip_ws( const char * cJson, ULONG * piPos, ULONG nLen )
{
   while( *piPos < nLen && ( cJson[ *piPos ] == ' ' || cJson[ *piPos ] == '\t' ||
          cJson[ *piPos ] == '\n' || cJson[ *piPos ] == '\r' ) )
      ( *piPos )++;
}

static PHB_ITEM json_decode_string( const char * cJson, ULONG * piPos, ULONG nLen )
{
   PHB_ITEM pResult;
   ULONG nSize = 256;
   ULONG j = 0;
   char * cBuf;

   if( *piPos >= nLen || cJson[ *piPos ] != '"' )
      return NULL;

   ( *piPos )++;
   cBuf = ( char * ) hb_xgrab( nSize );

   while( *piPos < nLen && cJson[ *piPos ] != '"' )
   {
      if( cJson[ *piPos ] == '\\' && ( *piPos + 1 ) < nLen )
      {
         ( *piPos )++;
         switch( cJson[ *piPos ] )
         {
            case '"':  cBuf[ j++ ] = '"'; break;
            case '\\': cBuf[ j++ ] = '\\'; break;
            case '/':  cBuf[ j++ ] = '/'; break;
            case 'n':  cBuf[ j++ ] = '\n'; break;
            case 'r':  cBuf[ j++ ] = '\r'; break;
            case 't':  cBuf[ j++ ] = '\t'; break;
            case 'b':  cBuf[ j++ ] = '\b'; break;
            case 'f':  cBuf[ j++ ] = '\f'; break;
            default:   cBuf[ j++ ] = cJson[ *piPos ]; break;
         }
      }
      else
      {
         cBuf[ j++ ] = cJson[ *piPos ];
      }
      if( j >= nSize - 2 )
      {
         nSize *= 2;
         cBuf = ( char * ) hb_xrealloc( cBuf, nSize );
      }
      ( *piPos )++;
   }
   cBuf[ j ] = '\0';
   if( *piPos < nLen ) ( *piPos )++;

   pResult = hb_itemPutC( NULL, cBuf );
   hb_xfree( cBuf );
   return pResult;
}

static PHB_ITEM json_arr_new( void )
{
   PHB_ITEM pArr = hb_itemNew( NULL );
   hb_arrayNew( pArr, 0 );
   return pArr;
}

static void json_arr_add( PHB_ITEM pArr, PHB_ITEM pVal )
{
   ULONG nCount = hb_arrayLen( pArr ) + 1;
   hb_arraySize( pArr, nCount );
   if( pVal )
   {
      hb_arraySet( pArr, nCount, pVal );
      hb_itemRelease( pVal );
   }
}

static PHB_ITEM json_decode_object( const char * cJson, ULONG * piPos, ULONG nLen )
{
   PHB_ITEM pObj;
   PHB_ITEM pKey, pVal, pPair;

   json_skip_ws( cJson, piPos, nLen );
   if( *piPos >= nLen || cJson[ *piPos ] != '{' ) return NULL;
   ( *piPos )++;

   pObj = json_arr_new();
   json_skip_ws( cJson, piPos, nLen );

   while( *piPos < nLen && cJson[ *piPos ] != '}' )
   {
      pKey = json_decode_string( cJson, piPos, nLen );
      if( pKey == NULL ) break;

      json_skip_ws( cJson, piPos, nLen );
      if( *piPos < nLen && cJson[ *piPos ] == ':' ) ( *piPos )++;

      pVal = json_decode_value( cJson, piPos, nLen );

      pPair = json_arr_new();
      hb_arraySize( pPair, 2 );
      hb_arraySet( pPair, 1, pKey );
      hb_itemRelease( pKey );
      if( pVal )
      {
         hb_arraySet( pPair, 2, pVal );
         hb_itemRelease( pVal );
      }
      json_arr_add( pObj, pPair );

      json_skip_ws( cJson, piPos, nLen );
      if( *piPos < nLen && cJson[ *piPos ] == ',' ) ( *piPos )++;
      json_skip_ws( cJson, piPos, nLen );
   }

   if( *piPos < nLen ) ( *piPos )++;
   return pObj;
}

static PHB_ITEM json_decode_array( const char * cJson, ULONG * piPos, ULONG nLen )
{
   PHB_ITEM pArr;
   PHB_ITEM pVal;

   json_skip_ws( cJson, piPos, nLen );
   if( *piPos >= nLen || cJson[ *piPos ] != '[' ) return NULL;
   ( *piPos )++;

   pArr = json_arr_new();
   json_skip_ws( cJson, piPos, nLen );

   while( *piPos < nLen && cJson[ *piPos ] != ']' )
   {
      pVal = json_decode_value( cJson, piPos, nLen );
      if( pVal )
         json_arr_add( pArr, pVal );
      else
      {
         PHB_ITEM pNil = hb_itemNew( NULL );
         hb_itemClear( pNil );
         json_arr_add( pArr, pNil );
      }
      json_skip_ws( cJson, piPos, nLen );
      if( *piPos < nLen && cJson[ *piPos ] == ',' ) ( *piPos )++;
      json_skip_ws( cJson, piPos, nLen );
   }

   if( *piPos < nLen ) ( *piPos )++;
   return pArr;
}

static PHB_ITEM json_decode_value( const char * cJson, ULONG * piPos, ULONG nLen )
{
   json_skip_ws( cJson, piPos, nLen );
   if( *piPos >= nLen ) return NULL;

   if( cJson[ *piPos ] == '"' )
      return json_decode_string( cJson, piPos, nLen );
   else if( cJson[ *piPos ] == '{' )
      return json_decode_object( cJson, piPos, nLen );
   else if( cJson[ *piPos ] == '[' )
      return json_decode_array( cJson, piPos, nLen );
   else if( strncmp( cJson + *piPos, "true", 4 ) == 0 )
   {
      *piPos += 4;
      return hb_itemPutL( NULL, 1 );
   }
   else if( strncmp( cJson + *piPos, "false", 5 ) == 0 )
   {
      *piPos += 5;
      return hb_itemPutL( NULL, 0 );
   }
   else if( strncmp( cJson + *piPos, "null", 4 ) == 0 )
   {
      *piPos += 4;
      return NULL;
   }
   else if( cJson[ *piPos ] == '-' || isdigit( ( unsigned char ) cJson[ *piPos ] ) )
   {
      char * cEnd;
      double dVal = strtod( cJson + *piPos, &cEnd );
      *piPos = ( ULONG )( cEnd - cJson );
      return hb_itemPutND( NULL, dVal );
   }

   return NULL;
}

HB_FUNC( HB_JSONDECODE )
{
   const char * cJson = hb_parc( 1 );
   PHB_ITEM pRef = hb_param( 2, HB_IT_BYREF );
   ULONG nLen, iPos = 0;
   PHB_ITEM pDecoded;

   if( cJson == NULL )
   {
      if( pRef ) hb_itemClear( pRef );
      hb_retl( 0 );
      return;
   }

   nLen = strlen( cJson );
   if( nLen >= 3 && (unsigned char)cJson[0] == 0xEF &&
       (unsigned char)cJson[1] == 0xBB && (unsigned char)cJson[2] == 0xBF )
      iPos = 3;

   json_skip_ws( cJson, &iPos, nLen );
   pDecoded = json_decode_value( cJson, &iPos, nLen );

   if( pRef && pDecoded )
      hb_itemCopy( pRef, pDecoded );

   if( pDecoded )
      hb_itemRelease( pDecoded );

   hb_retl( pDecoded != NULL );
}
