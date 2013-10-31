//
//  ADArduinoPin.m
//  Firmata-ObjC
//
//  Created by fiore on 30/10/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#import "ADArduinoPin.h"
#import "ADFirmataConst.h"
#import "ADArduino.h"

@implementation ADArduinoPin
@synthesize mode=_mode;
@synthesize value=_value;

- (id)initWithNumber:(int)number mode:(uint8_t)mode value:(uint32_t)value supportedModes:(uint64_t)supportedModes analogChannel:(uint8_t)analogChannel {
    if (self = [super init]){
        
        self.number = number;
        _mode = mode;
        _value = value;
        _reportEnabled = NO;
        self.supported_modes = supportedModes;
        self.analog_channel = analogChannel;
    }
    return self;
    
}

-(NSArray *)availableModes {
    NSMutableArray* m = [NSMutableArray array];
    
    if (self.supported_modes & (1<<MODE_INPUT)) [m addObject:@"Input"] ;
	if (self.supported_modes & (1<<MODE_OUTPUT)) [m addObject:@"Output"];
	if (self.supported_modes & (1<<MODE_ANALOG)) [m addObject:@"Analog"];
	if (self.supported_modes & (1<<MODE_PWM)) [m addObject:@"PWM"];
	if (self.supported_modes & (1<<MODE_SERVO)) [m addObject:@"Servo"];
    
    return m;
    
}
-(NSString *)currentMode {
    switch (self.mode) {
        case MODE_INPUT:
            return @"Input";
            break;
        case MODE_OUTPUT:
            return @"Output";
            break;
        case MODE_ANALOG:
            return @"Analog";
            break;
        case MODE_PWM:
            return @"PWM";
            break;
        case MODE_SERVO:
            return @"Servo";
            break;
        default:
            return nil;
            break;
    }
}

- (BOOL) isAnalogPin {
    return (self.analog_channel < 127);
}


- (void)setReportEnabled:(BOOL)reportEnabled {
    _reportEnabled = YES;
    [self.delegate changeReporting:reportEnabled on:self];
    
}


- (void)setMode:(uint8_t)newMode {
    if (!(self.supported_modes & (1<<newMode))){
        @throw @"Invalid mode requested";
    }
    [self.delegate changeMode:self mode:newMode];
    _mode = newMode;
    _value = 0;
}

- (void)setValue:(uint32_t)newValue {
    _value = newValue;
    [self.delegate changeValue:self value:newValue];

}


- (void) updateValue:(uint32_t)newValue {
    _value = newValue;
}

/****/
-(NSString *)description {
    if ([self isAnalogPin]){
        return [NSString stringWithFormat:@"Analog Pin A%d, mode %@, value %d", self.analog_channel, self.currentMode, self.value];
    }
    return [NSString stringWithFormat:@"Digital Pin %d, mode %@, value %d, analog %d", self.number, self.currentMode, self.value, self.analog_channel];
}
@end
