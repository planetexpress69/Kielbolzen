//
//  JAKAppDelegate.h
//  Kielbolzen
//
//  Created by Martin Kautz on 15.08.14.
//  Copyright (c) 2014 JAKOTA Design Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LovelyFetcherEngine.h"
#import "MacroImporter.h"

@interface JAKAppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate>
// ---------------------------------------------------------------------------------------------------------------------
@property (strong, nonatomic) IBOutlet      NSMenu                  *theMenu;
@property (strong, nonatomic) IBOutlet      NSMenuItem              *theMenuItemAtZero;
@property (strong, nonatomic) IBOutlet      NSMenuItem              *theMenuItemAtOne;
@property (strong, nonatomic) IBOutlet      NSMenuItem              *theMenuItemAtTwo;
@property (strong, nonatomic) IBOutlet      NSMenuItem              *theMenuItemAtThree;
@property (strong, nonatomic) IBOutlet      NSMenuItem              *theMenuItemSettings;
@property (strong, nonatomic)               NSStatusItem            *theStatusBar;
@property (strong, nonatomic) IBOutlet      NSPanel                 *thePanel;
@property (strong, nonatomic) IBOutlet      NSTextField             *theIPField;
@property (assign, getter = isRunning)      BOOL                    running;
@property (assign, getter = isConnected)    BOOL                    connected;
@property (strong, nonatomic)               LovelyFetcherEngine     *lovelyFetcherEngine;
@property (strong, nonatomic)               MacroImporter           *macroImporter;
@property (strong, nonatomic)               NSTimer                 *theTimer;
// ---------------------------------------------------------------------------------------------------------------------
@end
