;***********************************************************
;*
;*  Enter Name of file here
;*
;*  Enter the description of the program here
;*
;*  This is the RECEIVE skeleton file for Lab 6 of ECE 375
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
.def    data = r17
.def    accept = r18

.equ    WskrR = 0               ; Right Whisker Input Bit
.equ    WskrL = 1               ; Left Whisker Input Bit
.equ    EngEnR = 4              ; Right Engine Enable Bit
.equ    EngEnL = 7              ; Left Engine Enable Bit
.equ    EngDirR = 5             ; Right Engine Direction Bit
.equ    EngDirL = 6             ; Left Engine Direction Bit

.equ    BotID = 0b00100101      ; 37; Unique XD ID (MSB = 0)

;/////////////////////////////////////////////////////////////
;These macros are the values to make the TekBot Move.
;/////////////////////////////////////////////////////////////

.equ    MovFwd =  (1<<EngDirR|1<<EngDirL)   ;0b01100000 Move Forwards Command
.equ    MovBck =  $00                       ;0b00000000 Move Backwards Command
.equ    TurnR =   (1<<EngDirL)              ;0b01000000 Turn Right Command
.equ    TurnL =   (1<<EngDirR)              ;0b00100000 Turn Left Command
.equ    Halt =    (1<<EngEnR|1<<EngEnL)     ;0b10010000 Halt Command

;***********************************************************
;*  Start of Code Segment
;***********************************************************
.cseg                           ; Beginning of code segment

;-----------------------------------------------------------
; Interrupt Vectors
;-----------------------------------------------------------
.org    $0000                   ; Beginning of IVs
        rjmp    INIT            ; Reset interrupt

;Should have Interrupt vectors for:
;- Left wisker
;- Right wisker
;- USART receive
.org    $003C
        rcall   USART_Receive
        reti

.org    $0046                   ; End of Interrupt Vectors

;-----------------------------------------------------------
; Program Initialization
;-----------------------------------------------------------
INIT:
    ; Initialize registers
        clr     accept

    ; Initialize stack
        LDI     mpr, high(RAMEND)
        OUT     SPH, mpr
        LDI     mpr, low(RAMEND)
        OUT     SPL, mpr

    ; Initialize I/O Ports
        ; NOTES:
        ; Port D bit 2 corresponds to INT2 and is used for receiving data on USART1
        ; Port D bit 3 corresponds to INT3 and is used for transmitting data on USART1

        ; Set Port D pin 2 (TXD0) for input
        ldi mpr, (1<<PD2)
        out DDRD, mpr

        ; Initialize Port B for output
        ldi mpr, (1<<EngEnL)|(1<<EngEnR)|(1<<EngDirR)|(1<<EngDirL)
        out DDRB, mpr ; Set the DDR register for Port B
        ldi mpr, $00
        out PORTB, mpr ; Set the default output for Port B

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

        ; Enable receiver and receive interrupts
        ldi     mpr, (1<<RXEN1 | 1<<RXCIE1)
        sts     UCSR1B, mpr

    ; Initialize external interrupts
        ; Set the Interrupt Sense Control to level low for button interrupts (INT7:4)
        ldi mpr, (0<<ISC21)|(0<<ISC20)
        sts EICRA, mpr ; Use sts, EICRA in extended I/O space
        ; Set the External Interrupt Mask
        ldi mpr, (1<<INT2)
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

USART_Receive:
        push    mpr

        lds     data, UDR1 ; Read data from Receive Data Buffer

        ; Check if it's an ID or a command
        ldi     mpr, 0b10000000
        and     mpr, data
        breq    ProcessID ; If the result is all zeroes, it starts with a 0 and is an ID
        rjmp    ProcessCommand; Otherwise, it's a command

ProcessID:
        cpi     data, BotID
        breq    SetAccept ; If the BotID matches, go into accept mode
        clr     accept ; If it doesn't match, make sure we're NOT in accept mode
        rjmp    USART_Receive_End

SetAccept:
        ldi     accept, 1 ; If it does match, go into accept mode
        rjmp    USART_Receive_End

ProcessCommand:
        cpi     accept, 1
        brne    USART_Receive_End ; If we aren't in accept mode, do nothing
        ; If we are in accept mode, run the command

        ; Decode command
        andi    data, 0b01111111
        lsl     data

        out     PORTB, data  ; Send command to port
        clr     accept ; Leave accept mode since we just accepted

USART_Receive_End:

        pop     mpr
        ret

;***********************************************************
;*  Stored Program Data
;***********************************************************



;***********************************************************
;*  Additional Program Includes
;***********************************************************

