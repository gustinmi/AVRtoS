/*
* FILE: avros kernel v1
* Preemptive task scheduler
* Author: gustinmi@gmail.com
*/ 

.equ TIME_SLICE = 1953 ; timer (prescaler 8) time slice unit for 1/1024 s


; ********************************  KERNEL VARIABLES (7 bytes)
.dseg
.org SRAM_START

SCHPTR: .byte 2 ; pointer to pointer table in FLASH
SCHTST:	.byte 1 ; status flag when ongoing interrupt is in place
TIMH:	.byte 1 ; rts realtime clock driver hours
TIMM:	.byte 1 ; rts minutes
TIMS:	.byte 1 ; rts seconds
TIMF:	.byte 1 ; rts fractions

; ******************************* DRIVER VARIABLES


; ============================ INTERRUPT VECTOR TABLE
.cseg
.org FLASHSTART ; 0x0000
		jmp _START ; <0x0000> RESET		External Pin Reset, Power-on Reset,  Reset

.org TIMER1_COMPAaddr ; 0x0016	
		jmp _SCHINT; TIMER1_COMPA ; <0x0016> 	OC1A Timer/Counter1 Compare Match A

; =============================   RESET
; we must initialize stack pointer for soubroutine calls
_START: ldi r16, high(RAMEND) ; initialize stack pointer (end of SRAM upwards)
		out SPH, r16 ; Set Stack Pointer to top of RAM
		ldi r16, low(RAMEND)
		out SPL, r16

		call INIT ; initlize variables
		call USART_INIT ; initialize USART0 interface
		call SCHON ; enable the scheduler / start timer
		call MAIN ; main program loop

HALT:   rjmp HALT ; dead loop		

; ======================== INITIALIZE SRAM VARIABLES

INIT: 	cli ; disable all interrupts
		eor	r1, r1 ; empty r1 (expected behaviour)
		out	SREG, r1	; clear status flag register
		st	Z, r1		; clear Z index register
		; initialize SCHPTR; can only use Z register for FLASH
		ldi ZL, low(ptrs << 1)	; load start of table of pointers 
		ldi ZH, high(ptrs << 1) ; (points to FLASH )
		sts SCHPTR, ZH			; 4 store FLASH pointer to SRAM (big endian)
		sts SCHPTR+1, ZL 		; 4
		
		; store 0 to SRAM var
		sts SCHTST, r1 ; 2 initilize SRAM vars
		sts TIMH, r1 ; 2 initilize SRAM vars
		sts TIMM, r1 ; 2 initilize SRAM vars
		sts TIMS, r1 ; 2 initilize SRAM vars
		sts TIMF, r1 ; 2 initilize SRAM vars
	    
		; configure IO ports
		sbi DDRD, DDRB5 ; PORTB0 will be output

		ret ; 4 return to start

; *************************************** oc1 interrupt	routine	
; should not be interrupted by external interrupts or CPU
; ends before time slice is finished
; needs to store status register 

_SCHINT:
		in r0, SREG ; load status register into register
		push r0 ; push it on stack 
		lds r16, SCHTST ; load r16 direct from SRAM
		sbrc r16, 0 ; skip next if bit cleared
SCHERR: rjmp SCHERR	; trap (keep CPU in stable state)
SCHOK:  inc r16 ; increment A
		sts SCHTST, r16 ; set inside-interrupt flag 
		; add time slice to output compare register to trigger interrupt 
		ldi XL, LOW(TIME_SLICE) ; increment by time slice 1953  (1/1024 S)
		ldi XH, HIGH(TIME_SLICE) ; increment by time slice 1953 (1/1024 S)
		lds YL, OCR1AL ; load oc1 register L
		lds YH, OCR1AH ; load oc2 register H
		add XL, YL ; add time slice
		adc XH, YH ; add with carry time slice
		sts OCR1AH, XH ; store back to oc1
		sts OCR1AL, XL ; store back to oc1

		; task execution
		lds ZH, SCHPTR   ; load PTR to FLASH from SRAM
		lds ZL, SCHPTR+1 
		lpm r16, Z+		 ; load VAL of the pointer to register
		lpm r17, Z		 
		mov ZL, r16      ; move it to index register Z for icall
		mov ZH, r17
		icall ; execute instruction pointed to by Z

		lds r25, SCHPTR   ; load PTR to FLASH from SRAM
		lds r24, SCHPTR+1 
		adiw r25:r24, 2 ; increment pointer by 2 (FLASH is 2x8)
		andi r24, 0b0001_1110 ; overlay 0's  (cycle 0-15 tasks)
		sts SCHPTR, r25 ; update PTR location
		sts SCHPTR+1, r24
		sts SCHTST, r1 ; enable back interupts

		pop r0 ; pop status register from stack
		out	SREG, r0 ; restore it
		reti ; back to main program

SCHON:	sts	TCCR1A, r1 ; clear 8 bit control registers TCCR1
		sts	TCCR1B, r1

		lds XL, TCNT1L ; load timer1 counter value 
		lds XH, TCNT1H ; load timer1 counter value 
		ldi YL, LOW(TIME_SLICE) ; Copy low byte of 1953
		ldi YH, HIGH(TIME_SLICE) ; Copy HIGH byte of 1953
		add XL, YL ; add time slice
		adc XH, YH ; add with carry time slice
		sts OCR1AH, XH ; store it to output compare register
		sts OCR1AL, XL ; store it to output compare register
		
		; enable timer output compare A interrupt
		clr r19
		ori r19, (1 << OCIE1A) 
		sts TIMSK1, r19
	
		; set timer prescaler 8
		clr r19
		ori r19, (1 << CS11)  ;  1/8 CPU CLK prescaler
		sts TCCR1B, r19

		sts SCHTST, r1	; clear interrupt test register
		sei				; enable interrupts
		
		ret ; return to start

; ****************************************** 
;  DRIVERS
; ****************************************** 

; =============  Realtime clock driver ~=50
; Should be placed into the task schedule at 1/256 duty cycle
; Updates four global variables TIMF (second fractions 0 ... 255), TIMS (seconds), TIMM (minutes), TIMH (hours)

TIM:	lds r20, TIMF ; 2 load fractions
		inc r20 ; 1 increment fraction counter
		sts TIMF, r20 ; 2 store fractions
		tst r20	 ; 1 set flags 
		brne TIMRTS ; 1-2 branch down not zero
		; ================== SECONDS
		call LED_FLIP	; 8-10 debugging 
		lds r20, TIMS ;2 load seconds
		inc r20 ; 1 increment second counter
		sts TIMS, r20 ; 2 store seconds
		cpi r20, 60 ; 1 compare with 60
		brne TIMRTS ; 1-2 branch down if not equal
		;==================  MINUTES
		sts TIMS, r1 ; 2 clear seconds counter otherwise
		lds r20, TIMM ;2 load minutes
		inc r20 ; 1 increment minutes
		sts TIMM, r20 ; 2 save it to SRAM minutes
		cpi r20, 60 ; 1 compare with 60
		brne TIMRTS ; 1-2 branch down if not equal
		; ================= HOURS
		sts TIMM, r1 ; 2 clear minutes otherwise
		lds r20, TIMH ;2 load hours
		inc r20 ; 1 increment by hour
		sts TIMH, r20 ; 2 store to SRAM
		cpi r20, 24 ; 1 compare with 24
		brne TIMRTS ; 1-2 branch down if not equal
		sts TIMH, r1 ; 2 clear hours
TIMRTS:	ret ; 4 return from subroutine

KBD:	ret
SCI:	ret
LED:	ret

SCHRTS: ret ; void task (to fill scheduler)

; *******************************************
; LIBRARY 
; *******************************************

; initilize USART 0 interface
USART_INIT:
		clr r17
		sts UBRR0H, r17
		ldi r16, 0x19 ;Set BAUD rate to 38400 (16MHz system clock)
		sts UBRR0L, r16

		;Enable transmitter and receiver.
		ldi r16, (1<<RXEN0)|(1<<TXEN0)
		sts UCSR0B, r16

		;Not going to do anything with UCSR0C since the default
		;values will give the 8:N:1 format needed to communicate
		;with the serial monitor of the Arduino IDE.
		ret

USART_TRA:
		; put data into transmit buffer (it will send data automatically)
		sts UDR0, r16 ; put to output buffer
		ret

USART_REC:
		lds r17, UCSR0A
		sbrs r17, RXC0
		ret
		; get data from buffer
		lds r16, UDR0
		ret

USART_FLUSH:
		lds r16, UCSR0A
		sbrs r16, TXC0
		ret
		lds r16, UDR0
		rjmp USART_FLUSH

; ================  LED DRIVER 
; status leds

LEDOK_ON:
		sbi PORTB, PORTB0 ; set portb 0 high
		ret

LEDOK_OFF:
		cbi PORTB, PORTB0 ; set portb 0 high
		ret

; flips the output port bit 8~10 cycles
LED_FLIP:
		in r0, PORTD ; 1 load current state
		tst r0 ; 1 set flags
		brne LED_CLEAR ; 2 branch if Z=0 (not equal)
		sbi    PORTD, PORTB5	; 2 set bit
		ret                     ; 4
LED_CLEAR:
		cbi    PORTD, PORTB5	; 2 clear bit
		ret	

; =====================    MAIN PROGRAM ===============================

MAIN:	rjmp MAIN

; ======================   TASK SCHEDULE

.org 0x0300 ; put scheduler table at the and of FLASH

; pointer array to interrrupt handlers; scheduler will pick one after one

ptrs:
		.dw TIM ; realtime clock driver
		.dw LED ; led display driver
		.dw KBD ; keyboard driver
		.dw SCI ; serial SPI driver
		.dw TIM ; realtime clock driver
		.dw LED ; led display drive
		.dw SCHRTS ; void task
		.dw SCHRTS ; void task
		.dw TIM ; realtime clock driver
		.dw LED ; led display drive
		.dw SCHRTS ; void task
		.dw SCHRTS ; void task
		.dw TIM ; realtime clock driver
		.dw LED ; led display drive
		.dw SCHRTS ; void task
		.dw SCHRTS ; void task