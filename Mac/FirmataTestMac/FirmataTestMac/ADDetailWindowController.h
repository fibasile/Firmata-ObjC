//
//  ADDetailWindowController.h
//  FirmataTestMac
//
//  Created by fiore on 31/10/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ADArduino.h"

@interface ADDetailWindowController : NSWindowController <NSTableViewDataSource,NSTableViewDelegate>


@property (strong) ADArduino* arduino;
@property (assign) IBOutlet NSTableView *tableView;
@property (assign) BOOL stopRefresh;
@property (assign) NSTimer* timer;
@end
