/*
 * HB_HASH.C - hb_Hash() para xHarbour 0.82
 * Crea hash: hb_Hash("key1", val1, "key2", val2, ...)
 * En xHarbour 0.82 los hashes son HB_IT_ARRAY con API interna
 */

#include "hbapi.h"
#include "hbapiitm.h"

/* Forward declarations - funciones de hashapi.h + runtime xHarbour */
extern PHB_ITEM hb_hashNew( PHB_ITEM pItem );
extern BOOL hb_hashAddForward( PHB_ITEM pHash, ULONG ulPos, PHB_ITEM pKey, PHB_ITEM pValue );
extern ULONG hb_hashLen( PHB_ITEM pHash );
extern void hb_itemClear( PHB_ITEM pItem );
extern void hb_itemReturnRelease( PHB_ITEM pItem );
extern void hb_itemClear( PHB_ITEM pItem );
extern void hb_itemReturnRelease( PHB_ITEM pItem );

HB_FUNC( HB_HASH )
{
   long nCount = hb_pcount();
   PHB_ITEM pHash;
   long n;

   pHash = hb_hashNew( NULL );

   for( n = 1; n <= nCount; n += 2 )
   {
      PHB_ITEM pKey = hb_param( n, HB_IT_ANY );
      PHB_ITEM pValue = ( n + 1 <= nCount ) ? hb_param( n + 1, HB_IT_ANY ) : NULL;

      if( pKey && ! HB_IS_NIL( pKey ) )
      {
         if( pValue )
         {
            hb_hashAddForward( pHash, hb_hashLen( pHash ) + 1, pKey, pValue );
         }
         else
         {
            PHB_ITEM pNil = hb_itemNew( NULL );
            hb_itemClear( pNil );
            hb_hashAddForward( pHash, hb_hashLen( pHash ) + 1, pKey, pNil );
            hb_itemRelease( pNil );
         }
      }
   }

   hb_itemReturnRelease( pHash );
}
