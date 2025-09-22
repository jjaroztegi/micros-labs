#include <msp430.h>

#define LED1 0x0001
#define LED2 0x0002
#define TMRCTLFAST 0x210
#define TMRCTLSLOW 0x250

volatile unsigned char myled = LED1;
volatile unsigned short mytmrctl = TMRCTLFAST;

void setup(void);

volatile unsigned char sw1_flag = 0;
volatile unsigned char sw2_flag = 0;

int main(void) {
  WDTCTL = WDTPW | WDTHOLD;  // Stop watchdog timer

  setup();

  while (1) {
    if (sw1_flag) {
      sw1_flag = 0;
      if (myled == LED1) {
        myled = LED2;
      } else {
        myled = LED1;
      }
      // Turn off both LEDs immediately
      P1OUT &= ~(0x03);
    } else if (sw2_flag) {
      sw2_flag = 0;
      // Toggle timer speed
      if (mytmrctl == TMRCTLFAST) {
        mytmrctl = TMRCTLSLOW;
      } else {
        mytmrctl = TMRCTLFAST;
      }
      // Apply new timer settings
      TA0CTL = mytmrctl;
    }
  }
}

void setup(void) {
  // P1.0 and P1.1 as outputs, start low
  P1DIR = P1DIR | 0x03;
  P1OUT = P1OUT & (~0x03);

  // P5.5 (SW2) and P5.6 (SW1) as inputs with pull-ups and interrupts
  P5DIR = P5DIR & (~0x60);
  P5REN = P5REN | (0x60);
  P5OUT = P5OUT | (0x60);
  P5IES = P5IES | (0x60);
  P5IFG = P5IFG & (~0x60);
  P5IE = P5IE | (0x60);

  PM5CTL0 = PM5CTL0 & (~LOCKLPM5);  // Disable high-impedance mode on GPIOs

  TA0CCR0 = 50000;
  TA0CTL = 0x0210;  // Timer_A0: SMCLK, up mode
  TA0CCTL0 = CCIE;  // Enable CCR0 interrupt

  __bis_SR_register(GIE + CPUOFF);  // Enable interrupts and enter LPM0
}

#pragma vector = TIMER0_A0_VECTOR
__interrupt void Timer_A(void) { P1OUT ^= myled; }

#pragma vector = PORT5_VECTOR
__interrupt void Port_5(void) {
  switch (P5IFG) {
    case 0x40:  // P5.6 (SW1)
      sw1_flag = 1;
      break;
    case 0x20:  // P5.5 (SW2)
      sw2_flag = 1;
      break;
  }
  P5IFG &= ~0x00ff;                   // Clear port interrupt flags
  __bic_SR_register_on_exit(CPUOFF);  // Wake CPU on ISR exit
}
