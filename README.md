# Microprocessors and Microcontrollers Labs (MSP-EXP430FR5994)

This repository contains the laboratory assignments for the "Microprocesadores y Microcontroladores" course, developed for the **Texas Instruments MSP-EXP430FR5994 LaunchPad**.

The labs progress from low-level assembly programming to higher-level C, demonstrating fundamental concepts of embedded systems. The projects cover direct register manipulation, interrupt handling, and the use of Texas Instruments' Driver Library (DriverLib) to interface with on-board and external peripherals.

## Labs Overview

The repository is structured by lab, with each folder containing a standalone Code Composer Studio project.

### Assembly

- **`asm1_led`**: Introduces the MSP430 assembly language and toolchain.

  - **Objective**: Configure a GPIO pin as an output to blink an LED.
  - **Key Concepts**: Basic assembly syntax, watchdog timer, GPIO configuration, and software delay loops (busy-waiting).

- **`asm2_interrupts`**: Expands on Lab 1 by introducing event-driven programming.
  - **Objective**: Use timer and GPIO interrupts to control LED blinking frequency and selection without halting the CPU in a delay loop.
  - **Key Concepts**: Timer_A configuration, interrupt service routines (ISRs), GPIO interrupts for button handling, and low-power modes (LPM).

### C

- **`msp430-c-int-sw-led`**: Re-implements the functionality of Lab 2 using the C programming language.

  - **Objective**: Control LEDs with timer and switch interrupts by manipulating peripheral registers directly in C.
  - **Key Concepts**: C syntax for embedded systems, pointer-based register access, defining ISRs with `#pragma`, and bitwise operations.

- **`lab4_driverlib`**: Introduces a higher level of abstraction using the TI Driver Library.

  - **Objective**: Recreate the interrupt-driven application from Lab 3 using the DriverLib API, moving away from direct register manipulation.
  - **Key Concepts**: Software Development Kits (SDKs), Hardware Abstraction Layers (HAL), using API functions for clocks, GPIO, and timers.

- **`lab5_msp430fr5994_edumkii_uart`**: Integrates multiple peripherals on the **Educational BoosterPack MKII (EDUMKII)**.
  - **Objective**: Write a full-featured application that uses drivers for the LCD, buttons, joystick, light sensor, accelerometer, and more, communicating status via UART.
  - **Key Concepts**: HAL/Driver architecture, SPI and I2C communication protocols, ADC for analog sensors, PWM for audio/visual feedback, and creating a Command Line Interface (CLI) over UART.

## Hardware and Software Requirements

### Hardware

- Texas Instruments **MSP-EXP430FR5994 LaunchPad**
- Educational BoosterPack MKII (for Lab 5)
- Micro-USB Cable

### Software

- **Texas Instruments Code Composer Studio (CCS)**
- **TI MSP430 DriverLib** (included in projects where needed)

## Getting Started

1.  **Clone the repository:**

    ```sh
    git clone https://github.com/jjaroztegi/micros-labs.git
    ```

2.  **Open Code Composer Studio.**

3.  **Import a project:**

    - Navigate to `Project` -> `Import CCS Projects...`.
    - Browse to the directory of the lab you wish to run (e.g., `asm1_led`).
    - Ensure the project is selected and click `Finish`.

4.  **Build and Debug:**
    - Connect your MSP430 LaunchPad to your computer.
    - Click the **Build** icon (hammer) to compile the project.
    - Click the **Debug** icon (bug) to flash the program to the microcontroller and start a debug session.
    - Click **Run** to execute the code.

## Repository Structure

```
.
├── asm1_led/                           # Lab 1: Simple LED blink with delay
│   └── main.asm
├── asm2_interrupts/                    # Lab 2: Timer and GPIO interrupts
│   └── main.asm
├── msp430-c-int-sw-led/                # Lab 3: Lab 2 rewritten in C
│   └── main.c
├── lab4_driverlib/                     # Lab 4: Lab 3 rewritten using DriverLib
│   └── main.c
└── lab5_msp430fr5994_edumkii_uart/     # Lab 5: Full app with EDUMKII BoosterPack
    ├── main.c
    ├── drivers/
    └── hal/
```
