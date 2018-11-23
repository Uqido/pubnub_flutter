#import <Flutter/Flutter.h>
#import "PubNub.h"

@class MessageStreamHandler;
@class StatusStreamHandler;

@interface PubnubFlutterPlugin : NSObject<FlutterPlugin>
@property (nonatomic, strong) MessageStreamHandler *messageStreamHandler;
@property (nonatomic, strong) StatusStreamHandler *statusStreamHandler;
@end

@interface MessageStreamHandler : NSObject<FlutterStreamHandler>
@property (nonatomic, strong) FlutterEventSink eventSink;

- (void) sendMessage:(PNMessageResult *)message;

@end

@interface StatusStreamHandler : NSObject <FlutterStreamHandler>
@property (nonatomic, strong) FlutterEventSink eventSink;

- (void) sendStatus:(PNStatus *)status;

@end

