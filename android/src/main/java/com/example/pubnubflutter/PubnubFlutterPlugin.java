package com.example.pubnubflutter;

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
import com.pubnub.api.models.consumer.PNPublishResult;
import com.pubnub.api.models.consumer.PNStatus;
import com.pubnub.api.models.consumer.presence.PNSetStateResult;
import com.pubnub.api.models.consumer.pubsub.PNMessageResult;
import com.pubnub.api.models.consumer.pubsub.PNPresenceEventResult;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * PubnubFlutterPlugin
 */
public class PubnubFlutterPlugin implements MethodCallHandler {

    private static final String PUBNUB_FLUTTER_CHANNEL_NAME =
            "plugins.flutter.io/pubnub_flutter";
    private static final String PUBNUB_MESSAGE_CHANNEL_NAME =
            "plugins.flutter.io/pubnub_message";
    private static final String PUBNUB_STATUS_CHANNEL_NAME =
            "plugins.flutter.io/pubnub_status";
    private static final String PUBNUB_ERROR_CHANNEL_NAME =
            "plugins.flutter.io/pubnub_error";

    static private MessageStreamHandler messageStreamHandler;
    static private StatusStreamHandler statusStreamHandler;
    static private ErrorStreamHandler errorStreamHandler;

    private static PubNub client;

    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {

        PubnubFlutterPlugin instance = new PubnubFlutterPlugin();

        final MethodChannel channel = new MethodChannel(registrar.messenger(), PUBNUB_FLUTTER_CHANNEL_NAME);
        channel.setMethodCallHandler(instance);

        messageStreamHandler = new MessageStreamHandler();
        final EventChannel messageChannel =
                new EventChannel(registrar.messenger(), PUBNUB_MESSAGE_CHANNEL_NAME);

        messageChannel.setStreamHandler(messageStreamHandler);

        statusStreamHandler = new StatusStreamHandler();
        final EventChannel statusChannel =
                new EventChannel(registrar.messenger(), PUBNUB_STATUS_CHANNEL_NAME);

        statusChannel.setStreamHandler(statusStreamHandler);

        errorStreamHandler = new ErrorStreamHandler();
        final EventChannel errorChannel =
                new EventChannel(registrar.messenger(), PUBNUB_ERROR_CHANNEL_NAME);

        errorChannel.setStreamHandler(errorStreamHandler);

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
            case "setState":
                if (handleSetState(call)) {
                    result.success(true);
                } else {
                    result.error("ERROR", "Cannot Set State.", null);
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
                String uuid = handleUuid();

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

    boolean handleCreate(MethodCall call) {
        String publishKey = call.argument("publishKey");
        String subscribeKey = call.argument("subscribeKey");
        String uuid = call.argument("uuid");
        String filter = call.argument("filter");
        PNConfiguration config;

        if(client == null) {
            if (publishKey != null && subscribeKey != null) {
                config = new PNConfiguration();
                config.setPublishKey(publishKey);
                config.setSubscribeKey(subscribeKey);
                if (uuid != null) {
                    config.setUuid(uuid);
                }
                if (filter != null) {
                    config.setFilterExpression(filter);
                }

                client = new PubNub(config);

                System.out.println("CREATE: " + client);

                client.addListener(new SubscribeCallback() {
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
                    }
                });

                return true;
            }
            System.out.println("CREATE FAILED");


            return false;
        }

        return true;
    }

    String handleUuid() {
        if(client != null) {
            return client.getConfiguration().getUuid();
        }

        return null;
    }

    boolean handleSubscribe(MethodCall call) {
        List<String> channels = call.argument("channels");

        if(client != null && channels != null && !channels.isEmpty()) {
            System.out.println("SUBSCRIBE");
                client.subscribe().channels(channels).execute();

            return true;
        }

        return false;
    }

    boolean handleUnsubscribe(MethodCall call) {
        String channel = call.argument("channel");

        if(client != null) {
            if (channel != null) {
                List<String> channels = new ArrayList<>();
                channels.add(channel);
                client.unsubscribe().channels(channels).execute();

                return true;
            } else {
                client.unsubscribeAll();
                return true;
            }
        }

        return false;
    }

    private boolean handlePublish(MethodCall call) {
        String channel = call.argument("channel");
        Map message = call.argument("message");
        Map metadata = call.argument("metadata");

        if(client != null && channel != null && message != null) {
            client.publish().channel(channel).message(message).meta(metadata).async(new PNCallback<PNPublishResult>() {
                @Override
                public void onResponse(PNPublishResult result, PNStatus status) {
                    handleStatus(status);
                }
            });

            return true;
        }

        return false;
    }

    boolean handleSetState(MethodCall call) {
        String channel = call.argument("channel");
        String uuid = call.argument("uuid");
        String state = call.argument("state");

        if(client != null && channel != null && uuid != null && state != null) {
            List<String> channels = new ArrayList<>();
            channels.add(channel);
            client.setPresenceState().uuid(uuid).channels(channels).async(new PNCallback<PNSetStateResult>() {
                @Override
                public void onResponse(PNSetStateResult result, PNStatus status) {
                    handleStatus(status);
                }
            });

            return true;
        }

        return false;
    }

    void handleStatus(PNStatus status) {
        if(status.isError()) {
            Map<String, String> map = new HashMap<>();
            map.put("type", "state");
            map.put("category", status.getCategory().toString());
            errorStreamHandler.sendError(map);
        } else {
            statusStreamHandler.sendStatus(status);
        }
    }

    public abstract static class BaseStreamHandler implements EventChannel.StreamHandler {
        private EventChannel.EventSink sink;

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

                Map<String, String> map = new HashMap<>();
                map.put("uuid", message.getPublisher());
                map.put("channel", message.getChannel());
                map.put("message", message.getMessage().toString());

                // Send message
                super.sink.success(map);
            }
        }
    }

    public static class StatusStreamHandler extends BaseStreamHandler {

        void sendStatus(PNStatus status) {
            if (super.sink != null) {
                // Send message
                Map<String, String> map = new HashMap<>();
                map.put("operation", status.getOperation().toString());
                super.sink.success(map);
            }
        }
    }

    public static class ErrorStreamHandler extends BaseStreamHandler {

        void sendError(Map map) {
            if (super.sink != null) {
                // Send message
                super.sink.success(map);
            }
        }
    }

}
