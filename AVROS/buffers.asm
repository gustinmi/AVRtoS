/*
 * buffers.asm
 *
 *  Created: 26.5.2019 19:05:09
 *   Author: gustin
 */ 

 .dseg
.org SRAM_START

; pointers for static circular buffers

; UART transmitting buffer with a capacity of 64 characters.
TRAB:  .byte 3+64 ; transmitting buffer begin 
TRAE: .byte 2 ; transmitting buffer end 

; UART receiving buffer with capacity of 8 chars
RECB: .byte 3+9 ; receiving buffer begin 
RECE: .byte 2 ; receiving buffer end 

  .cseg
.org 0x0000

START: 
	; Clear the UART transmitting buffer
	; (both pointers point to same location)
	ldi ZH, high(TRAB+2)
	ldi ZL, low(TRAB+2) 
	sts TRAB, ZH
	sts TRAB+1, ZL
	sts TRAE, ZH
	sts TRAE+1, ZL

	ldi r16, 0xff
	call TRACHR
	ldi r16, 0x1f
	call TRACHR
	ldi r16, 0x2f
	call TRACHR
	ldi r16, 0x3f
	call TRACHR

	rjmp start

;  Place binary in r16 to the SCI transmitting buffer TRAB-TRAE. In case of a     
;  full buffer, the procedure returns Z=1, otherwise Z=0. The contents of all   
;  registers are preserved. This procedure must never be interrupted by another 
;  call to TRACHR!                                                              
;------------------------------------------------------------------------------ 
TRACHR:
	push ZH ; save index register Z 
	push ZL ; to stack
	push XH ; save index register Z 
	push XL ; to stack

	; Z pointer to konec

	ldi ZH, high(TRAE) ; nalo�i logi�ni konec medpomnilnika v X
	ldi ZL, low(TRAE) 
	st Z+, r16	 ; in zapi�e znak iz r16 v medpomnilnik in pove�a kazalec Z za 1
	
	; X pointer to physical end

	ldi XL, LOW(TRAE) ; nalo�i fizi�ni konec medpomnilnika
	ldi XH, HIGH(TRAE) ;  
	
	cp ZL, XL ; in ga primerja s fizi�nim koncem medpomnilnika  
	cpc ZH, XH ; 
	brne TRAC1 ; �e prese�emo fizi�ni konec, sko�i, sicer (Branch if not equal)
	ldi ZH, high(TRAB+2) ; se prestavi na za�etek
	ldi ZL, low(TRAB+2) ; preko�i na za�etek

TRAC1:
	
	; nalo�i fizi�ni za�etek medpomnilnika v X
	ldi XH, high(TRAB) ; preko�i na za�etek
	ldi XL, low(TRAB) ; preko�i na za�etek

	cp ZL, XL ; primerja logi�ni konec z za�etkom 
	cpc ZH, XH ; 
	
	breq TRAERR	 ; If TRAE=TRAB, then the buffer is full (medpomnilnik poln), kon�a
	sts TRAE, ZH ; sicer shrani novi logi�ni konec
	sts TRAE+1, ZL

TRAERR:
	pop XL ; restore X
	pop	XH ; from stack
	pop ZL ; restore Z
	pop	ZH ; from stack
	ret	   ; return