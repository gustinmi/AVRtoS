;==============
; Declarations:

.def temp = r16
.def overflows = r17

.org 0x0000              ; memory (PC) location of reset handler
rjmp Reset               ; jmp costs 2 cpu cycles and rjmp costs only 1
                         ; so unless you need to jump more than 8k bytes
                         ; you only need rjmp. Some microcontrollers therefore only 
                         ; have rjmp and not jmp
.org 0x0016
rjmp oc1a_handler

.org 0x001A				 ; 
rjmp overflow_handler1	 ; 

.org 0x0020              ; memory location of Timer0 overflow handler
rjmp overflow_handler    ; go here if a timer0 overflow interrupt occurs 


;============

Reset: 
	ldi temp,  0b00000101
	out TCCR0B, temp      ; set the Clock Selector Bits CS00, CS01, CS02 to 101
                         ; this puts Timer Counter0, TCNT0 in to FCPU/1024 mode
                         ; so it ticks at the CPU freq/1024
	ldi temp, 0b00000001
	sts TIMSK0, temp      ; set the Timer Overflow Interrupt Enable (TOIE0) bit 
                         ; of the Timer Interrupt Mask Register (TIMSK0)

	; set timer prescaler 64
	ldi r19, 0x00
	ori r19, (1 << CS11) | (1 << CS10) 
	sts TCCR1B, r19

	; enable timer output compate B interrupt
	ldi r19, 0x00
	ori r19, (1 << OCIE1A) | (1 << OCIE1B) | (1 << TOIE1)
	sts TIMSK1, r19

	sei                   ; enable global interrupts -- equivalent to "sbi SREG, I"

	clr temp
	out TCNT0, temp       ; initialize the Timer/Counter to 0

	; TCNT1 = 0 load timer
	ldi r17, 0x00
	ldi r16, 0x00
	sts TCNT1H, r17
	sts TCNT1L, r16

	
	; load output compare register
	ldi r19, 0x11
	sts OCR1BH, r19
	sts OCR1BL, r19
	sts OCR1AH, r19
	sts OCR1AL, r19


;======================
; Main body of program:

blink:
	jmp blink            ; loop back to the start
  
delay:
   clr overflows         ; set overflows to 0 
   ret                   ; if 30 overflows have occured return to blink

oc1a_handler:
	inc overflows
	cpi overflows, 61
	reti


overflow_handler1:
	inc overflows
	cpi overflows, 61
	reti

overflow_handler: 
   inc overflows         ; add 1 to the overflows variable
   cpi overflows, 61     ; compare with 61
   reti                  ; return from interrupt