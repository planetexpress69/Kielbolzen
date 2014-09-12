//
//  MacroImporter.h
//  Kielbolzen
//
//  Created by Chris Bünger on 10/09/14.
//  Copyright (c) 2014 JAKOTA Design Group. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MacroImporter : NSObject

@property (strong, nonatomic) NSMutableDictionary *networkTypes;
@property (strong, nonatomic) NSMutableDictionary *networkTypesEx;
@property (strong, nonatomic) NSMutableDictionary *plmnRat;

- (void)extractNetworkTypes:(NSString *)sPayload;
- (void)extractPlmnRat:(NSString *)sPayload;

@end
