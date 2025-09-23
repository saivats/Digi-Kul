// Custom JavaScript for Digi Kul Teachers Portal

// Global variables
let socket;
let currentUser = null;
let recordingStatus = false;

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    initializeApp();
    initializeSocket();
    setupEventListeners();
    addFadeInAnimation();
});

// Initialize application
function initializeApp() {
    // Check if user is logged in
    const userElement = document.querySelector('[data-user-id]');
    if (userElement) {
        currentUser = {
            id: userElement.dataset.userId,
            type: userElement.dataset.userType,
            name: userElement.dataset.userName
        };
    }
    
    // Initialize tooltips
    var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl);
    });
    
    // Auto-hide alerts
    const alerts = document.querySelectorAll('.alert');
    alerts.forEach(alert => {
        setTimeout(() => {
            const bsAlert = new bootstrap.Alert(alert);
            bsAlert.close();
        }, 5000);
    });
}

// Initialize Socket.IO connection
function initializeSocket() {
    if (currentUser && currentUser.id) {
        socket = io();
        
        socket.on('connect', function() {
            console.log('Connected to server');
            socket.emit('connect');
        });

        socket.on('disconnect', function() {
            console.log('Disconnected from server');
        });

        // Recording events
        socket.on('recording_started', function(data) {
            showToast('Recording started', 'success');
            showRecordingIndicator();
        });

        socket.on('recording_stopped', function(data) {
            showToast('Recording stopped', 'info');
            hideRecordingIndicator();
        });

        socket.on('recording_error', function(data) {
            showToast('Recording error: ' + data.message, 'error');
        });

        // Live session events
        socket.on('new_lecture', function(data) {
            showToast(`New lecture: ${data.title}`, 'info');
        });

        socket.on('live_session_started', function(data) {
            showToast(`Live session started: ${data.lecture_title}`, 'success');
        });

        socket.on('new_material', function(data) {
            showToast(`New material uploaded: ${data.title}`, 'info');
        });
    }
}

// Setup event listeners
function setupEventListeners() {
    // Form submissions
    document.querySelectorAll('form[data-ajax]').forEach(form => {
        form.addEventListener('submit', handleAjaxForm);
    });
    
    // Recording buttons
    document.querySelectorAll('[data-recording-action]').forEach(button => {
        button.addEventListener('click', handleRecordingAction);
    });
    
    // Lecture actions
    document.querySelectorAll('[data-lecture-action]').forEach(button => {
        button.addEventListener('click', handleLectureAction);
    });
    
    // Quiz actions
    document.querySelectorAll('[data-quiz-action]').forEach(button => {
        button.addEventListener('click', handleQuizAction);
    });
}

// Toast notification system
function showToast(message, type = 'info', duration = 5000) {
    const toastContainer = document.getElementById('toastContainer');
    if (!toastContainer) {
        console.error('Toast container not found');
        return;
    }
    
    const toastId = 'toast-' + Date.now();
    
    const toastHtml = `
        <div id="${toastId}" class="toast fade-in" role="alert" aria-live="assertive" aria-atomic="true">
            <div class="toast-header bg-${type === 'error' ? 'danger' : type} text-white">
                <i class="bi bi-${getToastIcon(type)} me-2"></i>
                <strong class="me-auto">${getToastTitle(type)}</strong>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="toast"></button>
            </div>
            <div class="toast-body">
                ${message}
            </div>
        </div>
    `;
    
    toastContainer.insertAdjacentHTML('beforeend', toastHtml);
    const toastElement = document.getElementById(toastId);
    const toast = new bootstrap.Toast(toastElement);
    toast.show();
    
    // Auto remove after duration
    setTimeout(() => {
        if (toastElement && toastElement.parentNode) {
            toastElement.parentNode.removeChild(toastElement);
        }
    }, duration);
}

function getToastIcon(type) {
    const icons = {
        'success': 'check-circle-fill',
        'error': 'exclamation-triangle-fill',
        'warning': 'exclamation-triangle-fill',
        'info': 'info-circle-fill'
    };
    return icons[type] || 'info-circle-fill';
}

function getToastTitle(type) {
    const titles = {
        'success': 'Success',
        'error': 'Error',
        'warning': 'Warning',
        'info': 'Info'
    };
    return titles[type] || 'Info';
}

// Recording functions
function showRecordingIndicator() {
    const indicator = document.getElementById('recordingIndicator');
    if (indicator) {
        indicator.style.display = 'block';
        recordingStatus = true;
    }
}

function hideRecordingIndicator() {
    const indicator = document.getElementById('recordingIndicator');
    if (indicator) {
        indicator.style.display = 'none';
        recordingStatus = false;
    }
}

function handleRecordingAction(event) {
    const action = event.target.dataset.recordingAction;
    const sessionId = event.target.dataset.sessionId;
    const lectureId = event.target.dataset.lectureId;
    
    if (action === 'start') {
        startRecording(sessionId, lectureId);
    } else if (action === 'stop') {
        stopRecording(sessionId);
    }
}

function startRecording(sessionId, lectureId) {
    if (!socket) {
        showToast('Not connected to server', 'error');
        return;
    }
    
    socket.emit('start_recording', {
        session_id: sessionId,
        lecture_id: lectureId,
        recording_type: 'full'
    });
}

function stopRecording(sessionId) {
    if (!socket) {
        showToast('Not connected to server', 'error');
        return;
    }
    
    socket.emit('stop_recording', {
        session_id: sessionId
    });
}

// Cohort selection for teachers
function selectCohort(cohortId) {
    if (!cohortId) return;
    
    const button = document.getElementById('cohortSelector');
    const originalContent = showLoading(button);
    
    fetch('/api/cohorts/select', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ cohort_id: cohortId })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            showToast(data.message, 'success');
            // Reload the page to update the UI
            setTimeout(() => location.reload(), 1000);
        } else {
            showToast(data.error || 'Failed to select cohort', 'error');
        }
    })
    .catch(error => {
        showToast('Network error', 'error');
        console.error('Error:', error);
    })
    .finally(() => {
        hideLoading(button, originalContent);
    });
}

// Lecture functions
function handleLectureAction(event) {
    const action = event.target.dataset.lectureAction;
    const lectureId = event.target.dataset.lectureId;
    
    switch (action) {
        case 'start_session':
            startLiveSession(lectureId);
            break;
        case 'join_session':
            joinLiveSession(lectureId);
            break;
        case 'upload_material':
            showUploadMaterialModal(lectureId);
            break;
        case 'view_materials':
            viewLectureMaterials(lectureId);
            break;
    }
}

function startLiveSession(lectureId) {
    fetch('/api/teacher/live_session/start', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ lecture_id: lectureId })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            showToast('Live session started', 'success');
            // Redirect to live session page
            window.location.href = `/teacher/manage_session/${data.session_id}`;
        } else {
            showToast(data.error || 'Failed to start session', 'error');
        }
    })
    .catch(error => {
        showToast('Network error', 'error');
        console.error('Error:', error);
    });
}

function joinLiveSession(lectureId) {
    // Get session ID for the lecture
    fetch(`/api/session/by_lecture/${lectureId}`)
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            window.location.href = `/student/join_session/${data.session_id}`;
        } else {
            showToast('No active session found', 'warning');
        }
    })
    .catch(error => {
        showToast('Network error', 'error');
        console.error('Error:', error);
    });
}

// Quiz functions
function handleQuizAction(event) {
    const action = event.target.dataset.quizAction;
    const quizSetId = event.target.dataset.quizSetId;
    
    switch (action) {
        case 'start_quiz':
            startQuizAttempt(quizSetId);
            break;
        case 'view_analytics':
            viewQuizAnalytics(quizSetId);
            break;
        case 'delete_quiz':
            deleteQuiz(quizSetId);
            break;
    }
}

function startQuizAttempt(quizSetId) {
    fetch(`/api/quiz/sets/${quizSetId}/start`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        }
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            showToast('Quiz started', 'success');
            // Redirect to quiz page
            window.location.href = `/quiz/${data.attempt_id}`;
        } else {
            showToast(data.error || 'Failed to start quiz', 'error');
        }
    })
    .catch(error => {
        showToast('Network error', 'error');
        console.error('Error:', error);
    });
}

// Form handling
function handleAjaxForm(event) {
    event.preventDefault();
    
    const form = event.target;
    const formData = new FormData(form);
    const url = form.action;
    const method = form.method || 'POST';
    
    const submitButton = form.querySelector('button[type="submit"]');
    const originalContent = showLoading(submitButton);
    
    fetch(url, {
        method: method,
        body: formData
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            showToast(data.message || 'Operation successful', 'success');
            if (form.dataset.reload) {
                location.reload();
            }
        } else {
            showToast(data.error || 'Operation failed', 'error');
        }
    })
    .catch(error => {
        showToast('Network error', 'error');
        console.error('Error:', error);
    })
    .finally(() => {
        hideLoading(submitButton, originalContent);
    });
}

// Modal functions (placeholder implementations)
function showCreateLectureModal() {
    showToast('Create lecture modal will be implemented', 'info');
}

function showCreateQuizModal() {
    showToast('Create quiz modal will be implemented', 'info');
}

function showJoinCohortModal() {
    showToast('Join cohort modal will be implemented', 'info');
}

function showCreateInstitutionModal() {
    showToast('Create institution modal will be implemented', 'info');
}

function showProfileModal() {
    showToast('Profile modal will be implemented', 'info');
}

function showUploadMaterialModal(lectureId) {
    showToast('Upload material modal will be implemented', 'info');
}

function viewLectureMaterials(lectureId) {
    showToast('View materials functionality will be implemented', 'info');
}

function viewQuizAnalytics(quizSetId) {
    showToast('Quiz analytics will be implemented', 'info');
}

function deleteQuiz(quizSetId) {
    if (confirm('Are you sure you want to delete this quiz?')) {
        showToast('Delete quiz functionality will be implemented', 'info');
    }
}

// Utility functions
function showLoading(element) {
    if (!element) return '';
    const originalContent = element.innerHTML;
    element.innerHTML = '<span class="loading-spinner"></span> Loading...';
    element.disabled = true;
    return originalContent;
}

function hideLoading(element, originalContent) {
    if (!element) return;
    element.innerHTML = originalContent;
    element.disabled = false;
}

function validateForm(formId) {
    const form = document.getElementById(formId);
    if (!form) return false;
    
    const requiredFields = form.querySelectorAll('[required]');
    let isValid = true;
    
    requiredFields.forEach(field => {
        if (!field.value.trim()) {
            field.classList.add('is-invalid');
            isValid = false;
        } else {
            field.classList.remove('is-invalid');
        }
    });
    
    return isValid;
}

function addFadeInAnimation() {
    const cards = document.querySelectorAll('.card');
    cards.forEach((card, index) => {
        setTimeout(() => {
            card.classList.add('fade-in');
        }, index * 100);
    });
}

// Chart.js helper functions
function createChart(canvasId, data, type = 'line') {
    const ctx = document.getElementById(canvasId);
    if (!ctx) return null;
    
    return new Chart(ctx, {
        type: type,
        data: data,
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    position: 'top',
                }
            }
        }
    });
}

// Format date/time
function formatDateTime(dateString) {
    const date = new Date(dateString);
    return date.toLocaleString();
}

// Format duration
function formatDuration(seconds) {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;
    
    if (hours > 0) {
        return `${hours}h ${minutes}m ${secs}s`;
    } else if (minutes > 0) {
        return `${minutes}m ${secs}s`;
    } else {
        return `${secs}s`;
    }
}

// Format file size
function formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes';
    
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}
