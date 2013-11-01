//
//  ADSerialPort.h
//  Firmata-ObjC
//
//  Created by fiore on 28/10/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol ADSerialPort <NSObject>

- (void) write:(NSData*)byteData;
- (UInt8) read;
- (BOOL)available;
- (int)rxCount;
- (int)txCount;
@end


