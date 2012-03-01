//  *****************************************************************************
//   						main.c
// 
//     Demonstration program for Olimex SAM7-H256 Evaluation Board
//
//     blinks LED0 (pin PA8) with an endless loop
//
//  Authors:  James P Lynch  September 23, 2006; Olimex, Mar 2007
//  *****************************************************************************
 
//  *******************************************************
//                Header Files
//  *******************************************************
//#include "lib_AT91SAM7S256.h"

#include "AT91SAM7S256.h"

#include "board.h"


#include "cdc_enumerate.h"

extern void Usart_init ( void );
extern void AT91F_US_Put( char *buffer); // \arg pointer to a string ending by \0

//  *******************************************************
//                Function Prototypes
//  *******************************************************
void Timer0IrqHandler(void);
void FiqHandler(void);

//  *******************************************************
//                External References
//  *******************************************************
extern	void LowLevelInit(void);
extern	void TimerSetup(void);
extern	unsigned enableIRQ(void);
extern	unsigned enableFIQ(void);

//  *******************************************************
//               Global Variables
//  *******************************************************
unsigned int	FiqCount = 0;		// global uninitialized variable		

struct _AT91S_CDC 	pCDC;

void AT91F_USB_Open(void)
{
    // Set the PLL USB Divider
    AT91C_BASE_CKGR->CKGR_PLLR |= AT91C_CKGR_USBDIV_1 ;

    // Specific Chip USB Initialisation
    // Enables the 48MHz USB clock UDPCK and System Peripheral USB Clock
    AT91C_BASE_PMC->PMC_SCER = AT91C_PMC_UDP;
    AT91C_BASE_PMC->PMC_PCER = (1 << AT91C_ID_UDP);

    // Enable UDP PullUp (USB_DP_PUP) : enable & Clear of the corresponding PIO
    // Set in PIO mode and Configure in Output
    AT91F_PIO_CfgOutput(AT91C_BASE_PIOA,AT91C_PIO_PA16);
    // Clear for set the Pul up resistor
    AT91F_PIO_ClearOutput(AT91C_BASE_PIOA,AT91C_PIO_PA16);

    // CDC Open by structure initialization
    AT91F_CDC_Open(&pCDC, AT91C_BASE_UDP);
}

//  *******************************************************
//                     MAIN
//  ******************************************************/
int	main (void) {
	unsigned volatile long	j;								// loop counter (stack variable)
	unsigned long	IdleCount = 0;					// idle loop blink counter (2x)
	
	// Initialize the Atmel AT91SAM7S256 (watchdog, PLL clock, default interrupts, etc.)
	// ---------------------------------------------------------------------------------
	LowLevelInit();


	
	// Turn on the peripheral clock for Timer0
	// ---------------------------------------
	
	// pointer to PMC data structure
	volatile AT91PS_PMC	pPMC = AT91C_BASE_PMC;
	
	// enable Timer0 peripheral clock		
	pPMC->PMC_PCER = (1<<AT91C_ID_TC0);	
	
	
	// Set up the PIO ports
	// --------------------			

	// pointer to PIO data structure
	volatile AT91PS_PIO	pPIO = AT91C_BASE_PIOA;


	// PIO Output Enable Register - sets pins P0 - P3 to outputs			
	pPIO->PIO_OER = LED_MASK;
	
	// PIO Set Output Data Register - turns off the four LEDs						
	pPIO->PIO_SODR = LED_MASK;						
	pPIO->PIO_CODR = LED1;
	
	// Set up the Advanced Interrupt Controller AIC for Timer 0
	// --------------------------------------------------------
	
	// pointer to AIC data structure  
	volatile AT91PS_AIC	pAIC = AT91C_BASE_AIC;
										
	// Disable timer 0 interrupt in AIC Interrupt Disable Command Register		
	pAIC->AIC_IDCR = (1<<AT91C_ID_TC0);												
	
	// Set the TC0 IRQ handler address in AIC Source Vector Register[12]
	pAIC->AIC_SVR[AT91C_ID_TC0] = (unsigned int)Timer0IrqHandler;				
	
	// Set the interrupt source type and priority in AIC Source Mode Register[12]
	pAIC->AIC_SMR[AT91C_ID_TC0] = (AT91C_AIC_SRCTYPE_INT_HIGH_LEVEL | 0x4 );	
	
	// Clear the TC0 interrupt in AIC Interrupt Clear Command Register
	pAIC->AIC_ICCR = (1<<AT91C_ID_TC0); 										
	
	// Remove disable timer 0 interrupt in AIC Interrupt Disable Command Register			
	pAIC->AIC_IDCR = (0<<AT91C_ID_TC0);											
	
	// Enable the TC0 interrupt in AIC Interrupt Enable Command Register
	pAIC->AIC_IECR = (1<<AT91C_ID_TC0); 										
	
	
	
	// Set up the Advanced Interrupt Controller AIC for FIQ (pushbutton SW1)
	// ---------------------------------------------------------------------
	
    // Disable FIQ interrupt in AIC Interrupt Disable Command Register	
	pAIC->AIC_IDCR = (1<<AT91C_ID_FIQ);													
	
	// Set the interrupt source type in AIC Source Mode Register[0]
	pAIC->AIC_SMR[AT91C_ID_FIQ] = (AT91C_AIC_SRCTYPE_INT_POSITIVE_EDGE);		
	
	// Clear the FIQ interrupt in AIC Interrupt Clear Command Register
	pAIC->AIC_ICCR = (1<<AT91C_ID_FIQ); 										
	
	// Remove disable FIQ interrupt in AIC Interrupt Disable Command Register		
	pAIC->AIC_IDCR = (0<<AT91C_ID_FIQ);												
	
	// Enable the FIQ interrupt in AIC Interrupt Enable Command Register
	pAIC->AIC_IECR = (1<<AT91C_ID_FIQ); 										
	
	
	// Setup timer0 to generate a 50 msec periodic interrupt
	// -----------------------------------------------------
	
	TimerSetup();


	// enable interrupts
	// -----------------
	
	enableIRQ();
	enableFIQ();

    // Init USB device
   AT91F_USB_Open();

#define MSG_SIZE 				100


    // Init USB device
    // Wait for the end of enumeration
   while (!pCDC.IsConfigured(&pCDC));

   pPIO->PIO_CODR = LED1;
   //while(1);

  //* Set led 1e LED's.
    //AT91F_PIO_ClearOutput( AT91C_BASE_PIOA, AT91B_LED1 ) ;
    // Set Usart in interrupt
    Usart_init();
   //* Set led all LED's.
    //AT91F_PIO_ClearOutput( AT91C_BASE_PIOA, AT91B_LED_MASK ) ;

    int length;
    char data[MSG_SIZE];
    while (1)
   {       // Loop
		if  ((pPIO->PIO_ODSR & LED1) == LED1)		// read previous state of LED1
			pPIO->PIO_CODR = LED1;					// turn LED1 (DS1) on
		else
			pPIO->PIO_SODR = LED1; // turn LED1 (DS1) off

	  length = pCDC.Read(&pCDC, data, MSG_SIZE);
  	  data[length]=0;
	  //Trace_Toggel_LED( AT91B_LED1) ;
        AT91F_US_Put(data);
        //
        AT91F_US_Put("arne\n\0");
    	  //AT91F_US_PutChar(COM0, 'U');
   }

	// endless background blink loop
	// -----------------------------

	while (1) {
		if  ((pPIO->PIO_ODSR & LED1) == LED1)		// read previous state of LED1
			pPIO->PIO_CODR = LED1;					// turn LED1 (DS1) on	
		else
			pPIO->PIO_SODR = LED1; // turn LED1 (DS1) off
		
		for (j = 3000000; j != 0; j-- );			// wait 1 second  2000000
	
		IdleCount++;								// count # of times through the idle loop

	}
}

