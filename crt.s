/* ****************************************************************************************************** */
/*   											crt.s	                                                  */
/*                                                                                                        */
/*                       Assembly Language Startup Code for Atmel AT91SAM7S256                            */
/*                                                                                                    	  */
/*                                                                                           			  */
/*                                                                                                        */
/*                                                                                                        */
/* Author:  James P Lynch      September 2, 2006                                                          */
/* ****************************************************************************************************** */

/* Stack Sizes */
.set  UND_STACK_SIZE, 0x00000010		/* stack for "undefined instruction" interrupts is 16 bytes 	 */
.set  ABT_STACK_SIZE, 0x00000010		/* stack for "abort" interrupts is 16 bytes                 	 */
.set  FIQ_STACK_SIZE, 0x00000080		/* stack for "FIQ" interrupts  is 128 bytes     				 */
.set  IRQ_STACK_SIZE, 0X00000080		/* stack for "IRQ" normal interrupts is 128 bytes  				 */
.set  SVC_STACK_SIZE, 0x00000080		/* stack for "SVC" supervisor mode is 128 bytes  				 */

/* Standard definitions of Mode bits and Interrupt (I & F) flags in PSRs (program status registers) 	 */
.set  MODE_USR, 0x10            		/* Normal User Mode 											 */
.set  MODE_FIQ, 0x11            		/* FIQ Processing Fast Interrupts Mode 							 */
.set  MODE_IRQ, 0x12            		/* IRQ Processing Standard Interrupts Mode 						 */
.set  MODE_SVC, 0x13            		/* Supervisor Processing Software Interrupts Mode 				 */
.set  MODE_ABT, 0x17            		/* Abort Processing memory Faults Mode 							 */
.set  MODE_UND, 0x1B            		/* Undefined Processing Undefined Instructions Mode 			 */
.set  MODE_SYS, 0x1F            		/* System Running Priviledged Operating System Tasks  Mode		 */
.set  I_BIT, 0x80               		/* when I bit is set, IRQ is disabled (program status registers) */
.set  F_BIT, 0x40               		/* when F bit is set, FIQ is disabled (program status registers) */

/* Addresses and offsets of AIC and PIO  */
.set  AT91C_BASE_AIC, 0xFFFFF000 		/* (AIC) Base Address                         */
.set  AT91C_PIOA_CODR, 0xFFFFF434		/* (PIO) Clear Output Data Register           */
.set  AT91C_AIC_IVR, 0xFFFFF100			/* (AIC) IRQ Interrupt Vector Register        */
.set  AT91C_AIC_FVR, 0xFFFFF104			/* (AIC) FIQ Interrupt Vector Register        */
.set  AIC_IVR, 256						/* IRQ Vector Register offset from base above */
.set  AIC_FVR, 260						/* FIQ Vector Register offset from base above */
.set  AIC_EOICR, 304					/* End of Interrupt Command Register          */

/* identify all GLOBAL symbols  */
.global _vec_reset						
.global _vec_undef						
.global _vec_swi						
.global _vec_pabt						
.global _vec_dabt						
.global _vec_rsv						
.global _vec_irq						
.global _vec_fiq
.global AT91F_Irq_Handler
.global	AT91F_Fiq_Handler
.global	AT91F_Default_FIQ_handler
.global	AT91F_Default_IRQ_handler
.global	AT91F_Spurious_handler
.global	AT91F_Dabt_Handler
.global	AT91F_Pabt_Handler
.global	AT91F_Undef_Handler


/* GNU assembler controls  */
.text									/* all assembler code that follows will go into .text section	 */
.arm									/* compile for 32-bit ARM instruction set						 */
.align									/* align section on 32-bit boundary								 */

/* ============================================================ */
/* 						VECTOR TABLE     					 	*/
/*																*/
/*	Must be located in FLASH at address 0x00000000				*/
/*																*/
/*	Easy to do if this file crt.s is first in the list 			*/
/*	for the linker step in the makefile, e.g.					*/
/*																*/
/*	    $(LD) $(LFLAGS) -o main.out  crt.o main.o				*/
/*																*/
/* ============================================================ */

_vec_reset:		b           _init_reset				/* RESET vector - must be at 0x00000000	*/
_vec_undef:		b           AT91F_Undef_Handler		/* Undefined Instruction vector			*/
_vec_swi:		b           _vec_swi				/* Software Interrupt vector			*/
_vec_pabt:		b           AT91F_Pabt_Handler		/* Prefetch abort vector				*/
_vec_dabt:		b           AT91F_Dabt_Handler		/* Data abort vector					*/
_vec_rsv:		nop                     			/* Reserved vector						*/
_vec_irq:		b           AT91F_Irq_Handler		/* Interrupt Request (IRQ) vector		*/
_vec_fiq:		                         			/* Fast interrupt request (FIQ) vector	*/

/* ======================================================================== */
/* Function: 			AT91F_Fiq_Handler	       			 				*/
/*                                                                        	*/
/* The FIQ interrupt asserts when switch SW1 is pressed.                    */
/*																			*/
/* This simple FIQ handler turns on LED3 (Port PA2). The LED3 will be       */
/* turned off by the background loop in main() thus giving a visual         */
/* indication that the interrupt has occurred.                              */
/*																			*/
/* This FIQ_Handler supports non-nested FIQ interrupts (a FIQ interrupt 	*/
/* cannot itself be interrupted).											*/
/*	                                               							*/
/* The Fast Interrupt Vector Register (AIC_FVR) is read to clear the        */
/* interrupt.                                                             	*/
/*                                                                        	*/
/* A global variable FiqCount is also incremented.							*/
/*																			*/
/* Remember that switch SW1 is not debounced, so the FIQ interrupt may   	*/
/* occur more than once for a single button push.                           */
/*																			*/
/* Programmer: James P Lynch												*/
/* ======================================================================== */
AT91F_Fiq_Handler:

/* Adjust LR_irq */
				sub		lr, lr, #4

/* Read the AIC Fast Interrupt Vector register to clear the interrupt */
				ldr		r12, =AT91C_AIC_FVR
				ldr		r11, [r12]
				
/* Turn on LED3 (write 0x0008 to PIOA_CODR at 0xFFFFF434) */
				ldr		r12, =AT91C_PIOA_CODR
				mov		r11, #0x04
				str		r11, [r12]

/* Increment the _FiqCount variable */
				ldr		r12, =FiqCount
				ldr		r11, [r12]
				add		r11, r11, #1
				str		r11, [r12]

/* Return from Fiq interrupt */
				movs	pc, lr


/* ======================================================================== */
/* 				  _init_reset Handler                                       */
/*																            */
/*	 RESET vector 0x00000000 branches to here.                              */
/*	                                                                        */
/*	 _init_reset handler:  creates a stack for each ARM mode.               */
/*	                       sets up a stack pointer for each ARM mode.       */
/*	                       turns off interrupts in each mode.               */
/*						   leaves CPU in SYS (System) mode.                 */
/*	                                                   			            */
/*	                       block copies the initializers to .data section   */
/*						   clears the .bss section to zero	                */
/*	                                             				            */
/*						   branches to main( ) 					            */
/* ======================================================================== */
.text			/* all assembler code that follows will go into .text section	 */
.align			/* align section on 32-bit boundary								 */
_init_reset: 
				/* Setup a stack for each mode with interrupts initially disabled. */
    			ldr	  r0, =_stack_end					/* r0 = top-of-stack  */
    			
    			msr   CPSR_c, #MODE_UND|I_BIT|F_BIT 	/* switch to Undefined Instruction Mode  */
    			mov   sp, r0							/* set stack pointer for UND mode  */
    			sub   r0, r0, #UND_STACK_SIZE			/* adjust r0 past UND stack  */
    			
    			msr   CPSR_c, #MODE_ABT|I_BIT|F_BIT 	/* switch to Abort Mode */
    			mov   sp, r0							/* set stack pointer for ABT mode  */
    			sub   r0, r0, #ABT_STACK_SIZE			/* adjust r0 past ABT stack  */
    			
    			msr   CPSR_c, #MODE_FIQ|I_BIT|F_BIT 	/* switch to FIQ Mode */
    			mov   sp, r0							/* set stack pointer for FIQ mode  */	
   				sub   r0, r0, #FIQ_STACK_SIZE			/* adjust r0 past FIQ stack  */
   				
    			msr   CPSR_c, #MODE_IRQ|I_BIT|F_BIT 	/* switch to IRQ Mode */
    			mov   sp, r0							/* set stack pointer for IRQ mode  */
    			sub   r0, r0, #IRQ_STACK_SIZE			/* adjust r0 past IRQ stack  */
    			
    			msr   CPSR_c, #MODE_SVC|I_BIT|F_BIT 	/* switch to Supervisor Mode */
    			mov   sp, r0							/* set stack pointer for SVC mode  */
    			sub   r0, r0, #SVC_STACK_SIZE			/* adjust r0 past SVC stack  */
    			
    			msr   CPSR_c, #MODE_SYS|I_BIT|F_BIT 	/* switch to System Mode */
    			mov   sp, r0							/* set stack pointer for SYS mode  */
    													/* we now start execution in SYSTEM mode */
    													/* This is exactly like USER mode (same stack) */
    													/* but SYSTEM mode has more privileges */

				/* copy initialized variables .data section  (Copy from ROM to RAM) */
                ldr     R1, =_etext
                ldr     R2, =_data
                ldr     R3, =_edata
1:        		cmp     R2, R3
                ldrlo   R0, [R1], #4
                strlo   R0, [R2], #4
                blo     1b

				/* Clear uninitialized variables .bss section (Zero init)  */
                mov     R0, #0
                ldr     R1, =_bss_start
                ldr     R2, =_bss_end
2:				cmp     R1, R2
                strlo   R0, [R1], #4
                blo     2b

				/* Enter the C code  */
                b       main




/* ======================================================================== */
/* Function: 			AT91F_Irq_Handler	       			 				*/
/*																			*/
/* This IRQ_Handler supports nested interrupts (an IRQ interrupt can itself	*/
/* be interrupted).															*/
/*	                                               							*/
/* This handler re-enables interrupts and switches to "Supervisor" mode to  */
/* prevent any corruption to the link and IP registers.						*/
/*	                                               							*/
/* The Interrupt Vector Register (AIC_IVR) is read to determine the address */
/* of the required interrupt service routine. The ISR routine can be a 		*/
/* standard C function since this handler minds all the save/restore 		*/
/* protocols.																*/
/*																			*/
/*																			*/
/* Programmer: James P. Lynch												*/
/* ======================================================================== */
AT91F_Irq_Handler:

/* Adjust link register and save r0 and lr on IRQ stack */
				sub		lr, lr, #4
				stmfd	sp!, {r0, lr}
				
/*- SPSR needs to be saved on IRQ stack for nested interrupt */
				mrs		r14, SPSR
				stmfd	sp!, {r14}

/* Read the AIC Interrupt Vector register to clear the interrupt and fetch IRQ handler address */
				ldr		r14, =AT91C_AIC_IVR
				ldr		r0 , [r14]

/* Enable IRQ interrupts and switch to Supervisor mode */
				msr		CPSR_c, #MODE_SVC
				
/* Save scratch/used registers and LR in Supervisor Stack */
				stmfd	sp!, { r1-r3, r12, r14}

/* Branch to the C language routine pointed by the AIC_IVR */
				mov		r14, pc
				bx		r0

/* Restore scratch/used registers and LR from Supervisor Stack */
				ldmia	sp!, { r1-r3, r12, r14}

/* Disable IRQ interrupts and switch back to IRQ mode */
    			msr		CPSR_c, #MODE_IRQ | I_BIT

/* Mark the End of Interrupt on the AIC */
				ldr		r14, =AT91C_BASE_AIC
				str		r14, [r14, #AIC_EOICR]

/* Restore SPSR_irq and r0 from IRQ stack */
				ldmia	sp!, {r14}
				msr		SPSR_cxsf, r14
				
/* pop r0 and lr from IRQ stack and restore the SPSR_irq; this returns from IRQ interrupt */
				ldmia	sp!, {r0, pc}^				
				


/* ======================================================================== */
/* Function: 			AT91F_Dabt_Handler	       			 				*/
/*																			*/
/* Entered on Data Abort exception.                    						*/
/* Enters blink routine  (3 blinks followed by a pause)                		*/
/* processor hangs in the blink loop forever								*/
/*																			*/
/* ======================================================================== */
AT91F_Dabt_Handler:			mov     R0, #3
							b 		blinker
							
										
/* ======================================================================== */
/* Function: 			AT91F_Pabt_Handler	       			 				*/
/*																			*/
/* Entered on Prefetch Abort exception.                						*/
/* Enters blink routine  (2 blinks followed by a pause)                		*/
/* processor hangs in the blink loop forever								*/
/*																			*/
/* ======================================================================== */
AT91F_Pabt_Handler:			mov     R0, #2
							b 		blinker			
							
										
/* ======================================================================== */
/* Function: 			AT91F_Undef_Handler	       			 				*/
/*																			*/
/* Entered on Undefined Instruction exception.         						*/
/* Enters blink routine  (1 blinks followed by a pause)                		*/
/* processor hangs in the blink loop forever								*/
/*																			*/
/* ======================================================================== */
AT91F_Undef_Handler:		mov     R0, #1
							b 		blinker			


AT91F_Default_FIQ_handler:	b	AT91F_Default_FIQ_handler

AT91F_Default_IRQ_handler:	b	AT91F_Default_IRQ_handler

AT91F_Spurious_handler:		b	AT91F_Spurious_handler
.end
