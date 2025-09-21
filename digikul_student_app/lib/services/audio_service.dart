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
      final micPermission = await Permission.microphone.request();
      if (!micPermission.isGranted) {
        _errorController.add('Microphone permission denied');
        return false;
      }

      _isInitialized = true;
      
      // Simulate successful audio connection
      await Future.delayed(const Duration(seconds: 2));
      _isConnected = true;
      _connectionStateController.add(true);
      
      return true;
    } catch (e) {
      _errorController.add('Failed to initialize audio: $e');
      return false;
    }
  }

  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    // In a real implementation, this would control the microphone
    print('Audio ${_isMuted ? 'muted' : 'unmuted'}');
  }

  Future<void> setMuted(bool muted) async {
    _isMuted = muted;
    // In a real implementation, this would control the microphone
    print('Audio ${_isMuted ? 'muted' : 'unmuted'}');
  }

  Future<void> joinSession(String sessionId) async {
    _currentSessionId = sessionId;
    
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        throw Exception('Failed to initialize audio system');
      }
    }
  }

  Future<void> leaveSession() async {
    _currentSessionId = null;
    _isConnected = false;
    _connectionStateController.add(false);
  }

  void dispose() {
    _connectionStateController.close();
    _errorController.close();
  }
}
