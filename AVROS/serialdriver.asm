; Circular buffer implementation
; Prevent moving data by moving only pointers to data
; Buffer is solving different devices speed.
; buffers.asm
;
; Circular buffer looks like this :
;
; Begin									  End						
; 00  01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0f
;
;        Pointer to begin of data
;         |		  
;		  ¡
; ----------------------------------------------
; |PTR B|       place for data           | PTRE|
; |  |02|  |  |  |  |  |  |  |  |  |  |  |  |02|
; ----------------------------------------------
;        ^
;        |
;	   Pointer to end of data
;
;  PTRB = logical begin
;  PTRE = logica end
;
;  Author: Mitja Gustin gustinmi [at] gmail [dot] com
; 

;.include "configuration.inc"	; system wide configuration opts

; to use this file as library, define TEST_BUFFERS 0 in main file 
#ifndef TEST_BUFFERS
#define TEST_BUFFERS 1
#endif

#if TEST_BUFFERS > 0
.include "configuration.inc"	; system wide configuration opts
.dseg
.org SRAM_START
	
; declaration of 2 pointers for static circular buffers
; they are the first and the last data in buffer. 
; actual serial data is between them

; UART transmitting buffer with a capacity of 64 characters.
TRAB:  .byte 3+8 ; transmitting buffer begin 
TRAE: .byte 2 ; transmitting buffer end 

; UART receiving buffer with capacity of 8 chars
RECB: .byte 3+9 ; receiving buffer begin 
RECE: .byte 2 ; receiving buffer end 
DOLNIZ: .byte 1 ; length of RECSTR string
HEAP: .byte 1 ; constant pointer to beginning of heap	(first free location after global variables)
#endif

#if TEST_BUFFERS > 0
.cseg
.org 0x0000

START: 

	call UART_INIT ; init UART 

	; Clear the UART transmitting buffer
	; (by making both pointers point to same location)
	ldi ZH, high(TRAB+2) ; load	addres of first empty location
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

	; test routine (fill receive buffer with string ascii HELLO)
	; when comming from serial line, the string is CR terminated
	; (user hit enter to send)
	ldi r16, A2I_H
	st Z+, r16
	ldi r16, A2I_E
	st Z+, r16
	ldi r16, A2I_L
	st Z+, r16
	ldi r16, A2I_L
	st Z+, r16
	ldi r16, A2I_O
	st Z+, r16
	ldi r16, A2I_ENTER_CODE	   ; terminate with CR enter
	st Z+, r16
	; correct the end pointer
	sts RECE, ZH ; store address to pointer TRAE
	sts RECE+1, ZL

	; get physical location of the beginning of HEAP
	; RECSTR uses X as pointer to where copy the string to 
	ldi XH, high(HEAP) 
	ldi XL, low(HEAP) 
	ldi r17, 10 ; max chars to receive (excluding CR)	
	call RECSTR ; receive string to location at X		
			
			 	
	; test routine (how to test circularity)
	;ldi r16, 0xff
	;call TRACHR
	;ldi r16, 0x1f
	;call TRACHR
	;ldi r16, 0x2f
	;call TRACHR
	;ldi r16, 0x3f
	;call TRACHR
	;ldi r16, 0xff
	;call TRACHR
	;ldi r16, 0x1f
	;call TRACHR
	;ldi r16, 0x2f
	;call TRACHR
	;ldi r16, 0x3f
	;call TRACHR
	;call RECCHR
	;call RECCHR

; we will copy the constant string from FLASH to HEAP
; we will transmit it to UART

; read data into receiving buffer
	ldi ZL, low(message<<1)
	ldi ZH, high(message<<1)

	; get physical location of the beginning of HEAP
	; TRASTR uses X as pointer to the beginning of the string
	ldi XH, high(HEAP) 
	ldi XL, low(HEAP) 

FILL_TRA: 
	lpm r16, Z+
	tst r16
	breq END_TRA
	st X+, r16 
	rjmp FILL_TRA
END_TRA:
	clr r16		; clear register
	st X, r16	;zero terminate string
	ldi XH, high(HEAP) 
	ldi XL, low(HEAP)
	call TRASTR ; transmit string


DONE:  rjmp DONE
	
#endif

;------------------------------------------------------------------------------ 
;Not going to do anything with UCSR0C since the default
;values will give the 8:N:1 format needed to communicate
;with the serial monitor of the Arduino IDE.
;------------------------------------------------------------------------------ 

UART_INIT:
		push r16 ; save r16 to stack
		clr r16
		sts UBRR0H, r16
		ldi r16, 0x19 ; Set BAUD rate to 9600 (assuming a 16MHz system clock)
		sts UBRR0L, r16

		;Enable transmitter and receiver.
		ldi r16, (1<<RXEN0)|(1<<TXEN0)
		sts UCSR0B, r16

		pop r16 ; restore 
		ret
	
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
	; naloži logièni zaèetek medpomnilnika v X
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

	; ==========  Z points to logical begin	
	lds ZH, RECB ; naloži logièni zaèetek medpomnilnika 
	lds ZL, RECB+1 
	lds XH, RECE ; naloži logièni konec medpomnilnika 
	lds XL, RECE+1
	cp ZL, XL  ; primerjaj 
	cpc ZH, XH ; 
	breq KON ; v primeru enakosti zakljuèi (prazen), sicer
	ld r16, Z+ ; naloži prvi znak in poveèaj logièni zaèetek

	;load physical end of buffer into X
	ldi XH, high(RECE) ; naloži fizièni konec medpomnilnika	v  x
	ldi XL, low(RECE) ;
	cp ZL, XL  ; in primerjaj z logiènim zaèetkom
	cpc ZH, XH ;

	brne WRTE  ; ob presegu fiziènega konca
	ldi XH, high(RECB+2) ; preskoèi na fizièni zaèetek
	ldi XL, low(RECB+2) ;

WRTE:
	sts RECB, ZH ; in spravi novi zaèetek
	sts RECB+1, ZL

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
SCI: 
	push ZH ; save index register Z 
	push ZL ; to stack
	push XH ; save index register Z 
	push XL ; to stack
	push r16 ; save r16 to stack

	;Receiving part, we fill RECB-RECE buffer
	lds r16, UCSR0A ; load control register 
	sbrs r16, RXC0  ; skip if no new data received
  	rjmp SCIERR		; jump to transmit
	lds r16, UDR0 ; load new received data 
	; nalozi konec sprejemnega pomnilnika
	lds XH, RECE ; load *END pointer
	lds XL, RECE+1 ;
	st X+, r16 ; store there data				
	; compare ebnd pointer with physical end 
	ldi ZH, high(RECE) ; #END address
	ldi ZL, low(RECE) ;				
	cp ZL, XL  ; *PTR END vs #END
	cpc ZH, XH ;
	brne SCIRE1	 ; if physical end not reached jump
	ldi ZH, high(RECB+2) ; naloži fizièni zaèetek
	ldi ZL, low(RECB+2)
	cp XL, ZL  ; compare physical #BEGIN with logical #END
	cpc XH, ZH	;
	breq SCIEXIT ; exit, buffer is full

SCIRE1:
	; primerja logièni konec z logiènim zaèetkom medpomnilnika
	lds ZH, RECE ; load Z with logical *BEGIN
	lds ZL, RECE+1 ;
	cp ZL, XL  ; compare logical *END and logical *begin (buff full)
	cpc ZH, XH ;
	breq  SCIEXIT  ; exit buff is full (return Z flag)
	sts RECE, XH	; store new logican *END pointer
	sts RECE+1, XL
	rjmp SCIEXIT ; exit done

SCIERR:		   ;transmitting
	lds r16, UCSR0A ; load control register
	sbrs r16, TXC0 ; check transmition completed
	rjmp SCIEXIT ; exit if not
	sbrs r16, UDRE0 ; check if shift register empty
	rjmp SCIEXIT ; exit if not
	lds XH, TRAB  ; load *BEGIN pointer
	lds XL, TRAB+1
	lds ZL, TRAE+1 ; load *END pointer
	lds ZH, TRAE
	cp ZL, XL ; compare it (if empty)
	cpc ZH, XH
	brne SCITRA1 ; goto transmit
	rjmp SCIEXIT
SCITRA1:
	ld r16, X+ ; load value at X (*BEGIN) to r16
	sts UDR0, r16 ; store r16 to transmit buffer
	sts TRAB, XH	 ; store new *BEGIN pointer
	sts TRAB+1, XL
	ldi ZL, low(TRAE) ; load #END physical
	ldi ZH, high(TRAE)
	cp ZL, XL  ; compare *BEGIN to #END
	cpc ZH, XH
	breq SCITRA2
	rjmp SCIEXIT ; exit
SCITRA2:
	ldi XL, low(TRAB+2)	; load #BEGIN physical
	ldi XH, high(TRAB+2)
	sts TRAB, XH	 ; store it to *BEGIN
	sts TRAB+1, XL

SCIEXIT:			; RETURN
	pop r16
	pop XL ; restore X
	pop	XH ; from stack
	pop ZL ; restore Z
	pop	ZH ; from stack
	ret                     


; =======================================================================
;*  This subrutine fills the transmission buffer with characters from the
;*  string. If the whole string is sent to the buffer, flag Z is cleared.
;*  Otherwise Z is set which means that the whole string wasn't sent because
;*  the buffer is full.
; =======================================================================

TRASTR: ; transmit string 
	push r16
	clz ; clear zero flag 
TRASTR1:
	ld r16, X+
	breq TRASTR2 ; end of string
	call TRACHR
	breq TRASTR3 ; if z=1 buff=full 
	rjmp TRASTR1 ; continue 

TRASTR2:
	inc r16
TRASTR3:
	pop r16
	ret


;________________________ RECEIVE STRING FROM SCI _____________________________
;  Get a CR-terminated string from the SCI receiveing buffer using RECCHR.
;  As they are read, the characters are echoed back via TRACHR. Backspace
;  characters ($08) cause the deletion of the leftmost character. The resulting
;  null-terminated string is stored in memory at X. The string length will not
;  exceed r17 characters excluding the termination byte. The final string length
;  is returned in r18.
;  Only call from main program.
;------------------------------------------------------------------------------
RECSTR:
	ldi r16, 0	    ; store 0 to DOLNIZ variable
	sts DOLNIZ, r16 ;
CAKAJ:
	call RECCHR		; receive data from RECB-RECE into r16
	breq CAKAJ		; if empty, just wait
	cpi r16, A2I_ENTER_CODE	; check if ENTER CR=$0D
	breq RECSTVN	; end with 0 termination
	cpi r16, A2I_BACKSPACE	; check if backspace BS=$08
	breq RECSBAK	; process backspace
	cpi r16, 0x20	; check if valid > ascii  ($20 = ascii sign !)
	brsh RECSTR1	; jump if valid
	rjmp RECSTP		; end receiving; not a ascii char
RECSTR1:
	cpi r16, 0x7e	; check if valid < ascii
	brlo RECSEH0	; jump if valid
RECSTP:
	ldi r16, A2I_BELL	; load ascii BELL char
	call TRACHR		; transmit to terminal
	rjmp CAKAJ		; goto wait loop
RECSEH0:	; store end echo back
	st X+, r16		; store received data to X
	call TRACHR		; echo to terminal
	lds r18, DOLNIZ	; load length
	inc r18			; increment it
	sts DOLNIZ, r18	; store it
	dec r17			; decrement MAX length
	breq RECSTVN	; null terminate if max reached
	rjmp CAKAJ		; continue receiving until max len reached or CR enter code encountered
RECSBAK:
	call TRACHR		; echo backspace to terminal
	lds r18, DOLNIZ	; load string length
	breq CAKAJ		; if string is empty, go to wait loop
	dec r18			; decrement length
	sts DOLNIZ, r18	; store new length
	inc r17			; restore max len 
	sbiw XH:XL, 1	; decrement X
	rjmp CAKAJ		; goto wait loop
RECSTVN:  ; echo last char and append newline, null terminate  string
	call TRACHR		; echo to terminal what we have	 CR
	ldi r16, A2I_NEWLINE	; append NEWLINE character  FF
	call TRACHR		; echo newline to terminal
	ldi r16, 0		; null termination to the end of string
	st X, r16		; store to end of string  (no more incrementing)
	lds r18, DOLNIZ ; store length to variable
	ret				; return from subroutine

; string constants at the end of FLASH memory

message: .db  "hello world", 0x00 ; null terminated string
