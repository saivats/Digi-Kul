"""
Configuration Example for Digi Kul Teachers Portal
Copy this file to config.py and update with your actual values
"""

import os
from datetime import timedelta

class Config:
    # Flask Configuration
    SECRET_KEY = os.environ.get('SECRET_KEY', 'your-secret-key-change-this')
    DEBUG = os.environ.get('FLASK_DEBUG', 'True').lower() == 'true'
    
    # Session Configuration
    PERMANENT_SESSION_LIFETIME = timedelta(hours=8)
    SESSION_COOKIE_SECURE = True
    SESSION_COOKIE_HTTPONLY = True
    SESSION_COOKIE_SAMESITE = 'Lax'
    SESSION_COOKIE_NAME = 'digi_kul_session'
    
    # Database Configuration (Supabase)
    SUPABASE_URL = os.environ.get('SUPABASE_URL', 'your-supabase-url')
    SUPABASE_KEY = os.environ.get('SUPABASE_KEY', 'your-supabase-key')
    
    # File Upload Configuration
    UPLOAD_FOLDER = os.environ.get('UPLOAD_FOLDER', 'uploads')
    COMPRESSED_FOLDER = os.environ.get('COMPRESSED_FOLDER', 'compressed')
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16MB max file size
    
    # SMTP Email Configuration
    SMTP_HOST = os.environ.get('SMTP_HOST', 'smtp.gmail.com')
    SMTP_PORT = int(os.environ.get('SMTP_PORT', 587))
    SMTP_USERNAME = os.environ.get('SMTP_USERNAME', 'your-email@gmail.com')
    SMTP_PASSWORD = os.environ.get('SMTP_PASSWORD', 'your-app-password')
    SMTP_USE_TLS = os.environ.get('SMTP_USE_TLS', 'True').lower() == 'true'
    SMTP_SENDER_EMAIL = os.environ.get('SMTP_SENDER_EMAIL', 'your-email@gmail.com')
    
    # Flask-SocketIO Configuration
    SOCKETIO_CORS_ALLOWED_ORIGINS = os.environ.get('SOCKETIO_CORS_ALLOWED_ORIGINS', "*").split(',')
    SOCKETIO_ASYNC_MODE = os.environ.get('SOCKETIO_ASYNC_MODE', 'threading')
    
    # Recording Configuration
    RECORDING_DIRECTORY = os.environ.get('RECORDING_DIRECTORY', 'recordings')
    MAX_RECORDING_DURATION = int(os.environ.get('MAX_RECORDING_DURATION', 7200))  # 2 hours
    
    # Security Configuration
    WTF_CSRF_ENABLED = True
    WTF_CSRF_TIME_LIMIT = 3600  # 1 hour
    
    # Logging Configuration
    LOG_LEVEL = os.environ.get('LOG_LEVEL', 'INFO')
    LOG_FILE = os.environ.get('LOG_FILE', 'app.log')
    
    # Cache Configuration (Optional)
    CACHE_TYPE = os.environ.get('CACHE_TYPE', 'simple')
    CACHE_DEFAULT_TIMEOUT = int(os.environ.get('CACHE_DEFAULT_TIMEOUT', 300))
    
    # Rate Limiting (Optional)
    RATELIMIT_STORAGE_URL = os.environ.get('RATELIMIT_STORAGE_URL', 'memory://')
    RATELIMIT_DEFAULT = os.environ.get('RATELIMIT_DEFAULT', '100 per hour')
    
    # Admin Configuration
    ADMIN_EMAIL = os.environ.get('ADMIN_EMAIL', 'admin@example.com')
    ADMIN_PASSWORD = os.environ.get('ADMIN_PASSWORD', 'Admin@#1234')
    
    # Feature Flags
    ENABLE_RECORDING = os.environ.get('ENABLE_RECORDING', 'True').lower() == 'true'
    ENABLE_EMAIL_NOTIFICATIONS = os.environ.get('ENABLE_EMAIL_NOTIFICATIONS', 'True').lower() == 'true'
    ENABLE_QUIZ_ANALYTICS = os.environ.get('ENABLE_QUIZ_ANALYTICS', 'True').lower() == 'true'
    ENABLE_COHORT_SCOPING = os.environ.get('ENABLE_COHORT_SCOPING', 'True').lower() == 'true'

class DevelopmentConfig(Config):
    """Development configuration"""
    DEBUG = True
    TESTING = False
    
class ProductionConfig(Config):
    """Production configuration"""
    DEBUG = False
    TESTING = False
    SESSION_COOKIE_SECURE = True
    
    # Production-specific settings
    LOG_LEVEL = 'WARNING'
    
class TestingConfig(Config):
    """Testing configuration"""
    DEBUG = True
    TESTING = True
    WTF_CSRF_ENABLED = False
    
    # Use in-memory database for testing
    SUPABASE_URL = 'test-url'
    SUPABASE_KEY = 'test-key'

# Configuration mapping
config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'testing': TestingConfig,
    'default': DevelopmentConfig
}
