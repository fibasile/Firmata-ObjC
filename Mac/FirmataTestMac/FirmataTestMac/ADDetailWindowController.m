//
//  ADDetailWindowController.m
//  FirmataTestMac
//
//  Created by fiore on 31/10/13.
//  Copyright (c) 2013 Fiore Basile. All rights reserved.
//

#import "ADDetailWindowController.h"
#import "ADArduinoPin.h"
#import "ADFirmataConst.h"

@interface ADDetailWindowController ()

@end

@implementation ADDetailWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.


    
}


-(void)showWindow:(id)sender {
    
    self.stopRefresh = NO;
    [super showWindow:sender];
    [self initArduino];
}

- (void) initArduino {
    
    __block ADArduino* _warduino = self.arduino;
    [self.arduino connectWithBlock:^{
        
        NSLog(@"Arduino connected");
        NSLog(@"Arduino Firmata version %@ %@",[_warduino firmataVersion], [_warduino firmataVersionString]);
        
        NSLog(@"Analog pins %@", _warduino.analogPins);
        NSLog(@"Digital pins %@", _warduino.digitalPins);
        
        [self setupGUI];
    }];
}


- (void) setupGUI {
        [[self tableView] reloadData];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:.5 target:self selector:@selector(refresh:) userInfo:nil repeats:YES];
    
}


- (void) refresh:(NSTimer*)timer {
    
    [[self tableView] reloadData];

    
}


-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    ADArduinoPin* pin = nil;
    if (row < self.arduino.analogPins.count) {
        pin = [self.arduino.analogPins objectAtIndex:row];
    } else if (row < self.arduino.analogPins.count + self.arduino.digitalPins.count) {
        pin = [self.arduino.digitalPins objectAtIndex:row-self.arduino.analogPins.count];
        
    }
    
    if ([tableColumn.identifier isEqualToString:@"pin"]) {
        if (pin.isAnalogPin) {
            return [NSString stringWithFormat:@"A%d", pin.analog_channel];
        } else {
            return [NSString stringWithFormat:@"D%d", pin.number];
        }
    }
    if ([tableColumn.identifier isEqualToString:@"mode"]) {
        if (pin.availableModes.count == 0) {
            return @"N/A";
        }
        NSString* current = pin.currentMode;
        NSInteger idx = [pin.availableModes indexOfObject:current];
        return [NSNumber numberWithInt:(int)idx];
    }
    if ([tableColumn.identifier isEqualToString:@"pin_value"]) {
        if (pin.isAnalogPin && ([pin.currentMode isEqualToString:@"Input"] || [pin.currentMode isEqualToString:@"Analog"])){
            return [NSString stringWithFormat:@"%u",pin.value];
        } else if (pin.isAnalogPin && ([pin.currentMode isEqualToString:@"Output"])){
            return [NSNumber numberWithUnsignedInt:pin.value];
        } else if (!pin.isAnalogPin && [pin.currentMode isEqualToString:@"Output"]) {
            return [NSNumber numberWithBool:pin.value];
        } else if (!pin.isAnalogPin && [pin.currentMode isEqualToString:@"Servo"]) {
            return [NSNumber numberWithUnsignedInt:pin.value];
        } else {
            return [NSString stringWithFormat:@"%d",pin.value];
        }
    }
    
    
    return nil;
}

-(ADArduinoPin*) pinForRow:(NSInteger)row {
    ADArduinoPin* pin = nil;
    if (row < self.arduino.analogPins.count) {
        pin = [self.arduino.analogPins objectAtIndex:row];
    } else if (row < self.arduino.analogPins.count + self.arduino.digitalPins.count) {
        pin = [self.arduino.digitalPins objectAtIndex:row-self.arduino.analogPins.count];
        
    } else {
        return nil;
    }
    return pin;
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    
    return self.arduino.digitalPins.count + self.arduino.analogPins.count;
    
}

-(CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row{
    return 25.0;
}


-(BOOL)tableView:(NSTableView *)tableView shouldSelectTableColumn:(NSTableColumn *)tableColumn {
    return ([tableColumn.identifier isEqualToString:@"mode"]);
    
}
-(NSCell *)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (tableColumn == nil){
        return nil;
    }
    
    ADArduinoPin* pin = [self pinForRow:row];
    if (!pin) return nil;
    
    
    if ([tableColumn.identifier isEqualToString:@"pin"]){
        NSTextFieldCell* tf = [[NSTextFieldCell alloc] init];
        return tf;
    }
    if ([tableColumn.identifier isEqualToString:@"mode"]){
        
        if (pin.availableModes.count) {
            NSPopUpButtonCell* boxCell =  [[NSPopUpButtonCell alloc] init];

            [boxCell addItemsWithTitles:pin.availableModes];

            return boxCell;
        } else {
            NSTextFieldCell* tf = [[NSTextFieldCell alloc] init];
            //        tf.stringValue = [self tableView:tableView objectValueForTableColumn:tableColumn row:row];
            return tf;
      }
    }
    if ([tableColumn.identifier isEqualToString:@"pin_value"]){
        if ( [pin.currentMode isEqualToString:@"Output"] ){
            NSButtonCell* buttonCell = [[NSButtonCell alloc] init];
            [buttonCell setBezelStyle:NSRoundedBezelStyle];
            [buttonCell setTitle:pin.value ? @"On" : @"Off"];
            return buttonCell;
        } else if ([pin.currentMode isEqualToString:@"Servo"] ){
            NSSliderCell* sliderCell= [[NSSliderCell alloc] init];
            [sliderCell setMinValue:0];
            [sliderCell setMaxValue:180];
            [sliderCell setContinuous:YES];
            return sliderCell;
        } else if ([pin.currentMode isEqualToString:@"PWM"]){
            NSSliderCell* sliderCell= [[NSSliderCell alloc] init];
            [sliderCell setMinValue:0];
            [sliderCell setMaxValue:255];
            [sliderCell setContinuous:YES];
            return sliderCell;
        } else {
            NSTextFieldCell* textFieldCell = [[NSTextFieldCell alloc] init];
            return textFieldCell;
        }

        
    }

    return [[NSCell alloc] init];
}


-(void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    if ([tableColumn.identifier isEqualToString:@"mode"]){
        
        [self changePinMode:row index:[object intValue]];
    }
    if ([tableColumn.identifier isEqualToString:@"pin_value"]){
        [self changePinValue:row value:[object unsignedIntValue]];
    }
    
    
}
-(void)changePinValue:(NSInteger)row value:(uint32_t)value {
    ADArduinoPin* pin = [self pinForRow:row];
    if (!pin) return;
    NSLog(@"Setting value %u", value);
   
    [pin setValue:value];
}


-(void)changePinMode:(NSInteger)row index:(int)index{
    
    ADArduinoPin* pin = [self pinForRow:row];
    if (!pin) return;
    
    NSString* currVal = [[pin availableModes] objectAtIndex:index];
    int targetMode = 127;
    if ([currVal isEqualToString:@"Analog"]){
        targetMode = MODE_ANALOG;
    } else if ([currVal isEqualToString:@"Output"]){
        targetMode = MODE_OUTPUT;
    } else if ([currVal isEqualToString:@"Input"]){
        targetMode = MODE_INPUT;
    } else if ([currVal isEqualToString:@"Servo"]){
        targetMode = MODE_SERVO;
    } else if ([currVal isEqualToString:@"PWM"]){
        targetMode = MODE_PWM;
    }
    if (targetMode < 127) {
            [pin setMode:targetMode];
    }
    
    
}

-(void)close {
    [self.timer invalidate];
    self.stopRefresh = YES;
    [super close];
    
}
@end
