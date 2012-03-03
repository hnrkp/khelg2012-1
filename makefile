BINARY = sketnisse

############
#
# Paths
#
############

CROSS_COMPILE=arm-none-eabi-

sourcedir = src
builddir = build
armdir = arm
thumbdir = thumb

#############
#
# Build tools
#
#############

CC = $(CROSS_COMPILE)gcc $(COMPILEROPTIONS)
AS = $(CROSS_COMPILE)gcc $(ASSEMBLEROPTIONS)
LD = $(CROSS_COMPILE)ld
GDB = $(CROSS_COMPILE)gdb
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump
MKDIR = mkdir -p

###############
#
# Build configs
#
###############

INCLUDE_DIRECTIVES = -I./${sourcedir} 
COMPILEROPTIONS = $(INCLUDE_DIRECTIVES) -mcpu=arm7tdmi -mlittle-endian -Os -mthumb-interwork -Wall -gdwarf-2
ASSEMBLEROPTIONS = $(INCLUDE_DIRECTIVES) -mcpu=arm7tdmi -mlittle-endian -x assembler-with-cpp -mthumb-interwork -gdwarf-2
LINKERSCRIPT = arm.ld
LINKEROPTIONS = -e 0
OBJCOPYOPTIONS_HEX = -O ihex ${builddir}/$(BINARY).elf
OBJCOPYOPTIONS_BIN = -O binary ${builddir}/$(BINARY).elf

###############
#
# Files and libs
#
###############

ASFILES = crt.s fundamentals.s
THUMBFILES =  lowlevelinit.c main.c timerisr.c timersetup.c interrupt_Usart.c cdc_enumerate.c  blinker.c
ARMFILES =
#ARMFILES =   
ARMFILES += isrsupport.c

LIBS=

BINARYEXT = .hex

############
#
# Tasks
#
############

vpath %.c ${sourcedir}
vpath %.s ${sourcedir}

ASOBJFILES = $(ASFILES:%.s=${builddir}/${armdir}/%.o)
ARMOBJFILES = $(ARMFILES:%.c=${builddir}/${armdir}/%.o)
THUMBOBJFILES = $(THUMBFILES:%.c=${builddir}/${thumbdir}/%.o)

ARMDEPFILES = $(ARMFILES:%.c=${builddir}/${armdir}/%.d)
THUMBDEPFILES = $(THUMBFILES:%.c=${builddir}/${thumbdir}/%.d)

ALLOBJFILES  = $(ASOBJFILES)
ALLOBJFILES += $(ARMOBJFILES)
ALLOBJFILES += $(THUMBOBJFILES)

DEPENDENCIES = $(THUMBDEPFILES) $(ARMDEPFILES) 

# link object files, create binary for flashing
$(BINARY): $(ALLOBJFILES)
	@echo "... linking"
	@${LD} $(LINKEROPTIONS) -T $(LINKERSCRIPT) -Map ${builddir}/$(BINARY).map -o ${builddir}/$(BINARY).elf $(ALLOBJFILES) $(LIBS)
	@echo "... objcopy"
	@${OBJCOPY} $(OBJCOPYOPTIONS_BIN) ${builddir}/$(BINARY).out
	@${OBJCOPY} $(OBJCOPYOPTIONS_HEX) ${builddir}/$(BINARY)$(BINARYEXT) 
	@echo "... disasm"
	@${OBJDUMP} -d -S ${builddir}/$(BINARY).elf > ${builddir}/$(BINARY)_disasm.s
	@echo "${BINARY}.out is `du -b ${builddir}/${BINARY}.out | sed 's/\([0-9]*\).*/\1/g '` bytes on flash"

-include $(DEPENDENCIES)	   	

# compile assembly files, arm
$(ASOBJFILES) : ${builddir}/${armdir}/%.o:%.s
		@echo "... assembly $@"
		@${AS} -c -o $@ $<
		
# compile c files, arm
$(ARMOBJFILES) : ${builddir}/${armdir}/%.o:%.c
		@echo "... arm compile $@"
		@${CC} -c -o $@ $<

# compile c files, thumb
$(THUMBOBJFILES) : ${builddir}/${thumbdir}/%.o:%.c
		@echo "... thumb compile $@"
		@${CC} -mthumb -c -o $@ $<

# make dependencies
$(THUMBDEPFILES) : ${builddir}/${thumbdir}/%.d:%.c
		@echo "... thumb dep $@"; \
		rm -f $@; \
		${CC} $(COMPILEROPTIONS) -M -mthumb $< > $@.$$$$; \
		sed 's,\($*\)\.o[ :]*, ${builddir}/${thumbdir}/\1.o $@ : ,g' < $@.$$$$ > $@; \
		rm -f $@.$$$$

$(ARMDEPFILES) : ${builddir}/${armdir}/%.d:%.c
		@echo "... arm dep $@"; \
		rm -f $@; \
		${CC} $(COMPILEROPTIONS) -M $< > $@.$$$$; \
		sed 's,\($*\)\.o[ :]*, ${builddir}/${armdir}/\1.o $@ : ,g' < $@.$$$$ > $@; \
		rm -f $@.$$$$

all: info mkdirs $(BINARY)

info:
	@echo "* Building to ${builddir}"
	@echo "* Compiler options:  $(COMPILEROPTIONS)" 
	@echo "* Assembler options: $(ASSEMBLEROPTIONS)" 
	@echo "* Linker options:    $(LINKEROPTIONS)" 
	@echo "* Linker script:     ${LINKERSCRIPT}"
	
mkdirs:
	-@${MKDIR} ${builddir}/${armdir}
	-@${MKDIR} ${builddir}/${thumbdir}
	
clean:
	@echo ... removing build files in ${builddir}
	@rm -f ${builddir}/${armdir}/*.o
	@rm -f ${builddir}/${thumbdir}/*.o
	@rm -f ${builddir}/${armdir}/*.d
	@rm -f ${builddir}/${thumbdir}/*.d
	@rm -f ${builddir}/*.out
	@rm -f ${builddir}/*.hex
	@rm -f ${builddir}/*.elf
	@rm -f ${builddir}/*.map
	@rm -f ${builddir}/*_disasm.s
	@rm -f _sam7flash.script

install: $(BINARY)
	@sed 's/BUILDFILE/${builddir}\/${BINARY}.out/' sam7flash.script >_sam7flash.script
	@echo "script _sam7flash.script\nexit\n" | nc localhost 4444
	

debug: $(BINARY)
	@${GDB} ${builddir}/${BINARY}.elf -x debug.gdb
