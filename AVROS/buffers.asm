; Circular buffer implementation
; Prevent moving data by moving pointers to data
; Buffer is solving different devices speed.
; buffers.asm
;
; Begin
; 00  01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0f
; ----------------------------------------------
; |PTR B|       place for data           | PTRE|
; |  |02|  |  |  |  |  |  |  |  |  |  |  |  |02|
; ----------------------------------------------
;        ^
;        |
;	   PTRB, PTRE
;
;  Created: 26.5.2019 19:05:09
;   Author: gustin
; 

 .dseg
.org SRAM_START

; pointers for static circular buffers

; UART transmitting buffer with a capacity of 64 characters.
TRAB:  .byte 3+16 ; transmitting buffer begin 
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

	lds ZH, TRAE ; naloži logièni konec medpomnilnika v X
	lds ZL, TRAE+1 
	st Z+, r16	 ; in zapiše znak iz r16 v medpomnilnik in poveèa kazalec Z za 1
	
	; X pointer to physical end 

	ldi XH, high(TRAE) ; naloži fizièni konec medpomnilnika
	ldi XL, low(TRAE) ;  
	
	cp ZL, XL ; in ga primerja s fiziènim koncem medpomnilnika  
	cpc ZH, XH ; 
	brne TRAC1 ; preveri, ali presegamo fizièni konec, 
	; Èe presežemo fizièni konec
	ldi ZH, high(TRAB+2) ; naloži fizièni zaèetek 
	ldi ZL, low(TRAB+2) ; (prekoèi na zaèetek)

TRAC1:
	
	; naloži fizièni zaèetek medpomnilnika v X
	lds XH, TRAB ; prekoèi na zaèetek
	lds XL, TRAB+1 ; prekoèi na zaèetek

	cp ZL, XL ; primerja logièni konec z zaèetkom 
	cpc ZH, XH ; 
	
	breq TRAERR	 ; If TRAE=TRAB, then the buffer is full (medpomnilnik poln), konèa
	sts TRAE, ZH ; sicer shrani novi logièni konec
	sts TRAE+1, ZL

TRAERR:
	pop XL ; restore X
	pop	XH ; from stack
	pop ZL ; restore Z
	pop	ZH ; from stack
	ret	   ; return