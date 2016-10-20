//
//  WebSocketHandler.h
//  OinkerClient
//
//  Created by Ye David on 6/2/14.
//  Copyright (c) 2014 All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SockJSClient.h"

extern NSString * const CONST_FUNCTION;
extern NSString * const CONST_STRING;
extern NSString * const CONST_TYPE;
extern NSString * const CONST_ADDRESS;
extern NSString * const CONST_BODY;
extern NSString * const CONST_REPLY_HANDLER;
extern NSString * const CONST_REPLY_ADDRESS;
extern NSString * const CONST_REPLY_SEND;
extern NSString * const CONST_REGISTER;
extern NSString * const CONST_UNREGISTER;
extern NSString * const CONST_SEND;
extern NSString * const CONST_PUBLISH;

@protocol WebSocketHandlerDelegate <NSObject>
// Fires whenever there is an error
- (void)errorEvent:(NSString*)errorMessage;
// Fires whenever there is a message
- (void)messageEvent:(NSString*)message;

@optional
// Fires whenever a connection is opened
- (void)openEvent;
// Fires whenever a heartbeat ping is received
- (void)heatbeatEvent;
// Fires whenever there is a close event
- (void)closeEvent:(int)code reason:(NSString*)reason;

@end

@interface WebSocketHandler : NSObject<SockJSClientDelegate> {
    // The sock js client
    SockJSClient *sockjsClient;
    // A list of handlers for the messages received from the server
    NSMutableDictionary *handlers;
    // A list of reply handlers for messages
    NSMutableDictionary *replyHandlers;
    // The interval between heartbeat pings
    float _interval;
    // The base url for the websocket server
    NSString * _url;
}

@property (nonatomic, assign) id<WebSocketHandlerDelegate> delegate;
// Initialises the handler with the heartbeat interval and the base url
- (id)init:(float)interval url:(NSString*)url;
// Checks if the connection is open
- (BOOL)checkIsOpen;
// Registers a message handler to a certain name
- (void)registerHandler:(NSString*)handlerName handler:(void (^)(id, id))handler;
// De-registers a message handle with a certain name
- (void)deregisterHandler:(NSString*)handlerName handler:(void (^)(id, id))handler;
// Sends a message based on the parameters passed
- (void)send:(NSDictionary*)messageDictionary;
// Reconnects to the server if the connection is closed
- (void)reconnectIfClosed;
// Closes the connection to the server
- (void)closeConnection;

@end
