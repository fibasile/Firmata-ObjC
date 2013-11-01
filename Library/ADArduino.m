//
//  ADArduino.m
//  Firmata-ObjC
//
//  Created by fiore on 28/10/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#import "ADArduino.h"
#import "ADFirmataConst.h"
#import "ADArduinoPin.h"



@interface ADArduino (Private)



-(void)setupPins;

@end


@implementation ADArduino

- (id)initWithSerial:(__autoreleasing id<ADSerialPort>)aSerialPort
{
    self = [super init];
    if (self) {
        self.serialPort = aSerialPort;
        self.analogPins = [NSMutableArray array];
        self.digitalPins = [NSMutableArray array];
//        self.digitalPorts = [NSArray array];
        self.connected = NO;
        // private vars
        self.waitForData = 0;
        self.executeMultiByteCommand = 0;
        self.multiByteChannel = 0;
        self.parsingSysEx = NO;
        self.sysexBytesRead = 0;
        self.receivedBuffer = [NSMutableData dataWithCapacity:128];
        self.hasAnalogMapping=NO;
        self.hasCapabilities=NO;
        
        for (int i=0;i<128;i++){
            pin_info[i].supported_modes=0;
            pin_info[i].analog_channel=127;
            pin_info[i].value=0;
            pin_info[i].mode=255;
        }

    }
    return self;
}

#pragma mark private methods
- (void) setupPins {
    /*
    NSMutableArray* pins = [NSMutableArray array];
    for (int i=0; i<ANALOG_PIN_COUNT;i++){
        ADAnalogPin* pin = [[ADAnalogPin alloc] initWithNumber:i];
        pin.delegate = self;
        [pins addObject:pin];
    }
    self.analogPins = [NSArray arrayWithArray:pins];
    [pins removeAllObjects];
    for (int i=0; i<DIGITAL_PORTS_COUNT;i++){
        ADDigitalPort* port = [[ADDigitalPort alloc] initWithNumber:i];
        port.delegate = self;
        [pins addObject:port];
    }
    self.digitalPorts = [NSArray arrayWithArray:pins];
    */
}




- (void) startLoop {
//    self.loopTimer = [NSTimer scheduledTimerWithTimeInterval:1/60 target:self selector:@selector(readLoop) userInfo:nil repeats:YES];
    self.bgThread = [[NSThread alloc] initWithTarget:self selector:@selector(readLoop:) object:self];
    [self.bgThread start];
}


#pragma mark public methods
- (void) connectWithBlock:(void (^)())initBlock {
    double delayInSeconds = 2.0;
    self.connectBlock = initBlock;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self startLoop];
        [self queryVersion];
    });
}

#pragma mark listening thread
- (void) readLoop:(ADArduino*)sender {
    while (![[NSThread currentThread] isCancelled]) {
        if ([[sender serialPort] available]) {
            UInt8 byte = [[sender serialPort] read];
//            NSLog(@"Received %02x", byte);
            dispatch_async(dispatch_get_main_queue(), ^{
                [sender parseResponse:byte];
            });
        } else {
            [NSThread sleepForTimeInterval:1/60];
        }
    }
}



#pragma mark message parsing

- (void) parseResponse:(UInt8)byte {
    UInt8 command;
    
    if (!self.parsingSysEx) {
        
        // waiting for data and byte is data
        if (self.waitForData && byte < 128){
            self.waitForData--;
            [self.receivedBuffer appendBytes:&byte length:1];

            if (self.executeMultiByteCommand != 0 && self.waitForData == 0) {
                uint8_t params[2];
                [self.receivedBuffer getBytes:&params length:2];
//                NSLog(@"%02x",self.executeMultiByteCommand);
                int analogVal=0;
                switch(self.executeMultiByteCommand) {
                    case DIGITAL_MESSAGE:
//                        NSLog(@"Digital message");
                        [self updateDigitalPortValue:self.multiByteChannel mask:params[0] | (params[1] << 7)   ];
                        break;
                    case ANALOG_MESSAGE:
                        analogVal=params[0] | (params[1] << 7);
                        [self updateAnalogPinValue:self.multiByteChannel mask:analogVal];
                        break;
                    case REPORT_FIRMWARE:
                        
                        self.firmataVersion = [NSString stringWithFormat:@"%d.%d", params[0], params[1]];
                        break;
                    case PROTOCOL_VERSION:
#ifdef DEBUG_FIRMATA
                        NSLog(@"Protocol version %d.%d", params[0], params[1]);
#endif
                        break;
                
                }
            }
        } else {
            // read the command + channel if any
            if(byte < 0xF0) {
                command = byte & 0xF0;
                self.multiByteChannel = byte & 0x0F;
            } else {
                command = byte;
                // commands in the 0xF* range don't use channel data
            }
            switch (command) {
                case DIGITAL_MESSAGE:
                case ANALOG_MESSAGE:
                case REPORT_FIRMWARE:
                case PROTOCOL_VERSION:
                    self.waitForData = 2;
                    self.executeMultiByteCommand = command;
                    self.receivedBuffer = [NSMutableData data];
                    break;
                case START_SYSEX:
                    self.parsingSysEx = YES;
                    self.sysexBytesRead = 0;
                    self.receivedBuffer = [NSMutableData data];
                    break;
                default:
#ifdef DEBUG_FIRMATA
                    NSLog(@"Unkown command %02x", command);
#endif
                    break;
            }
        }
        
        
    } else {
        if (byte == END_SYSEX) {
            // end system message
            
            self.parsingSysEx = NO;
            [self parseSystemMessage];
        } else {
            // fill system message buffer
            
            [self.receivedBuffer appendBytes:&byte length:1];
            self.sysexBytesRead++;
        }
        
    }

    
}





- (void) queryPins {
    /*
    for (int i=0; i<self.analogPins.count;i++){
        [[self.analogPins objectAtIndex:i] toggleActive:YES];
    }
     */
}
#pragma mark system messages handling


/* Generic Sysex Message
 * 0     START_SYSEX (0xF0)
 * 1     sysex command (0x00-0x7F)
 * x     between 0 and MAX_DATA_BYTES 7-bit bytes of arbitrary data
 * last  END_SYSEX (0xF7)
 */
- (void) parseSystemMessage {
    
    // do something with the message
    
    UInt8 firstByte;
    [self.receivedBuffer getBytes:&firstByte length:1];
    
    
    if (firstByte == REPORT_FIRMWARE) {
        
        [self parseSysexReportFirmware];
        
    } else if (firstByte == CAPABILITY_RESPONSE) {
        
        [self parseSysexCapabilityResponse];
        
    } else if (firstByte == ANALOG_MAPPING_RESPONSE) {
        
        [self parseSysexAnalogMappingResponse];
        
    } else if (firstByte == PIN_STATE_RESPONSE) {
        
        [self parseSysexPinStateResponse];
        
    } else {
        NSLog(@"Unknown Sysex message %@", self.receivedBuffer);
        
    }
    
    
    self.receivedBuffer = [NSMutableData data];
    self.sysexBytesRead = 0;
    
}




/* Query Firmware Name and Version
 * 0  START_SYSEX (0xF0)
 * 1  queryFirmware (0x79)
 * 2  END_SYSEX (0xF7)
 */
- (void) queryVersion {
    UInt8 pkt[3] = { START_SYSEX, REPORT_FIRMWARE, END_SYSEX };
    NSData* data = [NSData dataWithBytes:&pkt length:3];
    [self.serialPort write:data];
}


/* Receive Firmware Name and Version (after query)
 * 0  START_SYSEX (0xF0)
 * 1  queryFirmware (0x79)
 * 2  major version (0-127)
 * 3  minor version (0-127)
 * 4  first 7-bits of firmware name
 * 5  second 7-bits of firmware name
 * x  ...for as many bytes as it needs)
 * 6  END_SYSEX (0xF7)
 */
- (void) parseSysexReportFirmware {
#ifdef DEBUG_FIRMATA
    NSLog(@"parseSysexReportFirmware");
#endif
    if (self.receivedBuffer.length >= 3){
        UInt8 params[3];
        [self.receivedBuffer getBytes:&params length:3];
        self.firmataVersion = [NSString stringWithFormat:@"%c.%c", params[1] + '0', params[2] + '0'];
        unsigned long remaining = self.receivedBuffer.length-3;
        char name[140];
        char nameLen = 0;
        UInt8* firmwareNameBytes = malloc(sizeof(UInt8)*remaining);
        [self.receivedBuffer getBytes:firmwareNameBytes length:remaining];
        for (int i=0; i< remaining;i+=2){
            name[nameLen]= (firmwareNameBytes[i]&0x7F)  | ((firmwareNameBytes[i+1] &0x7F) << 7);
        }
        self.firmataVersionString = [[NSString alloc] initWithBytes:&name length:nameLen encoding:NSASCIIStringEncoding];
        free(firmwareNameBytes);
        
        if (!self.hasAnalogMapping) {
            [self queryAnalogMapping];
        }
    } else {
        NSLog(@"Invalid version string");
    }
    
}

/* capabilities query
 * -------------------------------
 * 0  START_SYSEX (0xF0) (MIDI System Exclusive)
 * 1  capabilities query (0x6B)
 * 2  END_SYSEX (0xF7) (MIDI End of SysEx - EOX)
 */
- (void) queryCapabilities {
    UInt8 pkt[3] = { START_SYSEX, CAPABILITY_QUERY, END_SYSEX };
    NSData* data = [NSData dataWithBytes:&pkt length:3];
    [self.serialPort write:data];
    
    for (int i=0; i<16; i++) {
        UInt8 pkt[4] = { REPORT_ANALOG_PIN | i, 1,REPORT_DIGITAL_PORT | i,1 };
        NSData* data = [NSData dataWithBytes:&pkt length:4];
        [self.serialPort write:data];
    }
}



/* capabilities response
 * -------------------------------
 * 0  START_SYSEX (0xF0) (MIDI System Exclusive)
 * 1  capabilities response (0x6C)
 * 2  1st mode supported of pin 0
 * 3  1st mode's resolution of pin 0
 * 4  2nd mode supported of pin 0
 * 5  2nd mode's resolution of pin 0
 ...   additional modes/resolutions, followed by a single 127 to mark the
 end of the first pin's modes.  Each pin follows with its mode and
 127, until all pins implemented.
 * N  END_SYSEX (0xF7)
 */
- (void) parseSysexCapabilityResponse {
    if (self.hasCapabilities)
        return;
    self.hasCapabilities = YES;
#ifdef DEBUG_FIRMATA
    NSLog(@"Capabilities %@", self.receivedBuffer);
#endif
    UInt8* receivedBytes;
    unsigned long receivedLength =self.receivedBuffer.length;
    receivedBytes = malloc(sizeof(UInt8)*receivedLength);
    [self.receivedBuffer getBytes:receivedBytes length:receivedLength];
    
    for (int i=0;i<128;i++){
        pin_info[i].supported_modes=0;
    }
    
    int pin=0;
    int i=1;
    int n=0;
    for (; i<receivedLength; i++) {
        if (receivedBytes[i] == 127) {
            pin++;
            n = 0;
            continue;
        }
        if (n == 0) {
            // first byte is supported mode
            pin_info[pin].supported_modes |= (1<<receivedBytes[i]);
        }
        n = n ^ 1;
    }
    for (int j=0;j<pin;j++){
        [self queryPinState:j];
    }
    
    
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (!self.connected) {
            self.connected = YES;
            self.connectBlock();
        }
    });
    

    
    free(receivedBytes);

}

- (void)queryAnalogMapping {
    UInt8 pkt[3] = { START_SYSEX, ANALOG_MAPPING_QUERY, END_SYSEX };
    NSData* data = [NSData dataWithBytes:&pkt length:3];
    [self.serialPort write:data];
    
}


/* analog mapping response
 * -------------------------------
 * 0  START_SYSEX (0xF0) (MIDI System Exclusive)
 * 1  analog mapping response (0x6A)
 * 2  analog channel corresponding to pin 0, or 127 if pin 0 does not support analog
 * 3  analog channel corresponding to pin 1, or 127 if pin 1 does not support analog
 * 4  analog channel corresponding to pin 2, or 127 if pin 2 does not support analog
 ...   etc, one byte for each pin
 * N  END_SYSEX (0xF7)
 */
- (void) parseSysexAnalogMappingResponse {
#ifdef DEBUG_FIRMATA
    NSLog(@"Analog mapping received");
#endif
    if (self.hasAnalogMapping) return;
    self.hasAnalogMapping = YES;
    
    
    UInt8* receivedBytes;
    unsigned long receivedLength =self.receivedBuffer.length;
    receivedBytes = malloc(sizeof(UInt8)*receivedLength);
    [self.receivedBuffer getBytes:receivedBytes length:receivedLength];
    
    
    int pin=0;
    for (int i=1; i<receivedLength; i++) {
        pin_info[pin].analog_channel = (uint8_t) receivedBytes[i];
#ifdef DEBUG_FIRMATA
        NSLog(@"Received %d -> %d",  receivedBytes[i], pin);
#endif
        pin++;
    }
    

    

    
    free(receivedBytes);
    
    [self queryCapabilities];
    
}


- (void) queryPinState:(int)pin {
    UInt8 pkt[4] = { START_SYSEX, PIN_STATE_QUERY, pin, END_SYSEX };
    NSData* data = [NSData dataWithBytes:&pkt length:4];
    [self.serialPort write:data];
    

    
}

/* pin state response
 * -------------------------------
 * 0  START_SYSEX (0xF0) (MIDI System Exclusive)
 * 1  pin state response (0x6E)
 * 2  pin (0 to 127)
 * 3  pin mode (the currently configured mode)
 * 4  pin state, bits 0-6
 * 5  (optional) pin state, bits 7-13
 * 6  (optional) pin state, bits 14-20
 ...  additional optional bytes, as many as needed
 * N  END_SYSEX (0xF7)
 */
- (void) parseSysexPinStateResponse {
    

#ifdef DEBUG_FIRMATA
    NSLog(@"Pin state received");
#endif
    UInt8* receivedBytes;
    unsigned long receivedLength =self.receivedBuffer.length;
    receivedBytes = malloc(sizeof(UInt8)*receivedLength);
    [self.receivedBuffer getBytes:receivedBytes length:receivedLength];

    int pin = receivedBytes[1];
    pin_info[pin].mode = receivedBytes[2];
    pin_info[pin].value = receivedBytes[3];
    if (receivedLength > 5) pin_info[pin].value |= (receivedBytes[4] << 7);
    if (receivedLength > 6) pin_info[pin].value |= (receivedBytes[5] << 14);
    
    // now setup pin in the arrays
    ADArduinoPin* arduino_pin = [[ADArduinoPin alloc] initWithNumber:pin mode:pin_info[pin].mode value:pin_info[pin].value supportedModes:pin_info[pin].supported_modes analogChannel:pin_info[pin].analog_channel];
    
    arduino_pin.delegate=self;
    
    if (arduino_pin.analog_channel < 127) {
        [self.analogPins addObject:arduino_pin];
    } else {
        [self.digitalPins addObject:arduino_pin];
    }
#ifdef DEBUG_FIRMATA
    NSLog(@"Adding pin %@", arduino_pin);
#endif
    
    
    free(receivedBytes);
}

- (void) startReportingAllPins {
//    for (ADArduinoPin* arduino_pin in self.analogPins) {
//        [arduino_pin setReportEnabled:YES];
//    }
//    for (int i=0;i<self.digitalPins.count;i++) {
//        ADArduinoPin* arduino_pin = [self.digitalPins objectAtIndex:i];
//        [arduino_pin setReportEnabled:YES];
//    }
}



#pragma mark ADPinDelegate

-(void)changeReporting:(BOOL)report on:(ADArduinoPin *)pin {
    if ([pin isAnalogPin]){
        UInt8 pkt[2] = { REPORT_ANALOG_PIN | pin.analog_channel, report ? 1 : 0};
        NSData* data = [NSData dataWithBytes:&pkt length:2];
        [self.serialPort write:data];
    } else {
        UInt8 portNumber = pin.number / 8 ;
        UInt8 pkt[2] = { REPORT_DIGITAL_PORT | portNumber, report ? 1 : 0 };
        NSData* data = [NSData dataWithBytes:&pkt length:2];
  
        [self.serialPort write:data];
    }
}

-(void)changeMode:(ADArduinoPin *)pin mode:(UInt8)newMode{
    UInt8 pkt[3] = { SET_PIN_MODE, pin.number, newMode };
    NSData* data = [NSData dataWithBytes:&pkt length:3];
    [self.serialPort write:data];
}



-(void)writeDigitalValue:(ADArduinoPin *)pin value:(uint32_t)newValue {
    
    int port_num = pin.number / 8;
    UInt8 port_val = 0;
    for (int i=0; i<8; i++) {
        int p = port_num * 8 + i;
        if (p < self.digitalPins.count) {
            ADArduinoPin* digitalPin = [self.digitalPins objectAtIndex:p];
            if (digitalPin.mode == MODE_OUTPUT || digitalPin.mode == MODE_INPUT) {
                if (digitalPin.value) {
                    port_val |= (1<<i);
                }
            }
        }
    }
    UInt8 pkt[3] = { DIGITAL_MESSAGE | port_num, port_val & 0x7F, (port_val >> 7) & 0x7F };
    NSData* data = [NSData dataWithBytes:&pkt length:3];
    //        NSLog(@"Sending %@", data);
    [self.serialPort write:data];
    

}

-(void)writeAnalogValue:(ADArduinoPin*)pin value:(uint32_t)newValue {
    
    if ( pin.number <= 15 && newValue<= 16383 ) {
#ifdef DEBUG_FIRMATA
        NSLog(@"Sending analog message");
#endif
        UInt8 pkt[3] = { ANALOG_MESSAGE | pin.number,  newValue & 0x7F, (newValue >> 7) & 0x7F};
        NSData* data = [NSData dataWithBytes:&pkt length:3];
        [self.serialPort write:data];
    } else {
        /* use sysex
         
         As an alternative to the normal analog message, this extended version allows addressing beyond pin 15,
         and supports sending analog values with any number of bits. The number of data bits is inferred by the length of the message.
         
         * extended analog
         * -------------------------------
         * 0  START_SYSEX (0xF0) (MIDI System Exclusive)
         * 1  extended analog message (0x6F)
         * 2  pin (0 to 127)
         * 3  bits 0-6 (least significant byte)
         * 4  bits 7-13
         * ... additional bytes may be sent if more bits needed
         * N  END_SYSEX (0xF7) (MIDI End of SysEx - EOX)
         */
        uint8_t buf[12];
		int len=4;
		buf[0] = START_SYSEX;
		buf[1] = 0x6F;
		buf[2] = pin.number;
		buf[3] = newValue & 0x7F;
        if (newValue > 0x00000080) buf[len++] = (newValue >> 7) & 0x7F;
		if (newValue > 0x00004000) buf[len++] = (newValue >> 14) & 0x7F;
		if (newValue > 0x00200000) buf[len++] = (newValue >> 21) & 0x7F;
		if (newValue > 0x10000000) buf[len++] = (newValue >> 28) & 0x7F;
		buf[len++] = END_SYSEX;
        NSData* data = [NSData dataWithBytes:&buf length:len];
        [self.serialPort write:data];
    }

}



-(void)changeValue:(ADArduinoPin *)pin value:(uint32_t)newValue {
    
    if ([[pin currentMode] isEqualToString:@"Output"]){
        // update the pin

        [self writeDigitalValue:pin value:newValue];
        
    } else {
        // update the port
        [self writeAnalogValue:pin value:newValue];
        
    
    }
    
}


- (void) updateDigitalPortValue:(UInt8)portNumber mask:(UInt8) port_val {
#ifdef DEBUG_FIRMATA
    NSLog(@"update %d", portNumber);
#endif
    int pinNo = portNumber * 8;
    for (int mask=1; mask & 0xFF; mask <<= 1, pinNo++) {
        if (pinNo >= self.digitalPins.count ) return;
        ADArduinoPin* pin = [self.digitalPins objectAtIndex:pinNo];
        if (pin && pin.mode == MODE_INPUT){
            uint32_t val = (port_val & mask) ? 1 : 0;
                if (pin.value != val) {
                    [pin updateValue:val];
                }
        }
    }
    

}

- (void) updateAnalogPinValue:(UInt8)pinNumber mask:(int) value {
    
    if (pinNumber >= self.analogPins.count ) return;
    for (ADArduinoPin* p in self.analogPins) {
        if (p.analog_channel == pinNumber) {
            ADArduinoPin* pin = p; // [self.analogPins objectAtIndex:pinNumber];
            if (pin) {
                [pin updateValue:value];
#ifdef DEBUG_FIRMATA
                NSLog(@"pin A%d %u",pin.analog_channel, value);
#endif
            }
        }
    }
}



- (void) stopListening {
    [self.bgThread cancel];
}

-(void)dealloc {

}

@end
