#import <Flutter/Flutter.h>
#import <PubNub/PubNub.h>

@class MessageStreamHandler;
@class StatusStreamHandler;
@class ErrorStreamHandler;

@interface PubnubFlutterPlugin : NSObject<FlutterPlugin>
@property (nonatomic, strong) MessageStreamHandler *messageStreamHandler;
@property (nonatomic, strong) StatusStreamHandler *statusStreamHandler;
@property (nonatomic, strong) ErrorStreamHandler *errorStreamHandler;
@end

@interface MessageStreamHandler : NSObject<FlutterStreamHandler>
@property (nonatomic, strong) FlutterEventSink eventSink;

- (void) sendMessage:(PNMessageResult *)message;

@end

@interface StatusStreamHandler : NSObject <FlutterStreamHandler>
@property (nonatomic, strong) FlutterEventSink eventSink;

- (void) sendStatus:(PNStatus *)status;

@end

@interface ErrorStreamHandler : NSObject <FlutterStreamHandler>
@property (nonatomic, strong) FlutterEventSink eventSink;

- (void) sendError:(NSDictionary *)error;

@end

