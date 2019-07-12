#import "PubnubFlutterPlugin.h"

@interface PubnubFlutterPlugin ()<PNObjectEventListener>

@property (nonatomic, strong) NSMutableDictionary<NSString*, PubNub*> *clients;
@end

@implementation PubnubFlutterPlugin

NSString *const PUBNUB_FLUTTER_CHANNEL_NAME = @"flutter.ingenio.com/pubnub_flutter";
NSString *const PUBNUB_MESSAGE_CHANNEL_NAME = @"flutter.ingenio.com/pubnub_message";
NSString *const PUBNUB_STATUS_CHANNEL_NAME = @"flutter.ingenio.com/pubnub_status";
NSString *const PUBNUB_PRESENCE_CHANNEL_NAME = @"flutter.ingenio.com/pubnub_presence";
NSString *const PUBNUB_ERROR_CHANNEL_NAME = @"flutter.ingenio.com/pubnub_error";

NSString *const CLIENT_NAME_KEY = @"clientName";

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
    } else if  ([@"dispose" isEqualToString:call.method]) {
        result([self handleDispose:call]);
    } else if  ([@"subscribe" isEqualToString:call.method]) {
        result([self handleSubscribe:call]);
    } else if  ([@"publish" isEqualToString:call.method]) {
        result([self handlePublish:call]);
    } else if  ([@"presence" isEqualToString:call.method]) {
        result([self handlePresence:call]);
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
    NSString *clientName = call.arguments[CLIENT_NAME_KEY];
    
    if(clientName && self.clients[clientName]) {
        PubNub *client = self.clients[clientName];
        
        if(channel) {
            [client unsubscribeFromChannels:@[channel] withPresence:NO];
        } else {
            [client unsubscribeFromAll];
        }
    }
    
    return NULL;
}

- (id) handleDispose:(FlutterMethodCall*)call {
    
    for(PubNub *client in [self.clients allValues]) {
        [client unsubscribeFromAll];
    }

    [self.clients removeAllObjects];
    
    return NULL;
}

- (id) handleUUID:(FlutterMethodCall*)call {
    NSString *clientName = call.arguments[CLIENT_NAME_KEY];
    
    if(clientName && self.clients[clientName]) {
        NSLog(@"HANDLE UUID: %@", clientName);
        PubNub *client = self.clients[clientName];
        return [[client currentConfiguration] uuid];
    }
    
    return NULL;
}

- (id) handlePublish:(FlutterMethodCall*)call {
    NSString *channel = call.arguments[@"channel"];
    NSDictionary *message = call.arguments[@"message"];
    NSDictionary *metadata = call.arguments[@"metadata"];
    NSString *clientName = call.arguments[CLIENT_NAME_KEY];
    
    if(channel && message && clientName && self.clients[clientName]) {
        PubNub *client = self.clients[clientName];
            
         __weak __typeof(self) weakSelf = self;
        [client publish:message toChannel:channel withMetadata:metadata completion:^(PNPublishStatus *status) {
            __strong __typeof(self) strongSelf = weakSelf;
            [strongSelf handleStatus:status client:client];
        }];
    }
    
    return NULL;
}

- (id) handleCreate:(FlutterMethodCall*)call {
    
    if(self.clients == NULL) {
        self.clients = [NSMutableDictionary new];
    }
    
    NSArray *clientList = call.arguments[@"clients"];
    
    for(NSDictionary *client in clientList) {
        NSString *clientName = [client valueForKey:CLIENT_NAME_KEY];
        
        NSLog(@"CLIENT NAME: %@", clientName);
        
        if (![self.clients valueForKey:clientName]) {
            NSString *publishKey = client[@"publishKey"];
            NSString *subscribeKey = client[@"subscribeKey"];
            NSString *uuid = client[@"uuid"];
            NSString *filter = client[@"filter"];
            NSString *authKey = client[@"authKey"];
            NSNumber *presenceTimeout = client[@"presenceTimeout"];
            
            if(publishKey && subscribeKey) {
                NSLog(@"Create client - Arguments: %@, %@, %@", publishKey, subscribeKey, clientName);
                
                PNConfiguration *config =
                [PNConfiguration configurationWithPublishKey:publishKey
                                                subscribeKey:subscribeKey];
                config.stripMobilePayload = NO;
                if(uuid) {
                    config.uuid = uuid;
                }
                
                if(authKey) {
                    config.authKey = authKey;
                }
                
                if(presenceTimeout) {
                    config.presenceHeartbeatValue = [presenceTimeout integerValue];
                }
                
                PubNub *client = [PubNub clientWithConfiguration:config];
                
                if(filter) {
                    client.filterExpression = filter;
                }
                
                self.clients[clientName] = client;
                
                [client addListener:self];
            }
        }
    }
    
    return NULL;
}

- (id) handlePresence:(FlutterMethodCall*)call {
    NSString *channel = call.arguments[@"channel"];
    NSString *clientName = call.arguments[CLIENT_NAME_KEY];
    NSDictionary<NSString*, NSString*> *state = call.arguments[@"state"];
    
    if(channel && state && state.count > 0 && clientName && self.clients[clientName]) {
        PubNub *client = self.clients[clientName];
        
        NSLog(@"Set Presence: %@", state);
        
        [client setState: state forUUID:client.uuid onChannel: channel
               withCompletion:^(PNClientStateUpdateStatus *status) {
                   
                   if (status.isError) {
                       NSDictionary *result = @{@"operation":  [PubnubFlutterPlugin getOperationAsNumber:status.operation], @"error": @""};
                       [self.errorStreamHandler sendError:result];
                   }
                   else {
                      [self.statusStreamHandler sendStatus:status];
                   }
               }];
    }
    
    return NULL;
}
- (id) handleSubscribe:(FlutterMethodCall*)call {
    NSArray<NSString *> *channels = call.arguments[@"channels"];
    NSString *clientName = call.arguments[CLIENT_NAME_KEY];
    
    if(channels && channels.count > 0 && clientName && self.clients[clientName]) {
        PubNub *client = self.clients[clientName];
        
        NSLog(@"Arguments: %@", channels);
        
        [client subscribeToChannels:channels withPresence:YES];
    }
    
    return NULL;
}

- (void)handleStatus:(PNStatus *)status client:(PubNub*)client {
    if (status.isError) {
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
            return [NSNumber numberWithInt:20];
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
        default:
            return [NSNumber numberWithInt:0];
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
        NSLog(@"Presence state: %@", presence.data.presence.state);
        self.eventSink(@{@"channel": presence.data.channel, @"event": presence.data.presenceEvent, @"uuid": presence.data.presence.uuid, @"occupancy": presence.data.presence.occupancy, @"state": presence.data.presence.state == NULL ? [NSDictionary new] : presence.data.presence.state});
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

