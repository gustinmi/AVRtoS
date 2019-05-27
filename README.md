# AVRtoS

AVR - Arduino Realtime operating system. With preemptive realtime scheduler written in assembler. Optimized for performance.

Support for Realtime system clock,  4x4 keyboard, LCD driver, stepper motor driver, ADC and UART Serial driver. Uses a realtime interrupt scheduler (time slice-ing) for implementing non blocking drivers that pool slow devices and gave away CPU to main program, in case previous operation is not yet completed. 

Originally written as a port of Motorola's 68HC11 learning operating system, designed at University of Ljubljana (prof. Tadej Tuma).
Main purpose is learning the ATMEGA 328PU internals and to get glimpse into realtime kernel design.

Project includes some important concepts as a separete modules, in order to demonstrate only one topic.
