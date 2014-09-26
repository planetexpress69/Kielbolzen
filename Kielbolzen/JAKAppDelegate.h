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

@interface JAKAppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate> {

    int _serviceStatus;
    int _signalLevel;
    int _signalIcon;
    int _batteryLevel;
    int _bytesIn;
    int _bytesOut;

    BOOL _connected;

    NSString                    *_plmnRat;         // 2G|3G|4G
    NSString                    *_provider;        // Carrier
    NSString                    *_netType;         // int (key im Dict) e.g. 1 == EDGE
    NSString                    *_netTypeEx;       // int 1 == Netzinfo zu EDGE, feingranuliert
    
    NSMutableAttributedString   *_noService;
    NSMutableAttributedString   *_error;
    NSMutableAttributedString   *_noDevice;
    NSMutableAttributedString   *_deviceInit;
    NSArray                     *_sigIcons;
    
}
// ---------------------------------------------------------------------------------------------------------------------
@property (strong, nonatomic)               IBOutlet    NSMenu              *theMenu;
@property (strong, nonatomic)               IBOutlet    NSMenuItem          *theMenuItemAtZero;
@property (strong, nonatomic)               IBOutlet    NSMenuItem          *theMenuItemAtOne;
@property (strong, nonatomic)               IBOutlet    NSMenuItem          *theMenuItemAtTwo;
@property (strong, nonatomic)               IBOutlet    NSMenuItem          *theMenuItemAtThree;
@property (strong, nonatomic)               IBOutlet    NSMenuItem          *theMenuItemSettings;
@property (strong, nonatomic)               IBOutlet    NSPanel             *thePanel;
@property (strong, nonatomic)               IBOutlet    NSTextField         *theIPField;
@property (strong, nonatomic)                           NSStatusItem        *theStatusBar;
@property (assign, getter = isRunning)                  BOOL                running;
//@property (assign, getter = isConnected)                BOOL                connected;
@property (strong, nonatomic)                           LovelyFetcherEngine *lovelyFetcherEngine;
@property (strong, nonatomic)                           MacroImporter       *macroImporter;
@property (strong, nonatomic)                           NSTimer             *theTimer;
@property (strong, nonatomic)                           NSTimer             *thePingTimer;
@property (strong, nonatomic)                           NSMutableDictionary *container;
// ---------------------------------------------------------------------------------------------------------------------
@end
