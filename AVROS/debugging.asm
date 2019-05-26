/*
 * debugging.asm
 *
 *  Created: 26.5.2019 15:20:11
 *   Author: gustin
 */ 

 .cseg
.org 0x0000

ldi r18, 0b_0000_0000
out SREG, r18

ldi r16, 0b0000_0000
tst r16
ldi r17, 0b1111_1111
tst r17
out SREG, r18
inc r17


loop: rjmp loop