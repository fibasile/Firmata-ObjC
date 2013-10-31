//
//  ADFirmata.m
//  Firmata-ObjC
//
//  Created by fiore on 28/10/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#import "ADFirmata.h"
#import "ADUnixSerialPort.h"
#import "ADFirmataConst.h"


@implementation ADFirmata

static ADArduino* _sharedArduino=nil;
static NSString* _defaultSerialPort=nil;
static int _defaultBaudRate=-1;


+(void)setSerialPort:(NSString*)serial {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultSerialPort = serial;
    });
}

+(void)setDefaultBaudRate:(int)baud {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultBaudRate = baud;
    });
}


+(ADArduino*) sharedArduino {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        NSString* mySerial = DEFAULT_SERIAL;
        int myBaud = DEFAULT_BAUDRATE;
        if (_defaultSerialPort!=nil){
            mySerial = _defaultSerialPort;
        }
        if (_defaultBaudRate > 0){
            myBaud = _defaultBaudRate;
        }
        
        id<ADSerialPort> defaultSerial = [[ADUnixSerialPort alloc] initWithDevice:DEFAULT_SERIAL baudRate:DEFAULT_BAUDRATE timeout:DEFAULT_TIMEOUT];
        
        _sharedArduino = [[ADArduino alloc] initWithSerial:defaultSerial];
    });
    return _sharedArduino;
    
}


@end
