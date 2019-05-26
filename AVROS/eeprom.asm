;
; AssemblerApplication1.asm
;
; Created: 1. 05. 2019 14:14:40
; Author : gustin
;

.ESEG 
eevar1:
	.db 0b1110_1111 ; initialize 1 word in EEPROM
	;.db 0x1110 ; initialize 1 word in EEPROM
	;.db 0x1111 ; initialize 1 word in EEPROM

;const2:
;	.db 1,2,3

.dseg
.org SRAM_START

eePromVal:
	.byte 1 ; Reserve 16 bytes to sLabel1

.cseg
.org 0x0000

; Replace with your application code
start:

	;initialization of the stack pointer
	ldi r16, high(RAMEND) ; init stack pointer
	out SPH, r16 ; Set Stack Pointer to top of RAM
	ldi r16, low(RAMEND)
	out SPL, r16

	ldi r30, low(eevar1); load address to Z
	ldi r31, high(eevar1)
	ld r1, Z


loop:
	ldi r16, 0x03
	ldi r18, 0x00 
	ldi r17, 0x01
	rcall eeprom_write
wt1:
	sbic EECR, EEPE
    rjmp wt1
	rcall eeprom_read
wt2:
	sbic EECR, EERE
	rjmp wt2
	clr r16
	clr r19
	rjmp loop

eeprom_write:
	sbic EECR, EEPE
	rjmp eeprom_write
	out EEARH, r18
	out EEARL, r17
	out EEDR, r16
	sbi EECR, EEMPE
	sbi EECR, EEPE
	ret

eeprom_read:
	sbic EECR, EERE
	rjmp eeprom_read
	out EEARH, r18
	out EEARL, r17
	sbi EECR, EERE
	in r19, EEDR

	ret