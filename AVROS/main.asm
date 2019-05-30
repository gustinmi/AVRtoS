; AVRtoS -  AVR Realtime operating system kernel
; Author : gustin

;.include "macrodefs.inc" ; Define device ATmega328P

; appoint names to program accessible registers

.def tempa = r16 ; accumulator a
.def tempb = r17 ; accumulator b

; some static variables

.equ cFreq = 16000000 ; Clock frequency processor in cycles/s

; ==========================   SRAM section

.dseg
.org SRAM_START

SCHPTR:	.byte 2 ; pointer to FLASH table of pointers
SCHTST:	.byte 1 ; status flag when ongoing interrupt is in place

; =========================   FLASH section

.cseg
.org 0x0000

	jmp RESET ; <0x0000> RESET		External Pin Reset, Power-on Reset,  Reset
	reti ; INT0_INT ; <0x0002> INT0	External Interrupt Request 0
	reti ; <0x0004> INT1			External Interrupt Request 0
	reti ; <0x0006> PCINT0			Pin Change Interrupt Request 0
	reti ; <0x0008> PCINT1			Pin Change Interrupt Request 1
	reti ; <0x000A> PCINT2			Pin Change Interrupt Request 2
	reti ; <0x000C> WDT				Watchdog Time-out Interrupt
	reti ; <0x000E> TIMER2_COMPA	OC2A Timer/Counter2 Compare Match A
	reti ; <0x0010> TIMER2_COMPB	OC2B Timer/Coutner2 Compare Match B
	reti ; <0x0012> TIMER2_OVF		OVF2 Timer/Counter2 Overflow
	reti ; <0x0014> TIMER1_CAPT		ICP1 Timer/Counter1 Capture Event
.org 0x0016	
	jmp _SCHINT; TIMER1_COMPA ; <0x0016> 	OC1A Timer/Counter1 Compare Match A
	;jmp TIMER1_COMPB ; <0x0018> TIMER1_COMPB	OC1B Timer/Coutner1 Compare Match B
	;jmp TIMER1_OVF ; <0x001A> TIMER1_OVF		OVF1 Timer/Counter1 Overflow
	reti ; <0x001C> TIMER0_COMPA	OC0A Timer/Counter0 Compare Match A
	reti ; <0x001E> TIMER0_COMPB	OC0B Timer/Coutner0 Compare Match B
	reti ; <0x0020> TIMER0_OVF		OVF0 Timer/Counter0 Overflow
	reti ; <0x0022> SPI STC			SPI Serial Transfer Complete
	reti ; <0x0024> USART_RX		URXC USART Rx Complete
	reti ; <0x0026> USART_UDRE		UDRE USART Data Register Empty
	reti ; <0x0028> USART_TX		UTXC USART Tx Complete
	reti ; <0x002A> ADC				ADC Conversion Complete
	reti ; <0x002C> EE READY		EEPROM Ready
	reti ; <0x002E> ANALOG COMP		ACI	Analog Comparator
	reti ; <0x0030> TWI				2-wire Serial Interface
	reti ; <0x0032> SPM READY		SPMR Store Program Memory Ready

RESET:	ldi r16, high(RAMEND) ; init stack pointer
		out SPH, r16 ; Set Stack Pointer to top of RAM
		ldi r16, low(RAMEND)
		out SPL, r16

		eor	r1, r1		; // clear general purpose register r1 to be 0
		out	SREG, r1	; // clear status flag register
		st	Z, r1		; clear Z index register

		call INIT ; call subroutine

		; clear 8 bit control registers TCCR1
		sts	TCCR1A, r1
		sts	TCCR1B, r1

		; TCNT1 clear timer counter value 
		ldi XL, LOW(1200) ;Copy low byte of 420
		ldi XH, HIGH(1200) ;Copy HIGH byte of 420
		sts TCNT1H, XH ; clear timer value high
		sts TCNT1L, XL ; clear timer value low
		
		; enable timer output compate B interrupt
		ldi r19, 0x00
		ori r19, (1 << OCIE1A) ;  | (1 << OCIE1B) | (1 << TOIE1)
		sts TIMSK1, r19

		; load output compare register A
		ldi r19, 0x00
	    sts OCR1AH, r19
		sts OCR1AL, r19

		; set timer prescaler 64
		ldi r19, 0x00
		ori r19, (1 << CS11) | (1 << CS10) 
		sts TCCR1B, r19

		sts SCHTST, r1	; // clear interrupt test register
		sei				; enable interrupts

loop:	rjmp loop ; // interupts do the rest
		inc r18 ; it will never come here
		

TIMER1_COMPA:
		inc r18
		inc r18
		reti

; *************************************** oc1 interrupt		
_SCHINT:lds tempa, SCHTST ; load tempa direct from SRAM
		sbrc tempa, 0 ; skip next if bit cleared
SCHERR: rjmp SCHERR	; trap
SCHOK:	inc tempa ; increment A
		sts SCHTST, tempa ; set in-interrupt flag 
		
		ldi XL, LOW(1200) ; increment by time slice 1200
		ldi XH, HIGH(1200) ; increment by time slice 1200

		ldi YL, OCR1AL ; load oc1 register L
		ldi YH, OCR1AH ; load oc2 register H

		add XL, YL ; add time slice
		adc XH, YH ; add with carry time slice

		sts OCR1AH, XH ; store back to oc1
		sts OCR1AL, XL ; store back to oc1
		
		;load task and execue it

		ldi tempa, 0 ; zero
		sts SCHTST, tempa ; enable back interupts
		rjmp loop ; back to main program

SCHRTS: reti
TIM:
	inc r20
	inc r20
	reti
KBD:	reti
SCI:	reti
LED:	reti

INIT: ; initialize SRAM variables
	ldi tempa, 0
	sts TIMH, tempa
	sts TIMM, tempa
	sts TIMS, tempa
	sts TIMF, tempa

; ****************** enable the scheduler
SCHON:
	sts SCHTST, r1 ; store 0 to SRAM variable
	ret
	

.org 0x037f ; align scheduler table with the end of FLASH

; TASK SCHEDULE DATA STRUCTURE
SCHTAB:	.dw TIM
		.dw LED
		.dw KBD
		.dw SCI
		.dw TIM
		.dw LED
		.dw SCHRTS
		.dw SCHRTS
		.dw TIM
		.dw LED
		.dw SCHRTS
		.dw SCHRTS
		.dw TIM
		.dw LED
		.dw SCHRTS
		.dw SCHRTS