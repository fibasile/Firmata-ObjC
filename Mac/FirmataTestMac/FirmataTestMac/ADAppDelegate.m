//
//  ADAppDelegate.m
//  FirmataTestMac
//
//  Created by fiore on 31/10/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#import "ADAppDelegate.h"
#import "ORSSerialPortManager.h"
#import "ORSSerialPort.h"
#import "ADArduino.h"
#import "ADUnixSerialPort.h"

@implementation ADAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    [self setupSerialPortGUI];
    
}


- (void) setupSerialPortGUI {
    
    
    self.rxLabel.stringValue = @"0";
    self.txLabel.stringValue = @"0";
    
    NSArray* availablePorts = [[ORSSerialPortManager sharedSerialPortManager] availablePorts ];
    for (ORSSerialPort* port in availablePorts) {
        [self.serialPortsCombo addItemWithObjectValue:port.path];
    }
    [self.serialPortsCombo selectItemAtIndex:0];
    
    NSArray* baudRates = [NSArray arrayWithObjects:@"19200", @"38400", @"57600",@"115200",nil];
    [self.serialBaudCombo addItemsWithObjectValues:baudRates];
    [self.serialBaudCombo selectItemAtIndex:2];

}


- (IBAction)connectAction:(id)sender {
    
    if (!self.connected) {
        self.rxLabel.stringValue = @"0";
        self.txLabel.stringValue = @"0";
        
        NSString* path = (NSString*)[self.serialPortsCombo objectValueOfSelectedItem];
        long baud = [(NSString*)[self.serialBaudCombo objectValueOfSelectedItem] integerValue];
        
        ADUnixSerialPort* port = [[ADUnixSerialPort alloc] initWithDevice:path baudRate:(int)baud timeout:3];
        
        [port addObserver:self forKeyPath:@"rxCount" options:NSKeyValueObservingOptionNew context:nil];
        [port addObserver:self forKeyPath:@"txCount" options:NSKeyValueObservingOptionNew context:nil];
        
        
        
        ADArduino* arduino = [[ADArduino alloc] initWithSerial:port];
        
        
        [self.detailController setArduino:arduino];
        
        [self.detailController showWindow:self];
        
        [self.connectButton setTitle:@"Disconnect"];
        self.connected = YES;

 
        
        
    } else {
        
        ADUnixSerialPort* port = (ADUnixSerialPort*) self.detailController.arduino.serialPort;
        [port removeObserver:self forKeyPath:@"rxCount"];
        [port removeObserver:self forKeyPath:@"txCount"];
        
        [self.detailController.window performClose:self];
        [self.detailController close];
        [self.detailController.arduino stopListening];
        [self.connectButton setTitle:@"Connect"];
        self.connected = NO;
        
    }
    
    
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"rxCount"]) {
         self.rxLabel.stringValue = [NSString stringWithFormat:@"%d bytes", [[change objectForKey:@"new"] intValue]];
    }
    if ([keyPath isEqualToString:@"txCount"]) {
        self.txLabel.stringValue = [NSString stringWithFormat:@"%d bytes", [[change objectForKey:@"new"] intValue]];
    }
}

@end
