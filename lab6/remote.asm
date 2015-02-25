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
.def    waitcnt = r17           ; Wait Loop Counter
.def    ilcnt = r18             ; Inner Loop Counter
.def    olcnt = r19             ; Outer Loop Counter

.equ    WTime = 100             ; Time to wait in wait loop

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

        ; Set Port D pin 3 (TXD1) for output
        ldi mpr, (1<<PD3)
        out DDRD, mpr

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

;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:

        rcall   ButtonMovFwd
        rcall   Wait
        rcall   Wait
        rcall   ButtonTurnR
        rcall   Wait

        rjmp    MAIN

;***********************************************************
;*  Functions and Subroutines
;***********************************************************

ButtonMovFwd:
        ldi     mpr, MovFwd
        sts     UDR1, mpr
        ret

ButtonMovBck:
        ldi     mpr, MovBck
        sts     UDR1, mpr
        ret

ButtonTurnR:
        ldi     mpr, TurnR
        sts     UDR1, mpr
        ret

ButtonTurnL:
        ldi     mpr, TurnL
        sts     UDR1, mpr
        ret

ButtonHalt:
        ldi     mpr, Halt
        sts     UDR1, mpr
        ret

;----------------------------------------------------------------
; Sub:  Wait
; Desc: A wait loop that is 16 + 159975*waitcnt cycles or roughly 
;       waitcnt*10ms.  Just initialize wait for the specific amount 
;       of time in 10ms intervals. Here is the general eqaution
;       for the number of clock cycles in the wait loop:
;           ((3 * ilcnt + 3) * olcnt + 3) * waitcnt + 13 + call
;----------------------------------------------------------------
Wait:
        ldi     waitcnt, WTime  ; Wait for 1 second

        push    waitcnt         ; Save wait register
        push    ilcnt           ; Save ilcnt register
        push    olcnt           ; Save olcnt register

Loop:   ldi     olcnt, 224      ; load olcnt register
OLoop:  ldi     ilcnt, 237      ; load ilcnt register
ILoop:  dec     ilcnt           ; decrement ilcnt
        brne    ILoop           ; Continue Inner Loop
        dec     olcnt       ; decrement olcnt
        brne    OLoop           ; Continue Outer Loop
        dec     waitcnt     ; Decrement wait 
        brne    Loop            ; Continue Wait loop    

        pop     olcnt       ; Restore olcnt register
        pop     ilcnt       ; Restore ilcnt register
        pop     waitcnt     ; Restore wait register
        ret             ; Return from subroutine

;***********************************************************
;*  Stored Program Data
;***********************************************************



;***********************************************************
;*  Additional Program Includes
;***********************************************************
