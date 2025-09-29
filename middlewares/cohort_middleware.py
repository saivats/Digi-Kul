"""
Cohort Middleware for data access scoping
Ensures all data access is scoped to the user's selected cohort.
"""

from functools import wraps
from flask import request, session, jsonify, g
from typing import Optional, List, Dict, Any
from utils.database_supabase import DatabaseManager

class CohortMiddleware:
    def __init__(self, app, db: DatabaseManager):
        """Initialize cohort middleware"""
        self.app = app
        self.db = db
    
    def require_cohort_selection(self, f):
        """
        Decorator to ensure user has selected a cohort
        This is required for teachers/admins who may belong to multiple cohorts
        """
        @wraps(f)
        def decorated_function(*args, **kwargs):
            user_type = session.get('user_type')
            
            # Students don't need cohort selection as they belong to one cohort only
            if user_type == 'student':
                return f(*args, **kwargs)
            
            # For teachers and admins, check if they have selected a cohort
            selected_cohort_id = session.get('selected_cohort_id')
            
            if not selected_cohort_id:
                # Get available cohorts for the user
                if user_type == 'teacher':
                    cohorts = self.db.get_teacher_cohorts(session.get('user_id'))
                elif user_type == 'admin':
                    cohorts = self.db.get_all_cohorts()
                else:
                    return jsonify({'error': 'Invalid user type'}), 400
                
                if not cohorts:
                    return jsonify({'error': 'No cohorts available. Please contact an administrator.'}), 400
                
                # If only one cohort, auto-select it
                if len(cohorts) == 1:
                    session['selected_cohort_id'] = cohorts[0]['id']
                    session['selected_cohort_name'] = cohorts[0]['name']
                    g.selected_cohort = cohorts[0]
                else:
                    # Multiple cohorts available, user needs to select one
                    return jsonify({
                        'error': 'Please select a cohort to continue',
                        'available_cohorts': cohorts,
                        'requires_cohort_selection': True
                    }), 400
            else:
                # Get cohort details and store in g for easy access
                cohort = self.db.get_cohort_by_id(selected_cohort_id)
                if not cohort:
                    # Cohort no longer exists, clear selection
                    session.pop('selected_cohort_id', None)
                    session.pop('selected_cohort_name', None)
                    return jsonify({'error': 'Selected cohort no longer exists'}), 400
                
                g.selected_cohort = cohort
            
            return f(*args, **kwargs)
        return decorated_function
    
    def scope_to_cohort(self, f):
        """
        Decorator to scope all data access to the selected cohort
        This ensures users only see data from their selected cohort
        """
        @wraps(f)
        def decorated_function(*args, **kwargs):
            user_type = session.get('user_type')
            user_id = session.get('user_id')
            
            # Get cohort context
            if user_type == 'student':
                # Students belong to one cohort only
                cohorts = self.db.get_student_cohorts(user_id)
                if not cohorts:
                    return jsonify({'error': 'Student not enrolled in any cohort'}), 400
                
                # Use the first (and likely only) cohort
                cohort = cohorts[0]
                g.selected_cohort = cohort
                g.scoped_cohort_id = cohort['id']
                
            elif user_type in ['teacher', 'admin']:
                # Teachers and admins may have selected a cohort
                selected_cohort_id = session.get('selected_cohort_id')
                if not selected_cohort_id:
                    return jsonify({'error': 'No cohort selected'}), 400
                
                # Verify user has access to this cohort
                if user_type == 'teacher':
                    teacher_cohorts = self.db.get_teacher_cohorts(user_id)
                    cohort_ids = [c['id'] for c in teacher_cohorts]
                    if selected_cohort_id not in cohort_ids:
                        return jsonify({'error': 'Access denied to selected cohort'}), 403
                
                g.scoped_cohort_id = selected_cohort_id
                cohort = self.db.get_cohort_by_id(selected_cohort_id)
                if cohort:
                    g.selected_cohort = cohort
            
            # Store cohort context in Flask's g object for easy access
            if hasattr(g, 'scoped_cohort_id'):
                g.cohort_id = g.scoped_cohort_id
                g.cohort_name = g.selected_cohort.get('name', '') if g.selected_cohort else ''
            
            return f(*args, **kwargs)
        return decorated_function
    
    def get_cohort_context(self) -> Optional[Dict[str, Any]]:
        """Get current cohort context from Flask's g object"""
        return getattr(g, 'selected_cohort', None)
    
    def get_scoped_cohort_id(self) -> Optional[str]:
        """Get current scoped cohort ID"""
        return getattr(g, 'scoped_cohort_id', None)
    
    def set_cohort_selection(self, cohort_id: str, cohort_name: str) -> bool:
        """
        Set the selected cohort for the current session
        
        Args:
            cohort_id: ID of the cohort to select
            cohort_name: Name of the cohort
            
        Returns:
            bool: True if successful
        """
        try:
            user_type = session.get('user_type')
            user_id = session.get('user_id')
            
            # Verify user has access to this cohort
            if user_type == 'teacher':
                teacher_cohorts = self.db.get_teacher_cohorts(user_id)
                cohort_ids = [c['id'] for c in teacher_cohorts]
                if cohort_id not in cohort_ids:
                    return False
            elif user_type == 'admin':
                # Admins have access to all cohorts
                cohort = self.db.get_cohort_by_id(cohort_id)
                if not cohort:
                    return False
            else:
                return False
            
            # Set session data
            session['selected_cohort_id'] = cohort_id
            session['selected_cohort_name'] = cohort_name
            
            return True
        except Exception:
            return False
    
    def clear_cohort_selection(self):
        """Clear the selected cohort from session"""
        session.pop('selected_cohort_id', None)
        session.pop('selected_cohort_name', None)
    
    def get_available_cohorts(self) -> List[Dict[str, Any]]:
        """Get available cohorts for the current user"""
        user_type = session.get('user_type')
        user_id = session.get('user_id')
        
        if user_type == 'student':
            return self.db.get_student_cohorts(user_id)
        elif user_type == 'teacher':
            return self.db.get_teacher_cohorts(user_id)
        elif user_type == 'admin':
            return self.db.get_all_cohorts()
        else:
            return []
    
    def validate_cohort_access(self, cohort_id: str) -> bool:
        """
        Validate if the current user has access to a specific cohort
        
        Args:
            cohort_id: ID of the cohort to validate
            
        Returns:
            bool: True if user has access
        """
        try:
            user_type = session.get('user_type')
            user_id = session.get('user_id')
            
            if user_type == 'admin':
                # Admins have access to all cohorts
                cohort = self.db.get_cohort_by_id(cohort_id)
                return cohort is not None
            
            elif user_type == 'teacher':
                # Check if teacher is assigned to this cohort
                teacher_cohorts = self.db.get_teacher_cohorts(user_id)
                return any(c['id'] == cohort_id for c in teacher_cohorts)
            
            elif user_type == 'student':
                # Check if student is enrolled in this cohort
                return self.db.is_student_in_cohort(user_id, cohort_id)
            
            return False
        except Exception:
            return False
    
    def filter_data_by_cohort(self, data: List[Dict], cohort_field: str = 'cohort_id') -> List[Dict]:
        """
        Filter data to only include items from the selected cohort
        
        Args:
            data: List of data items to filter
            cohort_field: Field name that contains the cohort ID
            
        Returns:
            Filtered list of data items
        """
        scoped_cohort_id = self.get_scoped_cohort_id()
        if not scoped_cohort_id:
            return []
        
        return [item for item in data if item.get(cohort_field) == scoped_cohort_id]
    
    def ensure_cohort_scope(self, query_params: Dict[str, Any]) -> Dict[str, Any]:
        """
        Ensure query parameters include cohort scoping
        
        Args:
            query_params: Original query parameters
            
        Returns:
            Updated query parameters with cohort scoping
        """
        scoped_cohort_id = self.get_scoped_cohort_id()
        if scoped_cohort_id:
            query_params['cohort_id'] = scoped_cohort_id
        
        return query_params
    
    def get_cohort_students(self) -> List[Dict[str, Any]]:
        """Get students from the current cohort context"""
        cohort_id = self.get_scoped_cohort_id()
        if not cohort_id:
            return []
        
        return self.db.get_cohort_students(cohort_id)
    
    def get_cohort_lectures(self) -> List[Dict[str, Any]]:
        """Get lectures from the current cohort context"""
        cohort_id = self.get_scoped_cohort_id()
        if not cohort_id:
            return []
        
        return self.db.get_cohort_lectures(cohort_id)
    
    def get_cohort_quizzes(self) -> List[Dict[str, Any]]:
        """Get quizzes from the current cohort context"""
        cohort_id = self.get_scoped_cohort_id()
        if not cohort_id:
            return []
        
        # This would need to be implemented in the quiz service
        # For now, return empty list
        return []
    
    def middleware_before_request(self):
        """Middleware function to run before each request"""
        # This can be registered with Flask's before_request
        pass
    
    def middleware_after_request(self, response):
        """Middleware function to run after each request"""
        # This can be registered with Flask's after_request
        return response

