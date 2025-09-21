# Digi-Kul Student App

A Flutter mobile application for students to participate in virtual classrooms with low-bandwidth optimization. This app provides real-time audio communication, interactive polls, cohort management, and study material access.

## Features

### 🎯 Core Features

- **Live Classroom Sessions**: Real-time audio communication using WebRTC
- **Interactive Polls**: Vote on polls created by teachers during or outside live sessions
- **Cohort Management**: Join cohorts using codes and access cohort-specific lectures
- **Study Materials**: Download and access compressed study materials
- **Chat System**: Real-time chat during live sessions
- **Content Sharing**: View shared content from teachers during live sessions

### 📱 Screens

1. **Login Screen**: Student authentication
2. **Home Screen**: Browse available lectures and join cohorts
3. **My Courses Screen**: View enrolled lectures and joined cohorts
4. **Lecture Details Screen**: View lecture information, enroll, access materials, and join live sessions
5. **Live Session Screen**: Real-time audio communication with chat and polls
6. **Polls Screen**: View and vote on polls for specific lectures
7. **Cohort Details Screen**: View lectures within a specific cohort
8. **Profile Screen**: User profile and logout functionality
9. **Settings Screen**: App configuration and preferences

### 🔧 Technical Features

- **WebRTC Integration**: Low-latency audio communication
- **Socket.IO**: Real-time messaging and signaling
- **File Download**: Optimized material downloads with compression
- **Responsive UI**: Material Design with custom theming
- **Session Management**: Secure authentication with session cookies

## Architecture

### Backend Integration

The app integrates with a Flask backend that provides:

- **Authentication**: Session-based login system
- **Real-time Communication**: Socket.IO for live sessions
- **File Management**: Compressed material downloads
- **Cohort System**: Group-based lecture organization
- **Polling System**: Interactive polls and voting

### API Endpoints Used

```
POST /api/login - Student authentication
GET /api/student/lectures/available - Available lectures
GET /api/student/enrolled_lectures - Enrolled lectures
GET /api/student/cohorts - Student's cohorts
POST /api/student/cohorts/join - Join cohort by code
GET /api/student/cohort/{id}/lectures - Cohort lectures
POST /api/student/enroll - Enroll in lecture
GET /api/student/lecture/{id}/materials - Lecture materials
GET /api/lectures/{id}/polls - Lecture polls
POST /api/polls/{id}/vote - Vote on poll
GET /api/polls/{id}/results - Poll results
GET /api/session/by_lecture/{id} - Active session info
POST /api/logout - Logout
GET /api/download/{id} - Download material
```

### WebSocket Events

```
join_session - Join live session
webrtc_offer - WebRTC offer
webrtc_answer - WebRTC answer
ice_candidate - ICE candidate
chat_message - Chat message
new_poll - New poll created
content_shared - Content shared by teacher
submit_poll_response - Submit poll response
```

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.6
  http: ^1.2.1
  socket_io_client: ^2.0.3+1
  url_launcher: ^6.2.6
  flutter_webrtc: ^0.9.48
  permission_handler: ^11.3.1
```

## Setup Instructions

### Prerequisites

- Flutter SDK (>=3.3.3)
- Android Studio / Xcode
- Backend server running on `http://192.168.29.104:5000`

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd digikul_student_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Update backend URL**
   Edit `lib/services/api_service.dart` and update the `baseUrl`:
   ```dart
   const String baseUrl = 'http://YOUR_BACKEND_IP:5000';
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Platform-specific Setup

#### Android

1. Add internet permission in `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.INTERNET" />
   <uses-permission android:name="android.permission.RECORD_AUDIO" />
   ```

2. Add network security config for HTTP connections (development only):
   ```xml
   <application
       android:usesCleartextTraffic="true"
       ...>
   ```

#### iOS

1. Add microphone permission in `ios/Runner/Info.plist`:
   ```xml
   <key>NSMicrophoneUsageDescription</key>
   <string>This app needs microphone access for live classroom sessions</string>
   ```

## Usage Guide

### Getting Started

1. **Login**: Use your student credentials to log in
2. **Join Cohort**: Use the "Join Cohort" button to enter a cohort code
3. **Browse Lectures**: View available lectures on the home screen
4. **Enroll**: Tap on lectures to view details and enroll

### Live Sessions

1. **Join Live Session**: Tap "Join Live Session" when a session is active
2. **Audio Controls**: Use the microphone button to mute/unmute
3. **Chat**: Send messages during the session
4. **Polls**: Vote on polls when they appear
5. **Content**: View shared content from the teacher

### Study Materials

1. **Access Materials**: View materials in lecture details
2. **Download**: Tap download button to save materials
3. **Offline Access**: Downloaded materials are available offline

## Development

### Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── cohort.dart
│   ├── lecture.dart
│   └── material.dart
├── screens/                  # UI screens
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── live_session_screen.dart
│   ├── polls_screen.dart
│   └── ...
└── services/                 # API services
    └── api_service.dart
```

### Key Components

- **ApiService**: Handles all backend communication
- **LiveSessionScreen**: WebRTC and Socket.IO integration
- **MainLayout**: Bottom navigation and screen management
- **Models**: Data structures for API responses

### Adding New Features

1. **New API Endpoint**: Add method to `ApiService`
2. **New Screen**: Create in `screens/` directory
3. **New Model**: Create in `models/` directory
4. **Navigation**: Update `MainLayout` or add to existing screens

## Troubleshooting

### Common Issues

1. **Connection Failed**: Check backend URL and network connectivity
2. **Audio Not Working**: Verify microphone permissions
3. **WebRTC Issues**: Check firewall and NAT configuration
4. **Socket Connection**: Ensure backend Socket.IO is running

### Debug Mode

Enable debug logging by setting:
```dart
const bool debugMode = true;
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation

---

**Note**: This app is optimized for low-bandwidth environments and prioritizes audio communication over video to ensure accessibility in rural areas with limited internet connectivity.