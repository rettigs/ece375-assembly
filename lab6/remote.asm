;***********************************************************
;*
;*  Enter Name of file here
;*
;*  Enter the description of the program here
;*
;*  This is the TRANSMIT skeleton file for Lab 6 of ECE 375
;*
;***********************************************************
;*
;*   Author: Sean Rettig
;*     Date: 2015-02-25
;*
;***********************************************************

.include "m128def.inc"          ; Include definition file

;***********************************************************
;*  Internal Register Definitions and Constants
;***********************************************************
.def    mpr = r16               ; Multi-Purpose Register

.equ    WskrR = 0               ; Right Whisker Input Bit
.equ    WskrL = 1               ; Left Whisker Input Bit
.equ    EngEnR = 4              ; Right Engine Enable Bit
.equ    EngEnL = 7              ; Left Engine Enable Bit
.equ    EngDirR = 5             ; Right Engine Direction Bit
.equ    EngDirL = 6             ; Left Engine Direction Bit

.equ    BotID = 0b00100101      ; 37; Unique XD ID (MSB = 0)

; Use these commands between the remote and TekBot
; MSB = 1 thus:
; commands are shifted right by one and ORed with 0b10000000 = $80
.equ    MovFwd =  ($80|1<<(EngDirR-1)|1<<(EngDirL-1))   ;0b10110000 Move Forwards Command
.equ    MovBck =  ($80|$00)                             ;0b10000000 Move Backwards Command
.equ    TurnR =   ($80|1<<(EngDirL-1))                  ;0b10100000 Turn Right Command
.equ    TurnL =   ($80|1<<(EngDirR-1))                  ;0b10010000 Turn Left Command
.equ    Halt =    ($80|1<<(EngEnR-1)|1<<(EngEnL-1))     ;0b11001000 Halt Command

;***********************************************************
;*  Start of Code Segment
;***********************************************************
.cseg                           ; Beginning of code segment

;-----------------------------------------------------------
; Interrupt Vectors
;-----------------------------------------------------------
.org    $0000                   ; Beginning of IVs
        rjmp    INIT            ; Reset interrupt
.org    $0008
        rcall   ButtonMovFwd
        reti
.org    $000A
        rcall   ButtonMovBck
        reti
.org    $000C
        rcall   ButtonTurnR
        reti
.org    $000E
        rcall   ButtonTurnL
        reti

.org    $0046                   ; End of Interrupt Vectors

;-----------------------------------------------------------
; Program Initialization
;-----------------------------------------------------------
INIT:
    ; Initialize stack
        LDI     mpr, high(RAMEND)
        OUT     SPH, mpr
        LDI     mpr, low(RAMEND)
        OUT     SPL, mpr

    ; Initialize I/O Ports
        ; NOTES:
        ; Port D bit 2 corresponds to INT2 and is used for receiving data on USART1
        ; Port D bit 3 corresponds to INT3 and is used for transmitting data on USART1
        ; Port E bits 7-4 correspond to INT7:4 and are used for receiving button presses

        ; Set Port D for output
        ldi     mpr, 0b00000100
        out     DDRD, mpr

        ; Set Port E for input
        ldi     mpr, 0b00000000
        out     DDRE, mpr

        ; Enable pull-up resistors
        ldi     mpr, (0b11110000)
        out     PORTE, mpr

        ; Set Port B for output
        ldi     mpr, 0b11111000
        out     DDRB, mpr

    ; Initialize USART1
        ldi     mpr, (1<<U2X1) ; Set double data rate
        sts     UCSR1A, mpr

        ; Set baud rate at 2400bps (taking into account double data rate)
        ldi     mpr, high(832) ; Load high byte of 0x0340
        sts     UBRR1H, mpr ; UBRR1H in extended I/O space
        ldi     mpr, low(832) ; Load low byte of 0x0340
        sts     UBRR1L, mpr

        ; Set frame format: 8 data, 2 stop bits
        ldi     mpr, (0<<UMSEL1 | 1<<USBS1 | 1<<UCSZ11 | 1<<UCSZ10)
        sts     UCSR1C, mpr ; UCSR0C in extended I/O space

        ; Enable transmitter
        ldi     mpr, (1<<TXEN1)
        sts     UCSR1B, mpr

    ; Initialize external interrupts
        ; Set the Interrupt Sense Control to level low for button interrupts (INT7:4)
        ldi mpr, (0<<ISC71)|(0<<ISC70)|(0<<ISC61)|(0<<ISC60)|(0<<ISC51)|(0<<ISC50)|(0<<ISC41)|(0<<ISC40)
        sts EICRB, mpr ; Use sts, EICRB in extended I/O space
        ; Set the External Interrupt Mask
        ldi mpr, (1<<INT7)|(1<<INT6)|(1<<INT5)|(1<<INT4)
        out EIMSK, mpr
        ; Turn on interrupts
        sei

;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:

        rjmp    MAIN

;***********************************************************
;*  Functions and Subroutines
;***********************************************************

ButtonMovFwd:
        ; Turn on button LED
        ldi     mpr, $FF
        out     PORTB, mpr

        ; Send Command
        ldi     mpr, MovFwd
        out     PORTD, mpr

        ; Turn off button LED
        ldi     mpr, 0
        out     PORTB, mpr

        ret

ButtonMovBck:
        ; Turn on button LED
        ldi     mpr, $FF
        out     PORTB, mpr

        ; Turn off button LED
        ldi     mpr, 0
        out     PORTB, mpr
        ret

ButtonTurnR:
        ; Turn on button LED
        ldi     mpr, $FF
        out     PORTB, mpr

        ; Turn off button LED
        ldi     mpr, 0
        out     PORTB, mpr
        ret

ButtonTurnL:
        ; Turn on button LED
        ldi     mpr, $FF
        out     PORTB, mpr

        ; Turn off button LED
        ldi     mpr, 0
        out     PORTB, mpr
        ret

ButtonHalt:
        ; Turn on button LED
        ldi     mpr, $FF
        out     PORTB, mpr

        ; Turn off button LED
        ldi     mpr, 0
        out     PORTB, mpr
        ret

;***********************************************************
;*  Stored Program Data
;***********************************************************



;***********************************************************
;*  Additional Program Includes
;***********************************************************
