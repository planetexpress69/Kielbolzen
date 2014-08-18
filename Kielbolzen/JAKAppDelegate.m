//
//  JAKAppDelegate.m
//  Kielbolzen
//
//  Created by Martin Kautz on 15.08.14.
//  Copyright (c) 2014 JAKOTA Design Group. All rights reserved.
//

#import "JAKAppDelegate.h"
#import <XMLReader/XMLReader.h>

@implementation JAKAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{

    self.connected                  = NO;
    self.running                    = NO;
    self.statusBar                  = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    self.statusBar.image            = [NSImage imageNamed:@"statusicon_default"];
    self.statusBar.menu             = self.theMenu;
    self.statusBar.highlightMode    = YES;
    self.theMenuItemAtZero.title    = @"Initializing...";

    [NSTimer scheduledTimerWithTimeInterval:5.0
                                     target:self
                                   selector:@selector(payload:)
                                   userInfo:nil
                                    repeats:YES];

    Reachability *reachabilityInfo;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(myReachabilityDidChangedMethod:)
                                                 name:kReachabilityChangedNotification
                                               object:reachabilityInfo];

    self.lovelyFetcherEngine = [[LovelyFetcherEngine alloc]initWithHostName:@"www.teambender.de"];

}

- (IBAction)payload:(id)sender
{
    if (!self.isConnected) {
        self.theMenuItemAtZero.title = @"No connection. :-(";
        self.statusBar.image = [NSImage imageNamed:@"statusicon_error"];
        return;
    }

    if (self.isRunning)
        return;

    self.running = YES;
    [self.lovelyFetcherEngine fetchLevelForCredentials:@"foo" onCompletion:^(MKNetworkOperation *completedOperation) {

        NSError *parsingError   = nil;
        NSDictionary *dResponse = [XMLReader dictionaryForXMLString:completedOperation.responseString
                                                              error:&parsingError];

        if (dResponse && !parsingError) {
            NSString *sLevel =  dResponse[@"payload"][@"value"][@"text"];
            self.theMenuItemAtZero.title =
            [NSString stringWithFormat:@"Level: %@%%", [NSString stringWithFormat:@"%d", (sLevel.intValue * 20)]];
            self.statusBar.image = [NSImage imageNamed:[NSString stringWithFormat:@"statusicon_%@", sLevel]];
            self.running = NO;
        } else {
            self.theMenuItemAtZero.title = @"Garbled response";
            self.statusBar.image = [NSImage imageNamed:@"statusicon_error"];
            self.running = NO;
        }

    } onError:^(NSError *error) {
        DLog(@"error: %@", error);
        self.theMenuItemAtZero.title = error.localizedDescription;
        self.statusBar.image = [NSImage imageNamed:@"statusicon_error"];
        self.running = NO;
    }];

}

- (void)myReachabilityDidChangedMethod:(NSNotification *)notification
{
    Reachability *reachability = (Reachability *)notification.object;
    NetworkStatus internetStatus = [reachability currentReachabilityStatus];
    if (internetStatus != NotReachable) {
        DLog(@"Connected, so move on!");
        self.connected = YES;
    }
    else {
        DLog(@"No internet :-(");
        self.connected = NO;
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
