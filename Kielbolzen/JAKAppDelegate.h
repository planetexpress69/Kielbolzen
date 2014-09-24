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

extern NSString * const kbHostKey;
extern NSString * const kbIntervalKey;

extern NSString * const kbSignalLevelChangedNotification;
extern NSString * const kbSignalIconChangedNotification;
extern NSString * const kbBatteryLevelChangedNotification;
extern NSString * const kbNetworkTypeChangedNotification;
extern NSString * const kbPlmnRatChangedNotification;
extern NSString * const kbProviderChangedNotification;
extern NSString * const kbBytesInOutChangedNotification;

@interface JAKAppDelegate : NSObject <NSApplicationDelegate> {
    int _status;
    int _sigLevel;
    int _sigIcon;
    int _batLevel;
    int _bytesIn;
    int _bytesOut;
    NSString *_plmnRat;
    NSString *_provider;
    NSString *_netType;
    NSString *_netTypeEx;
    
    NSMutableAttributedString *_noService;
    NSMutableAttributedString *_error;
    NSArray *_sigIcons;
}
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
