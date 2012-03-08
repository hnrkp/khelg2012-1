/*identify the Entry Point  (_vec_reset is defined in file crt.s) */
ENTRY(_vec_reset)

/* specify the AT91SAM7S256s64  */
MEMORY 
{
	flash	: ORIGIN = 0,          LENGTH = 256K	/* FLASH EPROM		*/	
	ram		: ORIGIN = 0x00200000, LENGTH = 16K  	/* static RAM area	*/
}


/* define a global symbol _stack_end */
_stack_end = 0x20FFFC;

/* now define the output sections  */
SECTIONS 
{
	. = 0;								/* set location counter to address zero  */
	
	.text :								/* collect all sections that should go into FLASH after startup  */ 
	{
	    *crt.o (.text)					/* boot code */
		*(.text)						/* all .text sections (code)  */
		*(.text.*)
		*(.gnu.linkonce.t.*)
		*(.rodata)						/* all .rodata sections (constants, strings, etc.)  */
		*(.rodata*)						/* all .rodata* sections (constants, strings, etc.)  */
		*(.glue_7)						/* all .glue_7 sections  (no idea what these are) */
		*(.glue_7t)						/* all .glue_7t sections (no idea what these are) */
		*(.gcc_except_table)
		*(.gnu.linkonce.r.*)
/*      . = ALIGN(4); */
		_etext = .;						/* define a global symbol _etext just after the last code byte */
	} >flash							/* put all the above into FLASH */
	
	.data :								/* collect all initialized .data sections that go into RAM  */ 
	{
		_data = .;						/* create a global symbol marking the start of the .data section  */
		*(.data)						/* all .data sections  */
/*      . = ALIGN(4);*/
		_edata = .;						/* define a global symbol marking the end of the .data section  */
	} >ram AT >flash          			/* put all the above into RAM (but load the LMA initializer copy into FLASH)  */

	.bss :								/* collect all uninitialized .bss sections that go into RAM  */
	{
		_bss_start = .;					/* define a global symbol marking the start of the .bss section */
		*(.bss)							/* all .bss sections  */
		*(.gnu.linkonce.b.*)
		*(COMMON)
	} >ram								/* put all the above in RAM (it will be cleared in the startup code */

	. = ALIGN(4);						/* advance location counter to the next 32-bit boundary */
	_bss_end = . ;						/* define a global symbol marking the end of the .bss section */
	_end = .;							/* define a global symbol marking the end of application RAM */

  /* Stabs debugging sections.  */
  .stab          0 : { *(.stab) }
  .stabstr       0 : { *(.stabstr) }
  .stab.excl     0 : { *(.stab.excl) }
  .stab.exclstr  0 : { *(.stab.exclstr) }
  .stab.index    0 : { *(.stab.index) }
  .stab.indexstr 0 : { *(.stab.indexstr) }
  .comment       0 : { *(.comment) }
  /* DWARF debug sections.
     Symbols in the DWARF debugging sections are relative to the beginning
     of the section so we begin them at 0.  */
  /* DWARF 1 */
  .debug          0 : { *(.debug) }
  .line           0 : { *(.line) }
  /* GNU DWARF 1 extensions */
  .debug_srcinfo  0 : { *(.debug_srcinfo) }
  .debug_sfnames  0 : { *(.debug_sfnames) }
  /* DWARF 1.1 and DWARF 2 */
  .debug_aranges  0 : { *(.debug_aranges) }
  .debug_pubnames 0 : { *(.debug_pubnames) }
  /* DWARF 2 */
  .debug_info     0 : { *(.debug_info .gnu.linkonce.wi.*) }
  .debug_abbrev   0 : { *(.debug_abbrev) }
  .debug_line     0 : { *(.debug_line) }
  .debug_frame    0 : { *(.debug_frame) }
  .debug_str      0 : { *(.debug_str) }
  .debug_loc      0 : { *(.debug_loc) }
  .debug_macinfo  0 : { *(.debug_macinfo) }
  /* SGI/MIPS DWARF 2 extensions */
  .debug_weaknames 0 : { *(.debug_weaknames) }
  .debug_funcnames 0 : { *(.debug_funcnames) }
  .debug_typenames 0 : { *(.debug_typenames) }
  .debug_varnames  0 : { *(.debug_varnames) }

}
