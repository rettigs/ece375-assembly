
;***********************************************************
;*
;*	Enter Name of file here
;*
;*	Enter the description of the program here
;*
;*	This is the skeleton file Lab 3 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Sean Rettig
;*	   Date: 2015-01-21
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register required for LCD Driver


;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;-----------------------------------------------------------
; Interrupt Vectors
;-----------------------------------------------------------
.org	$0000					; Beginning of IVs
		rjmp INIT				; Reset interrupt

.org	$0046					; End of Interrupt Vectors

;-----------------------------------------------------------
; Program Initialization
;-----------------------------------------------------------
INIT:							; The initialization routine
		; Initialize Stack Pointer
		LDI R16, LOW(RAMEND) ; Low Byte of End SRAM Address
		OUT SPL, R16 ; Write byte to SPL
		LDI R16, HIGH(RAMEND) ; High Byte of End SRAM Address
		OUT SPH, R16 ; Write byte to SPH

		; Initialize LCD Display
		rcall LCDInit ; Call LCD Init Subroutine

		; Move strings from Program Memory to Data Memory
		ldi ZH, high(STRING_BEG1<<1); Initialize Z-pointer
		ldi ZL, low(STRING_BEG1<<1)

		ldi		YL, low(LCDLn1Addr)
		ldi		YH, high(LCDLn1Addr)

		ldi		r23, 14

LINE1:
		lpm r16, Z+ ; Load constant from Program
		st  Y+, r16
		dec		r23			; Decrement Read Counter
		brne	LINE1
		
		; Move strings from Program Memory to Data Memory
		ldi ZH, high(STRING_BEG2<<1); Initialize Z-pointer
		ldi ZL, low(STRING_BEG2<<1)

		ldi		YL, low(LCDLn2Addr)
		ldi		YH, high(LCDLn2Addr)

		ldi		r23, 12

LINE2:
		lpm r16, Z+ ; Load constant from Program
		st  Y+, r16
		dec		r23			; Decrement Read Counter
		brne	LINE2

		; NOTE that there is no RET or RJMP from INIT, this is
		; because the next instruction executed is the first for
		; the main program

;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:							; The Main program
		; Display the strings on the LCD Display
		; Move ASCII string to line addresses $0100-$011F
		rcall LCDWrite ; Write string to LCD
		
		rjmp	MAIN			; jump back to main and create an infinite
								; while loop.  Generally, every main program is an
								; infinite while loop, never let the main program
								; just run off

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: Template function header
; Desc: Cut and paste this and fill in the info at the 
;		beginning of your functions
;-----------------------------------------------------------
FUNC:							; Begin a function with a label
		; Save variable by pushing them to the stack

		; Execute the function here
		
		; Restore variable by popping them from the stack in reverse order\
		ret						; End a function with RET


;***********************************************************
;*	Stored Program Data
;***********************************************************

;----------------------------------------------------------
; An example of storing a string, note the preceeding and
; appending labels, these help to access the data
;----------------------------------------------------------
STRING_BEG1:
.DB		"Sean and David"		; Storing the string in Program Memory
STRING_BEG2:
.DB		"Hello World!"		; Storing the string in Program Memory
STRING_END:

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver
