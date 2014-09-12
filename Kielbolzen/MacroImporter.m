//
//  MacroImporter.m
//  Kielbolzen
//
//  Created by Chris Bünger on 10/09/14.
//  Copyright (c) 2014 JAKOTA Design Group. All rights reserved.
//

#import "macroImporter.h"

@implementation MacroImporter

- (instancetype)init
{
    self= [super init];
    if (self) {
        //NSLog(@"Marcoimport init.");
    }
    return self;
}

- (void)extractPlmnRat:(NSString *)sPayload
{
    NSError *regexError         = nil;
    NSString *sPattern          = @"MACRO_CURRENT_NETWOORK_([0-9A-Z _]{1,})=[ ]{1,}'([0-9]{1,})'";
    NSRegularExpression *regex  = [NSRegularExpression regularExpressionWithPattern:sPattern
                                                                            options:NSRegularExpressionCaseInsensitive
                                                                              error:&regexError];
    if (sPayload == nil) {
        NSLog(@"Gimme some real food...");
        return;
    }
    
    if (regexError) {
        NSLog(@"Error initializing regex...");
        return;
    }
    
    NSMutableDictionary *dResult    = [NSMutableDictionary new];
    NSArray *aMatches               = [regex matchesInString:sPayload options:0 range:NSMakeRange(0, [sPayload length])];
    
    for (NSTextCheckingResult *match in aMatches) {
        NSString *matchString = [[sPayload substringWithRange: [match rangeAtIndex:1]]
                                 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSNumber *matchNumber = [NSNumber numberWithInt: [sPayload substringWithRange: [match rangeAtIndex:2]].intValue];
        
        [dResult setObject:matchNumber forKey:matchString];
        
    }
    self.plmnRat = dResult.allKeys.count > 0 ? dResult : nil;

}

- (void)extractNetworkTypes:(NSString *)sPayload
{
    NSError *regexError         = nil;
    NSString *sPattern          = @"MACRO_NET_WORK_TYPE_[(EX_)]{0,}([0-9A-Z _]{1,})=[ ]{1,}'([0-9]{1,})'";
    NSRegularExpression *regex  = [NSRegularExpression regularExpressionWithPattern:sPattern
                                                                            options:NSRegularExpressionCaseInsensitive
                                                                              error:&regexError];
    if (sPayload == nil) {
        NSLog(@"Gimme some real food...");
        return;
    }
    
    if (regexError) {
        NSLog(@"Error initializing regex...");
        return;
    }
    
    NSMutableDictionary *dResult    = [NSMutableDictionary new];
    NSArray *aMatches               = [regex matchesInString:sPayload options:0 range:NSMakeRange(0, [sPayload length])];
        
    for (NSTextCheckingResult *match in aMatches) {
        NSString *matchString = [[sPayload substringWithRange: [match rangeAtIndex:1]]
                                  stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSNumber *matchNumber = [NSNumber numberWithInt: [sPayload substringWithRange: [match rangeAtIndex:2]].intValue];
        //NSLog(@"%@, %@, %@", [sPayload substringWithRange: [match rangeAtIndex:0]],
        //     [sPayload substringWithRange: [match rangeAtIndex:1]],
        //      [sPayload substringWithRange: [match rangeAtIndex:2]]);
        [dResult setObject:matchNumber forKey:matchString];

    }
    self.networkTypes = dResult.allKeys.count > 0 ? dResult : nil;
}


@end