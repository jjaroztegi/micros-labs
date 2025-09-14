;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
; Lab1: LED blinking
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file
            
;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.
;-------------------------------------------------------------------------------
            .text                           ; Assemble into program memory.
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section.
            .retainrefs                     ; And retain any sections that have
                                            ; references to current section.

;-------------------------------------------------------------------------------
; Program Initialization
;-------------------------------------------------------------------------------
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer

;--- Port P1.0 Configuration ---
            bis.b   #0x01, &P1DIR           ; Set P1.0 to output direction
            bic.b   #0x01, &P1OUT           ; Clear P1.0 output (start LED off)
            bic.w   #LOCKLPM5, &PM5CTL0     ; Disable high-impedance mode for GPIOs

;-------------------------------------------------------------------------------
; Main Application
;-------------------------------------------------------------------------------
Mainloop    xor.b   #0x01, &P1OUT           ; Toggle the state of the LED (P1.0)
            call    #LongWait               ; Call the delay subroutine
            jmp     Mainloop                ; Repeat indefinitely

;-------------------------------------------------------------------------------
; Subroutines
;-------------------------------------------------------------------------------

; Creates a delay of 150ms.
Wait        mov.w   #50000, R15             ; Load counter value into R15
L1          dec.w   R15                     ; Decrement counter
            jnz     L1                      ; Loop until R15 is zero
            ret                             ; Return

; Creates a longer delay using two registers (R14, R15).
LongWait    mov.w   #10, R14                ; Initialize outer loop counter (R14)
L2          mov.w   #50000, R15             ; Initialize inner loop counter (R15)
L3          dec.w   R15                     ; Decrement inner counter
            jnz     L3                      ; Repeat inner loop until R15 is zero
            dec.w   R14                     ; Decrement outer counter
            jnz     L2                      ; Repeat outer loop until R14 is zero
            ret                             ; Return

;-------------------------------------------------------------------------------
; Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect   .stack
            
;-------------------------------------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET
