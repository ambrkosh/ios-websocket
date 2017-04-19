//
//  WebsocketApiTests.m
//  WebsocketApiTests
//
//  Created by Ye David on 6/10/14.
//  Copyright (c) 2014 All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Utils.h"
#import "WebsocketApiTestHelper.h"
#import "OHHTTPStubs.h"

@interface WebsocketApiTests : XCTestCase<WebsocketApiTestHelperDelegate> {
    WebsocketApiTestHelper *websocketTestHelper;
    BOOL isTestingInfoConnection;
    BOOL isTestingWebsocketConnectionOpen;
    BOOL isTestingWebsocketConnectionClose;
    BOOL isTestingWebsocketSendMessage;
    BOOL isTestingWebsocketHeartBeat;
}

@end

@implementation WebsocketApiTests

- (void)setUp
{
    [super setUp];
    // Setup the mock url request servers
    [self setupUrlRequestStubs];
    // Setup the websocket test helper
    websocketTestHelper = [[WebsocketApiTestHelper alloc] init];
    websocketTestHelper.delegate = self;
}

- (void)tearDown
{
    // Remove the websocket test helper
    [websocketTestHelper close];
    websocketTestHelper.delegate = nil;
    websocketTestHelper = nil;
    // Remove the mock url request servers
    [self removeUrlRequestStubs];
    [super tearDown];
}

- (void)setupUrlRequestStubs {
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString isEqualToString:@"http://localhost:8081/eventbus/info"];
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        NSString *responseString = @"{\"websocket\":true,\"cookie_needed\":true,\"origins\":[\"*:*\"],\"entropy\":65777370}";
        return [OHHTTPStubsResponse responseWithData:[responseString dataUsingEncoding:NSUTF8StringEncoding] statusCode:200 headers:@{@"content-type" : @"application/json; charset=UTF-8"}];
    }];
}

- (void)removeUrlRequestStubs {
    [OHHTTPStubs removeAllStubs];
}

- (void)urlConnectionRequestCompletedEvent:(NSData*)data {
    if (isTestingInfoConnection) {
        
        /*BOOL expectedWebsocket = YES;
        BOOL expectedCookies = YES;
        NSString *expectedOrigins = @"*:*";*/
        NSError *error = nil;
        id result = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        
        if (error) {
            XCTFail(@"Invalid JSON format for Info: %@", error.description);
        } else {
            NSDictionary *info = result;
            BOOL isValid = [info objectForKey:@"websocket"]
                            && [info objectForKey:@"cookie_needed"]
                            && [info objectForKey:@"origins"]
                            && [info objectForKey:@"entropy"];
            XCTAssertTrue(isValid, @"The returned info string is not correct. Actual: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        }
        
        isTestingInfoConnection = NO;
    }
}

- (void)errorEvent:(NSString*)errorMessage {
    if (isTestingInfoConnection) {
        XCTFail(@"Error connecting to info server: %@", errorMessage);
        isTestingInfoConnection = NO;
    } else if (isTestingWebsocketConnectionOpen) {
        XCTFail(@"Error connecting to websocket server: %@", errorMessage);
        isTestingWebsocketConnectionOpen = NO;
    } else if (isTestingWebsocketSendMessage) {
        XCTFail(@"Error sending message to websocket server: %@", errorMessage);
        isTestingWebsocketSendMessage = NO;
    }
}

- (void)openEvent {
    if (isTestingWebsocketConnectionOpen) {
        XCTAssertTrue([websocketTestHelper isOpen], @"Websocket connection failed to open.");
        isTestingWebsocketConnectionOpen = NO;
    } else if (isTestingWebsocketSendMessage) {
        __block NSString *expectedMessage = @"This is a test message";
        [websocketTestHelper registerTestMessageHandler:^(id body, id replyHandler) {
            NSDictionary *messageDictionary = body;
            if ([messageDictionary objectForKey:@"text"]) {
                NSString *actualMessage = [messageDictionary objectForKey:@"text"];
                expectedMessage = @"This is a test message";
                XCTAssertTrue([expectedMessage isEqualToString:actualMessage], @"Message received was different: expected: %@ actual: %@", expectedMessage, actualMessage);
            }
            isTestingWebsocketSendMessage = NO;
        }];
        
        [websocketTestHelper sendTestMessage:expectedMessage];
    }
}

- (void)closeEvent:(int)code reason:(NSString*)reason {
    if (isTestingWebsocketConnectionClose) {
        XCTAssertTrue([websocketTestHelper isClosed], @"Websocket failed to close: %@", reason);
        isTestingWebsocketConnectionClose = NO;
    } else if (isTestingWebsocketSendMessage) {
        isTestingWebsocketSendMessage = NO;
    }
}

- (void)heartbeatEvent {
    if (isTestingWebsocketHeartBeat) {
        XCTAssertTrue(websocketTestHelper.hasHeartBeat, @"Websocket has no heartbeat.");
        isTestingWebsocketHeartBeat = NO;
    }
}

#pragma SockJS unit tests

- (void)testInfoConnection {
    isTestingInfoConnection = YES;
    [websocketTestHelper testOpenConnection];
    while(isTestingInfoConnection) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
}

/*- (void)testWebSocketConnectionOpen {
    isTestingWebsocketConnectionOpen = YES;
    [websocketTestHelper testOpenConnection];
    while (isTestingWebsocketConnectionOpen) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
}*/

- (void)testWebSocketConnectionClose {
    isTestingWebsocketConnectionClose = YES;
    // Open the connection first
    [websocketTestHelper testOpenConnection];
    // Close the connection
    [websocketTestHelper close];
    while (isTestingWebsocketConnectionClose) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
}

/*- (void)testWebSocketSendMessage {
    isTestingWebsocketSendMessage = YES;
    [websocketTestHelper activateWebsocketHandler];
    while (isTestingWebsocketSendMessage) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
}

- (void)testWebSocketHeartBeat {
    isTestingWebsocketHeartBeat = YES;
    // Open the connection first
    [websocketTestHelper testOpenConnection];
    while (isTestingWebsocketHeartBeat) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
}*/

#pragma Utils unit tests
- (void)testUtilsGenerateRandomString {
    NSString *randomString = [Utils generateRandomString:8];
    XCTAssertTrue(randomString != nil, @"Returned String is null");
    XCTAssertTrue(randomString.length == 8, @"Returned String should be 8 characters long but instead has: %lu", (unsigned long)randomString.length);
    NSCharacterSet *alphanumericSet = [NSCharacterSet alphanumericCharacterSet];
    NSCharacterSet *numberSet = [NSCharacterSet decimalDigitCharacterSet];
    BOOL isAlphaNumberic = [[randomString stringByTrimmingCharactersInSet:alphanumericSet] isEqualToString:@""] && ![[randomString stringByTrimmingCharactersInSet:numberSet] isEqualToString:@""];
    XCTAssertTrue(isAlphaNumberic, @"The string was not alphanumeric: %@", randomString);
}

- (void)testUtilsGenerateRandomStringIncorrectLength {
    NSString *randomString = [Utils generateRandomString:0];
    XCTAssertTrue(randomString != nil, @"Returned String is null");
    XCTAssertTrue(randomString.length == 0, @"Returned String should be 0 characters long but instead has: %lu", (unsigned long)randomString.length);
    
    NSString *randomString2 = [Utils generateRandomString:-1];
    XCTAssertTrue(randomString2 != nil, @"Returned String is null");
    XCTAssertTrue(randomString2.length == 0, @"Returned String should be 0 characters long but instead has: %lu", (unsigned long)randomString2.length);
}

- (void)testUtilsGenerateRandomNumberString {
    NSString *randomNumberString = [Utils generateRandomNumberString:1000];
    XCTAssertTrue(randomNumberString != nil, @"Returned String is null");
    XCTAssertTrue(randomNumberString.length == 3, @"Returned String should be 3 characters long but instead has: %lu", (unsigned long)randomNumberString.length);
    
    NSCharacterSet *numberSet = [NSCharacterSet decimalDigitCharacterSet];
    BOOL isNumeric = [[randomNumberString stringByTrimmingCharactersInSet:numberSet] isEqualToString:@""];
    XCTAssertTrue(isNumeric, @"The string was not numeric: %@", randomNumberString);
}

- (void)testUtilsVerifyUrl {
    NSString *testUrl = @"http://localhost:8081/eventbus";
    BOOL result = [Utils verifyUrl:testUrl];
    XCTAssertTrue(result, @"The string was not a valid url: %@", testUrl);
    
}

- (void)testUtilsVerifyUrlIncorrectUrl {
    NSString *testUrl = @";ocalhostas@sdsdeventbus";
    BOOL result = [Utils verifyUrl:testUrl];
    XCTAssertFalse(result, @"The string was a valid url: %@", testUrl);
    
}

- (void)testUtilsCalculateRto {
    float testRtt = 10;
    float testRtt2 = 200;
    float expectedResult1 = 310;
    float expectedResult2 = 800;
    
    float result1 = [Utils calculateRto:testRtt];
    XCTAssertTrue(expectedResult1 == result1, @"RTO is incorrect - expected: %f actual: %f", expectedResult1, result1);
    
    float result2 = [Utils calculateRto:testRtt2];
    XCTAssertTrue(expectedResult2 == result2, @"RTO is incorrect - expected: %f actual: %f", expectedResult2, result2);
}

- (void)testUtilsdetectProtocols {
    NSArray *testProtocolWhitelist = [NSArray array];
    NSDictionary *testInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],@"websocket", nil];
    NSArray *expectedResult = [NSArray arrayWithObject:@"websocket"];
    
    NSArray *actualResult = [Utils detectProtocols:testProtocolWhitelist info:testInfo];
    
    XCTAssertTrue([expectedResult isEqualToArray:actualResult], @"The detected protocols are incorrect");
}

- (void)testUtilsdetectProtocolsIncorrectProtocol {
    NSArray *testProtocolWhitelist = [NSArray array];
    NSDictionary *testInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],@"sdsdsd", nil];
    NSArray *expectedResult = [NSArray array];
    
    NSArray *actualResult = [Utils detectProtocols:testProtocolWhitelist info:testInfo];
    
    XCTAssertTrue([expectedResult isEqualToArray:actualResult], @"Detected protocols returned a value when it was not supposed to.");
}

- (void)testUserSetCode {
    int testCode = 1000;
    BOOL expectedResult = YES;
    BOOL actualResult = [Utils userSetCode:testCode];
    XCTAssertTrue(expectedResult == actualResult, @"The user test code is incorrect.");
}

- (void)testEscapeJSONString {
    NSString *testJSONString = @"{\"type\" : \"send\"}";
    NSString *expectedResult = @"\"{\\\"type\\\" : \\\"send\\\"}\"";
    NSString *actualResult = [Utils JSONString:testJSONString];
    
    XCTAssertTrue([expectedResult isEqualToString:actualResult], @"The JSON string was not properly formatted expected: %@ actual: %@", expectedResult, actualResult);
}

@end
