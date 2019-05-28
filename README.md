# AVRtoS

AVR - Arduino Realtime operating system. With preemptive realtime scheduler written in assembler. Optimized for performance. Maximal utilization of onboard EEPROM, SRAM, FLASH.

Support for Realtime system clock,  4x4 keyboard, LCD driver, stepper motor driver, ADC and UART Serial driver. Uses a realtime interrupt scheduler (time slice-ing) for implementing non blocking drivers that pool slow devices and gave away CPU to main program, in case previous operation is not yet completed. 

Originally written as a port of Motorola's 68HC11 learning operating system, designed at University of Ljubljana (prof. Tadej Tuma).
Main purpose is learning the ATMEGA 328PU internals and to get glimpse into realtime kernel design.

Project includes some important concepts as a separete modules, in order to demonstrate only one topic.

![AVROS AVR Arduino real-time operating system](https://docs.google.com/drawings/d/e/2PACX-1vQEklykQxAZ16jxRNPSTgDQtxXqDBD045pV0PqP9_qf-mK30fVFLbMAqmDiIDicrVByWo7ejt2p0I_c/pub?w=832&h=621)

# Deploy with avrdude.exe

Adapt -PCOM port and -b baudrate to suite your needs. COM port is assigned by system, baudrate by bootloader.
Main file is `avrosmain.asm`

```
c:\Program Files (x86)\Arduino\hardware\tools\avr\bin\avrdude.exe -C "C:\Program Files (x86)\Arduino\hardware\tools\avr\etc\avrdude.conf" -v -patmega328p -carduino -PCOM8 -b115200 -D -Uflash:w:$(TargetDir)$(TargetName).hex:i 
```

Include EEPROM data (if any)
```
-Ueeprom:w:$(TargetDir)$(TargetName).eep:i
```
