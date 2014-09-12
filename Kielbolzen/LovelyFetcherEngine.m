//
//  LovelyFetcherEngine.m
//  Kielbolzen
//
//  Created by Martin Kautz on 18.08.14.
//  Copyright (c) 2014 JAKOTA Design Group. All rights reserved.
//

#import "LovelyFetcherEngine.h"

@implementation LovelyFetcherEngine

- (void)fetchMainjs:(NSString *)credentials
       onCompletion:(MKNKResponseBlock)completionBlock
            onError:(MKNKErrorBlock)errorBlock
{
    NSDictionary *params;
    MKNetworkOperation *op = [self operationWithPath:@"js/main.js"
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

- (void)fetchStatus:(NSString *)credentials
                 onCompletion:(MKNKResponseBlock)completionBlock
                      onError:(MKNKErrorBlock)errorBlock
{
    
    NSDictionary *params;
    
    MKNetworkOperation *op = [self operationWithPath:@"api/monitoring/status"
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

- (void)fetchCurrentPlmn:(NSString *)credentials
            onCompletion:(MKNKResponseBlock)completionBlock
                 onError:(MKNKErrorBlock)errorBlock
{
    MKNetworkOperation *op = [self operationWithPath:@"api/net/current-plmn"
                                              params:nil
                                          httpMethod:@"GET"
                                                 ssl:NO];
    
    [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        completionBlock(completedOperation);
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        errorBlock(error);
    }];
    
    [self enqueueOperation:op];

}

- (void)fetchTrafficStats:(NSString *)credentials
             onCompletion:(MKNKResponseBlock)completionBlock
                  onError:(MKNKErrorBlock)errorBlock
{
    MKNetworkOperation *op = [self operationWithPath:@"api/monitoring/traffic-statistics"
                                              params:nil
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
