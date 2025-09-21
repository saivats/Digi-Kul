import 'dart:async';
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  // State
  bool _isInitialized = false;
  bool _isMuted = false;
  bool _isConnected = false;
  String? _currentSessionId;
  
  // Event streams
  final StreamController<bool> _connectionStateController = StreamController<bool>.broadcast();
  final StreamController<String> _errorController = StreamController<String>.broadcast();

  // Getters
  Stream<bool> get connectionState => _connectionStateController.stream;
  Stream<String> get errorStream => _errorController.stream;
  bool get isMuted => _isMuted;
  bool get isConnected => _isConnected;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Request microphone permission
      var status = await Permission.microphone.request();
      if (status.isGranted) {
        _isInitialized = true;
        return true;
      } else {
        _errorController.add('Microphone permission denied');
        return false;
      }
    } catch (e) {
      _errorController.add('Error initializing audio: $e');
      return false;
    }
  }

  Future<void> joinSession(String sessionId) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return;
    }
    _currentSessionId = sessionId;
    _isConnected = true;
    _connectionStateController.add(true);
    // In a real scenario, this would start audio streaming
  }

  Future<void> leaveSession() async {
    _isConnected = false;
    _connectionStateController.add(false);
    _currentSessionId = null;
    // In a real scenario, this would stop audio streaming
  }

  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    // In a real scenario, this would mute/unmute the local audio stream
  }

  void dispose() {
    _connectionStateController.close();
    _errorController.close();
  }
}
