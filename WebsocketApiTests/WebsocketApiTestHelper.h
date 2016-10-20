//
//  WebsocketApiTestHelper.h
//  WebsocketApi
//
//  Created by Ye David on 6/6/14.
//  Copyright (c) 2014 All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SockJSClient.h"
#import "WebsocketHandler.h"

@protocol WebsocketApiTestHelperDelegate <NSObject>

@optional
// Event handler for the socket open event
- (void)openEvent;
// Event handler for the socket closed event
- (void)closeEvent:(int)code reason:(NSString*)reason;
// Event handler for the url connection request completion event
- (void)urlConnectionRequestCompletedEvent:(NSData*)data;
// Event handler for any error events
- (void)errorEvent:(NSString*)errorMessage;
// Event handler for the heart beat event
- (void)heartbeatEvent;

@end

// Provides helper methods for the tests
@interface WebsocketApiTestHelper : NSObject<SockJSClientDelegate, WebSocketHandlerDelegate> {
    // The sockjs client
    SockJSClient *sockJSClient;
    // The wrapper object for the sockjs client
    WebSocketHandler *websocketHandler;
}

// The delegate for this class
@property (nonatomic, assign) id<WebsocketApiTestHelperDelegate> delegate;
// the delegate for the web socket handler
@property (nonatomic, assign) id<WebSocketHandlerDelegate> websocketHandlerDelegate;
// Whether or not a heart beat exists
@property (nonatomic, assign) BOOL hasHeartBeat;

// Initialises the test helper
- (id)init;
// Opens a test connection
- (void)testOpenConnection;
// Closes the test connection
- (void)close;
// Checks if the test connection is open
- (BOOL)isOpen;
// Checks if the test connection is closed
- (BOOL)isClosed;
// Initialises the websocket handler
- (void)activateWebsocketHandler;
// Registers a callback handler for a test message
- (void)registerTestMessageHandler:(void (^)(id, id))handler;
// Sends a test message
- (void)sendTestMessage:(NSString*)message;

@end
