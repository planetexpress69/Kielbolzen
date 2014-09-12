//
//  LovelyFetcherEngine.h
//  Kielbolzen
//
//  Created by Martin Kautz on 18.08.14.
//  Copyright (c) 2014 JAKOTA Design Group. All rights reserved.
//

#import "MKNetworkEngine.h"

@interface LovelyFetcherEngine : MKNetworkEngine

- (void)fetchMainjs:(NSString *)credentials
       onCompletion:(MKNKResponseBlock)completionBlock
            onError:(MKNKErrorBlock)errorBlock;

- (void)fetchStatus:(NSString *)credentials
      onCompletion:(MKNKResponseBlock)completionBlock
           onError:(MKNKErrorBlock)errorBlock;

- (void)fetchCurrentPlmn:(NSString *)credentials
                 onCompletion:(MKNKResponseBlock)completionBlock
                      onError:(MKNKErrorBlock)errorBlock;

- (void)fetchTrafficStats:(NSString *)credentials
             onCompletion:(MKNKResponseBlock)completionBlock
                  onError:(MKNKErrorBlock)errorBlock;


@end
