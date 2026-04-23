import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logger/logger.dart';

class WebRtcService {
  WebRtcService({required this.onIceCandidate});

  final void Function(RTCIceCandidate candidate) onIceCandidate;
  final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  RTCPeerConnection? _peerConnection;
  MediaStream? _remoteStream;

  final _remoteStreamController = StreamController<MediaStream>.broadcast();
  Stream<MediaStream> get onRemoteStream => _remoteStreamController.stream;

  static const _iceServers = <Map<String, dynamic>>[
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
  ];

  Future<void> initialize() async {
    final config = <String, dynamic>{
      'iceServers': _iceServers,
      'sdpSemantics': 'unified-plan',
    };

    final constraints = <String, dynamic>{
      'mandatory': <String, dynamic>{},
      'optional': [
        {'DtlsSrtpKeyAgreement': true},
      ],
    };

    _peerConnection = await createPeerConnection(config, constraints);

    _peerConnection!.onIceCandidate = (candidate) {
      onIceCandidate(candidate);
    };

    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        _remoteStreamController.add(_remoteStream!);
        _logger.i('Remote stream received');
      }
    };

    _peerConnection!.onIceConnectionState = (state) {
      _logger.i('ICE connection state: $state');
    };

    _peerConnection!.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
    );
  }

  Future<RTCSessionDescription?> createOffer() async {
    if (_peerConnection == null) return null;

    final offer = await _peerConnection!.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': false,
    });

    final mungedSdp = _mungeAudioSdp(offer.sdp ?? '');
    final mungedOffer = RTCSessionDescription(mungedSdp, offer.type);

    await _peerConnection!.setLocalDescription(mungedOffer);
    return mungedOffer;
  }

  Future<void> handleAnswer(RTCSessionDescription answer) async {
    await _peerConnection?.setRemoteDescription(answer);
  }

  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    try {
      await _peerConnection?.addCandidate(candidate);
    } catch (e) {
      _logger.w('Failed to add ICE candidate, retrying: $e');
      await Future.delayed(const Duration(milliseconds: 500));
      try {
        await _peerConnection?.addCandidate(candidate);
      } catch (retryError) {
        _logger.e('ICE candidate retry failed: $retryError');
      }
    }
  }

  String _mungeAdp(String sdp) {
    return sdp.replaceAll(
      RegExp(r'a=fmtp:111 .*'),
      'a=fmtp:111 minptime=10;useinbandfec=1;maxaveragebitrate=24000;stereo=0;sprop-stereo=0;cbr=1',
    );
  }

  String _mungeAudioSdp(String sdp) {
    return _mungeAdp(sdp);
  }

  Future<void> dispose() async {
    _remoteStream?.dispose();
    await _peerConnection?.close();
    _peerConnection = null;
    _remoteStreamController.close();
  }
}
