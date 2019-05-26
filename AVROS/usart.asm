
.cseg

.org FLASHSTART ; 0x0000
		jmp _START ; <0x0000> RESET		External Pin Reset, Power-on Reset,  Reset

.org 0x0034

SerialInit:
		clr r17
		sts UBRR0H, r17
		ldi r16, 0x19 ;Set BAUD rate to 9600 (assuming a 16MHz system clock)
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


_START:
		
		sbi DDRB, DDRB5   ; PORTB0 will be output
		sbi PORTB, PORTB5 ; set portb 0 high
		sbi DDRB, DDRB0   ; PORTB0 will be output
		sbi PORTB, PORTB0 ; set portb 0 high
		
		cli ;Disable interrupts while doing setup

		;Set up USART
		call SerialInit

		sei ;Allow interrupts

		;Point Z-Register to our message and send.
		;Address of message is shifted left one bit since data in
		;program space is stored 16-bits wide. The LSB of the Z
		;register is used to distinguish between the upper or lower
		;byte.
		ldi r30, low(message<<1)
		ldi r31, high(message<<1)

UART_WAIT:
		lds r17, UCSR0A ; load uart0 status register
		sbrs r17, UDRE0 ; check for empty data register flag
		rjmp UART_WAIT
LOOP: 	lpm r16, Z+
		tst r16
		breq HALT
		call USART_TRA
		rjmp UART_WAIT

HALT:	rjmp HALT

message: .db  "kako si kaj", 0x00 ; null terminated string