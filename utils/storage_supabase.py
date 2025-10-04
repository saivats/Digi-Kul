"""
Supabase Storage utility for file uploads and management
"""
import os
import uuid
from typing import Optional, Tuple, Dict, Any
from datetime import datetime
from supabase import create_client, Client
from werkzeug.utils import secure_filename

class SupabaseStorageManager:
    def __init__(self, supabase_url: str, supabase_key: str):
        """Initialize Supabase Storage manager"""
        self.supabase: Client = create_client(supabase_url, supabase_key)
        self.buckets = {
            'materials': 'materials',
            'recordings': 'recordings',
            'documents': 'documents',
            'images': 'images'
        }
    
    def create_buckets(self) -> bool:
        """Create storage buckets if they don't exist"""
        try:
            for bucket_name in self.buckets.values():
                try:
                    # Check if bucket exists
                    self.supabase.storage.get_bucket(bucket_name)
                except Exception:
                    # Create bucket if it doesn't exist
                    self.supabase.storage.create_bucket(
                        bucket_name,
                        options={
                            "public": True,
                            "allowedMimeTypes": self._get_allowed_mime_types(bucket_name),
                            "fileSizeLimit": self._get_file_size_limit(bucket_name)
                        }
                    )
            return True
        except Exception as e:
            print(f"Error creating buckets: {e}")
            return False
    
    def _get_allowed_mime_types(self, bucket_name: str) -> list:
        """Get allowed MIME types for each bucket"""
        mime_types = {
            'materials': [
                'application/pdf',
                'application/msword',
                'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                'application/vnd.ms-excel',
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                'application/vnd.ms-powerpoint',
                'application/vnd.openxmlformats-officedocument.presentationml.presentation',
                'text/plain',
                'image/jpeg',
                'image/png',
                'image/gif',
                'image/webp'
            ],
            'recordings': [
                'video/mp4',
                'video/webm',
                'video/avi',
                'video/mov',
                'video/quicktime',
                'audio/mp3',
                'audio/wav',
                'audio/mpeg'
            ],
            'documents': [
                'application/pdf',
                'application/msword',
                'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                'text/plain'
            ],
            'images': [
                'image/jpeg',
                'image/png',
                'image/gif',
                'image/webp',
                'image/svg+xml'
            ]
        }
        return mime_types.get(bucket_name, [])
    
    def _get_file_size_limit(self, bucket_name: str) -> int:
        """Get file size limit for each bucket (in bytes)"""
        limits = {
            'materials': 50 * 1024 * 1024,  # 50MB
            'recordings': 500 * 1024 * 1024,  # 500MB
            'documents': 25 * 1024 * 1024,   # 25MB
            'images': 10 * 1024 * 1024       # 10MB
        }
        return limits.get(bucket_name, 10 * 1024 * 1024)
    
    def upload_file(self, file, bucket_name: str, folder_path: str = "", 
                   custom_filename: str = None) -> Tuple[Optional[str], str]:
        """Upload a file to Supabase Storage"""
        try:
            if not file or not file.filename:
                return None, "No file provided"
            
            # Generate unique filename
            if custom_filename:
                filename = custom_filename
            else:
                file_extension = os.path.splitext(secure_filename(file.filename))[1]
                unique_id = str(uuid.uuid4())
                filename = f"{unique_id}{file_extension}"
            
            # Create full path
            if folder_path:
                full_path = f"{folder_path}/{filename}"
            else:
                full_path = filename
            
            # Upload file
            result = self.supabase.storage.from_(bucket_name).upload(
                full_path,
                file.read(),
                file_options={"content-type": file.content_type}
            )
            
            if result:
                # Get public URL
                public_url = self.supabase.storage.from_(bucket_name).get_public_url(full_path)
                return public_url, "File uploaded successfully"
            else:
                return None, "Failed to upload file"
                
        except Exception as e:
            return None, str(e)
    
    def upload_file_from_path(self, file_path: str, bucket_name: str, 
                            folder_path: str = "", custom_filename: str = None) -> Tuple[Optional[str], str]:
        """Upload a file from local path to Supabase Storage"""
        try:
            if not os.path.exists(file_path):
                return None, "File not found"
            
            # Generate unique filename
            if custom_filename:
                filename = custom_filename
            else:
                file_extension = os.path.splitext(os.path.basename(file_path))[1]
                unique_id = str(uuid.uuid4())
                filename = f"{unique_id}{file_extension}"
            
            # Create full path
            if folder_path:
                full_path = f"{folder_path}/{filename}"
            else:
                full_path = filename
            
            # Read file and upload
            with open(file_path, 'rb') as f:
                file_data = f.read()
            
            # Determine content type
            content_type = self._get_content_type(file_path)
            
            # Upload file
            result = self.supabase.storage.from_(bucket_name).upload(
                full_path,
                file_data,
                file_options={"content-type": content_type}
            )
            
            if result:
                # Get public URL
                public_url = self.supabase.storage.from_(bucket_name).get_public_url(full_path)
                return public_url, "File uploaded successfully"
            else:
                return None, "Failed to upload file"
                
        except Exception as e:
            return None, str(e)
    
    def _get_content_type(self, file_path: str) -> str:
        """Get content type based on file extension"""
        extension = os.path.splitext(file_path)[1].lower()
        content_types = {
            '.pdf': 'application/pdf',
            '.doc': 'application/msword',
            '.docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            '.xls': 'application/vnd.ms-excel',
            '.xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            '.ppt': 'application/vnd.ms-powerpoint',
            '.pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
            '.txt': 'text/plain',
            '.jpg': 'image/jpeg',
            '.jpeg': 'image/jpeg',
            '.png': 'image/png',
            '.gif': 'image/gif',
            '.webp': 'image/webp',
            '.mp4': 'video/mp4',
            '.webm': 'video/webm',
            '.avi': 'video/avi',
            '.mov': 'video/quicktime',
            '.mp3': 'audio/mp3',
            '.wav': 'audio/wav'
        }
        return content_types.get(extension, 'application/octet-stream')
    
    def delete_file(self, bucket_name: str, file_path: str) -> bool:
        """Delete a file from Supabase Storage"""
        try:
            result = self.supabase.storage.from_(bucket_name).remove([file_path])
            return bool(result)
        except Exception as e:
            print(f"Error deleting file: {e}")
            return False
    
    def get_file_url(self, bucket_name: str, file_path: str) -> str:
        """Get public URL for a file"""
        try:
            return self.supabase.storage.from_(bucket_name).get_public_url(file_path)
        except Exception as e:
            print(f"Error getting file URL: {e}")
            return ""
    
    def list_files(self, bucket_name: str, folder_path: str = "") -> list:
        """List files in a bucket folder"""
        try:
            result = self.supabase.storage.from_(bucket_name).list(folder_path)
            return result if result else []
        except Exception as e:
            print(f"Error listing files: {e}")
            return []
    
    def get_file_info(self, bucket_name: str, file_path: str) -> Optional[Dict[str, Any]]:
        """Get file information"""
        try:
            result = self.supabase.storage.from_(bucket_name).info(file_path)
            return result if result else None
        except Exception as e:
            print(f"Error getting file info: {e}")
            return None
    
    def get_signed_url(self, bucket_name: str, file_path: str, expires_in: int = 3600) -> Optional[str]:
        """Get a signed URL for private file access"""
        try:
            result = self.supabase.storage.from_(bucket_name).create_signed_url(file_path, expires_in)
            if result and 'signedURL' in result:
                return result['signedURL']
            return None
        except Exception as e:
            print(f"Error getting signed URL: {e}")
            return None