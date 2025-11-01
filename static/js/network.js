/**
 * Network functionality for live sessions
 */

// Socket initialization with automatic reconnection
function initializeSocket(url, options = {}) {
    const socket = io(url, {
        reconnection: true,
        reconnectionAttempts: 10,
        reconnectionDelay: 1000,
        reconnectionDelayMax: 5000,
        timeout: 20000,
        ...options
    });
    
    // Setup reconnection with exponential backoff
    let reconnectAttempts = 0;
    const maxReconnectAttempts = 10;
    let reconnectDelay = 1000;
    
    socket.on('disconnect', function() {
        updateNetworkStatus('Offline');
        document.getElementById('connection-error').classList.remove('hidden');
        
        // Attempt to reconnect
        attemptReconnect();
    });
    
    socket.on('connect', function() {
        reconnectAttempts = 0;
        reconnectDelay = 1000;
        updateNetworkStatus('Good');
        document.getElementById('connection-error').classList.add('hidden');
    });
    
    function attemptReconnect() {
        if (reconnectAttempts >= maxReconnectAttempts) {
            console.error('Maximum reconnection attempts reached');
            return;
        }
        
        reconnectAttempts++;
        
        // Exponential backoff
        const delay = Math.min(reconnectDelay * Math.pow(1.5, reconnectAttempts - 1), 30000);
        
        setTimeout(function() {
            if (socket.connected) return;
            
            console.log(`Attempting to reconnect (${reconnectAttempts}/${maxReconnectAttempts})...`);
            socket.connect();
        }, delay);
    }
    
    // Start heartbeat to detect connection issues early
    startHeartbeat(socket);
    
    return socket;
}

// Heartbeat to detect connection issues
function startHeartbeat(socket, interval = 5000) {
    let heartbeatInterval;
    let missedHeartbeats = 0;
    const maxMissedHeartbeats = 3;
    
    function sendHeartbeat() {
        if (socket.connected) {
            socket.emit('heartbeat');
            missedHeartbeats++;
            
            // If server doesn't respond after max missed heartbeats, consider connection lost
            if (missedHeartbeats > maxMissedHeartbeats) {
                updateNetworkStatus('Poor');
                
                if (missedHeartbeats > maxMissedHeartbeats * 2) {
                    // Force reconnection if too many heartbeats missed
                    socket.disconnect();
                    socket.connect();
                }
            }
        }
    }
    
    socket.on('heartbeat-ack', function() {
        missedHeartbeats = 0;
        updateNetworkStatus('Good');
    });
    
    // Start sending heartbeats
    heartbeatInterval = setInterval(sendHeartbeat, interval);
    
    // Clean up on disconnect
    socket.on('disconnect', function() {
        clearInterval(heartbeatInterval);
    });
    
    // Restart on reconnect
    socket.on('connect', function() {
        clearInterval(heartbeatInterval);
        missedHeartbeats = 0;
        heartbeatInterval = setInterval(sendHeartbeat, interval);
    });
}

// Network bandwidth monitoring
function startBandwidthMonitoring(updateInterval = 30000) {
    const networkStatus = document.getElementById('network-status');
    if (!networkStatus) return;
    
    // Set default status to Good
    updateNetworkStatus('Good');
    
    // Check network conditions periodically
    setInterval(function() {
        checkNetworkConditions();
    }, updateInterval);
    
    // Initial check
    checkNetworkConditions();
}

// Check network conditions and update UI
function checkNetworkConditions() {
    // Use Navigator.connection API if available
    if (navigator.connection) {
        const connection = navigator.connection;
        
        if (connection.downlink < 0.5) {
            updateNetworkStatus('Poor');
            switchToLowBandwidthMode();
        } else if (connection.downlink < 1.5) {
            updateNetworkStatus('Fair');
        } else {
            updateNetworkStatus('Good');
        }
        
        // Check for effective connection type
        if (connection.effectiveType === '2g' || connection.effectiveType === 'slow-2g') {
            updateNetworkStatus('Poor');
            switchToLowBandwidthMode();
        }
    } else {
        // Fallback: measure response time to server
        measureServerResponseTime();
    }
}

// Measure server response time as a proxy for network quality
function measureServerResponseTime() {
    const start = Date.now();
    
    fetch('/api/ping', { method: 'GET', cache: 'no-cache' })
        .then(response => response.json())
        .then(data => {
            const duration = Date.now() - start;
            
            if (duration > 1000) {
                updateNetworkStatus('Poor');
                switchToLowBandwidthMode();
            } else if (duration > 300) {
                updateNetworkStatus('Fair');
            } else {
                updateNetworkStatus('Good');
            }
        })
        .catch(error => {
            console.error('Error measuring network response time:', error);
            updateNetworkStatus('Offline');
        });
}

// Update network status in UI
function updateNetworkStatus(status) {
    const networkStatus = document.getElementById('network-status');
    if (!networkStatus) return;
    
    // Remove all status classes
    networkStatus.classList.remove('status-good', 'status-fair', 'status-poor', 'status-offline');
    
    // Update text and add appropriate class
    networkStatus.textContent = status;
    
    switch (status) {
        case 'Good':
            networkStatus.classList.add('status-good');
            break;
        case 'Fair':
            networkStatus.classList.add('status-fair');
            break;
        case 'Poor':
            networkStatus.classList.add('status-poor');
            break;
        case 'Offline':
            networkStatus.classList.add('status-offline');
            break;
    }
}

// Switch to low bandwidth mode
function switchToLowBandwidthMode() {
    // Disable video if available
    const videoElements = document.querySelectorAll('video:not(.active-speaker)');
    videoElements.forEach(video => {
        if (!video.paused) {
            video.pause();
            video.dataset.pausedForBandwidth = 'true';
        }
    });
    
    // Show low bandwidth mode notification
    const notification = document.getElementById('low-bandwidth-notification');
    if (notification) {
        notification.classList.remove('hidden');
        
        // Hide after 5 seconds
        setTimeout(() => {
            notification.classList.add('hidden');
        }, 5000);
    }
    
    // Emit event to server to request lower quality streams
    if (window.socket) {
        window.socket.emit('request_low_bandwidth_mode');
    }
}

// Update participants list
function updateParticipantsList(participants) {
    const participantsList = document.getElementById('participants-list');
    if (!participantsList) return;
    
    // Clear current list
    participantsList.innerHTML = '';
    
    // If no participants, add current user and teacher as defaults
    if (!participants || participants.length === 0) {
        const currentUser = {
            id: 'current-user',
            name: 'You',
            role: 'student',
            status: 'online'
        };
        
        const teacher = {
            id: 'teacher',
            name: 'Teacher',
            role: 'teacher',
            status: 'online'
        };
        
        participants = [currentUser, teacher];
    }
    
    // Add each participant to the list
    participants.forEach(participant => {
        const participantItem = document.createElement('div');
        participantItem.className = `participant-item ${participant.status} ${participant.role}`;
        participantItem.dataset.id = participant.id;
        
        const nameSpan = document.createElement('span');
        nameSpan.className = 'participant-name';
        nameSpan.textContent = participant.name;
        
        const statusIndicator = document.createElement('span');
        statusIndicator.className = `status-indicator ${participant.status}`;
        
        participantItem.appendChild(statusIndicator);
        participantItem.appendChild(nameSpan);
        
        participantsList.appendChild(participantItem);
    });
}