//
//  SockJSClient.h
//  OinkerClient
//
//  Created by Ye David on 6/3/14.
//  Copyright (c) 2014 All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SRWebSocket.h"
#import "Utils.h"

extern NSString * const CONST_INFO;
extern NSString * const CONST_DEVEL;
extern NSString * const CONST_DEBUG;
extern NSString * const CONST_PROTOCOLS_WHITELIST;
extern NSString * const CONST_RTT;
extern NSString * const CONST_RTO;
extern NSString * const CONST_SERVER;

// Enum to show the connection status
typedef enum {
    SOCKJS_CONNECTING   = 0, // Connecting to the server
    SOCKJS_OPEN         = 1, // Connected
    SOCKJS_CLOSING      = 2, // Attempting to close the connection
    SOCKJS_CLOSED       = 3, // Connection to the server has closed
    SOCKJS_ERROR        = 4  // Error has occurred in the connection 
} SOCKJS_ReadyState;

@protocol SockJSClientDelegate <NSObject>

// Fires when the the socket connection has been closed
// Gives the code and the reason
- (void)closeEvent:(int)code reason:(NSString*)reason;
// Fires when the socket connection has been opened
- (void)openEvent;
// Fires when a message of type json is received
- (void)messageEvent:(id)messageData;
// Fires when there is an error and gives the error message
- (void)errorEvent:(NSString*)errorMessage;

@optional
// Fires when there is a heartbeat message sent from the server
- (void)heartbeatEvent;
// Fires when a http connection request has been completed
- (void)urlConnectionRequestCompletedEvent:(NSData*)data;

@end

@interface SockJSClient : NSObject<SRWebSocketDelegate, NSURLConnectionDelegate> {
    // The timer for the loop that does the heartbeat ping to the server
    dispatch_source_t timer;
    // The time interval between heartbeat pings in seconds
    float timerInterval;
    // The base url for the websocket server, e.g. http://localhost:8081/eventbus
    NSString *baseUrl;
    // The random string representing the server instance for the websocket connection
    NSString *server;
    // The protocol whitelist
    NSMutableArray *protocolsWhitelist;
    // The SR Websocket api used to connect to the server
    SRWebSocket *websocket;
    // The main protocols that are supported
    NSMutableDictionary *mainProtocolList;
    // The main options for this connection
    NSMutableDictionary *mainOptions;
    // The protocols supported by the client
    NSArray *protocols;
    // The current protocol used
    NSString *currentProtocol;
    // SOCKJS_ReadyState readyState;
    NSMutableData *responseInfoData;
    // The timestamp defining the start of the info request
    NSDate *startInverval;
    // The rtt
    float rtt;
    // Whether or not to use a custom websocket url
    BOOL m_useCustomUrl;
}
// The delegate
@property (nonatomic, assign) id<SockJSClientDelegate> delegate;
// The current state of the sock js connection
@property (nonatomic, assign) SOCKJS_ReadyState readyState;

// Initialises the client with options and valid protocols
- (id)init:(float)interval baseUrl:(NSString*)url protocolList:(NSArray*)protocolList options:(NSDictionary*)options useCustomUrl:(BOOL)useCustomUrl openImmediately:(BOOL)openImmediately;
// Sets up and starts the timer loop for the heartbeat pings
- (void)setupTimerLoop;
// Stops the timer loop for the heartbeat pings
- (void)stopTimerLoop;
// Sends a message through the websocket client
- (void)sendMessage:(NSString*)message;
// Gets the protocol info about the websocket server
- (void)getServerInfo;
// Gets the websocket server info and connects to it
- (void)processInfoData:(NSMutableData*)data timeElapsed:(NSTimeInterval)timeElapsed;
// Sets the protocol and option info in the client
- (void)applyInfo:(NSDictionary*)infoDictionary rtt:(float)localRtt protocolsWhitelist:(NSArray*)protocolswhitelist;
// Closes the current connection and reconnects if there are other protocols
- (void)didClose:(int)code reason:(NSString*)reason force:(BOOL)force;
// Tries to connect to the server based on the protocols accepted by the server
- (BOOL)tryNextProtocol;
// Closes the connection
- (BOOL)close;
// Opens the connection to the websocket server
- (void)open:(float)interval baseUrl:(NSString*)url protocolList:(NSArray*)protocolList options:(NSDictionary*)options useCustomUrl:(BOOL)useCustomUrl;
// Check if the websocket connection is open
- (BOOL)isOpen;
// Get the main options
- (NSDictionary*)getMainOptions;

@end
