//
//  LovelyFetcherEngine.h
//  Kielbolzen
//
//  Created by Martin Kautz on 18.08.14.
//  Copyright (c) 2014 JAKOTA Design Group. All rights reserved.
//

#import "MKNetworkEngine.h"

@interface LovelyFetcherEngine : MKNetworkEngine
- (void)fetchLevelForCredentials:(NSString *)credentials
                    onCompletion:(MKNKResponseBlock)completionBlock
                         onError:(MKNKErrorBlock)errorBlock;

@end
