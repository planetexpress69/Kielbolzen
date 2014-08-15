//
//  JAKAppDelegate.m
//  Kielbolzen
//
//  Created by Martin Kautz on 15.08.14.
//  Copyright (c) 2014 JAKOTA Design Group. All rights reserved.
//

#import "JAKAppDelegate.h"

@implementation JAKAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.flip = NO;
    self.statusBar = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusBar.image = [NSImage imageNamed:@"statusicon_default"];
    self.statusBar.menu = self.theMenu;
    self.statusBar.highlightMode = YES;

    [NSTimer scheduledTimerWithTimeInterval:2.0
                                     target:self
                                   selector:@selector(payload:)
                                   userInfo:nil
                                    repeats:YES];
}

- (IBAction)payload:(id)sender
{
    self.statusBar.image =
    self.flip ? [NSImage imageNamed:@"statusicon_default"] : [NSImage imageNamed:@"statusicon_alternate"];
    self.flip = !self.flip;
}

@end
