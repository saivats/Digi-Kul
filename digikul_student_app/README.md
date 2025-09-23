# Digi-Kul Student Mobile Application

A production-ready Flutter mobile application for the Digi-Kul educational platform. This app is designed to provide seamless educational experiences on low-bandwidth networks with audio-first, offline-capable functionality.

## 🚀 Features

### Core Features
- **Audio-First Design**: Optimized for low-bandwidth (2G/3G) networks
- **Offline Capability**: Download and access content without internet connection
- **Real-time Communication**: Live audio sessions with WebRTC
- **Interactive Learning**: Polls, quizzes, and chat during live sessions
- **Material Management**: Download and organize educational materials
- **Cohort Management**: Join and participate in study groups

### Technical Features
- **Clean Architecture**: Separation of concerns with data, domain, and presentation layers
- **State Management**: Riverpod for dependency injection and state management
- **Offline Storage**: Hive for local caching and offline data persistence
- **API Integration**: Robust API service with error handling and retry mechanisms
- **Real-time Updates**: Socket.IO for live session communication
- **Responsive Design**: Adaptive UI for different screen sizes
- **Comprehensive Testing**: Unit, widget, and integration tests

## 🏗️ Architecture

### Project Structure
```
lib/
├── src/
│   ├── core/                    # Core utilities and configuration
│   │   ├── config/             # App configuration
│   │   ├── constants/          # App constants
│   │   └── theme/              # Design system (colors, text styles)
│   ├── data/                   # Data layer
│   │   ├── models/             # Data models
│   │   ├── repositories/       # Repository implementations
│   │   └── services/           # API and external services
│   ├── domain/                 # Domain layer
│   │   └── providers/          # Riverpod providers
│   └── presentation/           # Presentation layer
│       ├── router/             # App routing
│       ├── screens/            # UI screens
│       └── widgets/            # Reusable widgets
├── main.dart                   # App entry point
test/
├── unit/                       # Unit tests
├── widget/                     # Widget tests
└── integration/                # Integration tests
```

### Architecture Principles
- **Clean Architecture**: Clear separation between data, domain, and presentation layers
- **SOLID Principles**: Single responsibility, dependency inversion, etc.
- **Repository Pattern**: Abstract data access through repositories
- **Provider Pattern**: Centralized state management with Riverpod
- **Dependency Injection**: Loose coupling through provider overrides

## 📱 Screens

### Authentication
- **Splash Screen**: App initialization and session validation
- **Login Screen**: Student authentication with form validation
- **Signup Screen**: Student registration (placeholder)

### Main Application
- **Dashboard Screen**: Home with quick stats and recent activity
- **Explore Screen**: Discover new lectures and courses
- **Downloads Screen**: Manage offline content
- **Settings Screen**: App configuration and preferences
- **Profile Screen**: User profile management

### Content Screens
- **Cohort Details**: View cohort information and lectures
- **Lecture Details**: Detailed lecture information and materials
- **Live Session**: Real-time audio session with chat and interactions

## 🛠️ Setup Instructions

### Prerequisites
- Flutter SDK (>=3.3.3)
- Dart SDK (>=3.0.0)
- Android Studio / VS Code with Flutter extensions
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Digi-Kul/digikul_student_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code (if needed)**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Configuration

1. **API Configuration**
   - Update the API base URL in `lib/src/core/config/app_config.dart`
   - Configure environment-specific settings

2. **Dependencies**
   - All required dependencies are included in `pubspec.yaml`
   - Run `flutter pub get` to install them

## 🧪 Testing

### Running Tests

1. **Unit Tests**
   ```bash
   flutter test test/unit/
   ```

2. **Widget Tests**
   ```bash
   flutter test test/widget/
   ```

3. **Integration Tests**
   ```bash
   flutter test integration_test/
   ```

4. **All Tests**
   ```bash
   flutter test
   ```

### Test Coverage
The application includes comprehensive tests covering:
- **Unit Tests**: Providers, repositories, and business logic
- **Widget Tests**: UI components and user interactions
- **Integration Tests**: End-to-end user flows

## 🔧 Development

### Code Generation
Some files require code generation. Run this command when you add new models or providers:
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Linting
The project uses strict linting rules. Run:
```bash
flutter analyze
```

### Formatting
Format code using:
```bash
flutter format .
```

## 📦 Dependencies

### Core Dependencies
- **flutter_riverpod**: State management and dependency injection
- **go_router**: Declarative routing
- **dio**: HTTP client with interceptors
- **hive**: Local storage and caching
- **socket_io_client**: Real-time communication
- **flutter_webrtc**: Audio communication for live sessions

### UI Dependencies
- **shimmer**: Loading animations
- **flutter_spinkit**: Loading indicators
- **cached_network_image**: Image caching
- **lottie**: Vector animations

### Development Dependencies
- **mocktail**: Mocking for tests
- **build_runner**: Code generation
- **very_good_analysis**: Strict linting rules

## 🌐 API Integration

The app integrates with the Digi-Kul backend API:
- **Authentication**: Session-based authentication with cookies
- **Lectures**: CRUD operations for lectures and enrollments
- **Materials**: File download and management
- **Real-time**: Socket.IO for live sessions
- **Offline**: Intelligent caching and sync strategies

## 📱 Platform Support

- **Android**: Minimum SDK 21 (Android 5.0)
- **iOS**: Minimum iOS 12.0
- **Web**: Limited support (WebRTC limitations)

## 🔒 Security Features

- **Session Management**: Secure session handling with automatic expiration
- **Input Validation**: Client-side and server-side validation
- **Error Handling**: Graceful error handling without exposing sensitive data
- **Offline Security**: Secure local storage with encryption

## 🎨 Design System

### Colors
- **Primary**: Indigo theme for education and trust
- **Secondary**: Orange for highlights and calls-to-action
- **Status Colors**: Success, warning, error, and info states
- **Accessibility**: High contrast colors for readability

### Typography
- **Material Design 3**: Modern typography scale
- **Responsive Text**: Scales appropriately for different screen sizes
- **Accessibility**: Proper text contrast ratios

### Components
- **Consistent Styling**: Unified design language across all components
- **Accessibility**: Screen reader support and proper semantics
- **Responsive**: Adaptive layouts for different screen sizes

## 🚀 Performance Optimizations

- **Image Caching**: Efficient image loading and caching
- **Lazy Loading**: On-demand content loading
- **Offline First**: Local-first data strategy
- **Bundle Optimization**: Tree-shaking and code splitting
- **Memory Management**: Proper disposal of resources

## 📈 Monitoring and Analytics

- **Error Tracking**: Comprehensive error logging
- **Performance Monitoring**: App performance metrics
- **User Analytics**: Privacy-focused usage analytics (optional)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow the existing code style and architecture
- Write tests for new features
- Update documentation as needed
- Ensure all tests pass before submitting

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation

## 🔄 Version History

### v1.0.0 (Current)
- Initial release with core features
- Authentication and session management
- Offline capability with local storage
- Real-time communication infrastructure
- Comprehensive test coverage
- Production-ready architecture

## 🎯 Roadmap

### Future Enhancements
- [ ] Push notifications
- [ ] Advanced offline synchronization
- [ ] Video support for live sessions
- [ ] Enhanced accessibility features
- [ ] Multi-language support
- [ ] Dark mode theme
- [ ] Advanced analytics dashboard

---

**Built with ❤️ for educational excellence**