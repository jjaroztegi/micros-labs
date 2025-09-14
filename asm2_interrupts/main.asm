;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
; Lab2: Using interrupts
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

;--- General Purpose Register Initialization ---
            mov.w   #0x01, R15              ; R15: LED control. 0x01=LED1 (P1.0), 0x02=LED2 (P1.1). Default: LED1
            mov.w   #0x0210, R14            ; R14: Timer config. Default: UpMode, SMCLK, DIV_1
            clr.w   R13                     ; R13: Switch flag. 0=None, 1=SW1, 2=SW2

;--- Port 1 Configuration (LEDs) ---
            bis.b   #0x01, &P1DIR           ; Set P1.0 (LED1) to output
            bic.b   #0x01, &P1OUT           ; Clear P1.0 output
            bis.b   #0x02, &P1DIR           ; Set P1.1 (LED2) to output
            bic.b   #0x02, &P1OUT           ; Clear P1.1 output

;--- Port 5 Configuration (Switches) ---
            ; SW1 (P5.6)
            bic.b   #0x40, &P5DIR           ; Set P5.6 as input
            bis.b   #0x40, &P5REN           ; Enable pull-up/pull-down resistor on P5.6
            bis.b   #0x40, &P5OUT           ; Select pull-up resistor
            bis.b   #0x40, &P5IES           ; Interrupt on high-to-low edge
            bic.b   #0x40, &P5IFG           ; Clear P5.6 interrupt flag
            bis.b   #0x40, &P5IE            ; Enable interrupt for P5.6
            ; SW2 (P5.5)
            bic.b   #0x20, &P5DIR           ; Set P5.5 as input
            bis.b   #0x20, &P5REN           ; Enable pull-up/pull-down resistor on P5.5
            bis.b   #0x20, &P5OUT           ; Select pull-up resistor
            bis.b   #0x20, &P5IES           ; Interrupt on high-to-low edge
            bic.b   #0x20, &P5IFG           ; Clear P5.5 interrupt flag
            bis.b   #0x20, &P5IE            ; Enable interrupt for P5.5

            bic.w   #LOCKLPM5, &PM5CTL0     ; Disable high-impedance mode for GPIOs

;--- Timer A0 Configuration ---
            mov.w   #50000, &TA0CCR0        ; Set timer period (50000 cycles)
            mov.w   R14, &TA0CTL            ; Configure timer: UpMode, SMCLK, DIV_1
            bis.w   #CCIE, &TA0CCTL0        ; Enable Capture/Compare interrupt for CCR0

;-------------------------------------------------------------------------------
; Main Application
;-------------------------------------------------------------------------------
Mainloop    nop                             ; satisfies W0005 compiler warning
            bis.w   #GIE+CPUOFF, SR         ; Enter LPM0, enable global interrupts
            nop                             ; For debugger stability after waking up

;--- Check which switch was pressed (if any) ---
CheckFlagSW1
            cmp.w   #1, R13                 ; Check if SW1 was pressed
            jnz     CheckFlagSW2            ; If not, check SW2
            call    #ToggleLed              ; If yes, toggle the active LED
            mov.w   #0, &P1OUT              ; Turn off both LEDs
            call    #Debounce               ; Wait for switch to stabilize
            clr.w   R13                     ; Clear the switch flag
CheckFlagSW2
            cmp.w   #2, R13                 ; Check if SW2 was pressed
            jnz     Mainloop                ; If not, go back to sleep
            call    #ToggleCount            ; If yes, change the timer frequency
            mov.w   R14, &TA0CTL            ; Apply the new timer configuration
            call    #Debounce               ; Wait for switch to stabilize
            clr.w   R13                     ; Clear the switch flag
            jmp     Mainloop                ; Go back to sleep

;-------------------------------------------------------------------------------
; Subroutines
;-------------------------------------------------------------------------------
; Toggles which LED is blinking (R15)
ToggleLed
            cmp.w   #0x01, R15              ; Is R15 set for LED1?
            jnz     SetLED1                 ; If not, it must be LED2, so set to LED1
SetLED2     mov.w   #0x02, R15              ; Set R15 to blink LED2
            ret
SetLED1     mov.w   #0x01, R15              ; Set R15 to blink LED1
            ret

; Toggles the timer frequency (R14)
ToggleCount
            cmp.w   #0x0210, R14            ; Is timer set to fast speed?
            jnz     SetFast                 ; If not, it must be slow, so set to fast
SetSlow     mov.w   #0x0250, R14            ; Set timer to slow (SMCLK/2)
            ret
SetFast     mov.w   #0x0210, R14            ; Set timer to fast (SMCLK/1)
            ret

; Simple delay to debounce mechanical switches
Debounce
            mov.w   #5, R11
            mov.w   #50000, R10
L_Debounce  dec.w   R10
            jnz     L_Debounce
            dec.w   R11
            jnz     Debounce
            ret

;-------------------------------------------------------------------------------
; Interrupt Service Routines (ISRs)
;-------------------------------------------------------------------------------
; --- Timer A0 ISR ---
; Triggered when TA0R reaches TA0CCR0. Toggles the LED indicated by R15.
TIMER0_A0_ISR
            xor.b   R15, &P1OUT             ; Toggle the currently selected LED
            reti                            ; Return from interrupt

; --- Port 5 ISR ---
; Triggered by a button press on P5.5 or P5.6.
P5_ISR
            bit.b   #0x40, &P5IFG           ; Check if SW1 (P5.6) caused the interrupt
            jz      CheckSW2                ; If not, check SW2
            mov.w   #1, R13                 ; Set flag for SW1
            bic.b   #0x40, &P5IFG           ; Clear SW1 interrupt flag
            jmp     Exit_P5_ISR
CheckSW2
            mov.w   #2, R13                 ; Set flag for SW2
            bic.b   #0x20, &P5IFG           ; Clear SW2 interrupt flag
Exit_P5_ISR
            bic.w   #CPUOFF, 0(SP)          ; Wake up CPU from LPM0
            reti                            ; Return from interrupt

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

            .sect   TIMER0_A0_VECTOR        ; Timer0_A0 Vector
            .short  TIMER0_A0_ISR

            .sect   PORT5_VECTOR            ; Port 5 Vector
            .short  P5_ISR
