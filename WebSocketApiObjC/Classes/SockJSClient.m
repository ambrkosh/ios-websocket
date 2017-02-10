//
//  SockJSClient.m
//  SockJS Client Wrapper for SocketRocket
//
//  Created by Ye David on 6/3/14.
//  Copyright (c) 2014 All rights reserved.
//

#import "SockJSClient.h"

@implementation SockJSClient

NSString * const CONST_INFO = @"info";
NSString * const CONST_DEVEL = @"devel";
NSString * const CONST_DEBUG = @"debug";
NSString * const CONST_PROTOCOLS_WHITELIST = @"protocols_whitelist";
NSString * const CONST_RTT = @"rtt";
NSString * const CONST_RTO = @"rto";
NSString * const CONST_SERVER = @"server";

-(id)init:(float)interval baseUrl:(NSString*)url protocolList:(NSArray*)protocolList options:(NSDictionary*)options useCustomUrl:(BOOL)useCustomUrl openImmediately:(BOOL)openImmediately {
    self = [super init];
    if (self) {
        // Initialise the options
        [self setOptions:interval baseUrl:url protocolList:protocolList options:options useCustomUrl:useCustomUrl];
        if (openImmediately) {
            // Open the connection to the server immediately
            [self open:interval baseUrl:url protocolList:protocolList options:options useCustomUrl:useCustomUrl];
        }
    }
    return self;
}

- (void)getServerInfo {
    NSString *infoUrl = [NSString stringWithFormat:@"%@/info", baseUrl];
    NSURL *nsUrl = [NSURL URLWithString:infoUrl];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:nsUrl];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
    [connection start];
}

- (void)connectToWebSocketServer:(NSString*)url {
    if ([Utils verifyUrl:url]) {
        NSURL *nsUrl = [NSURL URLWithString:url];
        NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:nsUrl];
        // Set the timeout interval
        NSTimeInterval timeoutInteval = ([(NSNumber*)[mainOptions objectForKey:CONST_RTO] floatValue] * 5000) / 1000;
        [urlRequest setTimeoutInterval:timeoutInteval];
        websocket = [[SRWebSocket alloc] initWithURLRequest:urlRequest];
        websocket.delegate = self;
    } else {
        // raise an error
        NSLog(@"Incorrectly formatted url: %@", url);
        if (self.delegate && [self.delegate respondsToSelector:@selector(errorEvent:)]) {
            [self.delegate errorEvent:[NSString stringWithFormat:@"Incorrectly formatted url: %@", url]];
        }
    }
}

- (void)processInfoData:(NSMutableData*)data timeElapsed:(NSTimeInterval)timeElapsed {
    NSError *error = nil;
    if (data) {
        id result = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if ([result isKindOfClass:[NSDictionary class]]) {
            NSDictionary* infoDictionary = result;
            
            if ([mainOptions objectForKey:CONST_INFO]) {
                infoDictionary = result;
            }
            if ([mainOptions objectForKey:CONST_RTT]) {
                rtt = [(NSNumber*)[mainOptions objectForKey:CONST_RTT] floatValue];
            }
            
            // Add all info and protocols to the variables
            [self applyInfo:infoDictionary rtt:rtt protocolsWhitelist:protocolsWhitelist];
            [self didClose:9999 reason:@"open" force:NO];
            
        } else if ([result isKindOfClass:[NSArray class]]) {
            NSArray* infoArray = result;
            // Unknown format - don't know how to handle this
            NSLog(@"Array returned from info get");
            
        } else {
            // unknown object so close the connection
            [self closeWebsocket];
        }
        
    } else {
        [self closeWebsocket];
    }
    responseInfoData = nil;
}

- (void)applyInfo:(NSDictionary*)infoDictionary rtt:(float)localRtt protocolsWhitelist:(NSArray*)protocolswhitelist {
    [mainOptions setObject:infoDictionary forKey:CONST_INFO];
    [mainOptions setObject:[NSNumber numberWithFloat:localRtt] forKey:CONST_RTT];
    [mainOptions setObject:[NSNumber numberWithFloat:[Utils calculateRto:localRtt]] forKey:CONST_RTO];
    [mainOptions setObject:[NSNumber numberWithBool:NO] forKey:CONST_NULL_ORIGIN];
    protocols = [Utils detectProtocols:protocolswhitelist info:infoDictionary];
}

- (void)didClose:(int)code reason:(NSString*)reason force:(BOOL)force {
    if (self.readyState != SOCKJS_CONNECTING &&
        self.readyState != SOCKJS_OPEN &&
        self.readyState != SOCKJS_CLOSING) {
        // Throw error
        //NSError *error = [[NSError alloc] initWithDomain:(NSString *)kCFErrorDomainCFNetwork code:1234 userInfo:[NSDictionary dictionaryWithObject:@"INVALID_STATE_ERR" forKey:@"description"]];
        NSLog(@"INVALID_STATE_ERR");
        if (self.delegate && [self.delegate respondsToSelector:@selector(errorEvent:)]) {
            [self.delegate errorEvent:@"INVALID_STATE_ERR"];
        }
    }
    // Close the websocket connection
    [self closeWebsocket];
    
    if (![Utils userSetCode:code] &&
        self.readyState == SOCKJS_CONNECTING && !force) {
        if ([self tryNextProtocol]) {
            // Open the web socket
            [self openWebsocket];
            return;
        }
        code = 2000;
        reason = @"All transports failed";
    }
    self.readyState = SOCKJS_CLOSED;
    // Stop the heartbeat timer loop
    [self stopTimerLoop];
    // Fire a close event
    if (self.delegate && [self.delegate respondsToSelector:@selector(closeEvent:reason:)]) {
        [self.delegate closeEvent:code reason:reason];
    }
}

- (BOOL)tryNextProtocol {
    BOOL result = NO;
    
    if (currentProtocol && ![currentProtocol isEqualToString:@""]) {
        currentProtocol = @"";
    }
    
    for (id object in protocols) {
        if ([object isKindOfClass:[NSString class]]) {
            // Only if it is a string
            NSString* protocol = object;
            NSDictionary *info = [mainOptions objectForKey:CONST_INFO];
            if (info && [info objectForKey:protocol]) {
                BOOL protocolEnabled = [(NSNumber*)[info objectForKey:protocol] boolValue];
                if (protocolEnabled) {
                    // Generate a random connection id for the websocket
                    NSString *connectionId = [Utils generateRandomString:8];
                    NSString *connectionUrl = baseUrl;
                    // Checks if a custom url is to be used for connecting to the websocket server
                    if (!m_useCustomUrl) {
                        // Generates a standard websocket connection url based on the connection id, server generated keys
                        NSString *url = baseUrl;
                        if ([[baseUrl substringToIndex:5] isEqualToString:@"https"]) {
                            url = [NSString stringWithFormat:@"wss%@",[baseUrl substringFromIndex:5]];
                        } else {
                            url = [NSString stringWithFormat:@"ws%@",[baseUrl substringFromIndex:4]];
                        }
                        
                        // Add extra info if it is a websocket protocol
                        if ([protocol isEqualToString:CONST_WEBSOCKET]) {
                            connectionUrl = [NSString stringWithFormat:@"%@/%@/%@/%@", url, server, connectionId, CONST_WEBSOCKET] ;
                        } else {
                            // All other protocols
                            connectionUrl = [NSString stringWithFormat:@"%@/%@/%@", url, server, connectionId] ;
                        }
                        
                        NSLog(@"Opening transport: %@ url: %@ rto: %@", protocol, connectionUrl, [mainOptions objectForKey:CONST_RTO]);
                    }
                    
                    [self connectToWebSocketServer:connectionUrl];
                    result = YES;
                    break;
                }
            }
        }
    }
    return result;
}

- (void)setupTimerLoop {
    // Create a timer loop on a different thread
    timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    if (timer) {
        // Fires it according the the time interval set
        dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, timerInterval * NSEC_PER_SEC, 1.0 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(timer, ^{ handleTimerEvent(websocket); });
        dispatch_resume(timer);
    }
}

- (void)stopTimerLoop {
    if (timer) {
        dispatch_source_cancel(timer);
    }
}

- (void)openWebsocket {
    if (websocket && websocket.readyState != SR_OPEN) {
        [websocket open];
    }
}

- (void)closeWebsocket {
    if (websocket && websocket.readyState == SR_OPEN) {
        [websocket close];
    }
}

- (void)sendMessage:(NSString*)message {
    if (websocket && websocket.readyState == SR_OPEN) {
        [websocket send:message];
        NSLog(@"Message sent: %@", message);
    } else {
        // reopen the connection
        [self open:timerInterval baseUrl:baseUrl protocolList:protocolsWhitelist options:mainOptions useCustomUrl:NO];
    }
}

- (void)dispatchOpenEvent {
    if (self.readyState == SOCKJS_CONNECTING) {
        self.readyState = SOCKJS_OPEN;
        // Fires an open event
        if (self.delegate && [self.delegate respondsToSelector:@selector(openEvent)]) {
            [self.delegate openEvent];
        }
    } else {
        // Server might have been restarted and lost track of our connection
        [self didClose:1006 reason:@"Server lost session" force:NO];
    }
}

- (void)dispatchMessageEvent:(id)messageData {
    if (self.readyState != SOCKJS_OPEN) {
        return;
    }
    // Fires a message event
    if (self.delegate && [self.delegate respondsToSelector:@selector(messageEvent:)]) {
        [self.delegate messageEvent:messageData];
    }
}

- (void)dispatchHeartBeatEvent {
    // Fires a heartheat event
    if (self.delegate && [self.delegate respondsToSelector:@selector(heartbeatEvent)]) {
        [self.delegate heartbeatEvent];
    }
}

- (BOOL)close {
    if (self.readyState != SOCKJS_CONNECTING &&
       self.readyState != SOCKJS_OPEN) {
        return NO;
    }
    self.readyState = SOCKJS_CLOSING;
    [self didClose:1000 reason:@"Normal closure" force:NO];
    return YES;
}

- (void)open:(float)interval baseUrl:(NSString*)url protocolList:(NSArray*)protocolList options:(NSDictionary*)options useCustomUrl:(BOOL)useCustomUrl {
    // Set the main options
    [self setOptions:interval baseUrl:url protocolList:protocolList options:options useCustomUrl:useCustomUrl];
    // Get the protocol and other info from the server
    [self getServerInfo];
    // Setup and start the timer loop for the pings
    [self setupTimerLoop];
}

- (BOOL)isOpen {
    return self.readyState == SOCKJS_OPEN;
}

- (void)processJSONMessageArray:(NSArray*)jsonArray {
    for (id object in jsonArray) {
        if ([object isKindOfClass:[NSString class]]) {
            // Only process the message if it is a string
            NSError *jsonError = nil;
            id objectDictionary = [NSJSONSerialization JSONObjectWithData:[object dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&jsonError];
            
            if (jsonError) {
                NSLog(@"JSON Parse Error: %@", jsonError.description);
            } else {
                [self dispatchMessageEvent:objectDictionary];
            }
        }
    }
}

- (NSDictionary*)getMainOptions {
    return mainOptions;
}

- (void)setOptions:(float)interval baseUrl:(NSString*)url protocolList:(NSArray*)protocolList options:(NSDictionary*)options useCustomUrl:(BOOL)useCustomUrl {
    // Set the timer interval
    timerInterval = interval;
    // Set the base url
    baseUrl = url;
    m_useCustomUrl = useCustomUrl;
    // Initialise the main protocol list
    mainProtocolList = protocolList && protocolList.count > 0 ? mainProtocolList : [NSMutableDictionary dictionary];
    // Initialise the main option list
    mainOptions = [NSMutableDictionary dictionaryWithObjectsAndKeys:CONST_DEVEL, [NSNumber numberWithBool:NO],
                   CONST_DEBUG, [NSNumber numberWithBool:NO],
                   CONST_PROTOCOLS_WHITELIST, [NSArray array],
                   CONST_INFO, [NSMutableDictionary dictionary],
                   CONST_RTT, [NSNumber numberWithFloat:0], nil];
    
    // If the option list passed in is not empty then add it to the main options
    if (options && options.count > 0) {
        [mainOptions addEntriesFromDictionary:options];
    }
    // Initialise the server instance
    server = [mainOptions objectForKey:CONST_SERVER];
    if (!server && server.length == 0) {
        // If it is not initialised then generate a new random number
        server = [Utils generateRandomNumberString:1000];
    }
    // Initialise the protocol whitelist
    if (mainOptions && [mainOptions objectForKey:CONST_PROTOCOLS_WHITELIST]) {
        protocolsWhitelist = [NSMutableArray arrayWithArray:[mainOptions objectForKey:CONST_PROTOCOLS_WHITELIST]];
    } else if (protocolList && protocolList.count > 0) {
        protocolsWhitelist = [NSMutableArray arrayWithArray:protocolList];
    } else {
        protocolsWhitelist = [NSMutableArray array];
    }
    // Initialise the protocols array
    protocols = [NSArray array];
    // Set the ready state to connecting
    self.readyState = SOCKJS_CONNECTING;
}

#pragma SRWebSocket delegate methods

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    if (message && [message isKindOfClass:[NSString class]]) {
        NSString *messageText = message;
        NSLog(@"%@", messageText);
        
        NSDictionary *jsonDictionary = nil;
        NSArray* jsonArray = nil;
        NSError *error = nil;
        // Parse the JSON object
        if (messageText.length > 0) {
            char frameCode = [[message substringToIndex:1] UTF8String][0];
            
            if (messageText.length > 1) {
                id jsonObject = [NSJSONSerialization JSONObjectWithData:[[messageText substringFromIndex:1] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
                
                if (error) {
                    NSLog(@"JSON Parse Error: %@", error.description);
                } else {
                    if ([jsonObject isKindOfClass:[NSDictionary class]]) {
                        jsonDictionary = jsonObject;
                    } else if ([jsonObject isKindOfClass:[NSArray class]]){
                        jsonArray = jsonObject;
                    }
                }
            }
            // Check the type of frame code and act accordingly
            switch(frameCode) {
                case 'o':
                    // The connection was opened by the server
                    [self dispatchOpenEvent];
                    break;
                case 'a':
                    // A message was sent from the server in an array format
                    if (jsonArray != nil) {
                        [self processJSONMessageArray:jsonArray];
                    }
                    break;
                case 'm':
                    // A message was sent from the server
                    if (jsonDictionary != nil) {
                        [self dispatchMessageEvent:jsonDictionary];
                    }
                    break;
                case 'c':
                    // The connection was closed by the server
                    if (jsonArray != nil) {
                        [self didClose:[(NSNumber*)[jsonArray objectAtIndex:0] intValue] reason:[jsonArray objectAtIndex:1] force:NO];
                    } else {
                        [self didClose:9999 reason:@"Normal closure" force:NO];
                    }
                    break;
                case 'h':
                    [self dispatchHeartBeatEvent];
                    break;
                default:
                    // Assume it is not framed with a char and is a straight json string
                    if (jsonArray) {
                        [self processJSONMessageArray:jsonArray];
                    } else if (jsonDictionary) {
                        [self dispatchMessageEvent:jsonDictionary];
                    }
                    NSLog(@"%@", message);
            }
        }
    }
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    NSLog(@"Socket Opened");
    //[self dispatchOpenEvent];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    if (self.delegate && [self.delegate respondsToSelector:@selector(errorEvent:)]) {
        [self.delegate errorEvent:[error description]];
    }
    NSLog(@"Socket open failed: %@",[error description]);
}

void handleTimerEvent(SRWebSocket *websocket) {
    // Send a ping
    if (websocket && websocket.readyState == SR_OPEN) {
        NSString *message = @"\"{\\\"type\\\" : \\\"ping\\\"}\"";
        [websocket send:message];
        NSLog(@"%@", message);
    }
}

#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // Initialise the response data variable
    // Will also be called if there is a redirect
    responseInfoData = [[NSMutableData alloc] init];
    startInverval = [NSDate date];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append the new data to the response data
    [responseInfoData appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // The request is complete and data has been received
    NSLog(@"%@",[[NSString alloc] initWithData:responseInfoData encoding:NSUTF8StringEncoding]);
    if (self.delegate && [self.delegate respondsToSelector:@selector(urlConnectionRequestCompletedEvent:)]) {
        [self.delegate urlConnectionRequestCompletedEvent:responseInfoData];
    }
    [self processInfoData:responseInfoData timeElapsed:[startInverval timeIntervalSinceNow]];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // The request has failed for some reason!
    // Check the error var
    responseInfoData = nil;
    self.readyState = SOCKJS_CLOSED;
    NSLog(@"Connection error for info: %@", error.description);
    if (self.delegate && [self.delegate respondsToSelector:@selector(errorEvent:)]) {
        [self.delegate errorEvent:[NSString stringWithFormat:@"Connection error for info: %@", error.description]];
    }
}

@end
