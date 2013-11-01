//
//  ADArduino.h
//  Firmata-ObjC
//
//  Created by fiore on 28/10/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ADSerialPort.h"
@class ADArduinoPin;

@protocol ADPinDelegate
/*
- (void) reportAnalogPin:(ADAnalogPin*)pin;
- (void) setDigitalPinMode:(ADDigitalPin*)pin;
- (void) reportDigitalPort:(ADDigitalPort*)port;
- (void) sendDigitalMessage:(ADDigitalPort*)port;
- (void) sendAnalogMessage:(ADDigitalPin*)pin;
*/

-(void)changeMode:(ADArduinoPin *)pin mode:(UInt8)newMode;
-(void)changeValue:(ADArduinoPin *)pin value:(uint32_t)newValue;
-(void)changeReporting:(BOOL)report on:(ADArduinoPin*)pin;
@end

typedef struct {
    int mode;
    int analog_channel;
    int supported_modes;
    uint32_t value;
} pin_t;


@interface ADArduino : NSObject <ADPinDelegate> {
    pin_t pin_info[128];
    
}

@property (nonatomic,strong) id<ADSerialPort> serialPort;

@property (nonatomic,strong) NSString* firmataVersion;
@property (nonatomic,strong) NSString* firmataVersionString;

//@property (nonatomic,strong) NSArray* digitalPorts;
//@property (nonatomic,strong) NSArray* analogPins;
//@property (nonatomic,readonly) NSArray* digitalPins;

@property (atomic,strong) NSMutableArray* analogPins;
@property (atomic,strong) NSMutableArray* digitalPins;

@property (nonatomic,assign) BOOL hasAnalogMapping;
@property (nonatomic,assign) BOOL hasCapabilities;
@property (nonatomic,assign) BOOL connected;


@property (nonatomic,strong) NSMutableData* receivedBuffer;
@property (nonatomic,assign) BOOL parsingSysEx;
@property (nonatomic,assign) int sysexBytesRead;
@property (nonatomic,assign) int waitForData;
@property (nonatomic,assign) int executeMultiByteCommand;
@property (nonatomic,assign) int multiByteChannel;
@property (nonatomic,assign) NSTimer* loopTimer;
@property (nonatomic,strong) NSThread* bgThread;
@property (nonatomic,strong) void (^connectBlock)(void);

- (id) initWithSerial:(id<ADSerialPort>) aSerialPort;
- (void) connectWithBlock:(void (^)())initBlock;
- (void) startReportingAllPins;
- (void) stopListening;
@end
