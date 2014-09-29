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
- (instancetype)init
{
    if (self = [super init]) {

        _serviceStatus  = 0;
        _signalLevel    = 0;
        _signalIcon     = 0;
        _batteryLevel   = 0;
        _bytesIn        = 0;
        _bytesOut       = 0;
        _plmnRat        = @"0";
        _provider       = @"";
        _netType        = @"";
        _netTypeEx      = @"";

        _noService      = [[NSMutableAttributedString alloc] initWithString:@"No Service"];
        [_noService addAttribute:NSFontAttributeName
                           value:[NSFont menuBarFontOfSize:12]
                           range:NSMakeRange(0, _noService.length)];

        _error          = [[NSMutableAttributedString alloc] initWithString:@"!!! Error !!!"];
        [_error addAttribute:NSFontAttributeName
                       value:[NSFont menuBarFontOfSize:12]
                       range:NSMakeRange(0, _error.length)];

        _noDevice          = [[NSMutableAttributedString alloc] initWithString:@"No device!"];
        [_noDevice addAttribute:NSFontAttributeName
                       value:[NSFont menuBarFontOfSize:12]
                       range:NSMakeRange(0, _noDevice.length)];

        _deviceInit          = [[NSMutableAttributedString alloc] initWithString:@"Init device..."];
        [_deviceInit addAttribute:NSFontAttributeName
                          value:[NSFont menuBarFontOfSize:12]
                          range:NSMakeRange(0, _deviceInit.length)];

        _sigIcons       = @[@"○○○○○",
                            @"●○○○○",
                            @"●●○○○",
                            @"●●●○○",
                            @"●●●●○",
                            @"●●●●●"];

        self.container  = [NSMutableDictionary new];

    }
    return self;
}

- (void)dealloc
{

}

// ---------------------------------------------------------------------------------------------------------------------
- (void)awakeFromNib
{
    self.theStatusBar                   = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.theStatusBar.attributedTitle   = _noService;
    self.theStatusBar.menu              = self.theMenu;
    self.theStatusBar.highlightMode     = YES;
    // --------------------------------------------------------------------------------------
    self.theMenuItemAtZero.title        = @"Initializing...";
    self.theMenuItemAtOne.title         = @"Waiting...";
    self.theMenuItemAtTwo.title         = @"Waiting...";
    self.theMenuItemAtThree.title       = @"Waiting...";
    [self.theMenuItemSettings setEnabled:YES];
    // --------------------------------------------------------------------------------------
    self.connected                      = NO;
    self.running                        = NO;
    // --------------------------------------------------------------------------------------
    self.thePanel.delegate              = self;
    // --------------------------------------------------------------------------------------
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"mifi"]) {
        [[NSUserDefaults standardUserDefaults] setObject:@"192.168.1.1" forKey:@"mifi"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}


// ---------------------------------------------------------------------------------------------------------------------
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self startTimerWithInterval:1.0];
}


// ---------------------------------------------------------------------------------------------------------------------
#pragma mark - Init the fetcher with the current hostname and start the timer...
// ---------------------------------------------------------------------------------------------------------------------
- (void)startTimerWithInterval:(CGFloat)interval
{
    NSString *host                  = [[NSUserDefaults standardUserDefaults]objectForKey:@"mifi"];
    self.lovelyFetcherEngine        = [[LovelyFetcherEngine alloc] initWithHostName:host];
    self.theTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(payload:) userInfo:nil repeats:YES];
}


// ---------------------------------------------------------------------------------------------------------------------
#pragma mark - Payload - fetching some stuff from the Mifi
// ---------------------------------------------------------------------------------------------------------------------
- (IBAction)payload:(id)sender
{
    NSLog(@"Tick!");

    // we're not connected, so tell the UI and ping
    if (!self.isConnected) {

        [self setUIToNotConnected];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{

            NSString *sURL = [NSString stringWithFormat:@"http://%@/js/main.js", [[NSUserDefaults standardUserDefaults] objectForKey:@"mifi"]];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:sURL]
                                                                   cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                               timeoutInterval:5.0];

            [request setHTTPMethod:@"GET"];

            NSURLResponse   *response   = [NSURLResponse new];
            NSError         *error      = nil;

            [NSURLConnection sendSynchronousRequest:request
                                  returningResponse:&response
                                              error:&error];

            if (response && !error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"Connected!");
                    self.connected = YES;
                });

            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"Not connected!");
                    self.connected = NO;
                });

            }
        });
    } else {

        //[self updateUI];

    // we're connected but haven't gotten stuff we rely on
    if (self.macroImporter.networkTypes == nil) {
        [self.lovelyFetcherEngine fetchMainjs:@"foo" onCompletion:^(MKNetworkOperation *completedOperation) {
            [self.macroImporter extractNetworkTypes:completedOperation.responseString];
            [self.macroImporter extractPlmnRat:completedOperation.responseString];
            NSLog(@"Could have gotten the stuff from mains.js I'm interested in. Nice!");
            self.theStatusBar.attributedTitle = _deviceInit;
        } onError:^(NSError *error) {
            DLog(@"error: %@", error);
            self.theMenuItemAtZero.title = error.localizedDescription;
            self.theMenuItemAtOne.title= @"RX/TX: -/-";
            self.theMenuItemAtTwo.title= @"Provider: -";
            self.theMenuItemAtThree.title= @"Battery: -";
            self.theStatusBar.attributedTitle = _error;
            self.connected = NO;
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
            NSString *sLevel            = dResponse[@"response"][@"SignalStrength"][@"text"];
            NSString *sIcon             = dResponse[@"response"][@"SignalIcon"][@"text"];
            NSString *sBatLevel         = dResponse[@"response"][@"BatteryPercent"][@"text"];
            NSString *sNetworkType      = dResponse[@"response"][@"CurrentNetworkType"][@"text"];
            NSString *sNetworkTypeEx    = dResponse[@"response"][@"CurrentNetworkTypeEx"][@"text"];

            _serviceStatus = ((NSString *)dResponse[@"response"][@"ServiceStatus"][@"text"]).intValue;

            if (_signalLevel != sLevel.intValue) {
                _signalLevel = sLevel.intValue;
            }

            if (_signalIcon != sIcon.intValue) {
                _signalIcon = sIcon.intValue;
            }

            if (_batteryLevel != sBatLevel.intValue) {
                _batteryLevel = sBatLevel.intValue;
            }

            if (sNetworkType && ![_netType isEqualToString:sNetworkType]) {
                _netType = [NSString stringWithString:sNetworkType];
            }

            if (sNetworkTypeEx && ![_netTypeEx isEqualToString:sNetworkTypeEx]) {
                _netTypeEx = [NSString stringWithString:sNetworkTypeEx];
            }

        } else {
            self.theMenuItemAtZero.title        = @"Garbled response";
            self.theStatusBar.attributedTitle   = _error;
        }
        self.running = NO;
        [self updateUI];

    } onError:^(NSError *error) {
        DLog(@"error: %@", error);
        self.theMenuItemAtZero.title        = error.localizedDescription;
        self.theStatusBar.attributedTitle   = _error;
        self.running = NO;
        self.connected = NO;
    }];


    [self.lovelyFetcherEngine fetchCurrentPlmn:@"foo" onCompletion:^(MKNetworkOperation *completedOperation) {

        NSError *parsingError   = nil;
        NSDictionary *dResponse = [XMLReader dictionaryForXMLString:completedOperation.responseString
                                                              error:&parsingError];
        if (dResponse && !parsingError) {
            NSString *sShort    = dResponse[@"response"][@"ShortName"][@"text"];
            NSString *sPlmnRat  = dResponse[@"response"][@"Rat"][@"text"];

            if (sPlmnRat && ![_plmnRat isEqualToString:sPlmnRat]) {
                _plmnRat = [NSString stringWithString:sPlmnRat];
            }

            if (sShort && ![_provider isEqualToString:sShort]) {
                _provider = [NSString stringWithString:sShort];
            }

        } else {
            self.theMenuItemAtTwo.title         = @"Garbled response";
            self.theStatusBar.attributedTitle   = _error;
        }
        self.running = NO;
        [self updateUI];


    } onError:^(NSError *error) {
        self.theMenuItemAtZero.title        = error.localizedDescription;
        self.theStatusBar.attributedTitle   = _error;
        self.running                        = NO;
        self.connected                      = NO;
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
            NSString *sBytesOut = dResponse[@"response"][@"CurrentUpload"][@"text"];
            NSString *sBytesIn  = dResponse[@"response"][@"CurrentDownload"][@"text"];

            if (_bytesIn != sBytesIn.intValue) {
                _bytesIn= sBytesIn.intValue;
            }

            if (_bytesOut != sBytesOut.intValue) {
                _bytesOut= sBytesOut.intValue;
            }
        } else {
            self.theMenuItemAtOne.title         = @"Garbled response";
            self.theStatusBar.attributedTitle   = _error;
        }
        self.running = NO;
        [self updateUI];


    } onError:^(NSError *error) {
        self.theMenuItemAtZero.title        = error.localizedDescription;
        self.theStatusBar.attributedTitle   = _error;
        self.running                        = NO;

    }];
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
    self.connected = NO;
    [self.theTimer invalidate];
    self.theTimer = nil;
    [self startTimerWithInterval:1.0];
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

    NSLog(@"Init fetcher...");

    self.theMenuItemAtOne.title     = @"Waiting...";
    self.theMenuItemAtTwo.title     = @"Waiting...";
    self.theMenuItemAtThree.title   = @"Waiting...";

    if (self.theTimer != nil && self.theTimer.isValid) {
        NSLog(@"Invalidate timer...");
        [self.theTimer invalidate];
        [self updateUI];
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

- (void)updateUI
{
    if (_signalLevel > 0) {
        NSString *s = [NSString stringWithFormat:@"%@ %@", _sigIcons[_signalIcon], [[self.macroImporter plmnRat]objectForKey:_plmnRat] ? [[self.macroImporter plmnRat]objectForKey:_plmnRat] : @""];

        if (![s isEqualToString:self.theStatusBar.title]) {
            NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:s];
            [attrStr addAttribute:NSFontAttributeName
                            value:[NSFont menuBarFontOfSize:12]
                            range:NSMakeRange(0, attrStr.length)];
            self.theStatusBar.attributedTitle = attrStr;
        }

    } else {
        if (![_noService.string isEqualToString:self.theStatusBar.title]) {
            self.theStatusBar.attributedTitle= _noService;
        }
    }

    // -----------------------------------------------------------------------------------------------------------------
    NSString *sNetMode = [[self.macroImporter networkTypes] objectForKey: _netTypeEx.length > 0 ? _netTypeEx : _netType];
    NSString *sServiceStatus = _serviceStatus == 2 ? [NSString stringWithFormat:@"Level: %d%% (%@)", _signalLevel, sNetMode] : @"No Service";
    if (![sServiceStatus isEqualToString:self.theMenuItemAtZero.title]) {
        self.theMenuItemAtZero.title = sServiceStatus;
    }

    // -----------------------------------------------------------------------------------------------------------------
    NSString *sTxRx = [NSString stringWithFormat:@"RX/TX: %@/%@",
                       [NSByteCountFormatter stringFromByteCount:_bytesIn
                                                      countStyle:NSByteCountFormatterCountStyleFile],
                       [NSByteCountFormatter stringFromByteCount:_bytesOut
                                                      countStyle:NSByteCountFormatterCountStyleFile]];
    if (![sTxRx isEqualToString:self.theMenuItemAtOne.title]) {
        self.theMenuItemAtOne.title = sTxRx;
    }

    // -----------------------------------------------------------------------------------------------------------------
    NSString *sProvider = _provider.length ? [NSString stringWithFormat:@"Provider: %@", _provider] : @"No Service";
    if (![sProvider isEqualToString:self.theMenuItemAtTwo.title]) {
        self.theMenuItemAtTwo.title = sProvider;
    }
    
    // -----------------------------------------------------------------------------------------------------------------
    NSString *sBattery = [NSString stringWithFormat:@"Battery: %d%%", _batteryLevel];
    if (![sBattery isEqualToString:self.theMenuItemAtThree.title]) {
        self.theMenuItemAtThree.title = sBattery;
    }
}

- (void)setConnected:(BOOL)connected
{
    _connected = connected;
    if (_connected) {
        // kill the fast timer and start with a mellow one....
        [self.theTimer invalidate];
        self.theTimer = nil;
        [self startTimerWithInterval:5.0];
    } 
    self.theStatusBar.attributedTitle = _connected ? _deviceInit : _noDevice;
}

- (BOOL)isConnected {
    return _connected;
}

- (void)setUIToNotConnected
{
    self.theStatusBar.attributedTitle   = _noDevice;
    self.theMenuItemAtZero.title        = @"No connection. :-(";
    self.theMenuItemAtOne.title         = @"RX/TX: -/-";
    self.theMenuItemAtTwo.title         = @"Provider: -";
    self.theMenuItemAtThree.title       = @"Battery: -";
}

@end
