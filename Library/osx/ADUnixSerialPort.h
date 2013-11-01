//
//  ADUnixSerialPort.h
//  Firmata-ObjC
//
//  Created by fiore on 28/10/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ADSerialPort.h"
#import "ADCircularBuffer.h"

@class ORSSerialPort;

@interface ADUnixSerialPort : NSObject <ADSerialPort> {

    ADCircularBuffer buffer;
}

@property (nonatomic,strong) ORSSerialPort* internalSerial;

@property (nonatomic,strong) NSString* device;
@property (nonatomic,assign) int baudRate;
@property (nonatomic,assign) NSTimeInterval timeout;
@property (nonatomic,assign) int rxCount;
@property (nonatomic,assign) int txCount;


/*
 * Init this Virtual Serial port with the given params
 * @param aDevice the unix device name
 * @param aBaudRate the actual baud rate in bps
 * @param aTimeout the time out interval for receiving data
 */

-initWithDevice:(NSString*)aDevice baudRate:(int)aBaudRate timeout:(NSTimeInterval)aTimeout;

@end