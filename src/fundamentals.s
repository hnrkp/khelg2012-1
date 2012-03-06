        .text
        .arm

# void _memcpy16(short* dst, short* src, int len)
# 16 bit memcpy
#
        .global _memcpy16
        .func   _memcpy16
_memcpy16:
   cmp     r2, #16
   blo     .Lmc16_word_loop
.Lmc16_entry32:

    @ --- Block run ---
    stmfd   sp!, {r4-r9}
.Lmc16_block_loop:
    subs    r2, r2, #16
    ldmhsia r1!, {r3-r9, r12}
    stmhsia r0!, {r3-r9, r12}
    bhi     .Lmc16_block_loop
    ldmfd   sp!, {r4-r9}
    bxeq    lr
    addne   r2, r2, #16         @ Correct for overstep in loop

    @ --- Word run (+ trailing halfword) ---
.Lmc16_word_loop:
        subs    r2, r2, #2
        ldrhs	r3, [r1], #4
        strhs   r3, [r0], #4
        bhi     .Lmc16_word_loop
    ldrneh	r3,	[r1], #2
    strneh  r3, [r0], #2        @ r2 != 0 means spare hword left
    bx  lr
        .size   _memcpy16, . - _memcpy16
        .endfunc



# void _memset16(short* addr, short data, int len)
# 16 bit memset
#
        .global _memset16
        .func   _memset16
_memset16:
	mov		r3, #0x10000
	sub		r3, r3, #1
	and		r1, r1, r3
    orr     r1, r1, lsl #16     @ Prep for word fills.

    cmp     r2, #16
    blo     .Lms16_word_loop
 .Lms16_entry32:

    @ --- Block run ---
    stmfd   sp!, {r4-r8}
    mov     r3, r1
    mov     r4, r1
    mov     r5, r1
    mov     r6, r1
    mov     r7, r1
    mov     r8, r1
    mov     r12, r1
.Lms16_block_loop:
    subs    r2, r2, #16
    stmhsia r0!, {r1, r3-r8, r12}
    bhi     .Lms16_block_loop
    ldmfd   sp!, {r4-r8}
    bxeq    lr
    addne   r2, r2, #16         @ Correct for overstep in loop

    @ --- Word run (+ trailing halfword) ---
.Lms16_word_loop:
        subs    r2, r2, #2
        strhs   r1, [r0], #4
        bhi     .Lms16_word_loop
    strneh  r1, [r0], #2        @ r2 != 0 means spare hword left
    bx  lr
        .size   _memset16, . - _memset16
        .endfunc


# int _div(int numerator, int denominator)
# 32 bit signed division
#
        .global _div
        .func   _div
_div:
    EORS    R3, R1, R0, ASR #32
    RSBCS   R0, R0, #0
    CMP     R1, #0
    BEQ     _divByZero

    RSBMI   R1, R1, #0
    MOV     R2, #0x10000000
    CMP     R1, R0, LSR #4
    BHI     _div4bits

_divSkipZeros:
    MOV     R1, R1, LSL #4
    MOV     R2, R2, LSR #4
    CMP     R1, R0, LSR #4
    BLS     _divSkipZeros

_divLoop:

    MOVCC   R1, R1, LSR #4
                
_div4bits:
    RSBS    R12, R1, R0, LSR #3
    SUBCS   R0, R0, R1, LSL #3
    ADC     R2, R2, R2

    RSBS    R12, R1, R0, LSR #2
    SUBCS   R0, R0, R1, LSL #2
    ADC     R2, R2, R2

    RSBS    R12, R1, R0, LSR #1
    SUBCS   R0, R0, R1, LSL #1
    ADC     R2, R2, R2

    RSBS    R12, R1, R0
    SUBCS   R0, R0, R1
    ADCS    R2, R2, R2
    BCC     _divLoop

    EOR     R0, R2, R3, ASR #31
    ADD     R0, R0, R3, LSR #31
    BX      LR

_divByZero:
    MOV     R0, #0
    BX      LR
        .size   _div, . - _div
        .endfunc

        .global _readDCCStat
        .func   _readDCCStat
_readDCCStat:
    mrc     P14,0,R0,C0,C0,0
    bx      lr
        .size   _readDCCStat, . - _readDCCStat
        .endfunc

        .global _readDCC
        .func   _readDCC
_readDCC:
    mrc      P14,0,R0,C1,C0,0
    bx       lr
        .size   _readDCC, . - _readDCC
        .endfunc

        .global _writeDCC
        .func   _writeDCC
_writeDCC:

    mcr      P14,0,R0,C1,C0,0
    bx       lr
        .size   _writeDCC, . - _writeDCC
        .endfunc

  .end
