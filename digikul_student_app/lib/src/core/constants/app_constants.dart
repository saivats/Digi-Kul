/// Application-wide constants
class AppConstants {
  // Route Names
  static const String splashRoute = '/';
  static const String loginRoute = '/login';
  static const String signupRoute = '/signup';
  static const String dashboardRoute = '/dashboard';
  static const String exploreRoute = '/explore';
  static const String downloadsRoute = '/downloads';
  static const String settingsRoute = '/settings';
  static const String profileRoute = '/profile';
  static const String cohortDetailsRoute = '/cohort/:id';
  static const String lectureDetailsRoute = '/lecture/:id';
  static const String liveSessionRoute = '/live-session/:id';
  
  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String sessionCookieKey = 'session_cookie';
  static const String lastSyncTimeKey = 'last_sync_time';
  static const String offlineDataKey = 'offline_data';
  static const String settingsKey = 'app_settings';
  static const String downloadedLecturesKey = 'downloaded_lectures';
  
  // Hive Box Names
  static const String userBox = 'user_box';
  static const String lecturesBox = 'lectures_box';
  static const String cohortsBox = 'cohorts_box';
  static const String materialsBox = 'materials_box';
  static const String pollsBox = 'polls_box';
  static const String settingsBox = 'settings_box';
  static const String cacheBox = 'cache_box';
  
  // API Endpoints
  static const String loginEndpoint = '/api/login';
  static const String logoutEndpoint = '/api/logout';
  static const String validateSessionEndpoint = '/api/validate-session';
  static const String availableLecturesEndpoint = '/api/student/lectures/available';
  static const String enrolledLecturesEndpoint = '/api/student/enrolled_lectures';
  static const String enrollEndpoint = '/api/student/enroll';
  static const String studentCohortsEndpoint = '/api/student/cohorts';
  static const String joinCohortEndpoint = '/api/student/cohorts/join';
  static const String studentPollsEndpoint = '/api/student/polls';
  static const String downloadMaterialEndpoint = '/api/download';
  static const String healthCheckEndpoint = '/api/health';
  
  // Socket Events
  static const String connectEvent = 'connect';
  static const String disconnectEvent = 'disconnect';
  static const String joinSessionEvent = 'join_session';
  static const String leaveSessionEvent = 'leave_session';
  static const String webrtcOfferEvent = 'webrtc_offer';
  static const String webrtcAnswerEvent = 'webrtc_answer';
  static const String iceCandidateEvent = 'ice_candidate';
  static const String chatMessageEvent = 'chat_message';
  static const String newLectureEvent = 'new_lecture';
  static const String newMaterialEvent = 'new_material';
  static const String liveSessionStartedEvent = 'live_session_started';
  static const String sessionEndedEvent = 'session_ended';
  static const String userJoinedEvent = 'user_joined';
  static const String userLeftEvent = 'user_left';
  static const String qualityReportEvent = 'quality_report';
  
  // File Types
  static const String audioFileType = 'audio';
  static const String imageFileType = 'image';
  static const String documentFileType = 'document';
  static const String videoFileType = 'video';
  
  // Supported File Extensions
  static const List<String> audioExtensions = ['.mp3', '.wav', '.m4a', '.aac'];
  static const List<String> imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
  static const List<String> documentExtensions = ['.pdf', '.doc', '.docx', '.txt', '.ppt', '.pptx'];
  static const List<String> videoExtensions = ['.mp4', '.avi', '.mkv', '.mov'];
  
  // Error Messages
  static const String networkErrorMessage = 'Network connection error. Please check your internet connection.';
  static const String serverErrorMessage = 'Server error occurred. Please try again later.';
  static const String authErrorMessage = 'Authentication failed. Please login again.';
  static const String unknownErrorMessage = 'An unknown error occurred. Please try again.';
  static const String offlineModeMessage = 'You are currently offline. Some features may not be available.';
  static const String downloadFailedMessage = 'Download failed. Please check your connection and try again.';
  static const String uploadFailedMessage = 'Upload failed. Please check your connection and try again.';
  
  // Success Messages
  static const String loginSuccessMessage = 'Login successful';
  static const String logoutSuccessMessage = 'Logged out successfully';
  static const String enrollSuccessMessage = 'Successfully enrolled in lecture';
  static const String joinCohortSuccessMessage = 'Successfully joined cohort';
  static const String downloadSuccessMessage = 'Download completed successfully';
  static const String pollSubmittedMessage = 'Your response has been submitted';
  
  // Validation Messages
  static const String emailRequiredMessage = 'Email is required';
  static const String emailInvalidMessage = 'Please enter a valid email address';
  static const String passwordRequiredMessage = 'Password is required';
  static const String passwordMinLengthMessage = 'Password must be at least 6 characters long';
  static const String nameRequiredMessage = 'Name is required';
  static const String institutionRequiredMessage = 'Institution is required';
  static const String cohortCodeRequiredMessage = 'Cohort code is required';
  
  // Network Status
  static const String networkStatusOnline = 'online';
  static const String networkStatusOffline = 'offline';
  static const String networkStatusPoor = 'poor';
  
  // Live Session Status
  static const String sessionStatusActive = 'active';
  static const String sessionStatusEnded = 'ended';
  static const String sessionStatusUpcoming = 'upcoming';
  
  // User Types
  static const String userTypeStudent = 'student';
  static const String userTypeTeacher = 'teacher';
  static const String userTypeAdmin = 'admin';
  
  // Lecture Status
  static const String lectureStatusActive = 'active';
  static const String lectureStatusUpcoming = 'upcoming';
  static const String lectureStatusEnded = 'ended';
  static const String lectureStatusCancelled = 'cancelled';
  
  // Download Status
  static const String downloadStatusPending = 'pending';
  static const String downloadStatusDownloading = 'downloading';
  static const String downloadStatusCompleted = 'completed';
  static const String downloadStatusFailed = 'failed';
  static const String downloadStatusPaused = 'paused';
  
  // Theme Mode
  static const String themeModeLight = 'light';
  static const String themeModeDark = 'dark';
  static const String themeModeSystem = 'system';
  
  // Audio Quality
  static const String audioQualityLow = 'low';
  static const String audioQualityMedium = 'medium';
  static const String audioQualityHigh = 'high';
  
  // Regular Expressions
  static const String emailRegex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phoneRegex = r'^\+?[1-9]\d{1,14}$';
  static const String cohortCodeRegex = r'^[A-Z0-9]{6,8}$';
  
  // Dimensions
  static const double defaultPadding = 16;
  static const double smallPadding = 8;
  static const double largePadding = 24;
  static const double defaultBorderRadius = 12;
  static const double cardElevation = 2;
  static const double bottomSheetMaxHeight = 0.9;
  
  // Animation Durations
  static const int shortAnimationMs = 200;
  static const int mediumAnimationMs = 300;
  static const int longAnimationMs = 500;
  
  // Limits
  static const int maxFileSize = 50 * 1024 * 1024; // 50MB
  static const int maxChatMessageLength = 500;
  static const int maxPollOptionLength = 100;
  static const int maxLectureDescriptionLength = 1000;
  
  // Default Values
  static const String defaultProfileImage = 'assets/images/default_profile.png';
  static const String defaultLectureImage = 'assets/images/default_lecture.png';
  static const String defaultCohortImage = 'assets/images/default_cohort.png';
}
