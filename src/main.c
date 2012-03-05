#include "AT91SAM7S256.h"
#include "board.h"
#include "cdc_enumerate.h"
#include "soft_synth.h"
#include "lib_AT91SAM7S256.h"


#define BLINK_DURING_USB_ENUM	0
#define BLINK_AUDIO				0
#define BLINK_CPU_USAGE			1

extern	void LowLevelInit(void);
extern	void TimerSetup(void);
extern  void enableIRQ(void);

#define MSG_SIZE 				100

//  *******************************************************
//               Global Variables
//  *******************************************************
struct _AT91S_CDC 	pCDC;
static struct SYNTH_Device_t synth_dev;

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

__attribute__ ((section (".ramfunc")))
void arne(void)
{
	pCDC.Write(&pCDC, "ARNEN!\n", 7);
}

static void audio_dac(int vol) {
#if BLINK_AUDIO
	volatile AT91PS_PIO	pPIO = AT91C_BASE_PIOA;
  	if  (vol > 0x80)
		pPIO->PIO_CODR = LED1;
	else
		pPIO->PIO_SODR = LED1;
#endif
  	AT91C_BASE_PWMC_CH0->PWMC_CUPDR = 257-vol;
  	 // errata for pwm on AT91 is thiiiiiiick, never do duty full nor low
 }

void Timer0IrqHandler() {
#if BLINK_CPU_USAGE
	volatile AT91PS_PIO	pPIO = AT91C_BASE_PIOA;
	pPIO->PIO_SODR = LED1;
#endif
	volatile AT91PS_TC 		pTC = AT91C_BASE_TC0;		// pointer to timer channel 0 register structure
	pTC->TC_SR++;									// read TC0 Status Register to clear it
	synth_tick(&synth_dev);
#if BLINK_CPU_USAGE
	pPIO->PIO_CODR = LED1;
#endif
}

static void setup_synthesizer() {
	//
	// Set up audio and tune
	//
    synth_init(&synth_dev, audio_dac, 2, 50);
    tune_init(&synth_dev);
    synth_dev.gain = 256/5;

    //
    // Set up pwm for doing dac stuff
    //

    // enable PWM peripheral on PA23
    AT91F_PIO_CfgPeriph( AT91C_BASE_PIOA, 0, AT91C_PA23_PWM0);
    // power things up
    AT91F_PWMC_CfgPMC();
    // set things up
    AT91F_PWMC_StopChannel( AT91C_BASE_PWMC, AT91C_PWMC_CHID0 );
   // CPRE = 10 : MCK/1024
   // CALG = 0  : The period is left aligned
   // CPOL = 1  : The output waveform starts at a high level
   // CPD = 0   : Writing to the PWM_CUPDx will modify the duty cycle at the next period start event
   AT91C_BASE_PWMC_CH0->PWMC_CMR =
		   0x0 |   		// CPRE = Master CLK
		   (0<<8) | 	// CALG 0 = left aligned period, 1 = center aligned
		   (1<<9) |     // CPOL 0 start low, 1 start high
		   (0<<10)      // CPD 0 modify duty cycle at next period, 1 modify period at next start event
		   ;
   // setup the period
   AT91C_BASE_PWMC_CH0->PWMC_CPRDR = 258;
   // setup the duty cycle
   AT91C_BASE_PWMC_CH0->PWMC_CDTYR = 1;
   // enable PWM channel 0
   AT91F_PWMC_StartChannel( AT91C_BASE_PWMC, AT91C_PWMC_CHID0 );


	// Set up the Advanced Interrupt Controller AIC for Timer 0
	// --------------------------------------------------------
	
	volatile AT91PS_PMC	pPMC = AT91C_BASE_PMC;
	// enable Timer0 peripheral clock
	pPMC->PMC_PCER = (1<<AT91C_ID_TC0);

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
	
	TimerSetup();

	enableIRQ();
}

//  *******************************************************
//                     MAIN
//  ******************************************************/
int	main (void) {
#if 0
	unsigned volatile long	j;								// loop counter (stack variable)
	unsigned long	IdleCount = 0;					// idle loop blink counter (2x)
#endif

	// Initialize the Atmel AT91SAM7S256 (watchdog, PLL clock, default interrupts, etc.)
	// ---------------------------------------------------------------------------------
	LowLevelInit();

	volatile AT91PS_PIO	pPIO = AT91C_BASE_PIOA;
	// PIO Output Enable Register - sets pins P0 - P3 to outputs
	pPIO->PIO_OER = LED_MASK;

	// PIO Set Output Data Register - turns off the four LEDs
	pPIO->PIO_SODR = LED_MASK;
	pPIO->PIO_CODR = LED1;

	setup_synthesizer();

	// Init USB device
   AT91F_USB_Open();

  // Init USB device
    // Wait for the end of enumeration
#if BLINK_DURING_USB_ENUM
    int enum_led = 0;
#endif
    while (!pCDC.IsConfigured(&pCDC)) {
#if BLINK_DURING_USB_ENUM
	// blink shortly during enumeration
  	if  (7 & (enum_led++ >> 14))
		pPIO->PIO_SODR = LED1;
	else
		pPIO->PIO_CODR = LED1;
#endif
   }

   // yaay, connected
    pPIO->PIO_CODR = LED1;
    //while(1);

    // Set Usart in interrupt
    //Usart_init();

    int length;
    char data[MSG_SIZE];
    while (1)
    {
    	if  ((pPIO->PIO_ODSR & LED1) == LED1)		// read previous state of LED1
			pPIO->PIO_CODR = LED1;					// turn LED1 (DS1) on
		else
			pPIO->PIO_SODR = LED1; // turn LED1 (DS1) off

    	length = pCDC.Read(&pCDC, data, MSG_SIZE);
    	data[length]=0;
		pCDC.Write(&pCDC, data, length);
		arne();
    }
    return 0;
}

