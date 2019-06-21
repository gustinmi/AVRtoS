/*
 * FILE: addressing.asm
 * Addressing of FLASH and SRAM. Execute 4 tasks defined in FLASH
 * Pointer to current task is saved into SRAM.
 * It shows conteptualoly, how flash pointers (address) is saved into
 * SRAM, where it occupys 2 bytes ( 1 word)
 * Author: Mitja Gustin gustinmi [at] gmail [dot] com
 */ 
 .dseg

 SCHPTR: .byte 2 ; pointer to current task (pointer) table in FLASH
 ; two locations are reserved because FLASH addresses are 16 bit in length

.cseg
.org 0x0000

	; initialize stack pointer (end of SRAM upwards)
	ldi r16, high(RAMEND) ; init stack pointer
	out SPH, r16 ; Set Stack Pointer to top of RAM
	ldi r16, low(RAMEND)
	out SPL, r16
	
	eor	r1, r1 ; empty r1, it's a convention
	
	; initialize SCHPTR; can only use Z register for FLASH
	; we will shift 14bit long flash addresses by one
	; so that we can get lower and higher data fro one 16 bit cell
	; into 8bit registers
	ldi ZL, low(ptrs << 1)	; load start of table of pointers 
	ldi ZH, high(ptrs << 1) ; (points to FLASH )
	sts SCHPTR, ZH			; store FLASH pointer to SRAM (big endian)
	sts SCHPTR+1, ZL 

SCHOK:
	lds ZH, SCHPTR   ; load PTR to FLASH from SRAM
	lds ZL, SCHPTR+1 
	lpm r16, Z+		 ; load VAL  of the pointer to register
	lpm r17, Z		 
	mov ZL, r16      ; move it to index register Z for icall
	mov ZH, r17
	icall ; execute instruction at (value of the pointer)

	lds r25, SCHPTR   ; load PTR to FLASH from SRAM
	lds r24, SCHPTR+1 
	adiw r25:r24, 2 ; increment pointer to FLASH for one word location
	sts SCHPTR, r25 ; store new PTR location
	sts SCHPTR+1, r24
	rjmp SCHOK ; jump to executor

err:
	rjmp err ; hang in error loop 

; Definition of four tasks

loop:           
	inc r23 ; dummy
	ret ; return to scheduler 
	
bra: 
	inc r23 ; dummy 
	ret ; return to scheduler

.org 0x03fb ; align scheduler ptr table with the FLASH end

ptrs: ; pointer array to interrrupt handlers; scheduler will pick one after one
	.dw bra
	.dw loop
	.dw loop
	.dw bra