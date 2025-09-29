"""
Session Recording Service
Handles recording of live lecture sessions including video, audio, and chat logs.
"""

import os
import json
import uuid
import threading
import time
from datetime import datetime, timedelta
from typing import Optional, Dict, List, Tuple
from utils.database_supabase import DatabaseManager
import logging

logger = logging.getLogger(__name__)

class SessionRecordingService:
    def __init__(self, db: DatabaseManager):
        self.db = db
        self.active_recordings = {}  # {session_id: recording_info}
        self.recording_threads = {}  # {session_id: thread}
        self.recording_directory = 'recordings'
        self.chat_logs = {}  # {session_id: [chat_messages]}
        self.participant_activity = {}  # {session_id: {user_id: activity_data}}
        
        # Ensure recording directory exists
        os.makedirs(self.recording_directory, exist_ok=True)
        os.makedirs(os.path.join(self.recording_directory, 'videos'), exist_ok=True)
        os.makedirs(os.path.join(self.recording_directory, 'audio'), exist_ok=True)
        os.makedirs(os.path.join(self.recording_directory, 'logs'), exist_ok=True)

    def start_recording(self, session_id: str, lecture_id: str, teacher_id: str, recording_type: str = 'full') -> Tuple[bool, str]:
        """
        Start recording a live session.
        
        Args:
            session_id: Unique session identifier
            lecture_id: Associated lecture ID
            teacher_id: Teacher conducting the session
            recording_type: Type of recording ('full', 'audio_only', 'chat_only')
        
        Returns:
            Tuple of (success, message)
        """
        try:
            if session_id in self.active_recordings:
                return False, "Recording already in progress for this session"
            
            # Generate unique recording ID
            recording_id = str(uuid.uuid4())
            
            # Create recording directory for this session
            session_recording_dir = os.path.join(self.recording_directory, session_id)
            os.makedirs(session_recording_dir, exist_ok=True)
            
            # Initialize recording data
            recording_info = {
                'recording_id': recording_id,
                'session_id': session_id,
                'lecture_id': lecture_id,
                'teacher_id': teacher_id,
                'recording_type': recording_type,
                'started_at': datetime.now().isoformat(),
                'status': 'recording',
                'recording_directory': session_recording_dir,
                'participants': {},
                'chat_messages': [],
                'quality_reports': [],
                'recording_stats': {
                    'duration': 0,
                    'participants_count': 0,
                    'chat_messages_count': 0,
                    'video_chunks': 0,
                    'audio_chunks': 0
                }
            }
            
            # Store recording info
            self.active_recordings[session_id] = recording_info
            self.chat_logs[session_id] = []
            self.participant_activity[session_id] = {}
            
            # Start background recording thread
            recording_thread = threading.Thread(
                target=self._recording_worker,
                args=(session_id,),
                daemon=True
            )
            recording_thread.start()
            self.recording_threads[session_id] = recording_thread
            
            # Save initial recording metadata
            self._save_recording_metadata(session_id)
            
            logger.info(f"Started recording for session {session_id}")
            return True, f"Recording started successfully. Recording ID: {recording_id}"
            
        except Exception as e:
            logger.error(f"Failed to start recording for session {session_id}: {e}")
            return False, str(e)

    def stop_recording(self, session_id: str) -> Tuple[bool, str]:
        """
        Stop recording a live session and finalize the recording.
        
        Args:
            session_id: Unique session identifier
        
        Returns:
            Tuple of (success, message)
        """
        try:
            if session_id not in self.active_recordings:
                return False, "No active recording found for this session"
            
            recording_info = self.active_recordings[session_id]
            recording_info['status'] = 'stopping'
            recording_info['stopped_at'] = datetime.now().isoformat()
            
            # Calculate final duration
            start_time = datetime.fromisoformat(recording_info['started_at'])
            stop_time = datetime.now()
            duration = int((stop_time - start_time).total_seconds())
            recording_info['recording_stats']['duration'] = duration
            
            # Finalize recording
            self._finalize_recording(session_id)
            
            # Save to database
            recording_id = recording_info['recording_id']
            success, message = self.db.create_session_recording(
                recording_id=recording_id,
                session_id=session_id,
                lecture_id=recording_info['lecture_id'],
                teacher_id=recording_info['teacher_id'],
                recording_type=recording_info['recording_type'],
                started_at=recording_info['started_at'],
                stopped_at=recording_info['stopped_at'],
                duration=duration,
                recording_path=recording_info['recording_directory'],
                participants=recording_info['participants'],
                stats=recording_info['recording_stats']
            )
            
            if success:
                # Clean up active recording
                del self.active_recordings[session_id]
                if session_id in self.recording_threads:
                    del self.recording_threads[session_id]
                if session_id in self.chat_logs:
                    del self.chat_logs[session_id]
                if session_id in self.participant_activity:
                    del self.participant_activity[session_id]
                
                logger.info(f"Stopped recording for session {session_id}")
                return True, "Recording stopped and saved successfully"
            else:
                return False, f"Failed to save recording: {message}"
                
        except Exception as e:
            logger.error(f"Failed to stop recording for session {session_id}: {e}")
            return False, str(e)

    def log_chat_message(self, session_id: str, user_id: str, user_name: str, message: str, message_type: str = 'text') -> bool:
        """
        Log a chat message during recording.
        
        Args:
            session_id: Session identifier
            user_id: User who sent the message
            user_name: Name of the user
            message: Chat message content
            message_type: Type of message ('text', 'system', 'file')
        
        Returns:
            Success status
        """
        try:
            if session_id not in self.active_recordings:
                return False
            
            chat_message = {
                'timestamp': datetime.now().isoformat(),
                'user_id': user_id,
                'user_name': user_name,
                'message': message,
                'message_type': message_type
            }
            
            self.chat_logs[session_id].append(chat_message)
            self.active_recordings[session_id]['recording_stats']['chat_messages_count'] += 1
            
            return True
            
        except Exception as e:
            logger.error(f"Failed to log chat message for session {session_id}: {e}")
            return False

    def log_participant_activity(self, session_id: str, user_id: str, user_name: str, activity_type: str, data: Dict = None) -> bool:
        """
        Log participant activity during recording.
        
        Args:
            session_id: Session identifier
            user_id: User performing the activity
            user_name: Name of the user
            activity_type: Type of activity ('join', 'leave', 'video_on', 'video_off', 'audio_on', 'audio_off')
            data: Additional activity data
        
        Returns:
            Success status
        """
        try:
            if session_id not in self.active_recordings:
                return False
            
            if session_id not in self.participant_activity:
                self.participant_activity[session_id] = {}
            
            if user_id not in self.participant_activity[session_id]:
                self.participant_activity[session_id][user_id] = {
                    'user_name': user_name,
                    'activities': [],
                    'total_time': 0,
                    'joined_at': None,
                    'left_at': None
                }
            
            activity_log = {
                'timestamp': datetime.now().isoformat(),
                'activity_type': activity_type,
                'data': data or {}
            }
            
            self.participant_activity[session_id][user_id]['activities'].append(activity_log)
            
            # Update participant info in recording
            if session_id in self.active_recordings:
                self.active_recordings[session_id]['participants'][user_id] = {
                    'user_name': user_name,
                    'last_activity': activity_log['timestamp']
                }
            
            return True
            
        except Exception as e:
            logger.error(f"Failed to log participant activity for session {session_id}: {e}")
            return False

    def save_video_chunk(self, session_id: str, user_id: str, chunk_data: bytes, chunk_type: str = 'video') -> bool:
        """
        Save a video/audio chunk during recording.
        
        Args:
            session_id: Session identifier
            user_id: User who sent the chunk
            chunk_data: Binary chunk data
            chunk_type: Type of chunk ('video', 'audio')
        
        Returns:
            Success status
        """
        try:
            if session_id not in self.active_recordings:
                return False
            
            recording_info = self.active_recordings[session_id]
            recording_dir = recording_info['recording_directory']
            
            # Create user-specific subdirectory
            user_dir = os.path.join(recording_dir, f"{chunk_type}s", user_id)
            os.makedirs(user_dir, exist_ok=True)
            
            # Save chunk with timestamp
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S_%f")
            chunk_filename = f"{chunk_type}_{timestamp}.webm"
            chunk_path = os.path.join(user_dir, chunk_filename)
            
            with open(chunk_path, 'wb') as f:
                f.write(chunk_data)
            
            # Update stats
            if chunk_type == 'video':
                recording_info['recording_stats']['video_chunks'] += 1
            else:
                recording_info['recording_stats']['audio_chunks'] += 1
            
            return True
            
        except Exception as e:
            logger.error(f"Failed to save {chunk_type} chunk for session {session_id}: {e}")
            return False

    def get_recording_status(self, session_id: str) -> Optional[Dict]:
        """
        Get current recording status for a session.
        
        Args:
            session_id: Session identifier
        
        Returns:
            Recording status dictionary or None
        """
        if session_id not in self.active_recordings:
            return None
        
        recording_info = self.active_recordings[session_id].copy()
        
        # Calculate current duration
        start_time = datetime.fromisoformat(recording_info['started_at'])
        current_duration = int((datetime.now() - start_time).total_seconds())
        recording_info['recording_stats']['duration'] = current_duration
        
        # Add current participant count
        recording_info['recording_stats']['participants_count'] = len(recording_info['participants'])
        
        return recording_info

    def get_session_recordings(self, lecture_id: str) -> List[Dict]:
        """
        Get all recordings for a specific lecture.
        
        Args:
            lecture_id: Lecture identifier
        
        Returns:
            List of recording information
        """
        try:
            recordings = self.db.get_lecture_recordings(lecture_id)
            return recordings
            
        except Exception as e:
            logger.error(f"Failed to get recordings for lecture {lecture_id}: {e}")
            return []

    def get_recording_details(self, recording_id: str) -> Optional[Dict]:
        """
        Get detailed information about a specific recording.
        
        Args:
            recording_id: Recording identifier
        
        Returns:
            Recording details or None
        """
        try:
            recording = self.db.get_recording_by_id(recording_id)
            if recording:
                # Load additional data if available
                recording_dir = recording.get('recording_path')
                if recording_dir and os.path.exists(recording_dir):
                    recording['files'] = self._get_recording_files(recording_dir)
                    recording['chat_log'] = self._load_chat_log(recording_dir)
            
            return recording
            
        except Exception as e:
            logger.error(f"Failed to get recording details for {recording_id}: {e}")
            return None

    def delete_recording(self, recording_id: str) -> Tuple[bool, str]:
        """
        Delete a recording and its associated files.
        
        Args:
            recording_id: Recording identifier
        
        Returns:
            Tuple of (success, message)
        """
        try:
            recording = self.db.get_recording_by_id(recording_id)
            if not recording:
                return False, "Recording not found"
            
            # Delete files
            recording_path = recording.get('recording_path')
            if recording_path and os.path.exists(recording_path):
                import shutil
                shutil.rmtree(recording_path)
            
            # Delete from database
            success, message = self.db.delete_recording(recording_id)
            
            if success:
                logger.info(f"Deleted recording {recording_id}")
                return True, "Recording deleted successfully"
            else:
                return False, f"Failed to delete recording from database: {message}"
                
        except Exception as e:
            logger.error(f"Failed to delete recording {recording_id}: {e}")
            return False, str(e)

    def _recording_worker(self, session_id: str):
        """
        Background worker for recording session data.
        """
        try:
            while session_id in self.active_recordings:
                recording_info = self.active_recordings[session_id]
                
                if recording_info['status'] == 'stopping':
                    break
                
                # Update duration
                start_time = datetime.fromisoformat(recording_info['started_at'])
                current_duration = int((datetime.now() - start_time).total_seconds())
                recording_info['recording_stats']['duration'] = current_duration
                
                # Save periodic metadata
                self._save_recording_metadata(session_id)
                
                # Sleep for a short interval
                time.sleep(5)
                
        except Exception as e:
            logger.error(f"Recording worker error for session {session_id}: {e}")

    def _save_recording_metadata(self, session_id: str):
        """Save recording metadata to file."""
        try:
            if session_id not in self.active_recordings:
                return
            
            recording_info = self.active_recordings[session_id]
            metadata_path = os.path.join(recording_info['recording_directory'], 'metadata.json')
            
            # Add current chat logs and participant activity
            recording_info['chat_messages'] = self.chat_logs.get(session_id, [])
            recording_info['participant_activity'] = self.participant_activity.get(session_id, {})
            
            with open(metadata_path, 'w') as f:
                json.dump(recording_info, f, indent=2)
                
        except Exception as e:
            logger.error(f"Failed to save metadata for session {session_id}: {e}")

    def _finalize_recording(self, session_id: str):
        """Finalize recording by saving final metadata and logs."""
        try:
            if session_id not in self.active_recordings:
                return
            
            recording_info = self.active_recordings[session_id]
            recording_dir = recording_info['recording_directory']
            
            # Save final chat log
            chat_log_path = os.path.join(recording_dir, 'chat_log.json')
            with open(chat_log_path, 'w') as f:
                json.dump(self.chat_logs.get(session_id, []), f, indent=2)
            
            # Save participant activity log
            activity_log_path = os.path.join(recording_dir, 'participant_activity.json')
            with open(activity_log_path, 'w') as f:
                json.dump(self.participant_activity.get(session_id, {}), f, indent=2)
            
            # Save final metadata
            self._save_recording_metadata(session_id)
            
            # Create recording summary
            summary_path = os.path.join(recording_dir, 'summary.txt')
            with open(summary_path, 'w') as f:
                f.write(f"Recording Summary\n")
                f.write(f"================\n")
                f.write(f"Session ID: {session_id}\n")
                f.write(f"Recording ID: {recording_info['recording_id']}\n")
                f.write(f"Lecture ID: {recording_info['lecture_id']}\n")
                f.write(f"Teacher ID: {recording_info['teacher_id']}\n")
                f.write(f"Started: {recording_info['started_at']}\n")
                f.write(f"Stopped: {recording_info.get('stopped_at', 'N/A')}\n")
                f.write(f"Duration: {recording_info['recording_stats']['duration']} seconds\n")
                f.write(f"Participants: {len(recording_info['participants'])}\n")
                f.write(f"Chat Messages: {recording_info['recording_stats']['chat_messages_count']}\n")
                f.write(f"Video Chunks: {recording_info['recording_stats']['video_chunks']}\n")
                f.write(f"Audio Chunks: {recording_info['recording_stats']['audio_chunks']}\n")
                
        except Exception as e:
            logger.error(f"Failed to finalize recording for session {session_id}: {e}")

    def _get_recording_files(self, recording_dir: str) -> List[str]:
        """Get list of files in recording directory."""
        try:
            files = []
            for root, dirs, filenames in os.walk(recording_dir):
                for filename in filenames:
                    relative_path = os.path.relpath(os.path.join(root, filename), recording_dir)
                    files.append(relative_path)
            return files
        except Exception as e:
            logger.error(f"Failed to get recording files: {e}")
            return []

    def _load_chat_log(self, recording_dir: str) -> List[Dict]:
        """Load chat log from recording directory."""
        try:
            chat_log_path = os.path.join(recording_dir, 'chat_log.json')
            if os.path.exists(chat_log_path):
                with open(chat_log_path, 'r') as f:
                    return json.load(f)
            return []
        except Exception as e:
            logger.error(f"Failed to load chat log: {e}")
            return []

    def cleanup_old_recordings(self, days_old: int = 30) -> int:
        """
        Clean up recordings older than specified days.
        
        Args:
            days_old: Number of days after which to delete recordings
        
        Returns:
            Number of recordings cleaned up
        """
        try:
            cutoff_date = datetime.now() - timedelta(days=days_old)
            old_recordings = self.db.get_old_recordings(cutoff_date.isoformat())
            
            cleaned_count = 0
            for recording in old_recordings:
                success, _ = self.delete_recording(recording['id'])
                if success:
                    cleaned_count += 1
            
            logger.info(f"Cleaned up {cleaned_count} old recordings")
            return cleaned_count
            
        except Exception as e:
            logger.error(f"Failed to cleanup old recordings: {e}")
            return 0
