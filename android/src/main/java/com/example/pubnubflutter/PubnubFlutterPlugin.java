package com.example.pubnubflutter;

import android.os.Handler;
import android.os.Looper;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import com.google.gson.JsonElement;
import com.pubnub.api.PNConfiguration;
import com.pubnub.api.PubNub;
import com.pubnub.api.callbacks.PNCallback;
import com.pubnub.api.callbacks.SubscribeCallback;
import com.pubnub.api.enums.PNOperationType;
import com.pubnub.api.enums.PNStatusCategory;
import com.pubnub.api.models.consumer.PNPublishResult;
import com.pubnub.api.models.consumer.PNStatus;
import com.pubnub.api.models.consumer.pubsub.PNMessageResult;
import com.pubnub.api.models.consumer.pubsub.PNPresenceEventResult;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.Executor;

/**
 * PubnubFlutterPlugin
 */
public class PubnubFlutterPlugin implements MethodCallHandler {

    private static final String PUBNUB_FLUTTER_CHANNEL_NAME =
            "flutter.ingenio.com/pubnub_flutter";
    private static final String PUBNUB_MESSAGE_CHANNEL_NAME =
            "flutter.ingenio.com/pubnub_message";
    private static final String PUBNUB_STATUS_CHANNEL_NAME =
            "flutter.ingenio.com/pubnub_status";
    private static final String PUBNUB_PRESENCE_CHANNEL_NAME =
            "flutter.ingenio.com/pubnub_presence";
    private static final String PUBNUB_ERROR_CHANNEL_NAME =
            "flutter.ingenio.com/pubnub_error";

    private static final String CLIENT_NAME_KEY = "clientName";

    private Map<String, PubNub> clients = new HashMap<>();

    private MessageStreamHandler messageStreamHandler;
    private StatusStreamHandler statusStreamHandler;
    private ErrorStreamHandler errorStreamHandler;
    private PresenceStreamHandler presenceStreamHandler;

    private PubnubFlutterPlugin() {
        System.out.println("PubnubFlutterPlugin constructor");
        messageStreamHandler = new MessageStreamHandler();
        statusStreamHandler = new StatusStreamHandler();
        errorStreamHandler = new ErrorStreamHandler();
        presenceStreamHandler = new PresenceStreamHandler();
    }

    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        System.out.println("PubnubFlutterPlugin registerWith");

        PubnubFlutterPlugin instance = new PubnubFlutterPlugin();

        final MethodChannel channel = new MethodChannel(registrar.messenger(), PUBNUB_FLUTTER_CHANNEL_NAME);
        channel.setMethodCallHandler(instance);


        final EventChannel messageChannel =
                new EventChannel(registrar.messenger(), PUBNUB_MESSAGE_CHANNEL_NAME);

        messageChannel.setStreamHandler(instance.messageStreamHandler);


        final EventChannel statusChannel =
                new EventChannel(registrar.messenger(), PUBNUB_STATUS_CHANNEL_NAME);

        statusChannel.setStreamHandler(instance.statusStreamHandler);

        final EventChannel presenceChannel =
                new EventChannel(registrar.messenger(), PUBNUB_PRESENCE_CHANNEL_NAME);

        presenceChannel.setStreamHandler(instance.presenceStreamHandler);


        final EventChannel errorChannel =
                new EventChannel(registrar.messenger(), PUBNUB_ERROR_CHANNEL_NAME);

        errorChannel.setStreamHandler(instance.errorStreamHandler);

    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        switch (call.method) {
            case "create":
                if (handleCreate(call)) {
                    result.success(true);
                } else {
                    result.error("ERROR", "Wrong PubNub Credentials.", null);
                }
                break;
            case "subscribe":
                if (handleSubscribe(call)) {
                    result.success(true);
                } else {
                    result.error("ERROR", "Cannot Subscribe.", null);
                }
                break;
            case "publish":
                if (handlePublish(call)) {
                    result.success(true);
                } else {
                    result.error("ERROR", "Cannot Publish.", null);
                }
                break;
            case "unsubscribe":
                if (handleUnsubscribe(call)) {
                    result.success(true);
                } else {
                    result.error("ERROR", "Cannot Unsubscribe.", null);
                }
                break;
            case "uuid":
                String uuid = handleUuid(call);

                if (uuid != null) {
                    result.success(uuid);
                } else {
                    result.error("ERROR", "Cannot Get UUID. PubNub Client Not Configured.", null);
                }
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    // PubNubFlutter({'clients':[{'clientName':'client1','pubKey':'xxx','subKey': 'rrrr', 'authKey':'wwwww', 'presenceTimeout':20, 'uuid':'ytttttt', 'filter':'vddsfdsfds'},
    ////                 'client2':{'subKey': 'ttttt', 'authKey':'fffff'}});
    private boolean handleCreate(MethodCall call) {
        System.out.println("PubnubFlutterPlugin handleCreate");

        List<HashMap> clientList = call.argument("clients");

        System.out.println("IN HANDLE CREATE: ");

        for (Map<String, Object> client : clientList) {
            String clientName = client.get(CLIENT_NAME_KEY).toString();
            System.out.println("CLIENT NAME: " + clientName);

            if (!clients.containsKey(clientName)) {
                Object publishKey = client.get("publishKey");
                Object subscribeKey = client.get("subscribeKey");
                Object authKey = client.get("authKey");
                Object presenceTimeout = client.get("presenceTimeout");
                Object uuid = client.get("uuid");
                Object filter = client.get("filter");
                PNConfiguration config;

                if (publishKey != null && subscribeKey != null) {
                    System.out.println("CREATE CLIENT: " + clientName);

                    config = new PNConfiguration();
                    config.setPublishKey(publishKey.toString());
                    config.setSubscribeKey(subscribeKey.toString());

                    if (authKey != null) {
                        config.setAuthKey(authKey.toString());
                    }

                    if (presenceTimeout != null && presenceTimeout instanceof Integer && ((Integer) presenceTimeout).intValue() > 0) {
                        config.setPresenceTimeout(((Integer) presenceTimeout).intValue());
                    }

                    if (uuid != null) {
                        config.setUuid(uuid.toString());
                    }
                    if (filter != null) {
                        config.setFilterExpression(filter.toString());
                    }

                    clients.put(clientName, new PubNub(config));

                    clients.get(clientName).addListener(new SubscribeCallback() {
                        @Override
                        public void status(PubNub pubnub, PNStatus status) {
                            System.out.println("IN STATUS");
                            statusStreamHandler.sendStatus(status);
                        }

                        @Override
                        public void message(PubNub pubnub, PNMessageResult message) {
                            System.out.println("IN MESSAGE");
                            messageStreamHandler.sendMessage(message);
                        }

                        @Override
                        public void presence(PubNub pubnub, PNPresenceEventResult presence) {
                            System.out.println("IN PRESENCE");
                            presenceStreamHandler.sendPresence(presence);
                        }
                    });
                }
            }
        }

        return true;

    }

    private String handleUuid(MethodCall call) {
        String clientName = call.argument(CLIENT_NAME_KEY);
        if(clientName != null && clients.get(clientName) != null) {
            return clients.get(clientName).getConfiguration().getUuid();
        }

        return null;
    }

    private boolean handleSubscribe(MethodCall call) {
        List<String> channels = call.argument("channels");
        String clientName = call.argument(CLIENT_NAME_KEY);

        if(clientName != null && clients.get(clientName) != null && channels != null && !channels.isEmpty()) {
            System.out.println("SUBSCRIBE");
            clients.get(clientName).subscribe().channels(channels).withPresence().execute();

            return true;
        }

        return false;
    }

    private boolean handleUnsubscribe(MethodCall call) {
        String channel = call.argument("channel");
        String clientName = call.argument(CLIENT_NAME_KEY);

        if(clientName != null && clients.get(clientName) != null) {
            if (channel != null) {
                List<String> channels = new ArrayList<>();
                channels.add(channel);
                clients.get(clientName).unsubscribe().channels(channels).execute();

                return true;
            } else {
                clients.get(clientName).unsubscribeAll();
                return true;
            }
        }

        return false;
    }

    private boolean handlePublish(MethodCall call) {
        String clientName = call.argument(CLIENT_NAME_KEY);
        String channel = call.argument("channel");
        Map message = call.argument("message");
        Map metadata = call.argument("metadata");

        if(clientName != null && clients.get(clientName) != null && channel != null && message != null) {
            clients.get(clientName).publish().channel(channel).message(message).meta(metadata).async(new PNCallback<PNPublishResult>() {
                @Override
                public void onResponse(PNPublishResult result, PNStatus status) {
                    handleStatus(status);
                }
            });

            return true;
        }

        return false;
    }

    private void handleStatus(PNStatus status) {
        System.out.println("Status:" + status);
        if(status.isError()) {
            Map<String, Object> map = new HashMap<>();
            map.put("operation", PubnubFlutterPlugin.getOperationAsNumber(status.getOperation()));
            map.put("error", status.getErrorData().toString());
            errorStreamHandler.sendError(map);
        } else {
            statusStreamHandler.sendStatus(status);
        }
    }

    private static int getCategoryAsNumber(PNStatusCategory category) {

        switch(category) {

            case PNUnknownCategory:
                return 0;
            case PNAcknowledgmentCategory:
                return 1;
            case PNAccessDeniedCategory:
                return 2;
            case PNTimeoutCategory:
                return 3;
            case PNNetworkIssuesCategory:
                return 4;
            case PNConnectedCategory:
                return 5;
            case PNReconnectedCategory:
                return 6;
            case PNDisconnectedCategory:
                return 7;
            case PNUnexpectedDisconnectCategory:
                return 8;
            case PNCancelledCategory:
                return 9;
            case PNBadRequestCategory:
                return 10;
            case PNMalformedFilterExpressionCategory:
                return 11;
            case PNMalformedResponseCategory:
                return 12;
            case PNDecryptionErrorCategory:
                return 13;
            case PNTLSConnectionFailedCategory:
                return 14;
            case PNTLSUntrustedCertificateCategory:
                return 15;
            case PNRequestMessageCountExceededCategory:
                return 16;
            case PNReconnectionAttemptsExhausted:
                return 0;
        }

        return 0;
    }

    private static int getOperationAsNumber(PNOperationType operation) {
        switch (operation) {

            case PNSubscribeOperation:
                return 1;
            case PNUnsubscribeOperation:
                return 2;
            case PNPublishOperation:
                return 3;
            case PNHistoryOperation:
                return 4;
            case PNFetchMessagesOperation:
                return 5;
            case PNDeleteMessagesOperation:
                return 6;
            case PNWhereNowOperation:
                return 7;
            case PNHeartbeatOperation:
                return 8;
            case PNSetStateOperation:
                return 9;
            case PNAddChannelsToGroupOperation:
                return 10;
            case PNRemoveChannelsFromGroupOperation:
                return 11;
            case PNChannelGroupsOperation:
                return 12;
            case PNRemoveGroupOperation:
                return 13;
            case PNChannelsForGroupOperation:
                return 14;
            case PNPushNotificationEnabledChannelsOperation:
                return 15;
            case PNAddPushNotificationsOnChannelsOperation:
                return 16;
            case PNRemovePushNotificationsFromChannelsOperation:
                return 17;
            case PNRemoveAllPushNotificationsOperation:
                return 18;
            case PNTimeOperation:
                return 19;
            case PNHereNowOperation:
                return 0;
            case PNGetState:
                return 0;
            case PNAccessManagerAudit:
                return 0;
            case PNAccessManagerGrant:
                return 0;
        }

        return 0;
    }

    public abstract static class BaseStreamHandler implements EventChannel.StreamHandler {
        private EventChannel.EventSink sink;
        protected Executor executor = new MainThreadExecutor();

        @Override
        public void onListen(Object o, EventChannel.EventSink eventSink) {
            this.sink = eventSink;
        }

        @Override
        public void onCancel(Object o) {
            this.sink = null;
        }
    }

    public static class MessageStreamHandler extends BaseStreamHandler {

        void sendMessage(PNMessageResult message) {
            if (super.sink != null) {

                System.out.println("publisher: " + message.getPublisher());

                final Map<String, String> map = new HashMap<>();
                map.put("uuid", message.getPublisher());
                map.put("channel", message.getChannel());
                map.put("message", message.getMessage().toString());

                // Send message
                executor.execute(new Runnable() {
                    @Override
                    public void run() {
                        MessageStreamHandler.super.sink.success(map);
                    }
                });

            }
        }
    }

    public static class StatusStreamHandler extends BaseStreamHandler {

        void sendStatus(PNStatus status) {
            if (super.sink != null) {
                // Send message
                final Map<String, Object> map = new HashMap<>();
                map.put("category", PubnubFlutterPlugin.getCategoryAsNumber(status.getCategory()));
                map.put("operation", PubnubFlutterPlugin.getOperationAsNumber(status.getOperation()));
                map.put("uuid", status.getUuid());
                map.put("channels", status.getAffectedChannels());

                executor.execute(new Runnable() {
                    @Override
                    public void run() {
                        StatusStreamHandler.super.sink.success(map);
                    }
                });

            }
        }
    }

    public static class PresenceStreamHandler extends BaseStreamHandler {

        void sendPresence(PNPresenceEventResult presence) {
            System.out.println(presence.toString());
            JsonElement state = presence.getState();
            if (state != null) {
                System.out.println("presence state: " + state.toString());
            }
            Object userMetadata = presence.getUserMetadata();
            if (userMetadata != null) {
                System.out.println("presence meta data: " + userMetadata.toString());
            }
            if (super.sink != null) {
                // Send message
                final Map<String, Object> map = new HashMap<>();
                map.put("channel", presence.getChannel());
                map.put("event", presence.getEvent());
                map.put("uuid", presence.getUuid());
                map.put("occupancy", presence.getOccupancy());
                executor.execute(new Runnable() {
                    @Override
                    public void run() {
                        PresenceStreamHandler.super.sink.success(map);
                    }
                });

            }
        }
    }

    public static class ErrorStreamHandler extends BaseStreamHandler {

        void sendError(final Map map) {
            if (super.sink != null) {
                // Send message
                executor.execute(new Runnable() {
                    @Override
                    public void run() {
                        ErrorStreamHandler.super.sink.success(map);
                    }
                });
            }
        }
    }

    private static class MainThreadExecutor implements Executor {

        final Handler handler = new Handler(Looper.getMainLooper());

        @Override
        public void execute(Runnable command) {
            handler.post(command);
        }
    }


}
