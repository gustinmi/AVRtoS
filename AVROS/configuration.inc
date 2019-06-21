// AVROS Configuration

#ifndef CONFIGURATION_H_
#define CONFIGURATION_H_

; ====================================================
; Definition of HD44780 LCD Assembly driver
; ====================================================

#define HD44780_CLEAR					0x01	; clear the screen command

#define HD44780_HOME					0x02	; cursor to home position

#define HD44780_ENTRY_MODE				0x04	; display modes
#define HD44780_EM_SHIFT_CURSOR		0
#define HD44780_EM_SHIFT_DISPLAY	1
#define HD44780_EM_DECREMENT		0
#define HD44780_EM_INCREMENT		2

; D = 0; Display off
; C = 0; Cursor off
; B = 0; Blinking off

#define HD44780_DISPLAY_ONOFF			0x08
#define HD44780_DISPLAY_OFF			0
#define HD44780_DISPLAY_ON			4
#define HD44780_CURSOR_OFF			0
#define HD44780_CURSOR_ON			2
#define HD44780_CURSOR_NOBLINK		0
#define HD44780_CURSOR_BLINK		1

#define HD44780_DISPLAY_CURSOR_SHIFT	0x10
#define HD44780_SHIFT_CURSOR		0
#define HD44780_SHIFT_DISPLAY		8
#define HD44780_SHIFT_LEFT			0
#define HD44780_SHIFT_RIGHT			4

#define HD44780_FUNCTION_SET			0x20	; settings for font size, 4 or 8 bit interface
#define HD44780_FONT5x7				0
#define HD44780_FONT5x10			4
#define HD44780_ONE_LINE			0
#define HD44780_TWO_LINE			8
#define HD44780_4_BIT				0
#define HD44780_8_BIT				16

#define HD44780_CGRAM_SET				0x40	; address of character RAMS
#define HD44780_DDRAM_SET				0x80	; address of dynamic DRAM

;------------------------------------------------------------------------------
; CLOCK settings 
;------------------------------------------------------------------------------

#define F_CPU 16000000 ; ATMega328PU clock settings

; DELAY UTILS need to set this for proper wait / delay 

#ifndef F_CPU
  #error "F_CPU must be defined!"
#endif

#if F_CPU < 4000000
  #warning "F_CPU too low, possible wrong delay"
#endif

#define CYCLES_PER_US (F_CPU/1000000)	; how many cycles for 1 microsecond us
#define C4PUS (CYCLES_PER_US/4)			;	
#define DVUS(x) (C4PUS*x)

;------------------------------------------------------------------------------
; UART SETTINGS and ASCII Mapping codes 
;------------------------------------------------------------------------------

; control characters

#define	A2I_ENTER_CODE 0x0D	; ascii ENTER CR
#define A2I_BACKSPACE 0x08	; asciie BS 
#define A2I_BELL 0x07		; ascii BELL
#define A2I_NEWLINE	0x0c	; ascii FF, NP

; value characters

#define A2I_SPACE 0x20	; binary value 00100000	
;#define ! 0x21		; binary value 00100001	
;#define " 0x22		; binary value 00100010	
;#define # 0x23		; binary value 00100011	
;#define $ 0x24		; binary value 00100100	
;#define % 0x25		; binary value 00100101	
;#define & 0x26		; binary value 00100110	
;#define ' 0x27		; binary value 00100111	
;#define ( 0x28		; binary value 00101000	
;#define ) 0x29		; binary value 00101001	
;#define * 0x2A		; binary value 00101010	
;#define + 0x2B		; binary value 00101011	
;#define , 0x2C		; binary value 00101100	
;#define - 0x2D		; binary value 00101101	
;#define . 0x2E		; binary value 00101110	
;#define / 0x2F		; binary value 00101111	
#define A2I_0 0x30		; binary value 00110000	
#define A2I_1 0x31		; binary value 00110001	
#define A2I_2 0x32		; binary value 00110010	
#define A2I_3 0x33		; binary value 00110011	
#define A2I_4 0x34		; binary value 00110100	
#define A2I_5 0x35		; binary value 00110101	
#define A2I_6 0x36		; binary value 00110110	
#define A2I_7 0x37		; binary value 00110111	
#define A2I_8 0x38		; binary value 00111000	
#define A2I_9 0x39		; binary value 00111001	
;#define : 0x3A		; binary value 00111010	
;#define ; 0x3B		; binary value 00111011	
;#define < 0x3C		; binary value 00111100	
;#define = 0x3D		; binary value 00111101	
;#define > 0x3E		; binary value 00111110	
;#define ? 0x3F		; binary value 00111111	
;#define @ 0x40		; binary value 01000000	
#define A2I_A 0x41		; binary value 01000001	
#define A2I_B 0x42		; binary value 01000010	
#define A2I_C 0x43		; binary value 01000011	
#define A2I_D 0x44		; binary value 01000100	
#define A2I_E 0x45		; binary value 01000101	
#define A2I_F 0x46		; binary value 01000110	
#define A2I_G 0x47		; binary value 01000111	
#define A2I_H 0x48		; binary value 01001000	
#define A2I_I 0x49		; binary value 01001001	
#define A2I_J 0x4A		; binary value 01001010	
#define A2I_K 0x4B		; binary value 01001011	
#define A2I_L 0x4C		; binary value 01001100	
#define A2I_M 0x4D		; binary value 01001101	
#define A2I_N 0x4E		; binary value 01001110	
#define A2I_O 0x4F		; binary value 01001111	
#define A2I_P 0x50		; binary value 01010000	
#define A2I_Q 0x51		; binary value 01010001	
#define A2I_R 0x52		; binary value 01010010	
#define A2I_S 0x53		; binary value 01010011	
#define A2I_T 0x54		; binary value 01010100	
#define A2I_U 0x55		; binary value 01010101	
#define A2I_V 0x56		; binary value 01010110	
#define A2I_W 0x57		; binary value 01010111	
#define A2I_X 0x58		; binary value 01011000	
#define A2I_Y 0x59		; binary value 01011001	
#define A2I_Z 0x5A		; binary value 01011010	
;#define A2I_[ 0x5B		; binary value 01011011	
;#define A2I_\ 0x5C		; binary value 01011100	
;#define A2I_] 0x5D		; binary value 01011101	
;#define A2I_^ 0x5E		; binary value 01011110	
;#define A2I__ 0x5F		; binary value 01011111	
;#define A2I_` 0x60		; binary value 01100000	
#define A2I_a 0x61		; binary value 01100001	
#define A2I_b 0x62		; binary value 01100010	
#define A2I_c 0x63		; binary value 01100011	
#define A2I_d 0x64		; binary value 01100100	
#define A2I_e 0x65		; binary value 01100101	
#define A2I_f 0x66		; binary value 01100110	
#define A2I_g 0x67		; binary value 01100111	
#define A2I_h 0x68		; binary value 01101000	
#define A2I_i 0x69		; binary value 01101001	
#define A2I_j 0x6A		; binary value 01101010	
#define A2I_k 0x6B		; binary value 01101011	
#define A2I_l 0x6C		; binary value 01101100	
#define A2I_m 0x6D		; binary value 01101101	
#define A2I_n 0x6E		; binary value 01101110	
#define A2I_o 0x6F		; binary value 01101111	
#define A2I_p 0x70		; binary value 01110000	
#define A2I_q 0x71		; binary value 01110001	
#define A2I_r 0x72		; binary value 01110010	
#define A2I_s 0x73		; binary value 01110011	
#define A2I_t 0x74		; binary value 01110100	
#define A2I_u 0x75		; binary value 01110101	
#define A2I_v 0x76		; binary value 01110110	
#define A2I_w 0x77		; binary value 01110111	
#define A2I_x 0x78		; binary value 01111000	
#define A2I_y 0x79		; binary value 01111001	
#define A2I_z 0x7A		; binary value 01111010	
;#define { 0x7B		; binary value 01111011	
;#define | 0x7C		; binary value 01111100	
;#define } 0x7D		; binary value 01111101	
;#define ~ 0x7E		; binary value 01111110	

#endif /* CONFIGURATION_H_ */
