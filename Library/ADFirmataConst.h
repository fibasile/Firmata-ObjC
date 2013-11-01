//
//  ADFirmataConst.h
//  Firmata-ObjC
//
//  Created by fiore on 28/10/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#ifndef Firmata_ObjC_ADFirmataConst_h
#define Firmata_ObjC_ADFirmataConst_h


#define DEFAULT_SERIAL @"/dev/tty.usbserial-A8004J3F"
#define DEFAULT_BAUDRATE 57600
#define DEFAULT_TIMEOUT 2

// Enable this define for debug output

//#define DEBUG_FIRMATA


// Message command bytes - straight outta Pd_firmware.pde
#define DIGITAL_MESSAGE 0x90 //# send data for a digital pin
#define ANALOG_MESSAGE 0xE0 // # send data for an analog pin (or PWM)

#define PULSE_MESSAGE  0xA0 // # proposed pulseIn/Out message (SysEx)
#define SHIFTOUT_MESSAGE  0xB0 // # proposed shiftOut message (SysEx)


#define START_SYSEX             0xF0 // start a MIDI SysEx message
#define END_SYSEX               0xF7 // end a MIDI SysEx message
#define PIN_MODE_QUERY          0x72 // ask for current and supported pin modes
#define PIN_MODE_RESPONSE       0x73 // reply with current and supported pin modes
#define PIN_STATE_QUERY         0x6D
#define PIN_STATE_RESPONSE      0x6E
#define CAPABILITY_QUERY        0x6B
#define CAPABILITY_RESPONSE     0x6C
#define ANALOG_MAPPING_QUERY    0x69
#define ANALOG_MAPPING_RESPONSE 0x6A
#define REPORT_FIRMWARE         0x79 // report name and version of the firmware
#define SYSTEM_RESET  0xFF //# reset from MIDI

#define ANALOG_MESSAGE          0xE0
#define DIGITAL_MESSAGE         0x90
#define REPORT_ANALOG_PIN       0xC0
#define REPORT_DIGITAL_PORT     0xD0
#define SET_PIN_MODE            0xF4
#define PROTOCOL_VERSION        0xF9
#define SYSTEM_RESET            0xFF

// Pin modes
#define UNAVAILABLE     -1
#define MODE_INPUT    0x00
#define MODE_OUTPUT   0x01
#define MODE_ANALOG   0x02
#define MODE_PWM      0x03
#define MODE_SERVO    0x04
#define MODE_SHIFT    0x05
#define MODE_I2C      0x06

#define IS_PWM_PIN(x)  (x == 9 || x == 10 || x == 11 )

#define ANALOG_PIN_COUNT 6
#define DIGITAL_PORTS_COUNT 2 
#define DIGITAL_PIN_COUNT 8

#endif
