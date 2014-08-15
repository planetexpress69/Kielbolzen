//
//  JAKAppDelegate.h
//  Kielbolzen
//
//  Created by Martin Kautz on 15.08.14.
//  Copyright (c) 2014 JAKOTA Design Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface JAKAppDelegate : NSObject <NSApplicationDelegate>

@property (strong, nonatomic) IBOutlet  NSMenu          *theMenu;
@property (strong, nonatomic)           NSStatusItem    *statusBar;
@property (assign)                      BOOL            flip;

@end
