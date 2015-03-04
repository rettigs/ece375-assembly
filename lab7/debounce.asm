;***********************************************************
;*
;*  debounce.asm
;*
;*  Contains the necessary functions to perform software 
;*  debouncing on the pushbutton switches attached to Port D.
;*
;***********************************************************
;*
;*   Author:    Taylor Johnson
;*     Date:    February 20th, 2015
;*
;***********************************************************

;***********************************************************
;*  Specifications
;***********************************************************
;   * Consective Data Memory locations DebounceQueue through DebounceResult are reserved
;   * Requires continuous use of Timer/Counter1
;   * Timer/Counter1 configured so raw Port D state is read every 2 milliseconds
;   * No registers are reserved or modified
;   * SREG is unchanged
;   * Debounced state of switches can be read from memory location DebounceResult
;***********************************************************
        
;***********************************************************
;*  Internal Constants
;***********************************************************
        ; OK to modify
.equ    DebounceQueue = $0120       ; starting memory location of queue
.equ    DebounceQueueSize = 16      ; size in bytes, expandable up to 63 bytes (for now)

        ; DO NOT MODIFY             ; 4-byte fixed storage after queue
.equ    DebounceVars    = DebounceQueue + DebounceQueueSize
.equ    DebounceResult  = DebounceVars + 3  ; debounced state saved here

        ; unofficial register definitions
        ; r16 = multipurpose
        ; r17 = OR result of all

;***********************************************************
;*  Functions and Subroutines
;***********************************************************
;----------------------------------------------------------------
; Sub:  DEBOUNCE_INIT
; Desc: Initializes the Data Memory locations that are used to
;       perform software debouncing of the pushbutton switches on
;       Port D, and initializes the 16-bit Timer/Counter1 (TCNT1)
;       to overflow (and generate the corresponding overflow
;       interrupt) every 2 milliseconds.
;       
;       This subroutine requires no parameters, returns no values,
;       and modifies none of the general-purpose registers nor the 
;       status register SREG.
;       
;----------------------------------------------------------------
DEBOUNCE_INIT:
        push    r16                 ; save r16
        in      r16, SREG           ; save SREG
        push    r16
        push    r17                 ; save r17
        push    XL                  ; save X pointer
        push    XH
         
        ldi     XL, low(DebounceQueue) ; start X at lowest address of circular queue
        ldi     XH, high(DebounceQueue)

        ldi     r16, $FF            ; default contents of all queue locations

        ldi     r17, DebounceQueueSize ; initialize loop variable


DEBOUNCE_INIT_LOOP:                 ; for each queue memory location
        st      X+, r16             ; store default value of $FF
        dec     r17
        brne    DEBOUNCE_INIT_LOOP

        sbiw    X, DebounceQueueSize ; return X to beginning queue location

        sts     DebounceVars, XL    ; save initial queue pointer
        sts     DebounceVars+1, XH
        sts     DebounceVars+2, r16 ; initialize last state memory location
        sts     DebounceVars+3, r16 ; initialize switch state memory location

        ldi     r16, (1<<CS10)      ; configure Timer/Counter 1
        out     TCCR1B, r16         ; with 1 prescalar value

        ldi     r16, (1<<TOIE1)     ; enable Timer/Counter 1
        out     TIMSK, r16          ; overflow interrupt

        ldi     r16, high(49535)    ; write high byte of VALUE
        out     TCNT1H, r16         ; to the high byte of TCNT1
        ldi     r16, low(49535)     ; next, write the low byte
        out     TCNT1L, r16         ; MUST be done in this order

        pop     XH                  ; restore registers
        pop     XL
        pop     r17
        pop     r16
        out     SREG, r16
        pop     r16

        ret

;----------------------------------------------------------------
; Sub:  DEBOUNCE_D (ISR)
;
; Note: Do not call this subroutine directly from the MAIN portion
;       of your program. Instead, place a subroutine call at the
;       interrupt vector for Timer1 OVF.
;
; Desc: Reads the raw state of Port D via the PIND register, and 
;       compares it against several previous raw states of Port D
;       saved in a circular queue in Data Memory, updating the 
;       "debounced state" byte whenever a persistent raw state is
;       seen several times in a row.
;
;       This subroutine returns one value, the debounced current
;       state of Port D, via the memorylocation DebounceResult;
;       it requires no parameters, and modifies none of the
;       general-purpose registers nor the status register SREG.
;       
;       When any pin on Port D has been '0' for DebounceQueueSize
;       consecutive instances of this subroutine, the corresponding
;       bit in the debouced state is also set to '0'.
;
;       The bit in the debounced state will stay at '0' until it is seen
;       as a '1' again in the raw state, which could be another several
;       milliseconds. Therefore, if you would like to perform "falling
;       edge debouncing" (i.e., the code in which you are using this
;       debounce function is only supposed to act ONCE PER 1->0 DEBOUNCED
;       TRANSITION), then after your code "triggers" on the falling edge,
;       you MUST manually reset that bit back to '1' in the debounced state.
;       
;----------------------------------------------------------------
DEBOUNCE_D:
        push    r16                 ; save registers
        in      r16, SREG           
        push    r16
        push    r17
        push    r18
        push    r19
        push    XL
        push    XH
        push    YL
        push    YH

        in      r16, PIND           ; read current raw state of PIND
        lds     XL, DebounceVars    ; retrieve saved X pointer, which contains the
        lds     XH, DebounceVars+1  ; address of the tail of the queue
        st      X+, r16             ; store newest raw state into tail of circular queue
        ldi     r17, $00            ; initial state value
        ldi     YL, low(DebounceQueue) ; initialize Y pointer to lowest queue address
        ldi     YH, high(DebounceQueue)

DEBOUNCE_LOOP:
        ld      r16, Y+             ; in loop, read each byte from circular queue
        or      r17, r16            ; logical OR all bytes of queue together
        ldi     r16, low(DebounceVars-1)    
        cp      r16, YL                     ; check to see if Y pointer has
        ldi     r16, high(DebounceVars-1)   ; moved past highest queue address
        cpc     r16, YH
        brcc    DEBOUNCE_LOOP       ; if not, still data in queue, so keep looping

        lds     r18, DebounceVars+2 ; load previous debounced state
        eor     r18, r17            ; compare against newest ORing of queue
        breq    DEBOUNCE_UNCHANGED  ; branch if no change

        lds     r19, DebounceVars+3 ; otherwise, load official debounced state from mem
        and     r19, r17            ; update official debounced state
        sts     DebounceVars+3, r19 ; save official debounced state back to memory
DEBOUNCE_UNCHANGED:
        sts     DebounceVars+2, r17 ; save newest state into memory
        ldi     r16, low(DebounceVars-1)    
        cp      r16, XL                     ; check to see if X pointer has
        ldi     r16, high(DebounceVars-1)   ; moved past highest queue address
        cpc     r16, XH
        brcc    DEBOUNCE_EXIT               ; if not, leave X as is and exit

        sbiw    X, DebounceQueueSize        ; if so, wrap X back to lowest queue address
DEBOUNCE_EXIT:
        sts     DebounceVars, XL    ; save new queue tail address
        sts     DebounceVars+1, XH
        ldi     r16, high(49535)    ; reset TCNT1 so that it overflows
        out     TCNT1H, r16         ; in another 2 milliseconds
        ldi     r16, low(49535)     
        out     TCNT1L, r16         ; MUST be done in this order (H then L)

        pop     YH                  ; restore registers
        pop     YL
        pop     XH
        pop     XL
        pop     r19
        pop     r18
        pop     r17
        pop     r16
        out     SREG, r16
        pop     r16

        ret                         ; leave
