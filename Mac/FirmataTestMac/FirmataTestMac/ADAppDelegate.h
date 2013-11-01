//
//  ADAppDelegate.h
//  FirmataTestMac
//
//  Created by fiore on 31/10/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ADDetailWindowController.h"

@interface ADAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) BOOL connected;
@property (assign) IBOutlet ADDetailWindowController *detailController;
@property (assign) IBOutlet NSComboBox* serialPortsCombo;
@property (assign) IBOutlet NSComboBox* serialBaudCombo;
@property (assign) IBOutlet NSButton* connectButton;
@property (assign) IBOutlet NSTextField* rxLabel;
@property (assign) IBOutlet NSTextField* txLabel;


- (IBAction)connectAction:(id)sender;


@end
