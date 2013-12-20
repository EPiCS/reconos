 #ifndef XIL_PRINTF_H
 #define XIL_PRINTF_H

#ifdef __cplusplus
extern "C" {
#endif

#include <ctype.h>
#include <string.h>
#include <stdarg.h>
#include "xparameters.h"
#include "xil_types.h"

/*----------------------------------------------------*/
/* Use the following parameter passing structure to   */
/* make xil_printf re-entrant.                        */
/*----------------------------------------------------*/
typedef struct params_s {
    int len;
    int num1;
    int num2;
    char pad_character;
    int do_padding;
    int left_flag;
} params_t;

/*---------------------------------------------------*/
/* The purpose of this routine is to output data the */
/* same as the standard printf function without the  */
/* overhead most run-time libraries involve. Usually */
/* the printf brings in many kilobytes of code and   */
/* that is unacceptable in most embedded systems.    */
/*---------------------------------------------------*/

typedef char* charptr;
typedef int (*func_ptr)(int c);

/*                                                   */
void padding( const int l_flag, params_t *par);
void outs( charptr lp, params_t *par);
void outnum( const long n, const long base, params_t *par);
int getnum( const charptr* linep);
void xil_printf( const char *ctrl1, ...);
void print( char const *ptr);

#ifdef __cplusplus
}
#endif

#endif	/* end of protection macro */
