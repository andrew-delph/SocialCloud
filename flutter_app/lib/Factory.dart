import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;

/*
It seems there are issues using plan-b and vpns for mobile.
 */
final Map<String, dynamic> rtcConfiguration = {
  "sdpSemantics": "unified-plan", //"plan-b",
  "iceServers": [
    {
      "urls": [
        "stun:stun1.l.google.com:19302",
        "stun:stun2.l.google.com:19302"
      ],
    },
    {
      "urls": "stun:relay.metered.ca:80",
    },
    {
      "urls": "turn:relay.metered.ca:80",
      "username": "db5611baf2f55446ccb6a207",
      "credential": "95Cmq0CBYp6WiHDA",
    },
    {
      "urls": "turn:relay.metered.ca:443",
      "username": "db5611baf2f55446ccb6a207",
      "credential": "95Cmq0CBYp6WiHDA",
    },
    {
      "urls": "turn:relay.metered.ca:443?transport=tcp",
      "username": "db5611baf2f55446ccb6a207",
      "credential": "95Cmq0CBYp6WiHDA",
    },
  ],
  "iceCandidatePoolSize": 10,
};

final Map<String, dynamic> offerSdpConstraints = {
  "mandatory": {
    "OfferToReceiveAudio": true,
    "OfferToReceiveVideo": true,
  },
  "optional": [],
};

class Factory {
  static Future<webrtc.RTCPeerConnection> createPeerConnection() async {
    webrtc.RTCPeerConnection peerConnection = await webrtc.createPeerConnection(
        rtcConfiguration, offerSdpConstraints);
    return peerConnection;
  }

  static String getWsHost() {
    return const String.fromEnvironment('WS_HOST',
        defaultValue: 'https://ws.solarsim.net');
  }

  static String getOptionsHost() {
    return const String.fromEnvironment('OPTIONS_HOST',
        defaultValue: 'https://options.solarsim.net');
  }
}
