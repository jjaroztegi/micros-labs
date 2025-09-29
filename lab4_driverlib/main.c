#include <driverlib.h>
#include <msp430.h>
#define TIMER_PERIOD 9400 / 2

void setup_CLOCK(void);
void setup_GPIO(void);
void setup_TimerA(void);
void toggle_speed();
void toggle_led();

/* Timer A1 configured to blink LEDs with adjustable divider */
Timer_A_initUpModeParam TimerConfig = {
    TIMER_A_CLOCKSOURCE_ACLK,             // clockSource 9.4 kHz VLOCLK
    TIMER_A_CLOCKSOURCE_DIVIDER_1,        // clockSourceDivider
    TIMER_PERIOD,                         // timerPeriod = 9400/2
    TIMER_A_TAIE_INTERRUPT_ENABLE,        // timer interrupt
    TIMER_A_CCIE_CCR0_INTERRUPT_DISABLE,  // Capture/compare interrupt enable
    TIMER_A_DO_CLEAR                      // timer clear
};

int myLed = 1;
int mySpeed = 1;

int main(void) {
  WDT_A_hold(WDT_A_BASE);  // Stop watchdog timer

  setup_CLOCK();
  setup_GPIO();
  setup_TimerA();
  __bis_SR_register(GIE);  // Enable global interrupts
  return 0;
}

void setup_CLOCK(void) {
  // Fast FRAM access, DCO at ~8 MHz, route clocks
  FRAMCtl_A_configureWaitStateControl(FRAMCTL_A_ACCESS_TIME_CYCLES_0);
  CS_setDCOFreq(CS_DCORSEL_1, CS_DCOFSEL_4);
  CS_initClockSignal(CS_MCLK, CS_DCOCLK_SELECT, CS_CLOCK_DIVIDER_1);
  CS_initClockSignal(CS_SMCLK, CS_DCOCLK_SELECT, CS_CLOCK_DIVIDER_1);
  CS_initClockSignal(CS_ACLK, CS_VLOCLK_SELECT, CS_CLOCK_DIVIDER_1);
}

void setup_GPIO(void) {
  /* Set P1.0 as LED1 output */
  GPIO_setAsOutputPin(GPIO_PORT_P1, GPIO_PIN0);
  GPIO_setOutputLowOnPin(GPIO_PORT_P1, GPIO_PIN0);
  /* Set P1.1 as LED2 output */
  GPIO_setAsOutputPin(GPIO_PORT_P1, GPIO_PIN1);
  GPIO_setOutputLowOnPin(GPIO_PORT_P1, GPIO_PIN1);
  /* Configure P5.5 and P5.6 as inputs with pull-ups and interrupts */
  GPIO_setAsInputPinWithPullUpResistor(GPIO_PORT_P5, GPIO_PIN5);
  GPIO_setAsInputPinWithPullUpResistor(GPIO_PORT_P5, GPIO_PIN6);
  GPIO_selectInterruptEdge(GPIO_PORT_P5, GPIO_PIN5,
                           GPIO_HIGH_TO_LOW_TRANSITION);
  GPIO_clearInterrupt(GPIO_PORT_P5, GPIO_PIN5);
  GPIO_enableInterrupt(GPIO_PORT_P5, GPIO_PIN5);
  GPIO_selectInterruptEdge(GPIO_PORT_P5, GPIO_PIN6,
                           GPIO_HIGH_TO_LOW_TRANSITION);
  GPIO_clearInterrupt(GPIO_PORT_P5, GPIO_PIN6);
  GPIO_enableInterrupt(GPIO_PORT_P5, GPIO_PIN6);
  PMM_unlockLPM5();
}

void setup_TimerA(void) {
  // Start Timer A1 in up mode and enable overflow interrupt
  Timer_A_initUpMode(TIMER_A1_BASE, &TimerConfig);
  Timer_A_startCounter(TIMER_A1_BASE, TIMER_A_UP_MODE);
  Timer_A_enableInterrupt(TIMER_A1_BASE);
}

void toggle_speed() {
  if (mySpeed == 1) {
    mySpeed = 2;
    TimerConfig.clockSourceDivider = TIMER_A_CLOCKSOURCE_DIVIDER_2;
  } else {
    mySpeed = 1;
    TimerConfig.clockSourceDivider = TIMER_A_CLOCKSOURCE_DIVIDER_1;
  }
  Timer_A_initUpMode(TIMER_A1_BASE, &TimerConfig);
  Timer_A_startCounter(TIMER_A1_BASE, TIMER_A_UP_MODE);
}

void toggle_led() {
  if (myLed == 1) {
    myLed = 2;
    GPIO_setOutputLowOnPin(GPIO_PORT_P1, GPIO_PIN0);
    GPIO_setOutputHighOnPin(GPIO_PORT_P1, GPIO_PIN1);
  } else {
    myLed = 1;
    GPIO_setOutputLowOnPin(GPIO_PORT_P1, GPIO_PIN1);
    GPIO_setOutputHighOnPin(GPIO_PORT_P1, GPIO_PIN0);
  }
}

#pragma vector = TIMER1_A1_VECTOR
__interrupt void timer1_a1_isr_handler(void) {
  uint16_t status;
  status = Timer_A_getInterruptStatus(TIMER_A1_BASE);
  if (status == TIMER_A_INTERRUPT_PENDING) {
    Timer_A_clearTimerInterrupt(TIMER_A1_BASE);
    GPIO_toggleOutputOnPin(GPIO_PORT_P1, myLed);
  }
}

#pragma vector = PORT5_VECTOR
__interrupt void port_5_isr_handler(void) {
  uint16_t status;
  status = GPIO_getInterruptStatus(GPIO_PORT_P5, GPIO_PIN6 | GPIO_PIN5);
  if (status & GPIO_PIN6) {
    toggle_led();
  } else if (status & GPIO_PIN5) {
    toggle_speed();
  }
  P5IFG &= ~0xffff;  // Clear all interrupt flags
}
