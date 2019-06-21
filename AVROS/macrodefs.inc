/*
 * macrodefs.inc
 *
 *  Created: 3. 05. 2019 00:35:15
 *   Author: gustin
 */ 

.MACRO SUBI16 ; Start macro definition 
subi @1,low(@0) ; Subtract low byte 
sbci @2,high(@0) ; Subtract high byte 
.ENDMACRO ; End macro definition

; LDS load SRAM at memory @0 address to register @1
.MACRO LDMEM ; Start macro definition 
ldi r30, low(@0); load address to Z
ldi r31, high(@0)
ld @1, Z ; load register
.ENDMACRO ; End macro definition

; STS store register @1 to SRAM address @0
.MACRO STMEM ; Start macro definition 
ldi r30, low(@0); load address to Z
ldi r31, high(@0)
st Z, @1 ; store to register
.ENDMACRO ; End macro definition