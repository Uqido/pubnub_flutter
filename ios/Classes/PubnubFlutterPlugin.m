#import "PubnubFlutterPlugin.h"

@interface PubnubFlutterPlugin ()<PNObjectEventListener>

@property (nonatomic, strong) PubNub* client;

// Holds the configs, indexed per channel
@property (nonatomic, strong) NSMutableDictionary <NSString *, PNConfiguration *> *configs;

// Holds the pubnub clients indexed per channel
@property (nonatomic, strong) NSMutableDictionary <NSString *, PubNub *> *clients;

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
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"getPlatformVersion" isEqualToString:call.method]) {
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    } else if  ([@"create" isEqualToString:call.method]) {
        NSLog(@"Create Pub Nub");
        
        result([self handleCreate:call]);
    } else if  ([@"subscribe" isEqualToString:call.method]) {
        NSLog(@"Register Pub Nub");
        
        result([self handleSubscribe:call]);
    } else if  ([@"unsubscribe" isEqualToString:call.method]) {
        NSLog(@"Unsubscribe Pub Nub");
        
        result([self handleUnsubscribe:call]);
    } else if  ([@"unsubscribe_all" isEqualToString:call.method]) {
        NSLog(@"Unsubscribe Pub Nub");
        
        result([self handleUnsubscribe:call]);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (id) handleUnsubscribe:(FlutterMethodCall*)call {
    NSString *channel = call.arguments[@"channel"];
    
    if(channel) {
        [self.client unsubscribeFromChannels:@[channel] withPresence:NO];
    } else {
        [self.clients[channel] unsubscribeFromAll];
    }
    
    return NULL;
}

- (id) handleCreate:(FlutterMethodCall*)call {
    NSString *publishKey = call.arguments[@"publishKey"];
    NSString *subscribeKey = call.arguments[@"subscribeKey"];
    
    if(publishKey && subscribeKey) {
        NSLog(@"Arguments: %@, %@", publishKey, subscribeKey);
       
        PNConfiguration *config =
        [PNConfiguration configurationWithPublishKey:publishKey
                                        subscribeKey:subscribeKey];
        config.stripMobilePayload = NO;
        config.uuid = [NSUUID UUID].UUIDString.lowercaseString;
      
        self.client = [PubNub clientWithConfiguration:config];
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
    
    
    NSLog(@"Received message: %@ on channel %@ at %@", message.data.message[@"msg"],
          message.data.channel, message.data.timetoken);
    
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
         self.eventSink(message.data.message);
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
        self.eventSink(status.stringifiedOperation);
    }
}

@end

