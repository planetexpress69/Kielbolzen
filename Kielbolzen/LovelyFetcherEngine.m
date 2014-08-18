//
//  LovelyFetcherEngine.m
//  Kielbolzen
//
//  Created by Martin Kautz on 18.08.14.
//  Copyright (c) 2014 JAKOTA Design Group. All rights reserved.
//

#import "LovelyFetcherEngine.h"

@implementation LovelyFetcherEngine

- (void)fetchLevelForCredentials:(NSString *)credentials
                    onCompletion:(MKNKResponseBlock)completionBlock
                         onError:(MKNKErrorBlock)errorBlock
{

    NSDictionary *params = @{ @"credentials" : credentials };

    MKNetworkOperation *op = [self operationWithPath:@"rand.php"
                                              params:params
                                          httpMethod:@"GET"
                                                 ssl:NO];

    [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        completionBlock(completedOperation);
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        errorBlock(error);
    }];

    [self enqueueOperation:op];

}

@end
