/*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*
 * utils.h -
 *     
\*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*/

#ifndef  __UTILS__H
#define  __UTILS__H


#define  LINE_SIZE 1000


void        replaceExt( char     * str, char    * ext );
bool        isFileExists( char     * file );
bool        isFileExtExists( char  * oldName, char  * ext );


#else   /* __UTILS__H */
#error  Header file utils.h included twice
#endif  /* __UTILS__H */

/* utils.h - End of File ------------------------------------------*/
