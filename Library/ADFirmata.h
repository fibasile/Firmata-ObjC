//
//  ADFirmata.h
//  Firmata-ObjC
//
//  Created by fiore on 28/10/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ADArduino.h"
#import "ADArduinoPin.h"
#import "ADFirmataConst.h"


@interface ADFirmata : NSObject

/*
 * Set Serial Port to be used by the shared Arduino
 */
+(void)setSerialPort:(NSString*)serial;

/*
 * Set Serial Baud Rate 
 */
+(void)setDefaultBaudRate:(int)baud;

/*
 * Get the shared Arduino instance
 */
+ (ADArduino*) sharedArduino;

@end
