/*
 * FILE: addressing.asm
 * Addressing of FLASH and SRAM
 * Created: 9. 05. 2019 19:16:50
 * Author: gustin
 */ 
 .dseg
 SCHPTR: .byte 2 ; pointer to pointer table in FLASH

.cseg
.org 0x0000

	; initialize stack pointer (end of SRAM upwards)
	ldi r16, high(RAMEND) ; init stack pointer
	out SPH, r16 ; Set Stack Pointer to top of RAM
	ldi r16, low(RAMEND)
	out SPL, r16
	
	eor	r1, r1 ; empty r1
	; initialize SCHPTR; can only use Z register for FLASH
	ldi ZL, low(ptrs << 1)	; load start of table of pointers 
	ldi ZH, high(ptrs << 1) ; (points to FLASH )
	;lpm r16, Z+				; put it into register pair, increment Z
	;lpm r17, Z				; 
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

loop:           
	inc r23 ; dummy
	inc r23 ; dummy 
	ret ; return to scheduler 
	
bra: 
	inc r23 ; dummy
	inc r23 ; dummy 
	ret ; return to scheduler


.org 0x03fb ; put scheduler table at the and of FLASH

ptrs: ; pointer array to interrrupt handlers; scheduler will pick one after one
	.dw bra
	.dw loop
	.dw loop
	.dw bra