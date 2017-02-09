//
//  Utils.m
//  OinkerClient
//
//  Created by Ye David on 6/4/14.
//  Copyright (c) 2014 All rights reserved.
//

#import "Utils.h"
#include <stdlib.h>

@implementation Utils

NSString * const CONST_NULL_ORIGIN = @"null_origin";
NSString * const CONST_WEBSOCKET = @"websocket";
NSString * const CONST_XHR_STREAMING = @"xhr-streaming";
NSString * const CONST_XDR_STREAMING = @"xdr-streaming";
NSString * const CONST_IFRAME_EVENTSOURCE = @"iframe-eventsource";
NSString * const CONST_IFRAME_HTMLFILE = @"iframe-htmlfile";
NSString * const CONST_XDR_POLLING = @"xdr-polling";
NSString * const CONST_XHR_POLLING = @"xhr-polling";
NSString * const CONST_IFRAME_XHR_POLLING = @"iframe-xhr-polling";
NSString * const CONST_JSONP_POLLING = @"jsonp-polling";
NSString * const CONST_COOKIE_NEEDED = @"cookie_needed";

const char randomStringChars[] = {'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','0','1','2','3','4','5'};

const NSString *allProtocols[] = {@"websocket",
    @"xdr-streaming",
    @"xhr-streaming",
    @"iframe-eventsource",
    @"iframe-htmlfile",
    @"xdr-polling",
    @"xhr-polling",
    @"iframe-xhr-polling",
    @"jsonp-polling"};

+ (NSString*)generateRandomString:(int)length {
    int baseStringLength = sizeof(randomStringChars)/sizeof(char);
    
    NSMutableString *randomString = [NSMutableString stringWithCapacity:length];
    
    for (int i = 0; i < length; ++i) {
        [randomString appendFormat:@"%c", randomStringChars[arc4random_uniform(baseStringLength - 1)]];
    }
    
    return [randomString copy];
}

+ (NSString*)generateRandomNumberString:(int)maxValue {
    int maxLength = [NSString stringWithFormat:@"%d", maxValue - 1].length;
    int randomNumber = arc4random_uniform(maxValue);
    NSString *randomNumberString = [NSString stringWithFormat:@"0%d", randomNumber];
    int randomNumberIndex = randomNumberString.length - maxLength;
    // Check if the random number index is valid for the string
    if (randomNumberIndex >= randomNumberString.length || randomNumberIndex < 0) {
        // If not then return an empty string
        return @"";
    }
    randomNumberString = [randomNumberString substringFromIndex:randomNumberString.length - maxLength];
    return [randomNumberString copy];
}

+ (BOOL)verifyUrl:(NSString*)url {
    NSString *urlRegEx = @"(http|https|ws|wss)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|:/]((\\w)*|([0-9]*)|([-|_])*))+";
    NSPredicate *urlTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", urlRegEx];
    return [urlTest evaluateWithObject:url];
}

+ (float)calculateRto:(float)localRtt {
    // In a local environment, when using IE8/9 and the `jsonp-polling`
    // transport the time needed to establish a connection (the time that pass
    // from the opening of the transport to the call of `_dispatchOpen`) is
    // around 200msec (the lower bound used in the article above) and this
    // causes spurious timeouts. For this reason we calculate a value slightly
    // larger than that used in the article.
    if (localRtt > 100) {
        return 4 * localRtt; // rto > 400msec
    } else {
        return 300 + localRtt;
    }
}

+ (NSArray*)detectProtocols:(NSArray*)protocolsWhitelist info:(NSDictionary*)info {
    NSMutableArray *protocols = [NSMutableArray array];
    NSMutableArray *result = [NSMutableArray array];
    if (!protocolsWhitelist || protocolsWhitelist.count == 0) {
        int length = sizeof(allProtocols)/sizeof(NSString*);
        for (int i; i < length; ++i) {
            [protocols addObject:allProtocols[i]];
        }
    } else {
        [protocols addObjectsFromArray:protocolsWhitelist];
    }
    
    // 1. websocket
    if ([info objectForKey:CONST_WEBSOCKET] && [(NSNumber*)[info objectForKey:CONST_WEBSOCKET] boolValue]) {
        [result addObject:CONST_WEBSOCKET];
    }
    
    // 2. Streaming
    if ([info objectForKey:CONST_XHR_STREAMING]
        && ([info objectForKey:CONST_NULL_ORIGIN] && ![(NSNumber*)[info objectForKey:CONST_NULL_ORIGIN] boolValue])) {
        [result addObject:CONST_XHR_STREAMING];
    } else {
        if ([info objectForKey:CONST_XDR_STREAMING]
            && ([info objectForKey:CONST_COOKIE_NEEDED] && ![(NSNumber*)[info objectForKey:CONST_COOKIE_NEEDED] boolValue])
            && ([info objectForKey:CONST_NULL_ORIGIN] && ![(NSNumber*)[info objectForKey:CONST_NULL_ORIGIN] boolValue])) {
            [result addObject:CONST_XDR_STREAMING];
        } else {
            if ([info objectForKey:CONST_IFRAME_EVENTSOURCE]) {
                [result addObject:CONST_IFRAME_EVENTSOURCE];
            }
            if ([info objectForKey:CONST_IFRAME_HTMLFILE]) {
                [result addObject:CONST_IFRAME_HTMLFILE];
            }
        }
    }
    
    // 3. Polling
    if ([info objectForKey:CONST_XHR_POLLING]
        && ([info objectForKey:CONST_NULL_ORIGIN] && ![(NSNumber*)[info objectForKey:CONST_NULL_ORIGIN] boolValue])) {
        [result addObject:CONST_XHR_POLLING];
    } else {
        if ([info objectForKey:CONST_XDR_POLLING]
            && ([info objectForKey:CONST_COOKIE_NEEDED] && ![(NSNumber*)[info objectForKey:CONST_COOKIE_NEEDED] boolValue])
            && ([info objectForKey:CONST_NULL_ORIGIN] && ![(NSNumber*)[info objectForKey:CONST_NULL_ORIGIN] boolValue])) {
            [result addObject:CONST_XDR_POLLING];
        } else {
            if ([info objectForKey:CONST_IFRAME_XHR_POLLING]) {
                [result addObject:CONST_IFRAME_XHR_POLLING];
            }
            if ([info objectForKey:CONST_JSONP_POLLING]) {
                [result addObject:CONST_JSONP_POLLING];
            }
        }
    }
    
    return [result copy];
}

+ (BOOL)userSetCode:(int)code {
    return code == 1000 || (code >= 3000 && code <= 4999);
}

// JSON string
+ (NSString *)JSONString:(NSString *)aString {
    NSMutableString *s = [NSMutableString stringWithString:aString];
    [s replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
    [s replaceOccurrencesOfString:@"/" withString:@"\\/" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
    [s replaceOccurrencesOfString:@"\n" withString:@"\\n" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
    [s replaceOccurrencesOfString:@"\b" withString:@"\\b" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
    [s replaceOccurrencesOfString:@"\f" withString:@"\\f" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
    [s replaceOccurrencesOfString:@"\r" withString:@"\\r" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
    [s replaceOccurrencesOfString:@"\t" withString:@"\\t" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
    // Add quotes to the begining and end if it doesn't exist
    if (![[s substringToIndex:1] isEqualToString:@"\""]) {
        s = [NSMutableString stringWithFormat:@"%@%@%@", @"\"", s, @"\""];
    }
    return [NSString stringWithString:s];
}

@end
