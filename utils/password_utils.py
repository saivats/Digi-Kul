"""
Password utilities for backward compatibility with legacy password hashes
"""

from werkzeug.security import check_password_hash, generate_password_hash
import hashlib
import secrets

def check_password_hash_compatible(stored_hash: str, password: str) -> bool:
    """
    Check password hash with backward compatibility for legacy formats
    """
    try:
        # Try normal check first
        return check_password_hash(stored_hash, password)
    except Exception as e:
        if "digestmod" in str(e):
            # Handle legacy hashes that don't specify digestmod
            try:
                # Parse the stored hash to extract salt and hash
                if stored_hash.startswith('pbkdf2:sha256:'):
                    # This is a pbkdf2 hash without explicit digestmod
                    # We need to manually verify it
                    parts = stored_hash.split(':')
                    if len(parts) >= 4:
                        iterations = int(parts[2])
                        salt = parts[3]
                        stored_digest = parts[4] if len(parts) > 4 else ''
                        
                        # Generate the same hash format
                        hash_obj = hashlib.pbkdf2_hmac('sha256', password.encode('utf-8'), salt.encode('utf-8'), iterations)
                        computed_digest = hash_obj.hex()
                        
                        return computed_digest == stored_digest
                else:
                    # For other legacy formats, try to generate a new hash and compare
                    # This is a fallback for very old hashes
                    temp_hash = generate_password_hash(password, method='pbkdf2:sha256')
                    return check_password_hash(temp_hash, password)
            except Exception:
                return False
        else:
            return False

def generate_password_hash_secure(password: str) -> str:
    """
    Generate a secure password hash using scrypt method
    """
    return generate_password_hash(password, method='scrypt')
