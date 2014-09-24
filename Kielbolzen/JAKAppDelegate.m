//
//  JAKAppDelegate.m
//  Kielbolzen
//
//  Created by Martin Kautz on 15.08.14.
//  Copyright (c) 2014 JAKOTA Design Group. All rights reserved.
//

#import "JAKAppDelegate.h"
#import <XMLReader/XMLReader.h>

NSString * const kbHostKey      = @"Host";
NSString * const kbIntervalKey  = @"Interval";

NSString * const kbSignalLevelChangedNotification   = @"kbSignalLevelChangedNotification";
NSString * const kbSignalIconChangedNotification    = @"kbSignalIconChangedNotification";
NSString * const kbBatteryLevelChangedNotification  = @"kbBatteryLevelChangedNotification";
NSString * const kbNetworkTypeChangedNotification   = @"kbNetworkTypeChangedNotification";
NSString * const kbPlmnRatChangedNotification       = @"kbPlmnRatChangedNotification";
NSString * const kbProviderChangedNotification      = @"kbProviderChangedNotification";
NSString * const kbBytesInOutChangedNotification    = @"kbBytesInOutChangedNotification";

@implementation JAKAppDelegate


// ---------------------------------------------------------------------------------------------------------------------
#pragma mark - Lifecycle
// ---------------------------------------------------------------------------------------------------------------------
- (instancetype)init
{
    if (self = [super init]) {
        _status= 0;
        _sigLevel= 0;
        _sigIcon= 0;
        _batLevel= 0;
        _bytesIn= 0;
        _bytesOut= 0;
        _plmnRat= @"0";
        _provider= @"";
        _netType= @"";
        _netTypeEx= @"";
        
        _noService= [[NSMutableAttributedString alloc] initWithString:@"No Service"];
        [_noService addAttribute:NSFontAttributeName
                           value:[NSFont menuBarFontOfSize:12]
                           range:NSMakeRange(0, 10)];
        
        _error= [[NSMutableAttributedString alloc] initWithString:@"!!! Error !!!"];
        [_error addAttribute:NSFontAttributeName
                       value:[NSFont menuBarFontOfSize:12]
                       range:NSMakeRange(0, 13)];
        
        _sigIcons= [NSArray arrayWithObjects: @"○○○○○", @"●○○○○", @"●●○○○", @"●●●○○", @"●●●●○", @"●●●●●", nil];
        
    }
    return self;
}

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
    self.theStatusBar               = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.theStatusBar.attributedTitle  = _noService;
    self.theStatusBar.menu          = self.theMenu;
    self.theStatusBar.highlightMode = YES;
    self.thePanel.delegate          = self;

    Reachability *reachabilityInfo;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(myReachabilityDidChangedMethod:)
                                                 name:kReachabilityChangedNotification
                                               object:reachabilityInfo];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(signalLevelDidChangeMethod:)
                                                 name:kbSignalLevelChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(signalLevelDidChangeMethod:)
                                                 name:kbNetworkTypeChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(signalIconDidChangeMethod:)
                                                 name:kbSignalIconChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(signalIconDidChangeMethod:)
                                                 name:kbPlmnRatChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(batteryLevelDidChangeMethod:)
                                                 name:kbBatteryLevelChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(providerDidChangeMethod:)
                                                 name:kbProviderChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(bytesInOutDidChangeMethod:)
                                                 name:kbBytesInOutChangedNotification object:nil];

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
        self.theStatusBar.attributedTitle = _error;
        return;
    }

    // we're connected but haven't gotten stuff we rely on
    if (self.macroImporter.networkTypes == nil) {
        [self.lovelyFetcherEngine fetchMainjs:@"foo" onCompletion:^(MKNetworkOperation *completedOperation) {
            if (!self.isConnected) {
                self.theMenuItemAtZero.title = @"No connection. :-(";
                self.theStatusBar.attributedTitle = _error;
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
            self.theStatusBar.attributedTitle = _error;
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

        if (dResponse && !parsingError) {
            NSString *sLevel =  dResponse[@"response"][@"SignalStrength"][@"text"];
            NSString *sIcon =  dResponse[@"response"][@"SignalIcon"][@"text"];
            NSString *sBatLevel =  dResponse[@"response"][@"BatteryPercent"][@"text"];
            NSString *sNetworkType = dResponse[@"response"][@"CurrentNetworkType"][@"text"];
            NSString *sNetworkTypeEx = dResponse[@"response"][@"CurrentNetworkTypeEx"][@"text"];
            
            _status= ((NSString *)dResponse[@"response"][@"ServiceStatus"][@"text"]).intValue;
            
            if (_sigLevel != sLevel.intValue) {
                _sigLevel= sLevel.intValue;
                [[NSNotificationCenter defaultCenter] postNotificationName: kbSignalLevelChangedNotification object:self];
            }
            
            if (_sigIcon != sIcon.intValue)
            {
                _sigIcon= sIcon.intValue;
                [[NSNotificationCenter defaultCenter] postNotificationName:kbSignalIconChangedNotification object:self];
            }
            
            if (_batLevel != sBatLevel.intValue) {
                _batLevel= sBatLevel.intValue;
                [[NSNotificationCenter defaultCenter] postNotificationName:kbBatteryLevelChangedNotification
                                                                    object:self];
            }
            
            if (sNetworkType && ![_netType isEqualToString:sNetworkType]) {
                _netType= [NSString stringWithString:sNetworkType];
                [[NSNotificationCenter defaultCenter] postNotificationName:kbNetworkTypeChangedNotification
                                                                    object:self];
            }
            
            if (sNetworkTypeEx && ![_netTypeEx isEqualToString:sNetworkTypeEx])
            {
                _netTypeEx= [NSString stringWithString:sNetworkTypeEx];
                [[NSNotificationCenter defaultCenter] postNotificationName:kbNetworkTypeChangedNotification
                                                                    object:self];
            }
        } else {
            self.theMenuItemAtZero.title = @"Garbled response";
            self.theStatusBar.attributedTitle = _error;
        }
        self.running = NO;
    } onError:^(NSError *error) {
        DLog(@"error: %@", error);
        self.theMenuItemAtZero.title = error.localizedDescription;
        self.theStatusBar.attributedTitle = _error;
        self.running = NO;
    }];


    [self.lovelyFetcherEngine fetchCurrentPlmn:@"foo" onCompletion:^(MKNetworkOperation *completedOperation) {

        NSError *parsingError   = nil;
        NSDictionary *dResponse = [XMLReader dictionaryForXMLString:completedOperation.responseString
                                                              error:&parsingError];

        if (dResponse && !parsingError) {
            NSString *sShort =  dResponse[@"response"][@"ShortName"][@"text"];
            NSString *sPlmnRat =  dResponse[@"response"][@"Rat"][@"text"];
            
            if (sPlmnRat && ![_plmnRat isEqualToString:sPlmnRat]) {
                _plmnRat= [NSString stringWithString:sPlmnRat];
                [[NSNotificationCenter defaultCenter] postNotificationName:kbPlmnRatChangedNotification
                                                                    object:self];
            }
            
            if (sShort && ![_provider isEqualToString:sShort]) {
                _provider= [NSString stringWithString:sShort];
                [[NSNotificationCenter defaultCenter] postNotificationName:kbProviderChangedNotification
                                                                    object:self];
            }
        } else {
            self.theMenuItemAtTwo.title = @"Garbled response";
            self.theStatusBar.attributedTitle = _error;
        }
        self.running = NO;
    } onError:^(NSError *error) {
        DLog(@"error: %@", error);
        self.theMenuItemAtZero.title    = error.localizedDescription;
        self.theStatusBar.attributedTitle         = _error;
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
            NSString *sBytesOut  =  dResponse[@"response"][@"CurrentUpload"][@"text"];
            NSString *sBytesIn =  dResponse[@"response"][@"CurrentDownload"][@"text"];
            
            if (_bytesIn != sBytesIn.intValue) {
                _bytesIn= sBytesIn.intValue;
                [[NSNotificationCenter defaultCenter] postNotificationName:kbBytesInOutChangedNotification object:self];
            }
            
            if (_bytesOut != sBytesOut.intValue) {
                _bytesOut= sBytesOut.intValue;
                [[NSNotificationCenter defaultCenter] postNotificationName:kbBytesInOutChangedNotification object:self];
            }
        } else {
            self.theMenuItemAtOne.title = @"Garbled response";
            self.theStatusBar.attributedTitle = _error;
        }
        self.running = NO;
    } onError:^(NSError *error) {
        DLog(@"error: %@", error);
        self.theMenuItemAtZero.title = error.localizedDescription;
        self.theStatusBar.attributedTitle = _error;
        self.running = NO;
    }];

}

- (void)signalLevelDidChangeMethod:(NSNotification *)notification
{
    DLog(@"Received notification: %@", notification);
    
    NSString *sNetMode = [[self.macroImporter networkTypes] objectForKey: _netTypeEx.length > 0 ? _netTypeEx : _netType];
    
    self.theMenuItemAtZero.title = _status==2 ? [NSString stringWithFormat: @"Level: %d%% (%@)", _sigLevel, sNetMode] : @"No Service";
}

- (void)signalIconDidChangeMethod:(NSNotification *)notification
{
    DLog(@"Received notification: %@", notification);
    
    NSString *sPlmnRat = [[self.macroImporter plmnRat] objectForKey: _plmnRat];
    
    self.theStatusBar.image= nil;
    if (_sigLevel > 0) {
        NSString *s= [NSString stringWithFormat:@"%@ %@", _sigIcons[_sigIcon], sPlmnRat?sPlmnRat:@""];
        NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:s];
        
        [attrStr addAttribute:NSFontAttributeName
                        value:[NSFont menuBarFontOfSize:12]
                        range:NSMakeRange(0, attrStr.length)];
        
        self.theStatusBar.attributedTitle = attrStr;
        
    } else {
        self.theStatusBar.attributedTitle= _noService;
    }
}

- (void)batteryLevelDidChangeMethod:(NSNotification *)notification
{
    DLog(@"Received notification: %@", notification);
    self.theMenuItemAtThree.title =[NSString stringWithFormat:@"Battery: %d%%", _batLevel];
}

- (void)providerDidChangeMethod:(NSNotification *)notification
{
    DLog(@"Received notification: %@", notification);
    self.theMenuItemAtTwo.title = _provider.length ? [NSString stringWithFormat:@"Provider: %@", _provider] : @"No Service";
}

- (void)bytesInOutDidChangeMethod:(NSNotification *)notification
{
    DLog(@"Received notification: %@", notification);
    self.theMenuItemAtOne.title = [NSString stringWithFormat:@"TX: %@/%@",
                                   [NSByteCountFormatter stringFromByteCount:_bytesIn countStyle:NSByteCountFormatterCountStyleFile],
                                   [NSByteCountFormatter stringFromByteCount:_bytesOut countStyle:NSByteCountFormatterCountStyleFile]];
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
