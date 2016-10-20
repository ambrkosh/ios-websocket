//
//  WebSocketHandler.m
//  OinkerClient
//
//  Created by Ye David on 6/2/14.
//  Copyright (c) 2014 All rights reserved.
//

#import "WebSocketHandler.h"

@implementation WebSocketHandler

NSString * const CONST_FUNCTION = @"function";
NSString * const CONST_STRING = @"string";
NSString * const CONST_TYPE = @"type";
NSString * const CONST_ADDRESS = @"address";
NSString * const CONST_BODY = @"body";
NSString * const CONST_REPLY_HANDLER = @"replyHandler";
NSString * const CONST_REPLY_ADDRESS = @"replyAddress";
NSString * const CONST_REPLY_SEND = @"send";
NSString * const CONST_REGISTER = @"register";
NSString * const CONST_UNREGISTER = @"unregister";
NSString * const CONST_SEND = @"send";
NSString * const CONST_PUBLISH = @"publish";


- (id)init:(float)interval url:(NSString*)url {
    self = [super init];
    if (self) {
        // Custom initialization
        _interval = interval;
        _url = url;
        sockjsClient = [[SockJSClient alloc] init:interval baseUrl:url protocolList:[NSArray array] options:[NSDictionary dictionary] useCustomUrl:NO openImmediately:YES];
        sockjsClient.delegate = self;
        
        handlers = [NSMutableDictionary dictionary];
        replyHandlers = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)send:(NSDictionary*)messageDictionary {
    NSString *jsonMessage = [self prepareMessage:messageDictionary];
    if ([jsonMessage isEqualToString:@""]) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(errorEvent:)]) {
            [self.delegate errorEvent:@"Cannot send empty string!"];
        }
    } else {
        [self sendMessage:jsonMessage];
    }
}

- (void)sendMessage:(NSString*)message {
    [sockjsClient sendMessage:message];
}

- (NSString*)prepareMessage:(NSDictionary*)messageDictionary {
    if (![self checkParamter:CONST_TYPE parameterType:CONST_STRING messageDictionary:messageDictionary optional:NO]) {
        if (self.delegate) {
            [self.delegate errorEvent:@"Parameter type must be specified"];
        }
    }
    
    if (![self checkParamter:CONST_ADDRESS parameterType:CONST_STRING messageDictionary:messageDictionary optional:NO]) {
        if (self.delegate) {
            [self.delegate errorEvent:@"Parameter address must be specified"];
        }
        return @"";
    }
    if (![self checkParamter:CONST_REPLY_HANDLER parameterType:CONST_FUNCTION messageDictionary:messageDictionary optional:YES]) {
        if (self.delegate) {
            [self.delegate errorEvent:@"Parameter replyHandler must be specified"];
        }
        return @"";
    }
    
    NSString *type = [messageDictionary objectForKey:CONST_TYPE];
    NSString *address = [messageDictionary objectForKey:CONST_ADDRESS];
    NSString *body = [messageDictionary objectForKey:CONST_BODY];
    id replyHandler = [messageDictionary objectForKey:CONST_REPLY_HANDLER];
    
    NSMutableDictionary *envelope = [NSMutableDictionary dictionaryWithObjectsAndKeys:type, CONST_TYPE,
                                     address, CONST_ADDRESS,
                                     body, CONST_BODY, nil];
    
    if (replyHandler) {
        // If the reply handler exists then store it
        NSString *replyAddress = [[NSUUID UUID] UUIDString];
        [envelope setObject:replyAddress forKey:CONST_REPLY_ADDRESS];
        [replyHandlers setObject:replyHandler forKey:replyAddress];
    }
    NSError *jsonError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:envelope options:0 error:&jsonError];
    
    // Error converting to a JSON string
    if (jsonError) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(errorEvent:)]) {
            [self.delegate errorEvent:[NSString stringWithFormat:@"Error converting to JSON string: %@", jsonError.description]];
        }
        
        return @"";
    } else { // Return the JSON string
        return [Utils JSONString:[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
    }
}

- (BOOL)checkParamter:(NSString*)parameterName parameterType:(NSString*)parameterType messageDictionary:(NSDictionary*)messageDictionary optional:(BOOL)optional {
    if ([messageDictionary objectForKey:parameterName]) {
        id parameter = [messageDictionary objectForKey:parameterName];
        if ([parameterType isEqualToString:CONST_STRING]) {
            return [parameter isKindOfClass:[NSString class]];
        } else if ([parameterType isEqualToString:CONST_FUNCTION]) {
            return [parameter isKindOfClass:NSClassFromString(@"NSBlock")];
        } else {
            return YES;
        }
        
    } else {
        return optional;
    }
}

- (BOOL)checkIsOpen {
    return [sockjsClient isOpen];
}

- (void)registerHandler:(NSString*)handlerName handler:(void (^)(id, id))handler {
    if (![handlers objectForKey:handlerName]) {
        NSDictionary *message = [NSDictionary dictionaryWithObjectsAndKeys:CONST_REGISTER, CONST_TYPE,
                                 handlerName, CONST_ADDRESS,
                                 nil];
        [self send:message];
        [handlers setObject:handler forKey:handlerName];
    }
}

- (void)deregisterHandler:(NSString*)handlerName handler:(void (^)(id, id))handler {
    if ([handlers objectForKey:handlerName]) {
        NSDictionary *message = [NSDictionary dictionaryWithObjectsAndKeys:CONST_UNREGISTER, CONST_TYPE,
                                 handlerName, CONST_ADDRESS,
                                 nil];
        [self send:message];
        [handlers removeObjectForKey:handlerName];
    }
}

- (void)reconnectIfClosed {
    if (![self checkIsOpen]) {
        // Stop the timer loop first
        [sockjsClient stopTimerLoop];
        // Reopen the connection
        [sockjsClient open:_interval baseUrl:_url protocolList:[NSArray array] options:[NSDictionary dictionary] useCustomUrl:NO];
    }
}

- (void)closeConnection {
    // Close the client
    [sockjsClient close];
}

#pragma SockJS client delegate methods

- (void)closeEvent:(int)code reason:(NSString*)reason {
    // Fires the connection closed event
    if (self.delegate && [self.delegate respondsToSelector:@selector(closeEvent:reason:)]) {
        [self.delegate closeEvent:code reason:reason];
    }
}

- (void)openEvent {
    // Fires the open event
    if (self.delegate && [self.delegate respondsToSelector:@selector(openEvent)]) {
        [self.delegate openEvent];
    }
}

- (void)messageEvent:(id)messageData {
    if (messageData && [messageData isKindOfClass:[NSDictionary class]]) {
        NSDictionary *messageDictionary = messageData;
        
        NSString *replyAddress = [messageDictionary objectForKey:CONST_REPLY_ADDRESS];
        NSString *address = [messageDictionary objectForKey:CONST_ADDRESS];
        NSDictionary *body = [messageDictionary objectForKey:CONST_BODY];
        void (^handler)(id, id) = [handlers objectForKey:address];
        void (^replyHandler)(id, id) = nil;
        
        if (replyAddress) {
            replyHandler = ^(id reply, id replyHandler) {
                [self send:[NSDictionary dictionaryWithObjectsAndKeys:CONST_REPLY_SEND, CONST_TYPE,
                              replyAddress, CONST_ADDRESS,
                              reply, CONST_BODY,
                              replyHandler, CONST_REPLY_HANDLER,
                              nil]];
            };
        }
        
        if (handler) {
            // We make a copy since the handler might get unregistered from within the
            // handler itself, which would screw up our iteration
            void (^handlerCopy)(id, id) = [handler copy];
            handlerCopy(body, replyHandler);
        } else {
            // Might be a reply message
            void (^tempHandler)(id, id) = [replyHandlers objectForKey:address];
            if (tempHandler) {
                [replyHandlers removeObjectForKey:address];
                tempHandler(body, replyHandler);
            }
        }
    }
}

- (void)errorEvent:(NSString*)errorMessage {
    // Fires the error event
    if (self.delegate && [self.delegate respondsToSelector:@selector(errorEvent:)]) {
        [self.delegate errorEvent:errorMessage];
    }
}

- (void)heartbeatEvent {
    // Fires the heartbeat event
    if (self.delegate && [self.delegate respondsToSelector:@selector(heatbeatEvent)]) {
        [self.delegate heatbeatEvent];
    }
}

@end
