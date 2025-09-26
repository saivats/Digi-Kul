import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import '../config.dart';

class LiveSessionScreenSimple extends StatefulWidget {
  final String sessionId;
  final String lectureId;
  final String lectureTitle;
  final String? teacherName;

  const LiveSessionScreenSimple({
    super.key,
    required this.sessionId,
    required this.lectureId,
    required this.lectureTitle,
    this.teacherName,
  });

  @override
  State<LiveSessionScreenSimple> createState() => _LiveSessionScreenSimpleState();
}

class _LiveSessionScreenSimpleState extends State<LiveSessionScreenSimple> {
  // Socket.IO
  IO.Socket? _socket;
  bool _isSocketConnected = false;

  // WebRTC
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();

  // Chat
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _chatMessages = [];
  final ScrollController _chatScrollController = ScrollController();

  // UI
  final bool _showChat = true;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _connectSocket();
    _initWebRTC();
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _messageController.dispose();
    _chatScrollController.dispose();
    _localStream?.dispose();
    _peerConnection?.dispose();
    _localRenderer.dispose();
    super.dispose();
  }

  Future<void> _initWebRTC() async {
    await _localRenderer.initialize();
    await _requestPermissions();
    _peerConnection = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    });

    _peerConnection?.onIceCandidate = (candidate) {
      _socket?.emit('ice_candidate', {
        'session_id': widget.sessionId,
        'candidate': candidate.toMap(),
        // In a real scenario, you'd send this to a specific user (the teacher)
        'target_user_id': 'teacher_id_placeholder',
      });
        };

    _localStream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });

    setState(() {
      _localRenderer.srcObject = _localStream;
    });
  }

  Future<void> _requestPermissions() async {
    await [Permission.microphone].request();
  }

  void _connectSocket() {
    try {
      _socket = IO.io(baseUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      _socket!.connect();

      _socket!.onConnect((_) {
        print('Connected to socket server');
        setState(() => _isSocketConnected = true);
        _socket!.emit('join_session', {'session_id': widget.sessionId});
      });

      _socket!.onDisconnect((_) => setState(() => _isSocketConnected = false));

      _socket!.on('chat_message', (data) {
        setState(() => _chatMessages.add(ChatMessage.fromJson(data)));
        _scrollToBottom();
      });

      // WebRTC Signaling Handlers
      _socket!.on('webrtc_offer', (data) async {
        await _peerConnection?.setRemoteDescription(RTCSessionDescription(data['sdp'], data['type']));
        RTCSessionDescription answer = await _peerConnection!.createAnswer();
        await _peerConnection!.setLocalDescription(answer);
        _socket?.emit('webrtc_answer', {
          'session_id': widget.sessionId,
          'answer': answer.toMap(),
          'target_user_id': data['from_user_id'],
        });
      });

      _socket!.on('webrtc_answer', (data) async {
        await _peerConnection?.setRemoteDescription(RTCSessionDescription(data['sdp'], data['type']));
      });

      _socket!.on('ice_candidate', (data) async {
        await _peerConnection?.addCandidate(RTCIceCandidate(
          data['candidate'],
          data['sdpMid'],
          data['sdpMLineIndex'],
        ));
      });

    } catch (e) {
      print('Socket connection error: $e');
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty && _socket != null) {
      final message = {
        'session_id': widget.sessionId,
        'message': _messageController.text.trim(),
        'user_name': 'Me (Student)',
        'user_type': 'student',
      };
      _socket!.emit('chat_message', message);
      setState(() => _chatMessages.add(ChatMessage.fromJson(message)));
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _toggleMute() {
    if (_localStream != null) {
      bool enabled = !_isMuted;
      _localStream!.getAudioTracks()[0].enabled = enabled;
      setState(() {
        _isMuted = !enabled;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lectureTitle),
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [
          _buildConnectionStatus(),
          Expanded(
            child: Row(
              children: [
                _buildMainContent(),
                if (_showChat) _buildChatSidebar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: _isSocketConnected ? Colors.green : Colors.orange,
      child: Text(
        _isSocketConnected ? 'Connected to Live Session' : 'Connecting...',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMainContent() {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Instructor: ${widget.teacherName}', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          const Icon(Icons.mic, size: 100, color: Colors.indigo),
          const SizedBox(height: 20),
          Text(_isMuted ? 'You are muted' : 'You are live', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 20),
          FloatingActionButton(
            onPressed: _toggleMute,
            child: Icon(_isMuted ? Icons.mic_off : Icons.mic),
          ),
          // Hidden video renderer
          SizedBox(width: 0, height: 0, child: RTCVideoView(_localRenderer)),
        ],
      ),
    );
  }

  Widget _buildChatSidebar() {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text('Live Chat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: _chatScrollController,
              padding: const EdgeInsets.all(8),
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                final message = _chatMessages[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(message.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text(message.message),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(hintText: 'Type a message...'),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String userName;
  final String message;
  final bool isFromTeacher;

  ChatMessage({required this.userName, required this.message, required this.isFromTeacher});

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      userName: json['user_name'] ?? 'Unknown',
      message: json['message'] ?? '',
      isFromTeacher: json['user_type'] == 'teacher',
    );
  }
}