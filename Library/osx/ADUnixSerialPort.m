//
//  ADUnixSerialPort.m
//  Firmata-ObjC
//
//  Created by fiore on 28/10/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#import "ADUnixSerialPort.h"
#import "ORSSerialPort.h"

#define MAX_BUFFER_SIZE 4096


@interface ADUnixSerialPort (Private) <ORSSerialPortDelegate>

@end

@implementation ADUnixSerialPort


-initWithDevice:(NSString*)aDevice baudRate:(int)aBaudRate timeout:(NSTimeInterval)aTimeout {
    
    self = [super init];
    if (self){
        self.device = aDevice;
        self.baudRate = aBaudRate;
        self.timeout = aTimeout;
        self.internalSerial = [ORSSerialPort serialPortWithPath:self.device];
        self.internalSerial.delegate = self;
        self.internalSerial.baudRate = [NSNumber numberWithInt:aBaudRate];
        [self.internalSerial open];
        ADCircularBufferInit(&buffer, MAX_BUFFER_SIZE);
        self.rxCount = 0;
        self.txCount = 0;
    }
    return self;
    
    
}

-(void)serialPort:(ORSSerialPort *)serialPort didReceiveData:(NSData *)data {
//    [self.receiveBuffer addObject:data];
    
    uint8_t* buffData = (uint8_t*) data.bytes;
    unsigned long len = data.length;
    self.rxCount += len;
     ElemType elem = {0};
    for (int i=0;i<len;i++){

        elem.value = (uint8_t)buffData[i];
        ADCircularBufferWrite(&buffer, &elem);
    }
    
}

-(void)serialPort:(ORSSerialPort *)serialPort didEncounterError:(NSError *)error {
    NSLog(@"SerialPort error %@:\n%@", error.localizedDescription, error.localizedFailureReason);
    
}

-(void)write:(NSData *)byteData {
    self.txCount += byteData.length;
    [self.internalSerial sendData:byteData];
}


- (UInt8) read {
    if (!ADCircularBufferIsEmpty(&buffer)){
        ElemType elem = {0};
        ADCircularBufferRead(&buffer, &elem);
        return elem.value;
    }
    return 0;
}

- (BOOL)available {
    return !ADCircularBufferIsEmpty(&buffer);
}

-(void)dealloc {
    
    [self.internalSerial close];
    ADCircularBufferFree(&buffer);
    
}


@end
 