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


// ---------------------------------------------------------------------------------------------------------------------
#pragma mark - Lifecycle
// ---------------------------------------------------------------------------------------------------------------------
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

// ---------------------------------------------------------------------------------------------------------------------
- (void)awakeFromNib
{
    self.theMenuItemAtZero.title    = @"Initializing...";
    self.theMenuItemAtOne.title     = @"Waiting...";
    self.theMenuItemAtTwo.title     = @"Waiting...";
    self.theMenuItemAtThree.title   = @"Waiting...";
    [self.theMenuItemSettings setEnabled:YES];

    self.connected                  = NO;
    self.running                    = NO;
    self.theStatusBar               = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    self.theStatusBar.image         = [NSImage imageNamed:@"statusicon_default"];
    self.theStatusBar.menu          = self.theMenu;
    self.theStatusBar.highlightMode = YES;
    self.thePanel.delegate          = self;

    Reachability *reachabilityInfo;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(myReachabilityDidChangedMethod:)
                                                 name:kReachabilityChangedNotification
                                               object:reachabilityInfo];

    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"mifi"]) {
        [[NSUserDefaults standardUserDefaults] setObject:@"192.168.0.1" forKey:@"mifi"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

// ---------------------------------------------------------------------------------------------------------------------
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self initFetcher];
}


// ---------------------------------------------------------------------------------------------------------------------
#pragma mark - Payload - fetching some stuff from the Mifi
// ---------------------------------------------------------------------------------------------------------------------
- (IBAction)payload:(id)sender
{
    // we're not connected at all, so get outta here
    if (!self.isConnected) {
        self.theMenuItemAtZero.title = @"No connection. :-(";
        self.theMenuItemAtOne.title= @"TX/RX: -/-";
        self.theMenuItemAtTwo.title= @"Provider:-";
        self.theMenuItemAtThree.title= @"Battery: -";
        self.theStatusBar.image = [NSImage imageNamed:@"statusicon_error"];
        return;
    }

    // we're connected but haven't gotten stuff we rely on
    if (self.macroImporter.networkTypes == nil) {
        [self.lovelyFetcherEngine fetchMainjs:@"foo" onCompletion:^(MKNetworkOperation *completedOperation) {
            if (!self.isConnected) {
                self.theMenuItemAtZero.title = @"No connection. :-(";
                self.theStatusBar.image = [NSImage imageNamed:@"statusicon_error"];
                return;
            }
            [self.macroImporter extractNetworkTypes: completedOperation.responseString];
            [self.macroImporter extractPlmnRat: completedOperation.responseString];
            NSLog(@"Could have gotten the stuff from mains.js I'm interested in. Nice!");
        } onError:^(NSError *error) {
            DLog(@"error: %@", error);
            self.theMenuItemAtZero.title = error.localizedDescription;
            self.theMenuItemAtOne.title= @"TX/RX: -/-";
            self.theMenuItemAtTwo.title= @"Provider:-";
            self.theMenuItemAtThree.title= @"Battery: -";
            self.theStatusBar.image = [NSImage imageNamed:@"statusicon_error"];
        }];
        // get outta here. next time we may have gotten the stuff from main.js...
        return;
    }

    // from now on avoid pending requests...
    if (self.isRunning)
        return;

    // get the mifi's state finally
    self.running = YES;

    [self.lovelyFetcherEngine fetchStatus:@"foo" onCompletion:^(MKNetworkOperation *completedOperation) {
        NSError *parsingError   = nil;
        NSDictionary *dResponse = [XMLReader dictionaryForXMLString:completedOperation.responseString
                                                              error:&parsingError];
        NSMutableDictionary *macroNetTypes= [self.macroImporter networkTypes];

        if (dResponse && !parsingError) {
            NSString *sLevel =  dResponse[@"response"][@"SignalStrength"][@"text"];
            NSString *sIcon =  dResponse[@"response"][@"SignalIcon"][@"text"];
            NSString *sStatus =  dResponse[@"response"][@"ServiceStatus"][@"text"];
            NSString *sBatLevel =  dResponse[@"response"][@"BatteryPercent"][@"text"];
            NSString *sNetworkType = dResponse[@"response"][@"CurrentNetworkType"][@"text"];
            NSString *sNetworkTypeEx = dResponse[@"response"][@"CurrentNetworkTypeEx"][@"text"];
            NSString *sNetMode = nil;

            if (sNetworkType.length == 0 && sNetworkTypeEx.length > 0) {
                sNetworkType = sNetworkTypeEx;
            }

            sNetMode = macroNetTypes[sNetworkType];

            NSString *sLevelStr = @"No Service";

            if (sStatus.intValue == 2) {
                sLevelStr= [NSString stringWithFormat:@"Level: %d%% (%@)", sLevel.intValue, sNetMode];
            }

            self.theMenuItemAtZero.title = sLevelStr;
            self.theMenuItemAtThree.title =[NSString stringWithFormat:@"Battery: %d%%", sBatLevel.intValue];

            self.theStatusBar.image= [NSImage imageNamed:[NSString stringWithFormat:@"signal_%@.gif", sIcon]];
        } else {
            self.theMenuItemAtZero.title = @"Garbled response";
            self.theStatusBar.image = [NSImage imageNamed:@"statusicon_error"];
        }
        self.running = NO;
    } onError:^(NSError *error) {
        DLog(@"error: %@", error);
        self.theMenuItemAtZero.title = error.localizedDescription;
        self.theStatusBar.image = [NSImage imageNamed:@"statusicon_error"];
        self.running = NO;
    }];


    [self.lovelyFetcherEngine fetchCurrentPlmn:@"foo" onCompletion:^(MKNetworkOperation *completedOperation) {

        NSError *parsingError   = nil;
        NSDictionary *dResponse = [XMLReader dictionaryForXMLString:completedOperation.responseString
                                                              error:&parsingError];

        if (dResponse && !parsingError) {
            NSMutableDictionary *currentPlmnRats    = [self.macroImporter plmnRat];
            NSString *sShort                        = dResponse[@"response"][@"ShortName"][@"text"];
            NSString *sRat                          =  dResponse[@"response"][@"Rat"][@"text"];
            NSString *sPlmnRat                      = nil;

            for (NSString *key in currentPlmnRats) {
                if (((NSNumber *)currentPlmnRats[key]).intValue == sRat.intValue) {
                    sPlmnRat = key;
                }
            }
            NSString *sProvider= @"No Service";

            if (sShort.length) {
                sProvider = [NSString stringWithFormat:@"Provider: %@ (%@)", sShort, sPlmnRat];
            }
            self.theMenuItemAtTwo.title = sProvider;
        } else {
            self.theMenuItemAtTwo.title = @"Garbled response";
            self.theStatusBar.image     = [NSImage imageNamed:@"statusicon_error"];
        }
        self.running = NO;
    } onError:^(NSError *error) {
        DLog(@"error: %@", error);
        self.theMenuItemAtZero.title    = error.localizedDescription;
        self.theStatusBar.image         = [NSImage imageNamed:@"statusicon_error"];
        self.running = NO;
    }];

    [self.lovelyFetcherEngine fetchTrafficStats:@"foo" onCompletion:^(MKNetworkOperation *completedOperation) {
        NSError *parsingError           = nil;
        NSDictionary *dResponse         = [XMLReader dictionaryForXMLString:completedOperation.responseString
                                                                      error:&parsingError];
        if (dResponse && !parsingError) {
            /*
             NSString *sCDownloadRate =  dResponse[@"response"][@"CurrentDownloadRate"][@"text"];
             NSString *sTTime =  dResponse[@"response"][@"TotalConnectTime"][@"text"];
             NSString *sTUpload =  dResponse[@"response"][@"TotalUpload"][@"text"];
             NSString *sTDownload =  dResponse[@"response"][@"TotalDownload"][@"text"];
             NSString *sCTime =  dResponse[@"response"][@"CurrentConnectTime"][@"text"];
             NSString *sCUploadRate =  dResponse[@"response"][@"CurrentUploadRate"][@"text"];
             */
            NSString *sCUpload =  dResponse[@"response"][@"CurrentUpload"][@"text"];
            NSString *sCDownload =  dResponse[@"response"][@"CurrentDownload"][@"text"];

            NSString *fsCDown = [NSByteCountFormatter stringFromByteCount:sCDownload.intValue countStyle:NSByteCountFormatterCountStyleFile];
            NSString *fsCUp = [NSByteCountFormatter stringFromByteCount:sCUpload.intValue countStyle:NSByteCountFormatterCountStyleFile];
            self.theMenuItemAtOne.title =
            [NSString stringWithFormat:@"TX: %@/%@", fsCUp, fsCDown];
        } else {
            self.theMenuItemAtOne.title = @"Garbled response";
            self.theStatusBar.image = [NSImage imageNamed:@"statusicon_error"];
        }
        self.running = NO;
    } onError:^(NSError *error) {
        DLog(@"error: %@", error);
        self.theMenuItemAtZero.title = error.localizedDescription;
        self.theStatusBar.image = [NSImage imageNamed:@"statusicon_error"];
        self.running = NO;
    }];

}


// ---------------------------------------------------------------------------------------------------------------------
#pragma mark - Callback for coinnection stte changes.
// ---------------------------------------------------------------------------------------------------------------------
- (void)myReachabilityDidChangedMethod:(NSNotification *)notification
{
    Reachability *reachability = (Reachability *)notification.object;

    NetworkStatus internetStatus = [reachability currentReachabilityStatus];
    if (internetStatus != NotReachable) {

        // necessary to re-read the main.js?
        self.macroImporter.networkTypes = nil;

        DLog(@"Connected, so move on!");
        self.connected = YES;
    }
    else {
        DLog(@"No internet :-(");
        self.connected = NO;
    }
}


// ---------------------------------------------------------------------------------------------------------------------
- (IBAction)openSettingsPanel:(id)sender
{

    // get the ip address from preferences
    NSString *host = [[NSUserDefaults standardUserDefaults]objectForKey:@"mifi"];
    self.theIPField.stringValue = host;

    // set panel's position
    NSPoint pos;
    pos.x = [NSScreen mainScreen].frame.size.width - self.thePanel.frame.size.width - 50;
    pos.y = [NSScreen mainScreen].frame.size.height - self.thePanel.frame.size.height - 50;
    [self.thePanel setFrameOrigin:pos];

    // show panel and give 'em focus
    [self.thePanel makeKeyAndOrderFront:sender];
    [self.thePanel becomeKeyWindow];
}


// ---------------------------------------------------------------------------------------------------------------------
- (void)windowWillClose:(NSNotification *)notification
{
    NSLog(@"Window will close and it's text field's value is: %@", self.theIPField.stringValue);
    [[NSUserDefaults standardUserDefaults]setObject:self.theIPField.stringValue forKey:@"mifi"];
    [[NSUserDefaults standardUserDefaults]synchronize];
    [self initFetcher];

}


// ---------------------------------------------------------------------------------------------------------------------
- (BOOL)windowShouldClose:(id)sender
{
    return [self isValidIp];
}


// ---------------------------------------------------------------------------------------------------------------------
- (BOOL)isValidIp
{
    return YES;
}


// ---------------------------------------------------------------------------------------------------------------------
- (MacroImporter *)macroImporter
{
    if (_macroImporter == nil) {
        _macroImporter = [MacroImporter new];
    }
    return _macroImporter;
}


// ---------------------------------------------------------------------------------------------------------------------
- (void)initFetcher
{
    self.theMenuItemAtOne.title     = @"Waiting...";
    self.theMenuItemAtTwo.title     = @"Waiting...";
    self.theMenuItemAtThree.title   = @"Waiting...";


    if (self.theTimer != nil) {
        NSLog(@"Invalidate timer...");
        [self.theTimer invalidate];
    }

    self.macroImporter              = nil;
    self.lovelyFetcherEngine        = nil;
    NSString *host                  = [[NSUserDefaults standardUserDefaults]objectForKey:@"mifi"];
    self.lovelyFetcherEngine        = [[LovelyFetcherEngine alloc] initWithHostName:host];
    self.theTimer                   = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                                       target:self
                                                                     selector:@selector(payload:)
                                                                     userInfo:nil
                                                                      repeats:YES];
}


@end
