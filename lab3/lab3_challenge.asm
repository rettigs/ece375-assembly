
;***********************************************************
;*
;*	LCDTest.asm	-	V1.5
;*
;*	This program contains all the essentials to create and 
;*	use the LCD Display on the TekBots(tm) platform.  It 
;*	covers the basics of initializing and writing to the 
;*	display.  Additionally, it also uses the Bin2ASCII 
;*	function to illustrate the limited use of a printf-like
;*	statement.  ALL CALLS TO THE LCD DRIVER WILL HAVE 
;*	CAPITALIZED COMMENTS SO THAT YOU CAN EASILY FIND WHERE
;*	AND HOW TO USE THE LCD DRIVER.
;*
;*	This version has been updated to support the LCDDriver V2
;*
;***********************************************************
;*
;*	 Author: David Zier
;*	   Date: March 25, 2003
;*	Company: TekBots(TM), Oregon State University - EECS
;*	Version: 1.5
;*
;***********************************************************
;*	Rev	Date	Name		Description
;*----------------------------------------------------------
;*	-	7/15/02	Zier		Initial Creation of Version 1.0
;*	A	3/15/03	Zier		V1.5 - Updated for LCD Driver V2
;*
;*
;***********************************************************

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.include "m128def.inc"			; Include the ATMega128 Definition Doc

.def	mpr = r16				; Multi-purpose register defined for LCDDV2
.def	lastchar = r15			; Multi-purpose register defined for LCDDV2
.def	ReadCnt = r23			; Counter used to read data from Program Memory
.def	counter = r4			; Counter used for Bin2ASCII demo
.def	val = r5				; Value to be compared with
.def	TimerCnt = r6			; Counter used for the timer

.equ	CountAddr = $0130		; Address of ASCII counter text

.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp INIT				; Reset interrupt
.org	$001e	
		rjmp TIM0_OVF			; Timer0 Overflow Handler

;***********************************************************
;*	Program Initialization 
;***********************************************************
.org	$0046					; Origin of the Program, after IVs
INIT:							; Initialize Stack Pointer
		ldi		mpr, HIGH(RAMEND)
		out		SPH, mpr
		ldi		mpr, LOW(RAMEND)
		out		SPL, mpr

;		ldi		mpr, 170
;		ldi		XL, 10
;;		ldi		XH, 01
;		rcall   Bin2ASCII

		rcall	LCDInit			; INITIALIZE THE LCD DISPLAY

		; Timer/Counter 0 Initialization
		; Clock Source: System Clock
		; Clock Value: 15.625 kHz
		; Mode: CTC top=OCR0
		; OC0 output: Disconnected
		ldi		mpr, (1<<WGM01|1<<CS02|1<<CS01|1<<CS00)	
		out		TCCR0, mpr		; Set timer prescalar to (clk/64)
		ldi		mpr, $30		; Set timer value
		out		OCR0, mpr		; Set TCNT0
		ldi		mpr, (1<<OCIE0)	; Set Timer 0 OVF interrupt

		; Timer(s)/Counter(s) Interrupt(s) initialization
		out		TIMSK, mpr		; Set TIMSK

		ldi		mpr, 0
		mov		counter, mpr	; Clear the Counter
		clr		TimerCnt		; Clear Timer Counter

		; Write initial string to LCD line 1
		ldi		ZL, low(TXT0<<1); Init variable registers
		ldi		ZH, high(TXT0<<1)
		ldi		YL, low(LCDLn1Addr)
		ldi		YH, high(LCDLn1Addr)
		ldi		ReadCnt, LCDMaxCnt
INIT_LINE1:
		lpm		mpr, Z+			; Read Program memory
		st		Y+, mpr			; Store into memory
		dec		ReadCnt			; Decrement Read Counter
		brne	INIT_LINE1		; Continue untill all data is read
		rcall	LCDWrLn1		; WRITE LINE 1 DATA

		; Write initial string to LCD line 2
		ldi		ZL, low(TXT1<<1); Init variable registers
		ldi		ZH, high(TXT1<<1)
		ldi		YL, low(LCDLn2Addr)
		ldi		YH, high(LCDLn2Addr)
		ldi		ReadCnt, LCDMaxCnt
INIT_LINE2:
		lpm		mpr, Z+			; Read Program memory
		st		Y+, mpr			; Store into memory
		dec		ReadCnt			; Decrement Read Counter
		brne	INIT_LINE2		; Continue untill all data is read
		rcall	LCDWrLn2		; WRITE LINE 1 DATA

		; Activate interrupts
		sei						; Turn on interrupts

;***********************************************************
;*	The main program 
;***********************************************************
MAIN:
		rjmp	MAIN			; Go back to beginning



;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;***********************************************************
;*	Interrupt Service Routines
;***********************************************************

;***********************************************************
;* ISR:		Timer 0 Overflow Interrupt Handler
;* Desc:	This ISR will increment the counter and update
;*			line 1 of the LCD Display to reflect the value
;***********************************************************
TIM0_OVF:
		push	mpr				; Save the mpr
		push	lastchar		; Save the lastchar
		in		mpr, SREG		; Save the SREG
		push	mpr				; 
		
		inc		TimerCnt		; Increment counter
		brne	TIM0_OVF_DONE	; If count is not 0, leave interrupt

		ldi		YL, low(LCDLn1Addr+LCDMaxCnt*2)
		ldi		YH, high(LCDLn1Addr+LCDMaxCnt*2)
		dec		YL
		ld		lastchar, Y
		dec		YL
		ldi		ReadCnt, LCDMaxCnt*2
SHIFT:
		ld		mpr, Y
		inc		YL
		st		Y, mpr
		dec		YL
		dec		YL
		dec		ReadCnt
		brne	SHIFT

		inc		YL
		inc		YL
		st		Y, lastchar

		rcall	LCDWrite

		inc		counter			; Increment the counter for the next round

TIM0_OVF_DONE:
		pop		mpr				; Restore the SREG
		out		SREG, mpr		; 
		pop		lastchar		; Restore the lastchar
		pop		mpr				; Restore the mpr
		reti					; Return from interrupt

;***********************************************************
;*	Data Definitions
;***********************************************************
TXT0:
.DB "Sean and David  "
TXT1:
.DB "Hello World!    "

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver
