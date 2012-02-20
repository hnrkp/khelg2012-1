# ***************************************************************
# *     Makefile for Atmel AT91SAM7S256 - flash execution       *
# *                                                             *
# *                                                             *
# * James P Lynch  September 3, 2006                            *
# ***************************************************************

NAME   = demo_at91sam7_h256_blink_flash

CROSS_COMPILE = arm-none-linux-gnueabi-

# variables 
CC      = $(CROSS_COMPILE)gcc
LD      = $(CROSS_COMPILE)ld -v
AR      = $(CROSS_COMPILE)ar
AS      = $(CROSS_COMPILE)as
CP      = $(CROSS_COMPILE)objcopy
OD		= $(CROSS_COMPILE)objdump

CFLAGS  = -I./ -c -fno-common -O0 -g -fno-unwind-tables
AFLAGS  = -ahls -mapcs-32 -o crt.o
LFLAGS  =  -Map main.map -Tdemo_at91sam7_h256_blink_flash.cmd
CPFLAGS = --output-target=binary
ODFLAGS	= -x --syms

OBJECTS = crt.o	main.o timerisr.o timersetup.o isrsupport.o lowlevelinit.o blinker.o


# make target called by Eclipse (Project -> Clean ...)
clean:
	-rm $(OBJECTS) crt.lst main.lst main.out main.bin main.hex main.map main.dmp

         
#make target called by Eclipse  (Project -> Build Project)
all:  main.out
	@ echo "...copying"
	$(CP) $(CPFLAGS) main.out main.bin
	$(OD) $(ODFLAGS) main.out > main.dmp

main.out: $(OBJECTS) demo_at91sam7_h256_blink_flash.cmd 
	@ echo "..linking"
	$(LD) $(LFLAGS) -o main.out $(OBJECTS) libgcc.a

crt.o: crt.s
	@ echo ".assembling crt.s"
	$(AS) $(AFLAGS) crt.s > crt.lst

main.o: main.c  AT91SAM7S256.h board.h
	@ echo ".compiling main.c"
	$(CC) $(CFLAGS) main.c
	
timerisr.o: timerisr.c  AT91SAM7S256.h board.h
	@ echo ".compiling timerisr.c"
	$(CC) $(CFLAGS) timerisr.c
	
lowlevelinit.o: lowlevelinit.c AT91SAM7S256.h board.h
	@ echo ".compiling lowlevelinit.c"
	$(CC) $(CFLAGS) lowlevelinit.c
	
timersetup.o: timersetup.c AT91SAM7S256.h board.h
	@ echo ".compiling timersetup.c"
	$(CC) $(CFLAGS) timersetup.c
	
isrsupport.o: isrsupport.c
	@ echo ".compiling isrsupport.c"
	$(CC) $(CFLAGS) isrsupport.c

blinker.o: blinker.c AT91SAM7S256.h board.h
	@ echo ".compiling blinker.c"
	$(CC) $(CFLAGS) blinker.c
	


# **********************************************************************************************
#                            FLASH PROGRAMMING      (using OpenOCD and Amontec JTAGKey)
#
# Alternate make target for flash programming only
#
# You must create a special Eclipse make target (program) to run this part of the makefile 
# (Project -> Create Make Target...  then set the Target Name and Make Target to "program")
#
# OpenOCD is run in "batch" mode with a special configuration file and a script file containing
# the flash commands. When flash programming completes, OpenOCD terminates.
#
# Note that the make file below creates the script file of flash commands "on the fly"
#
# Programmers: Martin Thomas, Joseph M Dupre, James P Lynch
# **********************************************************************************************

# specify output filename here (must be *.bin file)
TARGET = main.bin

# specify the directory where openocd executable resides (openocd-ftd2xx.exe or openocd-pp.exe)
OPENOCD_DIR = 'c:\Program Files\openocd-2006re93\bin\'

# specify OpenOCD executable (pp is for the wiggler, ftd2xx is for the USB debugger)
#OPENOCD = $(OPENOCD_DIR)openocd-pp.exe
OPENOCD = $(OPENOCD_DIR)openocd-ftd2xx.exe

# specify OpenOCD configuration file (pick the one for your device)
#OPENOCD_CFG = $(OPENOCD_DIR)at91sam7s256-wiggler-flash-program.cfg
#OPENOCD_CFG = $(OPENOCD_DIR)at91sam7s256-jtagkey-flash-program.cfg
OPENOCD_CFG = $(OPENOCD_DIR)at91sam7s256-armusbocd-flash-program.cfg

# specify the name and folder of the flash programming script file
OPENOCD_SCRIPT = c:\temp\temp.ocd

# program the AT91SAM7S256 internal flash memory
program: $(TARGET)
	@echo "Preparing OpenOCD script..."
	@cmd /c 'echo wait_halt > $(OPENOCD_SCRIPT)'
	@cmd /c 'echo armv4_5 core_state arm >> $(OPENOCD_SCRIPT)'
	@cmd /c 'echo flash write 0 $(TARGET) 0x0 >> $(OPENOCD_SCRIPT)'
	@cmd /c 'echo mww 0xfffffd08 0xa5000401 >> $(OPENOCD_SCRIPT)'
	@cmd /c 'echo reset >> $(OPENOCD_SCRIPT)'
	@cmd /c 'echo shutdown >> $(OPENOCD_SCRIPT)'
	@echo "Flash Programming with OpenOCD..."
	$(OPENOCD) -f $(OPENOCD_CFG)
	@echo "Flash Programming Finished."
