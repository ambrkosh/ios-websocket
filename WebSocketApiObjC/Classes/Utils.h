//
//  Utils.h
//  Various utils for SockJS Client use
//
//  Created by Ye David on 6/4/14.
//  Copyright (c) 2014 All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const CONST_NULL_ORIGIN;
extern NSString * const CONST_WEBSOCKET;
extern NSString * const CONST_XHR_STREAMING;
extern NSString * const CONST_XDR_STREAMING;
extern NSString * const CONST_IFRAME_EVENTSOURCE;
extern NSString * const CONST_IFRAME_HTMLFILE;
extern NSString * const CONST_XDR_POLLING;
extern NSString * const CONST_XHR_POLLING;
extern NSString * const CONST_IFRAME_XHR_POLLING;
extern NSString * const CONST_JSONP_POLLING;
extern NSString * const CONST_COOKIE_NEEDED;

@interface Utils : NSObject

// Generates a random string of the specified length
+ (NSString*)generateRandomString:(int)length;
// Generates a random number string of a specified length
+ (NSString*)generateRandomNumberString:(int)maxValue;
// Verifies that the url is a valid one
+ (BOOL)verifyUrl:(NSString*)url;
// Calculates the RTO
+ (float)calculateRto:(float)localRtt;
// Verifies which of the protocols passed in are valid ones
+ (NSArray*)detectProtocols:(NSArray*)protocolsWhitelist info:(NSDictionary*)info;
// Sets a user code
+ (BOOL)userSetCode:(int)code;
// Coverts it to a fully escaped valid vertx style message string
+ (NSString *)JSONString:(NSString *)aString;
@end
