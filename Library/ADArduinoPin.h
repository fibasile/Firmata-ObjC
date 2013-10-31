//
//  ADArduinoPin.h
//  Firmata-ObjC
//
//  Created by fiore on 30/10/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ADPinDelegate;

@interface ADArduinoPin : NSObject

@property (nonatomic,assign) id<ADPinDelegate> delegate;
@property (nonatomic,assign) int number;
@property (nonatomic,assign) uint8_t mode;
@property (nonatomic,assign) uint8_t analog_channel;
@property (nonatomic,assign) uint64_t supported_modes;
@property (nonatomic,assign) uint32_t value;
@property (nonatomic,assign) BOOL reportEnabled;

- (id)initWithNumber:(int)number mode:(uint8_t)mode value:(uint32_t)value supportedModes:(uint64_t)supportedModes analogChannel:(uint8_t)analogChannel;
- (BOOL) isAnalogPin;
- (NSArray*) availableModes;
- (NSString*)currentMode;
- (void) updateValue:(uint32_t)value;
@end
