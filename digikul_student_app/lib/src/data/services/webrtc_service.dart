import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logger/logger.dart';

import 'package:digikul_student_app/src/core/config/app_config.dart';
import 'package:digikul_student_app/src/core/constants/app_constants.dart';
import 'package:digikul_student_app/src/data/services/socket_service.dart';

/// WebRTC service for audio communication in live sessions
class WebRTCService {
  factory WebRTCService() => _instance;

  WebRTCService._internal() {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
    );
    _socketService = SocketService();
  }
  late Logger _logger;
  late SocketService _socketService;
  
  // WebRTC components
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  
  // Connection state
  String? _currentSessionId;
  String? _currentUserId;
  bool _isInitialized = false;
  bool _isConnected = false;
  bool _isMuted = true;
  bool _isSpeakerOn = false;
  
  // Stream controllers for state updates
  final _connectionStateController = StreamController<RTCPeerConnectionState>.broadcast();
  final _localStreamController = StreamController<MediaStream?>.broadcast();
  final _remoteStreamController = StreamController<MediaStream?>.broadcast();
  final _audioLevelController = StreamController<double>.broadcast();
  final _networkQualityController = StreamController<NetworkQuality>.broadcast();
  
  // Audio level monitoring
  Timer? _audioLevelTimer;
  double _currentAudioLevel = 0;
  
  // Network quality monitoring
  Timer? _qualityTimer;
  NetworkQuality _currentQuality = NetworkQuality.unknown;

  // Singleton pattern
  static final WebRTCService _instance = WebRTCService._internal();

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isConnected => _isConnected;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;
  
  // Stream getters
  Stream<RTCPeerConnectionState> get connectionStateStream => _connectionStateController.stream;
  Stream<MediaStream?> get localStreamStream => _localStreamController.stream;
  Stream<MediaStream?> get remoteStreamStream => _remoteStreamController.stream;
  Stream<double> get audioLevelStream => _audioLevelController.stream;
  Stream<NetworkQuality> get networkQualityStream => _networkQualityController.stream;

  /// Initialize WebRTC service
  Future<void> initialize() async {
    if (_isInitialized) {
      _logger.w('WebRTC service already initialized');
      return;
    }

    try {
      // Request audio permissions
      await _requestPermissions();
      
      // Setup socket event listeners
      _setupSocketListeners();
      
      _isInitialized = true;
      
      if (EnvironmentConfig.enableLogging) {
        _logger.i('WebRTC service initialized successfully');
      }
    } catch (e) {
      _logger.e('Failed to initialize WebRTC service: $e');
      rethrow;
    }
  }

  Future<void> _requestPermissions() async {
    try {
      // Request audio permissions
      final stream = await navigator.mediaDevices.getUserMedia({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
          'sampleRate': AppConfig.audioSampleRate,
        },
        'video': false,
      });
      
      // Stop the test stream immediately
      stream.getTracks().forEach((track) => track.stop());
      
      if (EnvironmentConfig.enableLogging) {
        _logger.i('Audio permissions granted');
      }
    } catch (e) {
      _logger.e('Failed to request audio permissions: $e');
      throw Exception('Microphone permission denied');
    }
  }

  void _setupSocketListeners() {
    // Listen for WebRTC offers
    _socketService.webrtcOfferStream.listen((data) async {
      await _handleOffer(data);
    });

    // Listen for WebRTC answers
    _socketService.webrtcAnswerStream.listen((data) async {
      await _handleAnswer(data);
    });

    // Listen for ICE candidates
    _socketService.iceCandidateStream.listen((data) async {
      await _handleICECandidate(data);
    });
  }

  /// Join audio session
  Future<void> joinAudioSession(String sessionId, String userId) async {
    if (!_isInitialized) {
      throw Exception('WebRTC service not initialized');
    }

    if (_isConnected) {
      _logger.w('Already connected to an audio session');
      return;
    }

    _currentSessionId = sessionId;
    _currentUserId = userId;

    try {
      // Create peer connection
      await _createPeerConnection();
      
      // Get local audio stream
      await _createLocalStream();
      
      // Start monitoring
      _startAudioLevelMonitoring();
      _startNetworkQualityMonitoring();
      
      if (EnvironmentConfig.enableLogging) {
        _logger.i('Joined audio session: $sessionId');
      }
    } catch (e) {
      _logger.e('Failed to join audio session: $e');
      await leaveAudioSession();
      rethrow;
    }
  }

  Future<void> _createPeerConnection() async {
    final configuration = RTCConfiguration(AppConfig.rtcConfiguration);
    
    _peerConnection = await createPeerConnection(configuration);
    
    // Setup event handlers
    _peerConnection!.onConnectionState = (state) {
      _connectionStateController.add(state);
      _isConnected = state == RTCPeerConnectionState.RTCPeerConnectionStateConnected;
      
      if (EnvironmentConfig.enableLogging) {
        _logger.d('Peer connection state: $state');
      }
    };

    _peerConnection!.onAddStream = (stream) {
      _remoteStream = stream;
      _remoteStreamController.add(stream);
      
      if (EnvironmentConfig.enableLogging) {
        _logger.i('Received remote audio stream');
      }
    };

    _peerConnection!.onRemoveStream = (stream) {
      _remoteStream = null;
      _remoteStreamController.add(null);
      
      if (EnvironmentConfig.enableLogging) {
        _logger.i('Remote audio stream removed');
      }
    };

    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        _socketService.sendICECandidate(
          sessionId: _currentSessionId!,
          targetUserId: 'teacher', // Assuming teacher is the target
          candidate: candidate.toMap(),
        );
      }
    };

    _peerConnection!.onIceConnectionState = (state) {
      if (EnvironmentConfig.enableLogging) {
        _logger.d('ICE connection state: $state');
      }
    };
  }

  Future<void> _createLocalStream() async {
    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
          'sampleRate': AppConfig.audioSampleRate,
        },
        'video': false,
      });

      // Add stream to peer connection
      await _peerConnection!.addStream(_localStream!);
      
      // Mute by default
      await _setMuted(true);
      
      _localStreamController.add(_localStream);
      
      if (EnvironmentConfig.enableLogging) {
        _logger.i('Local audio stream created');
      }
    } catch (e) {
      _logger.e('Failed to create local stream: $e');
      rethrow;
    }
  }

  /// Create and send offer (for teacher role)
  Future<void> createOffer(String targetUserId) async {
    if (_peerConnection == null) {
      throw Exception('Peer connection not created');
    }

    try {
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      await _socketService.sendWebRTCOffer(
        sessionId: _currentSessionId!,
        targetUserId: targetUserId,
        offer: offer.toMap(),
      );

      if (EnvironmentConfig.enableLogging) {
        _logger.i('Sent WebRTC offer to: $targetUserId');
      }
    } catch (e) {
      _logger.e('Failed to create offer: $e');
      rethrow;
    }
  }

  Future<void> _handleOffer(Map<String, dynamic> data) async {
    if (_peerConnection == null) {
      _logger.w('Received offer but peer connection not ready');
      return;
    }

    try {
      final offer = RTCSessionDescription(
        data['offer']['sdp'],
        data['offer']['type'],
      );

      await _peerConnection!.setRemoteDescription(offer);

      // Create and send answer
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      await _socketService.sendWebRTCAnswer(
        sessionId: _currentSessionId!,
        targetUserId: data['from_user_id'],
        answer: answer.toMap(),
      );

      if (EnvironmentConfig.enableLogging) {
        _logger.i('Handled offer and sent answer');
      }
    } catch (e) {
      _logger.e('Failed to handle offer: $e');
    }
  }

  Future<void> _handleAnswer(Map<String, dynamic> data) async {
    if (_peerConnection == null) {
      _logger.w('Received answer but peer connection not ready');
      return;
    }

    try {
      final answer = RTCSessionDescription(
        data['answer']['sdp'],
        data['answer']['type'],
      );

      await _peerConnection!.setRemoteDescription(answer);

      if (EnvironmentConfig.enableLogging) {
        _logger.i('Handled WebRTC answer');
      }
    } catch (e) {
      _logger.e('Failed to handle answer: $e');
    }
  }

  Future<void> _handleICECandidate(Map<String, dynamic> data) async {
    if (_peerConnection == null) {
      _logger.w('Received ICE candidate but peer connection not ready');
      return;
    }

    try {
      final candidate = RTCIceCandidate(
        data['candidate']['candidate'],
        data['candidate']['sdpMid'],
        data['candidate']['sdpMLineIndex'],
      );

      await _peerConnection!.addCandidate(candidate);

      if (EnvironmentConfig.enableLogging) {
        _logger.d('Added ICE candidate');
      }
    } catch (e) {
      _logger.e('Failed to handle ICE candidate: $e');
    }
  }

  /// Toggle mute state
  Future<void> toggleMute() async {
    await _setMuted(!_isMuted);
  }

  Future<void> _setMuted(bool muted) async {
    if (_localStream == null) return;

    _localStream!.getAudioTracks().forEach((track) {
      track.enabled = !muted;
    });

    _isMuted = muted;

    if (EnvironmentConfig.enableLogging) {
      _logger.i('Audio ${muted ? 'muted' : 'unmuted'}');
    }
  }

  /// Toggle speaker state
  Future<void> toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
    
    try {
      await Helper.setSpeakerphoneOn(_isSpeakerOn);
      
      if (EnvironmentConfig.enableLogging) {
        _logger.i('Speaker ${_isSpeakerOn ? 'enabled' : 'disabled'}');
      }
    } catch (e) {
      _logger.e('Failed to toggle speaker: $e');
    }
  }

  void _startAudioLevelMonitoring() {
    _audioLevelTimer?.cancel();
    _audioLevelTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _updateAudioLevel();
    });
  }

  void _updateAudioLevel() {
    // This is a simplified audio level calculation
    // In a real implementation, you would analyze the actual audio data
    if (_localStream != null && !_isMuted) {
      // Simulate audio level based on stream activity
      _currentAudioLevel = _localStream!.getAudioTracks().isNotEmpty ? 0.5 : 0.0;
    } else {
      _currentAudioLevel = 0.0;
    }
    
    _audioLevelController.add(_currentAudioLevel);
  }

  void _startNetworkQualityMonitoring() {
    _qualityTimer?.cancel();
    _qualityTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _updateNetworkQuality();
    });
  }

  Future<void> _updateNetworkQuality() async {
    if (_peerConnection == null) return;

    try {
      final stats = await _peerConnection!.getStats();
      
      // Analyze stats to determine network quality
      var quality = _analyzeNetworkStats(stats);
      
      if (quality != _currentQuality) {
        _currentQuality = quality;
        _networkQualityController.add(quality);
        
        // Send quality report to server
        await _socketService.sendQualityReport({
          'quality': quality.toString(),
          'timestamp': DateTime.now().toIso8601String(),
          'connection_state': _peerConnection!.connectionState?.toString(),
        });
      }
    } catch (e) {
      _logger.e('Failed to update network quality: $e');
    }
  }

  NetworkQuality _analyzeNetworkStats(List<StatsReport> stats) {
    // Simplified network quality analysis
    // In a real implementation, analyze packet loss, latency, jitter, etc.
    
    if (!_isConnected) {
      return NetworkQuality.poor;
    }
    
    // For now, return good quality if connected
    return NetworkQuality.good;
  }

  /// Leave audio session
  Future<void> leaveAudioSession() async {
    try {
      // Stop monitoring
      _audioLevelTimer?.cancel();
      _qualityTimer?.cancel();
      
      // Close local stream
      if (_localStream != null) {
        _localStream!.getTracks().forEach((track) => track.stop());
        _localStream = null;
        _localStreamController.add(null);
      }
      
      // Close remote stream
      if (_remoteStream != null) {
        _remoteStream = null;
        _remoteStreamController.add(null);
      }
      
      // Close peer connection
      if (_peerConnection != null) {
        await _peerConnection!.close();
        _peerConnection = null;
      }
      
      _isConnected = false;
      _currentSessionId = null;
      _currentUserId = null;
      
      if (EnvironmentConfig.enableLogging) {
        _logger.i('Left audio session');
      }
    } catch (e) {
      _logger.e('Error leaving audio session: $e');
    }
  }

  /// Get current audio level (0.0 to 1.0)
  double getCurrentAudioLevel() {
    return _currentAudioLevel;
  }

  /// Get current network quality
  NetworkQuality getCurrentNetworkQuality() {
    return _currentQuality;
  }

  /// Dispose service
  void dispose() {
    leaveAudioSession();
    
    // Close stream controllers
    _connectionStateController.close();
    _localStreamController.close();
    _remoteStreamController.close();
    _audioLevelController.close();
    _networkQualityController.close();
  }
}

/// Network quality enumeration
enum NetworkQuality {
  unknown,
  poor,
  fair,
  good,
  excellent,
}

extension NetworkQualityExtension on NetworkQuality {
  String get displayName {
    switch (this) {
      case NetworkQuality.unknown:
        return 'Unknown';
      case NetworkQuality.poor:
        return 'Poor';
      case NetworkQuality.fair:
        return 'Fair';
      case NetworkQuality.good:
        return 'Good';
      case NetworkQuality.excellent:
        return 'Excellent';
    }
  }
  
  String get description {
    switch (this) {
      case NetworkQuality.unknown:
        return 'Network quality unknown';
      case NetworkQuality.poor:
        return 'Poor connection - audio may be choppy';
      case NetworkQuality.fair:
        return 'Fair connection - some audio issues possible';
      case NetworkQuality.good:
        return 'Good connection - clear audio';
      case NetworkQuality.excellent:
        return 'Excellent connection - crystal clear audio';
    }
  }
}
