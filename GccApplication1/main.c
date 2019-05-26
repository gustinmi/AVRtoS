/*
 * GccApplication1.c
 *
 * Created: 2. 05. 2019 13:33:56
 * Author : gustin
 */ 

#include <avr/io.h>
#include <avr/interrupt.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <avr/sleep.h>

#define TIMER_ITR_VAL 15625

int numint = 0;

int main(void)
{
	TCCR1A = 0; // clear Timer control H register
	TCCR1B = 0; // clear Timer control L register	
	
	//TCNT1 = 34286;            

	//TCCR1B |= (1 << CS12);    
	// TCCR0B |= (1<<CS01)|(1<<CS00); 

	TIMSK1 |= (1 << OCIE1B);   // this will triger Interrupt Service routine ISR for timer1
	TCNT1 = 0; // Ko doseže to cifro overflow, se resetira

	OCR1B = 23330;

	// Frequency CPU = 16 000 000 / 256 = 62500 ticks per second . This will be "resolution" of one second of our timer
	// Method will start timer !!
	TCCR1B |= (1 << CS10);	
	
	sei(); /* enable interrupts back */

	for (;;){                    /* loop forever, the interrupts are doing the rest */
		;
	}

	return (0);
    
}

ISR(TIMER1_COMPB_vect)        // interrupt service routine that wraps a user defined function supplied by attachInterrupt
{	
	numint++;
}

