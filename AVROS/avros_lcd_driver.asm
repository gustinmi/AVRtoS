
; --------------------  Liquid Crystal Display Driver HD44780
; 4 Bit interface implementation
; Signals :
; RS RW DB7 DB6 DB5 DB4 DB3 DB2 DB1 DB0
; Description
; RS  0 instruction register for write busy flag, address counter for read
;     1 Data register (read and write)
; RW  1 Read
;	  0 Write
; E   Starts data read / write
; DB4 .. DB7 bidirectional Data / instruction 
; DB 7 Busy flag   (RS 0, RW 1)


.include "hd44780.inc"	; LCD driver options

.equ	LCD_PORT 	= PORTB ; port B on AVR (PORT 6 and 7 have XTAL!!)
.equ	LCD_DDR		= DDRB ; directions of pins on port B
.equ    LCD_PIN		= PINB ; pin states

; data signals (upper four)
.equ	LCD_D4 		= 0
.equ	LCD_D5 		= 1
.equ 	LCD_D6 		= 2
.equ	LCD_D7 		= 3

; control signals
.equ	LCD_RS		= 4 ; Register select
.equ	LCD_EN		= 5 ; Enable (start, read)
.equ	LCD_RW      = 7 ; PORTD
;***** Subroutine Register Variables Divide

.def	drem8u	=r15		;remainder
.def	dres8u	=r16		;result
.def	dd8u	=r16		;dividend
.def	dv8u	=r17		;divisor
.def	dcnt8u	=r18		;loop counter

.dseg

; empty

.cseg

.org 0x0000  

reset:
		ldi r16, high(RAMEND) ; initialize stack pointer (end of SRAM upwards)
		out SPH, r16 ; Set Stack Pointer to top of RAM
		ldi r16, low(RAMEND)
		out SPL, r16
		
		call LCD_Init
		ldi r16, 0
		
		call LCD_SetAddressDD
		ldi r16, 0b01000001
		call LCD_WriteData

		ldi r16, 1
		call LCD_SetAddressDD
		ldi r16, 0b01000001
		call LCD_WriteData

loop:	rjmp loop


.include "div8u.inc" ; divide soubroutine

; ==================
; LCD Soubroutines
; LCD_WriteNibble - internals - write 8 bit as 2x4 bit
; LCD_Init - initialization of LCD
; LCD_WriteCommand - write to command register
; LCD_WriteData - write to data register
; LCD_WriteString - display string from program memory
; LCD_SetAddressDD - sets address in Display Data RAM
; LCD_SetAddressCG - sets address in Character Generator RAM

; wirtes first 4 bits of data of r16
LCD_WriteNibble:
	sbi		LCD_PORT, LCD_EN ; set E high

	; write 4 bits 
	sbrs	r16, 0 ; Skip if Bit in Register is Set
	cbi		LCD_PORT, LCD_D4 ; clear bit in IO port
	sbrc	r16, 0 ; Skip if Bit in Register Cleared
	sbi		LCD_PORT, LCD_D4 ; set bit in IO port

	sbrs	r16, 1
	cbi		LCD_PORT, LCD_D5
	sbrc	r16, 1
	sbi		LCD_PORT, LCD_D5
	
	sbrs	r16, 2
	cbi		LCD_PORT, LCD_D6
	sbrc	r16, 2
	sbi		LCD_PORT, LCD_D6
	
	sbrs	r16, 3
	cbi		LCD_PORT, LCD_D7
	sbrc	r16, 3
	sbi		LCD_PORT, LCD_D7

	cbi		LCD_PORT, LCD_EN ; trigger negative CPU front
	ret

; write to data register 
; write data as 2 x 4 writes (nibbles)
LCD_WriteData:
	sbi		LCD_PORT, LCD_RS
	push	r16 ; save r16 to stack
	swap	r16 ; 1 Swap Nibbles Rd(3...0)←Rd(7...4), Rd(7...4)¬Rd(3...0)
	rcall	LCD_WriteNibble
	pop		r16 ; pop r16 from stack
	rcall	LCD_WriteNibble
	; delay loop
	clr		XH
	ldi		XL, 250
	rcall	Wait4xCycles
	ret

; write to command register
LCD_WriteCommand:
	cbi		LCD_PORT, LCD_RS
	push	r16
	swap	r16
	rcall	LCD_WriteNibble
	pop		r16
	rcall	LCD_WriteNibble
	ldi		r16,2
	rcall	WaitMiliseconds
	ret

; display string from program memory
LCD_WriteString:
	lpm		r16, Z+
	cpi		r16, 0
	breq	exit
	rcall	LCD_WriteData
	rjmp	LCD_WriteString
exit: ret

LCD_WriteHexDigit:
	cpi		r16,10
	brlo	Num
	ldi		r17,'7'
	add		r16,r17
	rcall	LCD_WriteData
	ret
Num:
	ldi		r17,'0'
	add		r16,r17
	rcall	LCD_WriteData
	ret

LCD_WriteHex8:
	push	r16
	
	swap	r16
	andi	r16,0x0F
	rcall	LCD_WriteHexDigit

	pop		r16
	andi	r16,0x0F
	rcall	LCD_WriteHexDigit
	ret


LCD_WriteDecimal:
	clr		r14
LCD_WriteDecimalLoop:
	ldi		r17,10
	rcall	div8u
	inc		r14
	push	r15
	cpi		r16,0
	brne	LCD_WriteDecimalLoop	

LCD_WriteDecimalLoop2:
	ldi		r17,'0'
	pop		r16
	add		r16,r17
	rcall	LCD_WriteData
	dec		r14
	brne	LCD_WriteDecimalLoop2
	ret


LCD_SetAddressDD:
	ori		r16, HD44780_DDRAM_SET
	rcall	LCD_WriteCommand
	ret

LCD_SetAddressCG:
	ori		r16, HD44780_CGRAM_SET
	rcall	LCD_WriteCommand
	ret

; programatic initialization  of LCD module
; this should be done by module itself, but its not sure
LCD_Init:
	; delay at least 15ms after VCC >4.5 v
	ldi		r16, 15 ; delay wait for 15ms
	rcall	WaitMiliseconds

	; first take care of RW signal on PORTD, LCD_RW pin
	sbi		DDRD, LCD_RW ; setup for LCD_RW signal
	cbi		PORTD, LCD_RW ; set LOW (writing mode) 

	; RS RW DB7 DB6 DB5 DB4 DB3 DB2 DB1 DB0
	; 0  0  0   0   1   1   *   *   *   *
	sbi		LCD_DDR, LCD_D4
	sbi		LCD_DDR, LCD_D5
	sbi		LCD_DDR, LCD_D6
	sbi		LCD_DDR, LCD_D7
	sbi		LCD_DDR, LCD_RS
	sbi		LCD_DDR, LCD_EN

	cbi		LCD_PORT, LCD_RS
	cbi		LCD_PORT, LCD_EN

	ldi		r16, 100 ; delay wait for 100ms
	rcall	WaitMiliseconds

	
	ldi		r17, 3 ; repeat 3 times
InitLoop:
	; main initializatin
	; RS RW DB7 DB6 DB5 DB4 DB3 DB2 DB1 DB0
	; 0  0  0   0   1   1   *   *   *   *
	; BusyFlag is not working yet before this instruction
	ldi		r16, 0b000_0011
	rcall	LCD_WriteNibble
	ldi		r16, 5  ; wait 5 miliseconds
	rcall	WaitMiliseconds
	dec		r17
	brne	InitLoop

	; RS RW DB7 DB6 DB5 DB4 DB3 DB2 DB1 DB0
	; 0  0  0   0   1   0   *   *   *   *
	ldi		r16, 0x02
	rcall	LCD_WriteNibble

	ldi		r16, 1 ; delay wait 1 ms
	rcall	WaitMiliseconds

	; 4 bit interface, 2 lines, font size, 
	ldi		r16, HD44780_FUNCTION_SET | HD44780_FONT5x7 | HD44780_TWO_LINE | HD44780_4_BIT
	rcall	LCD_WriteCommand

	ldi		r16, HD44780_DISPLAY_ONOFF | HD44780_DISPLAY_OFF
	rcall	LCD_WriteCommand

	ldi		r16, HD44780_CLEAR
	rcall	LCD_WriteCommand

	ldi		r16, HD44780_ENTRY_MODE |HD44780_EM_SHIFT_CURSOR | HD44780_EM_INCREMENT
	rcall	LCD_WriteCommand

	ldi		r16, HD44780_DISPLAY_ONOFF | HD44780_DISPLAY_ON | HD44780_CURSOR_OFF | HD44780_CURSOR_NOBLINK
	rcall	LCD_WriteCommand

	ret

; ------------------------------------
; check busy flag BF on data port 7
CHK_BUSY:
 	sbi		LCD_DDR, LCD_D7 ; PortD for D7 pin is inpuit
	sbi		LCD_PORT, LCD_EN ; positive front
	sbi		LCD_PORT, LCD_RS ; positive
	sbi		LCD_PORT, LCD_RW ; set reading mode  
	cbi		LCD_PORT, LCD_EN ; negative front
	ret


;------------------------------------------------------------------------------
; Busy-wait loops utilities module (Input : r16 - number of miliseconds to wait)

; This routine generate delay in CPU cycles multiply by 4.
; For delay equal 10000 CPU cycles load to XH:XL 2500.
; Input : XH:XL - number of CPU cycles to wait (divided by four)
Wait4xCycles:
		sbiw	  XH:XL, 1
		brne	  Wait4xCycles
		ret

; This routine generate delay in miliseconds. Number of miliseconds must be loaded into r16 register before call this routine.
WaitMiliseconds:
  		push	r16
WaitMsLoop: 
	  	ldi	   XH,HIGH(DVUS(500))
	  	ldi	   XL,LOW(DVUS(500))
	  	rcall	 Wait4xCycles
	  	ldi	   XH,HIGH(DVUS(500))
	  	ldi	   XL,LOW(DVUS(500))
	  	rcall	 Wait4xCycles
	  	dec	   r16
	  	brne	  WaitMsLoop
	  	pop	   r16
	  	ret