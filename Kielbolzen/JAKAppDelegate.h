//
//  JAKAppDelegate.h
//  Kielbolzen
//
//  Created by Martin Kautz on 15.08.14.
//  Copyright (c) 2014 JAKOTA Design Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LovelyFetcherEngine.h"
@interface JAKAppDelegate : NSObject <NSApplicationDelegate>

@property (strong, nonatomic) IBOutlet      NSMenu                  *theMenu;
@property (strong, nonatomic) IBOutlet      NSMenuItem              *theMenuItemAtZero;
@property (strong, nonatomic)               NSStatusItem            *statusBar;
@property (assign, getter = isRunning)      BOOL                    running;
@property (assign, getter = isConnected)    BOOL                    connected;
@property (strong, nonatomic)               LovelyFetcherEngine     *lovelyFetcherEngine;

@end
