# Digi-Kul Student App

A Flutter mobile application for students to participate in virtual classrooms with low-bandwidth optimization. This app is part of the Digi-Kul ecosystem designed for rural colleges with limited internet connectivity.

## Features

### ✅ Core Features Implemented

1. **Authentication System**
   - Secure student login with session management
   - Automatic session validation and logout

2. **Lecture Management**
   - Browse available lectures
   - Enroll in courses
   - View lecture details and materials
   - Join live sessions when available

3. **Cohort System**
   - Join cohorts using codes provided by teachers
   - View cohort-specific lectures
   - Access cohort materials and discussions

4. **Live Session with WebRTC Audio**
   - Real-time audio communication with teachers
   - WebRTC peer-to-peer audio connection
   - Mute/unmute functionality
   - Connection status indicators
   - Low-bandwidth optimized (audio-only)

5. **Real-time Features**
   - Live chat during sessions
   - Interactive polls with real-time results
   - Content sharing (images, documents)
   - Socket.IO for real-time communication

6. **Course Materials**
   - Download course materials for offline use
   - Support for PDFs, images, and documents
   - Compressed file downloads for low bandwidth

7. **User Interface**
   - Modern, intuitive design
   - Responsive layout for different screen sizes
   - Dark/light theme support
   - Accessibility features

## Technical Architecture

### Backend Integration
- **REST API**: Flask-based backend with Supabase database
- **Real-time Communication**: Socket.IO for live sessions
- **WebRTC Signaling**: Socket.IO handles offer/answer/ICE candidate exchange
- **Authentication**: Session-based with secure cookies

### Flutter Architecture
- **State Management**: StatefulWidget with proper lifecycle management
- **Services**: Modular service architecture
  - `ApiService`: HTTP API communication
  - `WebRTCService`: Audio communication handling
  - `SocketService`: Real-time messaging and signaling
- **Models**: Data models for lectures, cohorts, materials, polls
- **Screens**: Well-organized screen structure with navigation

### Key Technologies
- **Flutter**: Cross-platform mobile development
- **WebRTC**: Real-time audio communication
- **Socket.IO**: Real-time messaging and signaling
- **HTTP**: REST API communication
- **URL Launcher**: File downloads and external links

## Setup Instructions

### Prerequisites
- Flutter SDK (>=3.3.3)
- Dart SDK
- Android Studio / VS Code
- Backend server running (see main project README)

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

3. **Configure backend URL**
   - Update the base URL in `lib/services/api_service.dart`
   - Change `http://192.168.29.104:5000` to your backend server IP

4. **Run the app**
   ```bash
   flutter run
   ```

### Device Setup
- **Android**: Enable microphone permissions
- **iOS**: Grant microphone access when prompted
- **Network**: Ensure device can reach backend server

## Usage Guide

### Student Login
1. Open the app
2. Enter your email and password
3. Tap "Login" to access the dashboard

### Joining Cohorts
1. Tap the floating action button on the home screen
2. Enter the cohort code provided by your teacher
3. Tap "Join" to become a member

### Enrolling in Lectures
1. Browse available lectures on the home screen
2. Tap on a lecture to view details
3. Tap "Enroll in Course" to join

### Live Sessions
1. Look for lectures with "LIVE" indicator
2. Tap "Join Live Session" when available
3. Grant microphone permissions when prompted
4. Use mute/unmute button to control your audio
5. Participate in chat and polls during the session

### Accessing Materials
1. Go to "My Courses" tab
2. Select a lecture or cohort
3. View and download available materials
4. Files will open in your device's default app

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── lecture.dart
│   ├── cohort.dart
│   └── material.dart
├── screens/                  # UI screens
│   ├── login_screen.dart
│   ├── main_layout.dart
│   ├── home_screen.dart
│   ├── my_courses_screen.dart
│   ├── lecture_details_screen.dart
│   ├── cohort_details_screen.dart
│   ├── live_session_screen.dart
│   ├── polls_screen.dart
│   ├── profile_screen.dart
│   └── settings_screen.dart
└── services/                 # Business logic
    ├── api_service.dart
    ├── webrtc_service.dart
    └── socket_service.dart
```

## API Endpoints Used

### Authentication
- `POST /api/login` - Student login
- `POST /api/logout` - Logout

### Lectures
- `GET /api/student/lectures/available` - Get available lectures
- `GET /api/student/enrolled_lectures` - Get enrolled lectures
- `POST /api/student/enroll` - Enroll in lecture

### Cohorts
- `GET /api/student/cohorts` - Get student cohorts
- `POST /api/student/cohorts/join` - Join cohort by code
- `GET /api/student/cohort/{id}/lectures` - Get cohort lectures

### Materials
- `GET /api/student/lecture/{id}/materials` - Get lecture materials
- `GET /api/download/{id}` - Download material

### Live Sessions
- `GET /api/session/by_lecture/{id}` - Get active session ID

### Polls
- `GET /api/lectures/{id}/polls` - Get lecture polls
- `POST /api/polls/{id}/vote` - Vote on poll
- `GET /api/polls/{id}/results` - Get poll results

## Socket.IO Events

### WebRTC Signaling
- `webrtc_offer` - Receive WebRTC offer
- `webrtc_answer` - Receive WebRTC answer
- `ice_candidate` - Receive ICE candidate

### Session Management
- `join_session` - Join live session
- `leave_session` - Leave live session

### Real-time Features
- `chat_message` - Receive chat messages
- `new_poll` - Receive new poll
- `content_shared` - Receive shared content

## Troubleshooting

### Common Issues

1. **Cannot connect to backend**
   - Check if backend server is running
   - Verify IP address in api_service.dart
   - Ensure device and server are on same network

2. **Audio not working in live sessions**
   - Grant microphone permissions
   - Check if WebRTC is properly initialized
   - Verify network connection stability

3. **Login fails**
   - Check email/password credentials
   - Ensure backend authentication is working
   - Verify network connectivity

4. **Materials won't download**
   - Check internet connection
   - Verify file permissions
   - Ensure device has storage space

### Debug Mode
Run the app in debug mode for detailed logs:
```bash
flutter run --debug
```

## Performance Optimizations

### Low Bandwidth Features
- Audio-only WebRTC (no video)
- Compressed file downloads
- Efficient Socket.IO communication
- Minimal data usage for real-time features

### Mobile Optimizations
- Proper memory management
- Stream subscriptions cleanup
- Efficient UI rendering
- Battery usage optimization

## Security Features

- Session-based authentication
- Secure cookie handling
- HTTPS communication (when configured)
- Input validation and sanitization

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is part of the Digi-Kul educational platform.

## Support

For technical support or questions:
- Check the troubleshooting section
- Review the backend documentation
- Contact the development team

---

**Note**: This app is designed for educational purposes and is optimized for low-bandwidth environments typical in rural educational institutions.