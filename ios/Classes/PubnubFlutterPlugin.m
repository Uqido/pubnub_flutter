#import "PubnubFlutterPlugin.h"

@interface PubnubFlutterPlugin ()<PNObjectEventListener>

@property (nonatomic, strong) PubNub* client;
@property (nonatomic, strong) PNConfiguration *config;
@end

@implementation PubnubFlutterPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"pubnub_flutter"
                                     binaryMessenger:[registrar messenger]];
    PubnubFlutterPlugin* instance = [[PubnubFlutterPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
    
    // Event channel for streams
    instance.messageStreamHandler = [MessageStreamHandler new];
    
    FlutterEventChannel* messageChannel =
    [FlutterEventChannel eventChannelWithName:@"plugins.flutter.io/pubnub_message"
                              binaryMessenger:[registrar messenger]];
    [messageChannel setStreamHandler:instance.messageStreamHandler];
    
    // Event channel for streams
    instance.statusStreamHandler = [StatusStreamHandler new];
    
    FlutterEventChannel* statusChannel =
    [FlutterEventChannel eventChannelWithName:@"plugins.flutter.io/pubnub_status"
                              binaryMessenger:[registrar messenger]];
    [statusChannel setStreamHandler:instance.statusStreamHandler];
    
    instance.errorStreamHandler = [ErrorStreamHandler new];
    
    FlutterEventChannel* errorChannel =
    [FlutterEventChannel eventChannelWithName:@"plugins.flutter.io/pubnub_error"
                              binaryMessenger:[registrar messenger]];
    [errorChannel setStreamHandler:instance.errorStreamHandler];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if  ([@"create" isEqualToString:call.method]) {
        NSLog(@"Create Pub Nub");
        
        result([self handleCreate:call]);
    } else if  ([@"subscribe" isEqualToString:call.method]) {
        NSLog(@"Register Pub Nub");
        
        result([self handleSubscribe:call]);
    } else if  ([@"publish" isEqualToString:call.method]) {
        NSLog(@"Publish Pub Nub");
        
        result([self handlePublish:call]);
    } else if  ([@"filter" isEqualToString:call.method]) {
        NSLog(@"Filter Pub Nub");
        
        result([self handleFilter:call]);
    } else if  ([@"setState" isEqualToString:call.method]) {
        NSLog(@"set state Pub Nub");
        
        result([self handleSetState:call]);
    } else if  ([@"unsubscribe" isEqualToString:call.method]) {
        NSLog(@"Unsubscribe Pub Nub");
        
        result([self handleUnsubscribe:call]);
    } else if  ([@"unsubscribe_all" isEqualToString:call.method]) {
        NSLog(@"Unsubscribe Pub Nub");
        
        result([self handleUnsubscribe:call]);
    } else if  ([@"uuid" isEqualToString:call.method]) {
        NSLog(@"get UUID Pub Nub");
        
        result([self handleUUID:call]);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (id) handleUnsubscribe:(FlutterMethodCall*)call {
    NSString *channel = call.arguments[@"channel"];
    
    if(channel) {
        [self.client unsubscribeFromChannels:@[channel] withPresence:NO];
    } else {
        [self.client unsubscribeFromAll];
    }
    
    return NULL;
}

- (id) handleFilter:(FlutterMethodCall*)call {
    NSString *filter = call.arguments[@"filter"];
    
    self.client.filterExpression = filter;
    
    return NULL;
}

- (id) handleUUID:(FlutterMethodCall*)call {
    
    return self.config.uuid;
}

- (id) handlePublish:(FlutterMethodCall*)call {
    NSString *channel = call.arguments[@"channel"];
    NSDictionary *message = call.arguments[@"message"];
    NSDictionary *metadata = call.arguments[@"metadata"];

    if(channel && message) {
         __weak __typeof(self) weakSelf = self;
        [self.client publish:message toChannel:channel withMetadata:metadata completion:^(PNPublishStatus *status) {
            __strong __typeof(self) strongSelf = weakSelf;
            [strongSelf handleStatus:status client:strongSelf.client];
        }];
    }
    
    return NULL;
}

- (id) handleSetState:(FlutterMethodCall*)call {
    NSString *channel = call.arguments[@"channel"];
    NSString *uuid = call.arguments[@"uuid"];
    NSDictionary *state = call.arguments[@"state"];
    
    if(channel && uuid && state) {
        __weak __typeof(self) weakSelf = self;
        [self.client setState:state forUUID:uuid onChannel:channel withCompletion:^(PNClientStateUpdateStatus * _Nonnull status) {
            __strong __typeof(self) strongSelf = weakSelf;
            [strongSelf handleStatus:status client:strongSelf.client];
        }];
    }
    
    return NULL;
}


- (id) handleCreate:(FlutterMethodCall*)call {
    NSString *publishKey = call.arguments[@"publishKey"];
    NSString *subscribeKey = call.arguments[@"subscribeKey"];
    NSString *uuid = call.arguments[@"uuid"];
    
    if(publishKey && subscribeKey) {
        NSLog(@"Arguments: %@, %@", publishKey, subscribeKey);
       
        self.config =
        [PNConfiguration configurationWithPublishKey:publishKey
                                        subscribeKey:subscribeKey];
        self.config.stripMobilePayload = NO;
        if(uuid) {
            self.config.uuid = uuid;
        } else {
            self.config.uuid = [NSUUID UUID].UUIDString.lowercaseString;
        }
        
        self.client = [PubNub clientWithConfiguration:self.config];
        [self.client addListener:self];
    }
    
    return NULL;
}

- (id) handleSubscribe:(FlutterMethodCall*)call {

    NSArray *channels = call.arguments[@"channels"];
    
    if(channels) {
        NSLog(@"Arguments: %@", channels);
        
        [self.client addListener:self];
        [self.client subscribeToChannels:channels withPresence:YES];
    }
    
    return NULL;
}

- (void)handleStatus:(PNStatus *)status client:(PubNub*)client {
    if (status.isError) {
        [self.errorStreamHandler sendError:@{@"type":@"state", @"category": status.stringifiedCategory}];
    } else {
         [self.statusStreamHandler sendStatus:status];
    }
}

#pragma mark - Pubnub delegate methods

- (void)client:(PubNub *)client didReceiveStatus:(PNStatus *)status {
    NSLog(@"Received status: %@", status.stringifiedOperation);
    
    [self.statusStreamHandler sendStatus:status];
}

- (void)client:(PubNub *)client didReceiveMessage:(PNMessageResult *)message {
    
    // Handle new message stored in message.data.message
    if (![message.data.channel isEqualToString:message.data.subscription]) {
        
        // Message has been received on channel group stored in message.data.subscription.
    }
    else {
        
        // Message has been received on channel stored in message.data.channel.
    }
    
    NSLog(@"Received message: %@ on channel %@ uuid: %@ at %@", message.data.message[@"msg"],
          message.data.channel, message.uuid, message.data.timetoken);
    
    [self.messageStreamHandler sendMessage:message];
}

// New presence event handling.
- (void)client:(PubNub *)client didReceivePresenceEvent:(PNPresenceEventResult *)event {
    
    if (![event.data.channel isEqualToString:event.data.subscription]) {
        
        // Presence event has been received on channel group stored in event.data.subscription.
    }
    else {
        
        // Presence event has been received on channel stored in event.data.channel.
    }
    
    if (![event.data.presenceEvent isEqualToString:@"state-change"]) {
        
        NSLog(@"%@ \"%@'ed\"\nat: %@ on %@ (Occupancy: %@)", event.data.presence.uuid,
              event.data.presenceEvent, event.data.presence.timetoken, event.data.channel,
              event.data.presence.occupancy);
    }
    else {
        
        NSLog(@"%@ changed state at: %@ on %@ to: %@", event.data.presence.uuid,
              event.data.presence.timetoken, event.data.channel, event.data.presence.state);
    }
}

@end


@implementation MessageStreamHandler

- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)eventSink {
    self.eventSink = eventSink;
    return nil;
}

- (FlutterError*)onCancelWithArguments:(id)arguments {
    self.eventSink = nil;
    return nil;
}

- (void) sendMessage:(PNMessageResult *)message {
     if(self.eventSink) {
    
         NSDictionary *result = @{@"uuid": message.uuid, @"channel": message.data.channel, @"message": message.data.message};
         self.eventSink(result);
     }
}

@end

@implementation StatusStreamHandler

- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)eventSink {
    self.eventSink = eventSink;
    return nil;
}

- (FlutterError*)onCancelWithArguments:(id)arguments {
    self.eventSink = nil;
    return nil;
}

- (void) sendStatus:(PNStatus *)status {
    if(self.eventSink) {
        self.eventSink(@{@"operation": status.stringifiedOperation});
    }
}

@end

@implementation ErrorStreamHandler

- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)eventSink {
    self.eventSink = eventSink;
    return nil;
}

- (FlutterError*)onCancelWithArguments:(id)arguments {
    self.eventSink = nil;
    return nil;
}

- (void) sendError:(NSDictionary *)error {
    if(self.eventSink) {
        self.eventSink(error);
    }
}

@end

