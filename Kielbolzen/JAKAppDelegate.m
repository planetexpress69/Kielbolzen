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

- (void)awakeFromNib
{
    self.theMenuItemAtOne.title= @"Waiting...";
    self.theMenuItemAtTwo.title= @"Waiting...";
    self.theMenuItemAtThree.title= @"Waiting...";
}

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

    self.lovelyFetcherEngine = [[LovelyFetcherEngine alloc]initWithHostName:@"www.huaweimobilewifi.com"];
    self.macroImporter = [MacroImporter new];
    
    [self.lovelyFetcherEngine fetchMainjs:@"foo" onCompletion:^(MKNetworkOperation *completedOperation) {
        if (!self.isConnected) {
            self.theMenuItemAtZero.title = @"No connection. :-(";
            self.statusBar.image = [NSImage imageNamed:@"statusicon_error"];
            return;
        }
        
        if (self.isRunning)
            return;
        
        [self.macroImporter extractNetworkTypes: completedOperation.responseString];
        [self.macroImporter extractPlmnRat: completedOperation.responseString];
        
    } onError:^(NSError *error) {
        DLog(@"error: %@", error);
        self.theMenuItemAtZero.title = error.localizedDescription;
        self.statusBar.image = [NSImage imageNamed:@"statusicon_error"];
        self.running = NO;
    }];
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
    [self.lovelyFetcherEngine fetchStatus:@"foo" onCompletion:^(MKNetworkOperation *completedOperation) {
        
        NSError *parsingError   = nil;
        NSDictionary *dResponse = [XMLReader dictionaryForXMLString:completedOperation.responseString
                                                              error:&parsingError];
        NSMutableDictionary *macroNetTypes= nil;
        
        if (dResponse && !parsingError) {
            NSString *sLevel =  dResponse[@"response"][@"SignalStrength"][@"text"];
            NSString *sIcon =  dResponse[@"response"][@"SignalIcon"][@"text"];
            NSString *sStatus =  dResponse[@"response"][@"ServiceStatus"][@"text"];
            NSString *sBatLevel =  dResponse[@"response"][@"BatteryPercent"][@"text"];
            NSString *sNetworkType = dResponse[@"response"][@"CurrentNetworkType"][@"text"];
            NSString *sNetworkTypeEx = dResponse[@"response"][@"CurrentNetworkTypeEx"][@"text"];
            NSString *sNetMode = nil;
            
//            NSLog(@"%@,%d,%@,%d", sNetworkType, sNetworkType.length, sNetworkTypeEx, sNetworkTypeEx.length);
            if (sNetworkType.length > 0) {
                macroNetTypes= [self.macroImporter networkTypes];
            } else if (sNetworkTypeEx > 0) {
                macroNetTypes= [self.macroImporter networkTypesEx];
            }
            
            for (NSString *key in macroNetTypes) {
                if (((NSNumber *)macroNetTypes[key]).intValue == sNetworkType.intValue) {
                    sNetMode = key;
                }
            }
            
            NSString *sLevelStr = @"No Service";
            
            if (sStatus.intValue == 2) {
                sLevelStr= [NSString stringWithFormat:@"Level: %@%% (%@)", [NSString stringWithFormat:@"%d", (sLevel.intValue)], sNetMode];
            }
            self.theMenuItemAtZero.title = sLevelStr;
            self.theMenuItemAtThree.title =[NSString stringWithFormat:@"Battery: %@%%", [NSString stringWithFormat:@"%d", (sBatLevel.intValue)]];

            self.statusBar.image= [NSImage imageNamed:[NSString stringWithFormat:@"signal_%@.gif", sIcon]];
//            self.statusBar.title = [NSString stringWithFormat:@"%@%%", [NSString stringWithFormat:@"%d", (sLevel.intValue)]];
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

    [self.lovelyFetcherEngine fetchCurrentPlmn:@"foo" onCompletion:^(MKNetworkOperation *  completedOperation) {
        
        NSError *parsingError   = nil;
        NSDictionary *dResponse = [XMLReader dictionaryForXMLString:completedOperation.responseString
                                                              error:&parsingError];

        
        if (dResponse && !parsingError) {
            NSMutableDictionary *currentPlmnRats = [self.macroImporter plmnRat];
            
            NSString *sShort =  dResponse[@"response"][@"ShortName"][@"text"];
            NSString *sState =  dResponse[@"response"][@"State"][@"text"];
            NSString *sRat =  dResponse[@"response"][@"Rat"][@"text"];
            NSString *sPlmnRat = nil;
            
            for (NSString *key in currentPlmnRats) {
                if (((NSNumber *)currentPlmnRats[key]).intValue == sRat.intValue) {
                    sPlmnRat = key;
                }
            }
            NSString *sProvider= @"No Service";
            
            if (sShort.length) {
                sProvider= [NSString stringWithFormat:@"Provider: %@ (%@)", sShort, sPlmnRat];
            }
            self.theMenuItemAtTwo.title = sProvider;
            self.running = NO;
        } else {
            self.theMenuItemAtTwo.title = @"Garbled response";
            self.statusBar.image = [NSImage imageNamed:@"statusicon_error"];
            self.running = NO;
        }
        
    } onError:^(NSError *error) {
        DLog(@"error: %@", error);
        self.theMenuItemAtZero.title = error.localizedDescription;
        self.statusBar.image = [NSImage imageNamed:@"statusicon_error"];
        self.running = NO;
    }];

    [self.lovelyFetcherEngine fetchTrafficStats:@"foo" onCompletion:^(MKNetworkOperation *completedOperation) {

        NSError *parsingError   = nil;
        NSDictionary *dResponse = [XMLReader dictionaryForXMLString:completedOperation.responseString
                                                              error:&parsingError];
        if (dResponse && !parsingError) {
            NSString *sCTime =  dResponse[@"response"][@"CurrentConnectTime"][@"text"];
            NSString *sCUpload =  dResponse[@"response"][@"CurrentUpload"][@"text"];
            NSString *sCUploadRate =  dResponse[@"response"][@"CurrentUploadRate"][@"text"];
            NSString *sCDownload =  dResponse[@"response"][@"CurrentDownload"][@"text"];
            NSString *sCDownloadRate =  dResponse[@"response"][@"CurrentDownloadRate"][@"text"];
            NSString *sTTime =  dResponse[@"response"][@"TotalConnectTime"][@"text"];
            NSString *sTUpload =  dResponse[@"response"][@"TotalUpload"][@"text"];
            NSString *sTDownload =  dResponse[@"response"][@"TotalDownload"][@"text"];

            NSString *fsCDown = [NSByteCountFormatter stringFromByteCount:sCDownload.intValue countStyle:NSByteCountFormatterCountStyleFile];
            NSString *fsCUp = [NSByteCountFormatter stringFromByteCount:sCUpload.intValue countStyle:NSByteCountFormatterCountStyleFile];
            
            self.theMenuItemAtOne.title =
            [NSString stringWithFormat:@"TX: %@/%@", fsCUp, fsCDown];
            self.running = NO;
        } else {
            self.theMenuItemAtOne.title = @"Garbled response";
            self.statusBar.image = [NSImage imageNamed:@"statusicon_error"];
            self.running = NO;
        }

    } onError:^(NSError *error) {
        DLog(@"error: %@", error);
        self.theMenuItemAtZero.title = error.localizedDescription;
        self.statusBar.image = [NSImage imageNamed:@"statusicon_error"];
        self.running = NO;
    }];

//    [self.lovelyFetcherEngine fetchLevelForCredentials:@"foo" onCompletion:^(MKNetworkOperation *completedOperation) {
//
//        NSError *parsingError   = nil;
//        NSDictionary *dResponse = [XMLReader dictionaryForXMLString:completedOperation.responseString
//                                                              error:&parsingError];
//
//        if (dResponse && !parsingError) {
//            NSString *sLevel =  dResponse[@"payload"][@"value"][@"text"];
//            self.theMenuItemAtZero.title =
//            [NSString stringWithFormat:@"Level: %@%%", [NSString stringWithFormat:@"%d", (sLevel.intValue * 20)]];
//            self.statusBar.image = [NSImage imageNamed:[NSString stringWithFormat:@"statusicon_%@", sLevel]];
//            self.running = NO;
//        } else {
//            self.theMenuItemAtZero.title = @"Garbled response";
//            self.statusBar.image = [NSImage imageNamed:@"statusicon_error"];
//            self.running = NO;
//        }
//
//    } onError:^(NSError *error) {
//        DLog(@"error: %@", error);
//        self.theMenuItemAtZero.title = error.localizedDescription;
//        self.statusBar.image = [NSImage imageNamed:@"statusicon_error"];
//        self.running = NO;
//    }];

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
