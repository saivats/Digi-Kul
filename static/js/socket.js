/**
 * Socket connection handling with automatic reconnection
 */

// Initialize socket connection with session ID
function initializeSessionSocket(sessionId, role) {
    const socket = io({
        reconnection: true,
        reconnectionAttempts: 10,
        reconnectionDelay: 1000,
        reconnectionDelayMax: 5000,
        timeout: 20000
    });
    
    // Join the session room
    socket.on('connect', function() {
        console.log('Socket connected, joining session:', sessionId);
        socket.emit('join_session', {
            session_id: sessionId,
            role: role
        });
        
        // Update UI to show connected status
        updateNetworkStatus('Good');
        hideConnectionError();
    });
    
    // Handle successful join
    socket.on('join_success', function(data) {
        console.log('Successfully joined session:', data);
        
        // Update participants list
        if (data.participants) {
            updateParticipantsList(data.participants);
        }
        
        // Show success notification
        showNotification('Connected to session successfully', 'success');
    });
    
    // Handle join error
    socket.on('join_error', function(data) {
        console.error('Error joining session:', data);
        showNotification('Failed to join session: ' + data.message, 'error');
    });
    
    // Handle disconnect
    socket.on('disconnect', function() {
        console.log('Socket disconnected');
        updateNetworkStatus('Offline');
        showConnectionError();
        
        // Attempt to reconnect with exponential backoff
        attemptReconnect(socket, sessionId, role);
    });
    
    // Start heartbeat to detect connection issues early
    startHeartbeat(socket);
    
    // Start bandwidth monitoring
    startBandwidthMonitoring();
    
    return socket;
}

// Attempt to reconnect with exponential backoff
function attemptReconnect(socket, sessionId, role, attempt = 0) {
    const maxAttempts = 10;
    const baseDelay = 1000;
    
    if (attempt >= maxAttempts) {
        console.error('Maximum reconnection attempts reached');
        showNotification('Unable to reconnect after multiple attempts. Please refresh the page.', 'error');
        return;
    }
    
    // Calculate delay with exponential backoff
    const delay = Math.min(baseDelay * Math.pow(1.5, attempt), 30000);
    
    console.log(`Attempting to reconnect in ${delay}ms (attempt ${attempt + 1}/${maxAttempts})...`);
    showNotification(`Reconnecting in ${Math.round(delay/1000)}s... (${attempt + 1}/${maxAttempts})`, 'warning');
    
    setTimeout(function() {
        if (socket.connected) return;
        
        console.log(`Reconnecting (attempt ${attempt + 1}/${maxAttempts})...`);
        socket.connect();
        
        // If connection fails, try again
        setTimeout(function() {
            if (!socket.connected) {
                attemptReconnect(socket, sessionId, role, attempt + 1);
            }
        }, 1000);
    }, delay);
}

// Show connection error message
function showConnectionError() {
    const errorElement = document.getElementById('connection-error');
    if (errorElement) {
        errorElement.classList.remove('hidden');
    }
}

// Hide connection error message
function hideConnectionError() {
    const errorElement = document.getElementById('connection-error');
    if (errorElement) {
        errorElement.classList.add('hidden');
    }
}

// Show notification
function showNotification(message, type = 'info') {
    // Create notification element if it doesn't exist
    let notification = document.getElementById('notification');
    if (!notification) {
        notification = document.createElement('div');
        notification.id = 'notification';
        notification.className = 'notification hidden';
        document.body.appendChild(notification);
    }
    
    // Set notification content and type
    notification.textContent = message;
    notification.className = `notification notification-${type}`;
    
    // Show notification
    notification.classList.remove('hidden');
    
    // Hide after 5 seconds
    setTimeout(function() {
        notification.classList.add('hidden');
    }, 5000);
}