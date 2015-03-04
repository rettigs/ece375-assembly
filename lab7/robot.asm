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
.def    B = r17         ; Wait Loop Counter
.def    data = r20
.def    command = r21
.def    accept = r22
.def    speed = r23

.equ    WTime = 100             ; Time to wait in wait loop

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
.equ    Up =      0b00001110                ;0b11100000 Speed Up Command
.equ    Down =    0b00001100                ;0b11000000 Speed Down Command

;***********************************************************
;*  Start of Code Segment
;***********************************************************
.cseg                           ; Beginning of code segment

;-----------------------------------------------------------
; Interrupt Vectors
;-----------------------------------------------------------
.org    $0000                   ; Beginning of IVs
        rjmp    INIT            ; Reset interrupt
.org    $0002
        rcall   HitRight
        reti
.org    $0004
        rcall   HitLeft
        reti
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
        clr     command
        ldi     speed, 8

    ; Initialize stack
        LDI     mpr, high(RAMEND)
        OUT     SPH, mpr
        LDI     mpr, low(RAMEND)
        OUT     SPL, mpr

    ; Initialize I/O Ports
        ; NOTES:
        ; Port D bit 2 corresponds to INT2 and is used for receiving data on USART1
        ; Port D bit 3 corresponds to INT3 and is used for transmitting data on USART1

        ; Set Port D pin 2 (TXD0) for input and pins 1-0 for whisker input
        ldi mpr, (1<<PD2)|(0<<WskrR)|(0<<WskrL)
        out DDRD, mpr

        ; Set pullup resistors
        ldi mpr, (1<<PD2)|(0<<WskrR)|(0<<WskrL)
        out PORTD, mpr

        ; Initialize Port B for output
        ldi mpr, $FF
        out DDRB, mpr ; Set the DDR register for Port B
        out PORTB, speed ; Set the default output for Port B

    ; Initialize timers
        ; Initialize Timer/Counter 0 for right motor
        LDI     mpr, 0b01110011 ; Activate Fast PWM mode with toggle
        OUT     TCCR0, mpr ; (non-inverting), and set prescalar to 1024
        
        ; Initialize Timer/Counter 2 for left motor
        LDI     mpr, 0b01110011 ; Activate Fast PWM mode with toggle
        OUT     TCCR2, mpr ; (non-inverting), and set prescalar to 1024

        ; Set the compare value for timer/counter 0 and 2
        rcall   UpdateTimers

        ; Initialize Timer/Counter 3 for wait subroutine
        LDI     mpr, 0b00000000
        sts     TCCR3A, mpr
        LDI     mpr, 0b00000100
        sts     TCCR3B, mpr
        ldi     mpr, HIGH($FFFF)
        sts     OCR3AH, mpr
        ldi     mpr, LOW($FFFF)
        sts     OCR3AL, mpr

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
        ; Set the Interrupt Sense Control to level low
        ldi mpr, (0<<ISC21)|(0<<ISC20)|(0<<ISC11)|(0<<ISC10)|(0<<ISC01)|(0<<ISC00)
        sts EICRA, mpr ; Use sts, EICRA in extended I/O space
        ; Set the External Interrupt Mask
        ldi mpr, (1<<INT2)|(1<<INT1)|(1<<INT0)
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
        lsl     data ; Decode command

CheckUp:
        cpi     data, Up
        brne    CheckDown
        inc     speed
        cpi     speed, 16
        brne    SendCommand
        dec     speed
        rjmp    SendCommand

CheckDown:
        cpi     data, Down
        brne    OtherCommand
        dec     speed
        cpi     speed, 255
        brne    SendCommand
        inc     speed
        rjmp    SendCommand

OtherCommand:
        mov     command, data ; The command is direct motor input
        rjmp    SendCommand

SendCommand:
        mov     mpr, command    ; Upper 4 bits is motor command
        or      mpr, speed      ; Lower 4 bits is LED speed indicator

        rcall   UpdateTimers

        out     PORTB, mpr  ; Send command/speed to port
        clr     accept ; Leave accept mode since we just accepted
        rjmp    USART_Receive_End

USART_Receive_End:
        pop     mpr
        ret


UpdateTimers:
        push    mpr

        mov     mpr, speed
        lsl     mpr
        lsl     mpr
        lsl     mpr
        lsl     mpr
        or      mpr, speed

        out     OCR0, mpr
        out     OCR2, mpr

        pop     mpr
        ret

;----------------------------------------------------------------
; Sub:  HitRight
; Desc: Handles functionality of the TekBot when the right whisker
;       is triggered.
;----------------------------------------------------------------
HitRight:
        push    mpr         ; Save mpr register
        in      mpr, SREG   ; Save program state
        push    mpr         ;

        ; Move Backwards for a second
        ldi     mpr, MovBck ; Load Move Backwards command
        or      mpr, speed
        out     PORTB, mpr  ; Send command to port
        rcall   Wait            ; Call wait function

        ; Turn left for a second
        ldi     mpr, TurnL  ; Load Turn Left Command
        or      mpr, speed
        out     PORTB, mpr  ; Send command to port
        rcall   Wait            ; Call wait function

        ; Resume previous command
        mov     mpr, command
        or      mpr, speed
        out     PORTB, mpr

        pop     mpr     ; Restore program state
        out     SREG, mpr   ;
        pop     mpr     ; Restore mpr
        ret             ; Return from subroutine

;----------------------------------------------------------------
; Sub:  HitLeft
; Desc: Handles functionality of the TekBot when the left whisker
;       is triggered.
;----------------------------------------------------------------
HitLeft:
        push    mpr         ; Save mpr register
        in      mpr, SREG   ; Save program state
        push    mpr         ;

        ; Move Backwards for a second
        ldi     mpr, MovBck ; Load Move Backwards command
        or      mpr, speed
        out     PORTB, mpr  ; Send command to port
        rcall   Wait            ; Call wait function

        ; Turn right for a second
        ldi     mpr, TurnR  ; Load Turn Left Command
        or      mpr, speed
        out     PORTB, mpr  ; Send command to port
        rcall   Wait            ; Call wait function

        ; Resume previous command
        mov     mpr, command
        or      mpr, speed
        out     PORTB, mpr

        pop     mpr     ; Restore program state
        out     SREG, mpr   ;
        pop     mpr     ; Restore mpr
        ret             ; Return from subroutine

; Subroutine to wait for 1 s
Wait:
        LDI B, 1 ; Load loop count = 100
WAIT_10msec:
        LDI mpr, HIGH(0) ; (Re)load value for delay
        sts TCNT3H, mpr
        LDI mpr, LOW(0) ; (Re)load value for delay
        sts TCNT3L, mpr
        ; Wait for TCNT3 to roll over
CHECK:
        lds     mpr, ETIFR ; Read in TIFR
        ANDI    mpr, 0b00000100 ; Check if TOV3 set
        BREQ    CHECK ; Loop if TOV3 not set 
        LDI mpr, 0b00000100 ; Otherwise, Reset TOV3
        sts ETIFR, mpr ; Note - write 1 to reset
        DEC B ; Decrement count
        BRNE WAIT_10msec ; Loop if count not equal to 0
        RET 

;***********************************************************
;*  Stored Program Data
;***********************************************************



;***********************************************************
;*  Additional Program Includes
;***********************************************************

