# Digi Kul Teachers Portal

A comprehensive educational platform built with Flask that supports institution-based cohort management, live lecture sessions, quiz systems, and session recording.

## 🚀 Features

### 🏢 Institution-Based Cohort Management
- **Multiple Institutions**: Support for multiple educational institutions
- **Cohort Organization**: Students belong to one cohort with scoped access
- **Teacher Multi-Cohort Access**: Teachers can belong to multiple cohorts and select one upon login
- **Proper Database Relationships**: Institution → Cohorts → Users with proper foreign keys

### 📧 SMTP Email Notifications
- **Welcome Emails**: Automatic welcome emails upon student/teacher registration
- **Cohort Notifications**: Email notifications when students join cohorts
- **Lecture Updates**: Email notifications for lecture changes
- **Quiz Notifications**: Email alerts for new quizzes
- **Configurable SMTP**: Support for various SMTP providers

### 📚 Lecture & Material Management
- **Lecture Scheduling**: 
  - Prevent scheduling lectures in the past
  - Allow "now" lectures for immediate start
  - Future scheduling with validation
- **Lecture Expiry Logic**: Lectures expire after ending, not joinable but logged
- **Material Access**: Students can access uploaded resources and past attended lectures
- **File Compression**: Automatic compression of audio, image, and PDF files

### 🎯 Comprehensive Quiz System
- **Quiz Creation**: Teachers can create quizzes within cohorts
- **Multiple Choice Questions**: Support for multiple-choice questions with correct answers
- **Time Limits**: Optional time limits for quizzes
- **Multiple Attempts**: Configurable maximum attempts per student
- **Analytics Dashboard**: 
  - Individual student performance tracking
  - Aggregate performance metrics
  - Graphical analytics with charts
  - Question-level analytics
- **Real-time Results**: Dynamic results and performance tracking

### 📹 Session Recording
- **Live Session Recording**: Record video, audio, and chat during live sessions
- **Multiple Recording Types**: Full recording, audio-only, or chat-only
- **Participant Activity Logging**: Track participant joins, leaves, and activities
- **Chat Logging**: Automatic logging of all chat messages during sessions
- **Recording Management**: Start, stop, and manage recordings
- **File Organization**: Organized storage of recording chunks and metadata

### 🎨 Modern UI/UX
- **Responsive Design**: Modern, responsive design with Bootstrap/Tailwind
- **Card-Based Layout**: Replace lists/forms with modern cards
- **Modal Popups**: Modal popups for creating/editing lectures, materials, quizzes
- **Toast Notifications**: Real-time toast notifications for user feedback
- **Cohort Selection**: Dropdown for teachers to select active cohort
- **Interactive Dashboards**: Modern dashboard with cards for materials, lectures, quizzes
- **Chart Integration**: Quiz analytics with graphs and charts

### 🔐 Security & Access Control
- **Cohort Scoping**: Middleware for data access scoping by cohort
- **Role-Based Access**: Different access levels for students, teachers, and admins
- **Session Management**: Enhanced session security with proper expiration
- **Row Level Security**: Database-level security with RLS policies

## 🏗️ Architecture

### Modular Structure
```
Digi_Kul_TeachersPortal/
├── main.py                 # Main application entry point
├── config.py              # Configuration settings
├── supabase_schema.sql    # Database schema
├── middlewares/           # Authentication and cohort middleware
├── services/              # Business logic services
├── routes/                # API route blueprints
├── utils/                 # Utility functions
├── templates/             # HTML templates
└── static/               # Static assets
```

### Services
- **CohortService**: Institution and cohort management
- **LectureService**: Lecture scheduling and management
- **QuizService**: Quiz creation, taking, and analytics
- **AdminService**: Administrative operations
- **SessionRecordingService**: Live session recording
- **EmailService**: SMTP email notifications

### Middleware
- **AuthMiddleware**: Authentication decorators
- **CohortMiddleware**: Cohort-based access control

## 🛠️ Installation

### Prerequisites
- Python 3.8+
- Supabase account
- SMTP email service (optional)

### Setup
1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Digi_Kul_TeachersPortal
   ```

2. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

3. **Configure environment variables**
   ```bash
   # Copy example config
   cp config.example.py config.py
   
   # Edit config.py with your settings
   ```

4. **Database setup**
   - Create a Supabase project
   - Run the SQL schema from `supabase_schema.sql`
   - Update your Supabase URL and key in config.py

5. **Run the application**
   ```bash
   python main.py
   ```

## 📊 Database Schema

### Core Tables
- **institutions**: Educational institutions
- **teachers**: Teacher accounts with institution association
- **students**: Student accounts with institution association
- **cohorts**: Learning cohorts within institutions
- **lectures**: Lecture schedules and details
- **materials**: Teaching materials and resources

### Quiz System Tables
- **quiz_sets**: Quiz containers with metadata
- **quizzes**: Individual quiz questions
- **quiz_attempts**: Student quiz attempts
- **quiz_responses**: Individual question responses

### Session Recording Tables
- **session_recordings**: Recording metadata and statistics
- **recording_chunks**: Video/audio chunks for recordings

## 🔌 API Endpoints

### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/logout` - User logout
- `POST /api/auth/register/teacher` - Teacher registration (admin only)
- `POST /api/auth/register/student` - Student registration (admin only)

### Cohorts
- `GET /api/cohorts/` - Get all cohorts
- `POST /api/cohorts/` - Create cohort (admin only)
- `GET /api/cohorts/teacher` - Get teacher's cohorts
- `POST /api/cohorts/student/join` - Join cohort with code

### Lectures
- `POST /api/lectures` - Create lecture
- `POST /api/lectures/instant` - Create instant lecture
- `GET /api/lectures` - Get user's lectures
- `POST /api/lectures/<id>/materials` - Upload material

### Quizzes
- `POST /api/quiz/sets` - Create quiz set
- `POST /api/quiz/sets/<id>/questions` - Add quiz question
- `POST /api/quiz/sets/<id>/start` - Start quiz attempt
- `GET /api/quiz/sets/<id>/analytics` - Get quiz analytics

### Session Recording
- `POST /api/recordings/start` - Start recording
- `POST /api/recordings/stop` - Stop recording
- `GET /api/recordings/status/<session_id>` - Get recording status
- `GET /api/lectures/<id>/recordings` - Get lecture recordings

## 🔧 Configuration

### Environment Variables
```python
# Supabase Configuration
SUPABASE_URL = "your-supabase-url"
SUPABASE_KEY = "your-supabase-key"

# SMTP Configuration
SMTP_HOST = "smtp.gmail.com"
SMTP_PORT = 587
SMTP_USERNAME = "your-email@gmail.com"
SMTP_PASSWORD = "your-app-password"
SMTP_SENDER_EMAIL = "your-email@gmail.com"

# Application Configuration
SECRET_KEY = "your-secret-key"
UPLOAD_FOLDER = "uploads"
COMPRESSED_FOLDER = "compressed"
```

## 🌐 WebSocket Events

### Live Sessions
- `join_session` - Join a live session
- `leave_session` - Leave a live session
- `chat_message` - Send chat message
- `webrtc_offer/answer` - WebRTC signaling
- `ice_candidate` - ICE candidate exchange

### Recording
- `start_recording` - Start session recording
- `stop_recording` - Stop session recording
- `recording_chunk` - Send video/audio chunk
- `get_recording_status` - Get recording status

## 📱 Usage Examples

### Creating a Lecture
```javascript
// Create a scheduled lecture
fetch('/api/lectures', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({
        title: 'Mathematics 101',
        description: 'Introduction to algebra',
        scheduled_time: '2024-01-15T10:00:00Z',
        duration: 60,
        cohort_id: 'cohort-uuid'
    })
});
```

### Starting a Quiz
```javascript
// Start a quiz attempt
fetch('/api/quiz/sets/quiz-uuid/start', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'}
});
```

### Starting Recording
```javascript
// Start session recording
socket.emit('start_recording', {
    session_id: 'session-uuid',
    lecture_id: 'lecture-uuid',
    recording_type: 'full'
});
```

## 🔒 Security Features

- **Row Level Security (RLS)**: Database-level access control
- **Cohort Scoping**: Users can only access data from their cohorts
- **Session Security**: Enhanced session management with proper expiration
- **Input Validation**: Comprehensive input validation and sanitization
- **File Upload Security**: Secure file handling with type validation

## 🚀 Deployment

### Production Considerations
1. **Environment Variables**: Set all required environment variables
2. **Database**: Use production Supabase instance
3. **File Storage**: Configure proper file storage (AWS S3, etc.)
4. **SMTP**: Use production SMTP service
5. **SSL**: Enable HTTPS for production
6. **Monitoring**: Set up logging and monitoring

### Docker Deployment
```dockerfile
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE 5000
CMD ["python", "main.py"]
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Create an issue in the repository
- Check the documentation
- Review the API endpoints

## 🔄 Version History

### v2.0.0
- Added institution-based cohort management
- Implemented comprehensive quiz system
- Added session recording functionality
- Enhanced UI/UX with modern design
- Added SMTP email notifications
- Implemented cohort scoping middleware

### v1.0.0
- Basic lecture management
- Simple user authentication
- File upload functionality
- Live session support