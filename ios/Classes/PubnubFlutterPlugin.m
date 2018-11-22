#import "PubnubFlutterPlugin.h"
#import "PubNub.h"

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
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"getPlatformVersion" isEqualToString:call.method]) {
    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  } else if  ([@"subscribe" isEqualToString:call.method]) {
      NSLog(@"Register Pub Nub");

       result([self handleSubscribe:call]);
  }  else if  ([@"unsubscribe" isEqualToString:call.method]) {
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
        //[self.clients[channel] unsubscribeFromAll];
    }
    
    return NULL;
}

- (id) handleSubscribe:(FlutterMethodCall*)call {
    NSString *publishKey = call.arguments[@"publishKey"];
    NSString *subscribeKey = call.arguments[@"subscribeKey"];
    NSString *channel = call.arguments[@"channel"];
    
    if(publishKey && subscribeKey && channel) {
        NSLog(@"Arguments: %@, %@, %@", publishKey, subscribeKey, channel);
        if(self.configs == NULL) {
            self.configs = [NSMutableDictionary new];
        }
        
        PNConfiguration *config =
        [PNConfiguration configurationWithPublishKey:publishKey
                                        subscribeKey:subscribeKey];
        config.stripMobilePayload = NO;
        config.uuid = [NSUUID UUID].UUIDString.lowercaseString;
        
        self.configs[channel] = config;
        
        NSLog(@"Arguments: %@", channel);
        if(self.clients == NULL) {
            self.clients = [NSMutableDictionary new];
        }
        
        self.client = [PubNub clientWithConfiguration:self.configs[channel]];
        [self.client addListener:self];
        [self.client subscribeToChannels:@[channel] withPresence:YES];
       // self.clients[channel] = [PubNub clientWithConfiguration:self.configs[channel]];
        //[self.clients[channel] addListener:self];
        // Subscribe to channel
        //[self.clients[channel] subscribeToChannels: @[channel] withPresence:YES];
    }
    
    return NULL;
}

#pragma mark - Pubnub delegate methods

- (void)client:(PubNub *)client didReceiveStatus:(PNStatus *)status {
    NSLog(@"Received status: %@", status.stringifiedOperation);
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
