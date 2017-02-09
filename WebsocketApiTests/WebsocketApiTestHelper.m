//
//  WebsocketApiTestHelper.m
//  WebsocketApi
//
//  Created by Ye David on 6/6/14.
//  Copyright (c) 2014 All rights reserved.
//

#import "WebsocketApiTestHelper.h"

@implementation WebsocketApiTestHelper

- (id)init
{
    self = [super init];
    if (self) {
        sockJSClient = [[SockJSClient alloc] init:5.0 baseUrl:@"http://localhost:8081/eventbus" protocolList:[NSArray array] options:[NSDictionary dictionary] useCustomUrl:NO openImmediately:NO];
        sockJSClient.delegate = self;
        _hasHeartBeat = NO;
    }
    return self;
}

- (void)testOpenConnection {
    // Close existing connection
    [sockJSClient close];
    [sockJSClient open:5.0 baseUrl:@"http://localhost:8081/eventbus" protocolList:[NSArray array]  options:[NSDictionary dictionary] useCustomUrl:NO];
    // Set the heartbeat to yes to simulate one
    _hasHeartBeat = YES;
}

- (void)activateWebsocketHandler {
    websocketHandler = [[WebSocketHandler alloc] init:5.0 url:@"http://localhost:8081/eventbus"];
    websocketHandler.delegate = self;
}

- (void)registerTestMessageHandler:(void (^)(id, id))handler {
    if (websocketHandler) {
        [websocketHandler registerHandler:@"test-handler" handler:handler];
    }
}

- (void)sendTestMessage:(NSString*)message {
    if (websocketHandler) {
        NSDictionary *messageDictionary = [NSDictionary dictionaryWithObjectsAndKeys:CONST_PUBLISH, CONST_TYPE,
                                           @"test-handler", CONST_ADDRESS,
                                           [NSDictionary dictionaryWithObjectsAndKeys:message, @"text", nil], CONST_BODY, nil];
        [websocketHandler send:messageDictionary];
    }
}

- (void)close {
    [sockJSClient close];
}

- (BOOL)isOpen {
    return [sockJSClient isOpen];
}

- (BOOL)isClosed {
    return sockJSClient.readyState == SOCKJS_CLOSED;
}

#pragma SockJS client/Websocket Handler delegate methods

- (void)closeEvent:(int)code reason:(NSString*)reason {
    if (self.delegate && [self.delegate respondsToSelector:@selector(closeEvent:reason:)]) {
        [self.delegate closeEvent:code reason:reason];
    }
}
// Fires when the socket connection has been opened
- (void)openEvent {
    if (self.delegate && [self.delegate respondsToSelector:@selector(openEvent)]) {
        [self.delegate openEvent];
    }
}
// Fires when a message of type json is received
- (void)messageEvent:(id)messageData {
    
}

// Fires when there is an error and gives the error message
- (void)errorEvent:(NSString*)errorMessage {
    if (self.delegate && [self.delegate respondsToSelector:@selector(errorEvent:)]) {
        [self.delegate errorEvent:errorMessage];
    }
}

// Fires when a http connection request has been completed
- (void)urlConnectionRequestCompletedEvent:(NSData*)data {
    if (self.delegate && [self.delegate respondsToSelector:@selector(urlConnectionRequestCompletedEvent:)]) {
        [self.delegate urlConnectionRequestCompletedEvent:data];
    }
}

// Fires when a heartbeat event is dispatched
- (void)heartbeatEvent {
    // Update the heartbean status
    _hasHeartBeat = YES;
    // Fire an event for the heartbeat
    if (self.delegate && [self.delegate respondsToSelector:@selector(heartbeatEvent)]) {
        [self.delegate heartbeatEvent];
    }
}

@end
