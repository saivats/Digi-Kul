from flask import Blueprint, jsonify, request, session
import os
from services.chat_service import ChatService
from werkzeug.utils import secure_filename
from middlewares.auth_middleware import login_required

chat_bp = Blueprint('chat', __name__)
chat_service = ChatService()

@chat_bp.route('/discussions/<forum_id>/messages')
@login_required
def get_forum_messages(forum_id):
    try:
        messages = chat_service.get_forum_messages(forum_id)
        return jsonify({
            'success': True,
            'messages': messages
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@chat_bp.route('/discussions/upload', methods=['POST'])
@login_required
def upload_chat_attachment():
    try:
        if 'file' not in request.files:
            return jsonify({'error': 'No file provided'}), 400
            
        file = request.files['file']
        forum_id = request.form.get('forum_id')
        
        if not file or not forum_id:
            return jsonify({'error': 'Invalid request'}), 400
            
        # Validate file size and type
        allowed_extensions = {'pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'}
        if '.' not in file.filename:
            return jsonify({'error': 'Invalid file type'}), 400
            
        extension = file.filename.rsplit('.', 1)[1].lower()
        if extension not in allowed_extensions:
            return jsonify({'error': 'File type not allowed'}), 400
            
        # 10MB file size limit
        file_stream = file.stream
        file_stream.seek(0, os.SEEK_END)
        size = file_stream.tell()
        file_stream.seek(0)
        if size > 10 * 1024 * 1024:
            return jsonify({'error': 'File too large (max 10MB)'}), 400

        file_bytes = file.read()
        file.seek(0)
        filename = secure_filename(file.filename)
        print(f"[chat_routes] uploading file: {filename}, size={len(file_bytes)}, forum_id={forum_id}")
        result = chat_service.upload_attachment(
            institution_id=session.get('institution_id'),
            forum_id=forum_id,
            file_data=file_bytes,
            filename=filename
        )
        print(f"[chat_routes] upload result: {result}")
        
        if result:
            return jsonify({
                'success': True,
                'url': result['url']
            })
        else:
            return jsonify({
                'success': False,
                'error': 'Upload failed'
            }), 500
            
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500