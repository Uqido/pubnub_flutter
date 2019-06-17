#import "PubnubFlutterPlugin.h"

@interface PubnubFlutterPlugin ()<PNObjectEventListener>

@property (nonatomic, strong) PubNub* client;
@property (nonatomic, strong) PNConfiguration *config;
@end

@implementation PubnubFlutterPlugin

NSString *const PUBNUB_FLUTTER_CHANNEL_NAME = @"flutter.ingenio.com/pubnub_flutter";
NSString *const PUBNUB_MESSAGE_CHANNEL_NAME = @"flutter.ingenio.com/pubnub_message";
NSString *const PUBNUB_STATUS_CHANNEL_NAME = @"flutter.ingenio.com/pubnub_status";
NSString *const PUBNUB_PRESENCE_CHANNEL_NAME = @"flutter.ingenio.com/pubnub_presence";
NSString *const PUBNUB_ERROR_CHANNEL_NAME = @"flutter.ingenio.com/pubnub_error";

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:PUBNUB_FLUTTER_CHANNEL_NAME
                                     binaryMessenger:[registrar messenger]];
    PubnubFlutterPlugin* instance = [[PubnubFlutterPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
    
    // Event channel for streams
    instance.messageStreamHandler = [MessageStreamHandler new];
    
    FlutterEventChannel* messageChannel =
    [FlutterEventChannel eventChannelWithName:PUBNUB_MESSAGE_CHANNEL_NAME
                              binaryMessenger:[registrar messenger]];
    [messageChannel setStreamHandler:instance.messageStreamHandler];
    
    // Event channel for streams
    instance.statusStreamHandler = [StatusStreamHandler new];
    
    FlutterEventChannel* statusChannel =
    [FlutterEventChannel eventChannelWithName:PUBNUB_STATUS_CHANNEL_NAME
                              binaryMessenger:[registrar messenger]];
    [statusChannel setStreamHandler:instance.statusStreamHandler];
    
    // Event channel for streams
    instance.presenceStreamHandler = [PresenceStreamHandler new];
    
    FlutterEventChannel* presenceChannel =
    [FlutterEventChannel eventChannelWithName:PUBNUB_PRESENCE_CHANNEL_NAME
                              binaryMessenger:[registrar messenger]];
    [presenceChannel setStreamHandler:instance.presenceStreamHandler];
    
    instance.errorStreamHandler = [ErrorStreamHandler new];
    
    FlutterEventChannel* errorChannel =
    [FlutterEventChannel eventChannelWithName:PUBNUB_ERROR_CHANNEL_NAME
                              binaryMessenger:[registrar messenger]];
    [errorChannel setStreamHandler:instance.errorStreamHandler];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if  ([@"create" isEqualToString:call.method]) {
        result([self handleCreate:call]);
    } else if  ([@"subscribe" isEqualToString:call.method]) {
        result([self handleSubscribe:call]);
    } else if  ([@"publish" isEqualToString:call.method]) {
        result([self handlePublish:call]);
    } else if  ([@"unsubscribe" isEqualToString:call.method]) {
        result([self handleUnsubscribe:call]);
    } else if  ([@"unsubscribe_all" isEqualToString:call.method]) {
        result([self handleUnsubscribe:call]);
    } else if  ([@"uuid" isEqualToString:call.method]) {     
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

- (id) handleUUID:(FlutterMethodCall*)call {
    
    return self.config.uuid;
}

- (id) handlePublish:(FlutterMethodCall*)call {
    NSString *channel = call.arguments[@"channel"];
    NSDictionary *message = call.arguments[@"message"];
    NSDictionary *metadata = call.arguments[@"metadata"];

    if(channel && message) {
         __weak __typeof(self) weakSelf = self;
        [weakSelf.client publish:message toChannel:channel withMetadata:metadata completion:^(PNPublishStatus *status) {
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
    NSString *filter = call.arguments[@"filter"];
    NSString *authKey = call.arguments[@"authKey"];
    NSNumber *presenceTimeout = call.arguments[@"presenceTimeout"];
    
    if(publishKey && subscribeKey) {
        NSLog(@"Arguments: %@, %@", publishKey, subscribeKey);
       
        self.config =
        [PNConfiguration configurationWithPublishKey:publishKey
                                        subscribeKey:subscribeKey];
        self.config.stripMobilePayload = NO;
        if(uuid) {
            self.config.uuid = uuid;
        }
        
        if(authKey) {
            self.config.authKey = authKey;
        }
        
        if(presenceTimeout) {
            self.config.presenceHeartbeatValue = [presenceTimeout integerValue];
        }
 
        self.client = [PubNub clientWithConfiguration:self.config];
        
        if(filter) {
            self.client.filterExpression = filter;
        }
        
        [self.client addListener:self];
    }
    
    return NULL;
}

- (id) handleSubscribe:(FlutterMethodCall*)call {

    NSArray *channels = call.arguments[@"channels"];
    
    if(channels) {
        NSLog(@"Arguments: %@", channels);
        
        [self.client subscribeToChannels:channels withPresence:YES];
    }
    
    return NULL;
}

- (void)handleStatus:(PNStatus *)status client:(PubNub*)client {
    if (status.isError) {
        [self.errorStreamHandler sendError:@{@"type":@"state", @"category":  [PubnubFlutterPlugin getCategoryAsNumber:status.category]}];
        NSDictionary *result = @{@"operation":  [PubnubFlutterPlugin getOperationAsNumber:status.operation], @"error": @""};
        [self.errorStreamHandler sendError:result];
        
    } else {
         [self.statusStreamHandler sendStatus:status];
    }
}

#pragma mark - Pubnub delegate methods

- (void)client:(PubNub *)client didReceiveStatus:(PNStatus *)status {
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
- (void)client:(PubNub *)client didReceivePresenceEvent:(PNPresenceEventResult *)presence {
    
    if (![presence.data.channel isEqualToString:presence.data.subscription]) {
        
        // Presence event has been received on channel group stored in event.data.subscription.
    }
    else {
        
        // Presence event has been received on channel stored in event.data.channel.
    }
    
    if (![presence.data.presenceEvent isEqualToString:@"state-change"]) {
        
        NSLog(@"%@ \"%@'ed\"\nat: %@ on %@ (Occupancy: %@)", presence.data.presence.uuid,
              presence.data.presenceEvent, presence.data.presence.timetoken, presence.data.channel,
              presence.data.presence.occupancy);
    }
    else {
        
        NSLog(@"%@ changed state at: %@ on %@ to: %@", presence.data.presence.uuid,
              presence.data.presence.timetoken, presence.data.channel, presence.data.presence.state);
    }
    
    [self.presenceStreamHandler sendPresence:presence];
}


+ (NSNumber *) getCategoryAsNumber:(PNStatusCategory) category {
    switch(category) {
            
        case PNUnknownCategory:
            return [NSNumber numberWithInt:0];
        case PNAcknowledgmentCategory:
            return [NSNumber numberWithInt:1];
        case PNAccessDeniedCategory:
            return [NSNumber numberWithInt:2];
        case PNTimeoutCategory:
            return [NSNumber numberWithInt:3];
        case PNNetworkIssuesCategory:
            return [NSNumber numberWithInt:4];
        case PNConnectedCategory:
            return [NSNumber numberWithInt:5];
        case PNReconnectedCategory:
            return [NSNumber numberWithInt:6];
        case PNDisconnectedCategory:
            return [NSNumber numberWithInt:7];
        case PNUnexpectedDisconnectCategory:
            return [NSNumber numberWithInt:8];
        case PNCancelledCategory:
            return [NSNumber numberWithInt:9];
        case PNBadRequestCategory:
            return [NSNumber numberWithInt:10];
        case PNMalformedFilterExpressionCategory:
            return [NSNumber numberWithInt:11];
        case PNMalformedResponseCategory:
            return [NSNumber numberWithInt:12];
        case PNDecryptionErrorCategory:
            return [NSNumber numberWithInt:13];
        case PNTLSConnectionFailedCategory:
            return [NSNumber numberWithInt:14];
        case PNTLSUntrustedCertificateCategory:
            return [NSNumber numberWithInt:15];
        case PNRequestMessageCountExceededCategory:
            return [NSNumber numberWithInt:16];
        case PNRequestURITooLongCategory:
            return [NSNumber numberWithInt:0];
    }
    
    return [NSNumber numberWithInt:0];
}

+ (NSNumber *)  getOperationAsNumber:(PNOperationType) operation {
    switch (operation) {
        
        case PNSubscribeOperation:
            return [NSNumber numberWithInt:1];
        case PNUnsubscribeOperation:
            return [NSNumber numberWithInt:2];
        case PNPublishOperation:
           return [NSNumber numberWithInt:3];
        case PNHistoryOperation:
            return [NSNumber numberWithInt:4];
        case PNHistoryForChannelsOperation:
            return [NSNumber numberWithInt:0];
        case PNDeleteMessageOperation:
            return [NSNumber numberWithInt:6];
        case PNWhereNowOperation:
            return [NSNumber numberWithInt:7];
        case PNHereNowGlobalOperation:
            return [NSNumber numberWithInt:0];
        case PNHereNowForChannelOperation:
            return [NSNumber numberWithInt:0];
        case PNHereNowForChannelGroupOperation:
           return [NSNumber numberWithInt:0];
        case PNHeartbeatOperation:
            return [NSNumber numberWithInt:8];
        case PNSetStateOperation:
            return [NSNumber numberWithInt:9];
        case PNGetStateOperation:
            return [NSNumber numberWithInt:21];
        case PNStateForChannelOperation:
            return [NSNumber numberWithInt:0];
        case PNStateForChannelGroupOperation:
            return [NSNumber numberWithInt:0];
        case PNAddChannelsToGroupOperation:
            return [NSNumber numberWithInt:10];
        case PNRemoveChannelsFromGroupOperation:
            return [NSNumber numberWithInt:11];
        case PNChannelGroupsOperation:
            return [NSNumber numberWithInt:12];
        case PNRemoveGroupOperation:
            return [NSNumber numberWithInt:13];
        case PNChannelsForGroupOperation:
            return [NSNumber numberWithInt:14];
        case PNPushNotificationEnabledChannelsOperation:
            return [NSNumber numberWithInt:15];
        case PNAddPushNotificationsOnChannelsOperation:
            return [NSNumber numberWithInt:16];
        case PNRemovePushNotificationsFromChannelsOperation:
            return [NSNumber numberWithInt:17];;
        case PNRemoveAllPushNotificationsOperation:
            return [NSNumber numberWithInt:18];
        case PNTimeOperation:
            return [NSNumber numberWithInt:19];
    }
    
    return [NSNumber numberWithInt:0];
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
        
        self.eventSink(@{@"category": [PubnubFlutterPlugin getCategoryAsNumber:status.category],@"operation": [PubnubFlutterPlugin getOperationAsNumber:status.operation], @"uuid": status.uuid});
    }
}

@end

@implementation PresenceStreamHandler

- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)eventSink {
    self.eventSink = eventSink;
    return nil;
}

- (FlutterError*)onCancelWithArguments:(id)arguments {
    self.eventSink = nil;
    return nil;
}

- (void) sendPresence:(PNPresenceEventResult *)presence {
    if(self.eventSink) {
        
        self.eventSink(@{@"channel": presence.data.channel, @"event": presence.data.presenceEvent, @"uuid": presence.data.presence.uuid, @"occupancy": presence.data.presence.occupancy});
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

