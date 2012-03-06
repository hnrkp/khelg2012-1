//  *****************************************************************************
//   						blinker.c
// 
//     Endless loop blinks a code for crash analysis
//     
//	   Inputs:	Code  -  blink code to display
//						 1 = undefined instruction (one blinks ........ long pause)
//						 2 = prefetch abort        (two blinks ........ long pause)
//						 3 = data abort            (three blinks ...... long pause)
//
//  Author:  James P Lynch  July 12, 2006
//  ***************************************************************************** 

#include "AT91SAM7S256.h"
#include "board.h"

#define SPEAKER	(1<<23)
void  error_handler(unsigned char    code) {
	volatile AT91PS_PIO		pPIO = AT91C_BASE_PIOA;			// pointer to PIO register structure
	volatile unsigned int	j,k,l;							// loop counters

	pPIO->PIO_PER = SPEAKER | LED1; // Set in PIO mode
	pPIO->PIO_OER = SPEAKER | LED1; // Configure in Output
		
	// find out if clock is slow or quick
	int clock = AT91C_BASE_PMC->PMC_MCFR & (1<<16) ? 32 : 1;

	// endless loop, blinking and beeping
	while (1)  {	
		for  (j = code; j != 0; j--) {						// count out the proper number of blinks
			pPIO->PIO_CODR = LED1;							// turn LED1 (DS1) on	
			for (k = clock*16; k > 0; k-- ) {
				pPIO->PIO_SODR = SPEAKER;
				for (l = clock; l > 0; l--);
				pPIO->PIO_CODR = SPEAKER;
				for (l = clock*32; l > 0; l--);
			}
			pPIO->PIO_SODR = LED1;							// turn LED1 (DS1) off
			for (k = clock*16; k > 0; k-- ) {
				pPIO->PIO_CODR = SPEAKER;
				for (l = clock; l > 0; l--);
				pPIO->PIO_CODR = SPEAKER;
				for (l = clock*32; l > 0; l--);
			}
		}
		for (k = clock*32768; (code != 0) && (k > 0); k-- );	// wait 2 seconds
	}	
}
