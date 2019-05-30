; Circular buffer implementation
; Prevent moving data by moving only pointers to data
; Buffer is solving different devices speed.
; buffers.asm
;
; Begin									  End						
; 00  01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0f
;        Pointer begin
;         |		  
;		  ¡
; ----------------------------------------------
; |PTR B|       place for data           | PTRE|
; |  |02|  |  |  |  |  |  |  |  |  |  |  |  |02|
; ----------------------------------------------
;        ^
;        |
;	   Pointer end
;
;  PTRB = logical begin
;  PTRE = logica end
;
;   Author: Mitja Gustin gustinmi [at] gmail [dot] com
; 

#define TEST_BUFFERS 1
#if TEST_BUFFERS > 0
.dseg
.org SRAM_START
#endif
	
; declaration of 2 pointers for static circular buffers
; they are the first and the last data in buffer. 
; actual serail data is between them

; UART transmitting buffer with a capacity of 64 characters.
TRAB:  .byte 3+16 ; transmitting buffer begin 
TRAE: .byte 2 ; transmitting buffer end 

; UART receiving buffer with capacity of 8 chars
RECB: .byte 3+9 ; receiving buffer begin 
RECE: .byte 2 ; receiving buffer end 

#if TEST_BUFFERS > 0
.cseg
.org 0x0000
#endif

START: 
	; Clear the UART transmitting buffer
	; (by making both pointers point to same location)
	ldi ZH, high(TRAB+2) ; load	 addres of first data
	ldi ZL, low(TRAB+2) 
	sts TRAB, ZH  ; store address to pointer TRAB
	sts TRAB+1, ZL
	sts TRAE, ZH ; store address to pointer TRAE
	sts TRAE+1, ZL

	; clear the UART receiving buffer
	; (by making both pointers point to same location)
	ldi ZH, high(RECB+2) ; load	 addres of first data
	ldi ZL, low(RECB+2) 
	sts RECB, ZH  ; store address to pointer TRAB
	sts RECB+1, ZL
	sts RECE, ZH ; store address to pointer TRAE
	sts RECE+1, ZL
	
	; test routine (add some data)
	ldi r16, 0xff
	call TRACHR
	ldi r16, 0x1f
	call TRACHR
	ldi r16, 0x2f
	call TRACHR
	ldi r16, 0x3f
	call TRACHR

	; read data into receiving buffer
	ldi ZL, low(message<<1)
	ldi ZH, high(message<<1)

LOOP: 
	lpm r16, Z+
	tst r16
	breq HALT
	call LOOP

HALT:
	

	rjmp HALT

;------------------------------------------------------------------------------ 
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
	ret	   ; return (Z)ero flag


;________________________ RECEIVE CHARACTER (~<=) ___________________________
;  Read one character from the SCI receiveing buffer RECB-RECE into r16. In case
;  of an empty buffer, the procedure returns Z=1. A successful read is
;  indicated by Z=0. The contents of all registers are preserved. This
;  procedure must never be interrupted by another call to RECCHR!!
;------------------------------------------------------------------------------
RECCHR:
	push ZH ; save index register Z 
	push ZL ; to stack
	push XH ; save index register Z 
	push XL ; to stack
	
	lds ZH, RECB ; naloži logièni konec medpomnilnika 
	lds ZL, RECB+1 

	lds XH, RECE ; naloži logièni koncem medpomnilnika 
	lds XL, RECE+1

	; primerjaj ga s koncem medpomnilnika in
	cp ZL, XL 
	cpc ZH, XH ; 
	breq KON ; v primeru enakosti zakljuèi (prazen), sicer
	ld r16, Z+ ; naloži prvi znak,

	;load physical end of buffer into X
	ldi XH, high(RECE) ; naloži fizièni konec medpomnilnika
	ldi XL, low(RECE) ;
	brne WRTE  ; ob presegu fiziènega konca
	ldi XH, high(RECB+2) ; preskoèi na fizièni zaèetek
	ldi XL, low(RECB+2) ;

WRTE:
	sts RECB, XH ; in spravi novi zaèetek
	sts RECB+1, XL

KON:
	pop XL ; restore X
	pop	XH ; from stack
	pop ZL ; restore Z
	pop	ZH ; from stack
	ret	 ; return (Z)ero flag

;________________________ UART SERIAL COMMUNICATION TASK (~<=106) _____________
;  This is a real-time serial communication driver. UART should be placed into
;  the task schedule. In each cycle, UART checks the serial communication
;  hardware to see if a new byte has been received. If so, the byte is
;  transferred into the receiveing buffer RECB-RECE. The transmission register
;  is also checked. If it is empty and the transmission buffer TRAB-TRAE is not
;  empty, then the first byte from the fifo buffer is transferred to the
;  transmission hardware.
;------------------------------------------------------------------------------
SCI;
  ;Receiving 
  lds r16, UCSR0A ; nalozi nadzorni spr./odd. in statusni reg.
  andi r16, 0b1100_0000 ; in maskira 7 in 8 bit (odstrani)


  ;transmitting




SCITRVN: ret                     ;RETURN(RECB-RECE)
SCIREVN: ret                     ;RETURN(TRAB-TRAE)


message: .db  0xFF, 0xFE, 0xFD, 0xFC, 0xFB, 0xFA, 0xF9, 0x00