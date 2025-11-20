from datetime import datetime
from typing import Optional, Dict, List
from utils.database_supabase import get_supabase_client
from utils.storage_supabase import get_storage_client


class ChatService:
    def __init__(self):
        self.db = get_supabase_client()
        self.storage = get_storage_client()

    def save_message(self, institution_id: str, forum_id: str, user_id: str,
                     user_name: str, user_type: str, message: str,
                     attachment: Optional[Dict] = None) -> Optional[Dict]:
        """Save a chat message to the database"""
        try:
            message_data = {
                "institution_id": institution_id,
                "forum_id": forum_id,
                "user_id": user_id,
                "user_name": user_name,
                "user_type": user_type,
                "message": message,
                "attachment": attachment,
                "created_at": datetime.utcnow().isoformat()
            }

            result = self.db.table('chat_messages').insert(message_data).execute()
            return result.data[0] if result.data else None

        except Exception as e:
            print(f"Error saving message: {str(e)}")
            return None

    def get_forum_messages(self, forum_id: str, limit: int = 100) -> List[Dict]:
        """Get messages for a forum, merging legacy discussion_posts if present"""
        messages: List[Dict] = []
        try:
            # Primary source: chat_messages
            chat_res = self.db.table('chat_messages')\
                .select('*')\
                .eq('forum_id', forum_id)\
                .order('created_at', desc=False)\
                .limit(limit)\
                .execute()
            if chat_res and chat_res.data:
                # Normalize each chat message record
                for cm in chat_res.data:
                    # Ensure user_name exists
                    user_name = cm.get('user_name') or cm.get('name') or 'Unknown User'

                    # Normalize attachment: the DB may store JSON as string
                    attachment = cm.get('attachment')
                    try:
                        import json as _json
                        if isinstance(attachment, str):
                            # Some clients store the JSON as a string; parse it
                            attachment = _json.loads(attachment)
                    except Exception:
                        # leave attachment as-is if parsing fails
                        pass

                    messages.append({
                        'forum_id': cm.get('forum_id'),
                        'message': cm.get('message') or '',
                        'user_id': cm.get('user_id'),
                        'user_name': user_name,
                        'user_type': cm.get('user_type') or 'student',
                        'attachment': attachment,
                        'created_at': cm.get('created_at'),
                        'timestamp': cm.get('created_at')
                    })
        except Exception as e:
            print(f"Error fetching chat_messages: {e}")

        try:
            # Legacy source: discussion_posts (some old messages may be there)
            disc_res = self.db.table('discussion_posts')\
                .select('*')\
                .eq('forum_id', forum_id)\
                .order('created_at', desc=False)\
                .limit(limit)\
                .execute()
            if disc_res and disc_res.data:
                for d in disc_res.data:
                    # Map legacy fields to new format
                    author_id = d.get('author_id') or d.get('user_id')
                    author_type = d.get('author_type') or d.get('user_type') or 'student'
                    author_name = d.get('author_name') or d.get('user_name') or None
                    # Try to resolve by email if name missing
                    author_email = d.get('author_email') or d.get('email') or None
                    if not author_name and author_type == 'teacher':
                        t = self.db.table('teachers').select('name').eq('id', author_id).execute()
                        if t and t.data:
                            author_name = t.data[0].get('name')
                    if not author_name and author_type == 'student':
                        s = self.db.table('students').select('name').eq('id', author_id).execute()
                        if s and s.data:
                            author_name = s.data[0].get('name')

                    if not author_name and author_email:
                        # Try to resolve across teachers and students by email
                        try:
                            t = self.db.table('teachers').select('name').eq('email', author_email).execute()
                            if t and t.data:
                                author_name = t.data[0].get('name')
                        except Exception:
                            pass
                        if not author_name:
                            try:
                                s = self.db.table('students').select('name').eq('email', author_email).execute()
                                if s and s.data:
                                    author_name = s.data[0].get('name')
                            except Exception:
                                pass

                    messages.append({
                        'forum_id': forum_id,
                        'message': d.get('content') or d.get('message'),
                        'user_id': author_id,
                        'user_name': author_name or 'Unknown User',
                        'user_type': author_type,
                        'created_at': d.get('created_at') or d.get('timestamp')
                    })
        except Exception as e:
            print(f"Error fetching discussion_posts: {e}")

        # Deduplicate by timestamp+user+message (simple heuristic), preserve order
        seen = set()
        deduped: List[Dict] = []
        for m in messages:
            key = (m.get('user_id'), m.get('user_name'), m.get('message'), m.get('created_at') or m.get('timestamp'))
            if key in seen:
                continue
            seen.add(key)
            deduped.append(m)

        return deduped[:limit]

    def upload_attachment(self, forum_id: str, file_data: bytes, filename: str, content_type: Optional[str] = None, institution_id: Optional[str] = None) -> Optional[Dict]:
        """Upload a file attachment to storage and return its public URL and metadata"""
        try:
            timestamp = datetime.utcnow().strftime('%Y%m%d_%H%M%S')
            storage_path = f"chat_attachments/{forum_id}/{timestamp}_{filename}"
            # Use the new upload_bytes helper
            public_url, msg = self.storage.upload_bytes('chat-attachments', storage_path, file_data, content_type)
            if public_url:
                return {
                    'url': public_url,
                    'path': storage_path,
                    'name': filename
                }
            print(f"Upload failed: {msg}")
            return None
        except Exception as e:
            print(f"Error uploading attachment: {str(e)}")
            return None

    def delete_message(self, message_id: str, user_id: str) -> bool:
        """Delete a chat message (only by the message author)"""
        try:
            result = self.db.table('chat_messages')\
                .delete()\
                .eq('id', message_id)\
                .eq('user_id', user_id)\
                .execute()
            return bool(result.data)
        except Exception as e:
            print(f"Error deleting message: {str(e)}")
            return False