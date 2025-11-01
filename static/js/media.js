/**
 * Media handling with adaptive bitrate and optimization
 */

// Initialize media with adaptive bitrate
async function initializeMedia(videoElement, audioOnly = false) {
    try {
        // Get user media with appropriate constraints
        const constraints = getMediaConstraints(audioOnly);
        const stream = await navigator.mediaDevices.getUserMedia(constraints);
        
        // Apply stream to video element if provided
        if (videoElement) {
            videoElement.srcObject = stream;
        }
        
        // Apply audio processing if available
        applyAudioProcessing(stream);
        
        return stream;
    } catch (error) {
        console.error('Error accessing media devices:', error);
        showNotification('Failed to access camera/microphone: ' + error.message, 'error');
        return null;
    }
}

// Get appropriate media constraints based on network conditions
function getMediaConstraints(audioOnly = false) {
    // Check if we should use low bandwidth mode
    const useLowBandwidth = shouldUseLowBandwidth();
    
    // Audio constraints with Opus codec preferred
    const audioConstraints = {
        echoCancellation: true,
        noiseSuppression: true,
        autoGainControl: true
    };
    
    // Return audio-only constraints if requested or in very low bandwidth
    if (audioOnly || useLowBandwidth === 'very-low') {
        return {
            audio: audioConstraints,
            video: false
        };
    }
    
    // Video constraints based on bandwidth availability
    let videoConstraints = {};
    
    if (useLowBandwidth === 'low') {
        // Low bandwidth: 320x240 @ 15fps
        videoConstraints = {
            width: { ideal: 320 },
            height: { ideal: 240 },
            frameRate: { max: 15 }
        };
    } else {
        // Normal bandwidth: 640x480 @ 30fps
        videoConstraints = {
            width: { ideal: 640 },
            height: { ideal: 480 },
            frameRate: { max: 30 }
        };
    }
    
    return {
        audio: audioConstraints,
        video: videoConstraints
    };
}

// Check if we should use low bandwidth mode
function shouldUseLowBandwidth() {
    // Use Navigator.connection API if available
    if (navigator.connection) {
        const connection = navigator.connection;
        
        if (connection.downlink < 0.15) {
            return 'very-low'; // Below 150 Kbps - audio only
        } else if (connection.downlink < 0.5) {
            return 'low'; // Below 500 Kbps - low quality video
        }
        
        // Check for effective connection type
        if (connection.effectiveType === '2g' || connection.effectiveType === 'slow-2g') {
            return 'very-low';
        } else if (connection.effectiveType === '3g') {
            return 'low';
        }
    }
    
    return 'normal';
}

// Apply audio processing to stream
function applyAudioProcessing(stream) {
    const audioTracks = stream.getAudioTracks();
    
    if (audioTracks.length > 0) {
        // Apply constraints to audio track for better quality
        const track = audioTracks[0];
        
        if (track.applyConstraints) {
            track.applyConstraints({
                echoCancellation: true,
                noiseSuppression: true,
                autoGainControl: true
            });
        }
    }
}

// Optimize video rendering for inactive participants
function optimizeVideoRendering(videoElements) {
    // Pause inactive video elements
    videoElements.forEach(video => {
        if (!isInViewport(video) && !video.classList.contains('active-speaker')) {
            if (!video.paused) {
                video.pause();
                video.dataset.pausedForOptimization = 'true';
            }
        } else if (video.dataset.pausedForOptimization === 'true') {
            video.play();
            delete video.dataset.pausedForOptimization;
        }
    });
}

// Check if element is in viewport
function isInViewport(element) {
    const rect = element.getBoundingClientRect();
    return (
        rect.top >= 0 &&
        rect.left >= 0 &&
        rect.bottom <= (window.innerHeight || document.documentElement.clientHeight) &&
        rect.right <= (window.innerWidth || document.documentElement.clientWidth)
    );
}

// Monitor session quality
function monitorSessionQuality(peerConnection) {
    if (!peerConnection) return;
    
    // Get stats every 5 seconds
    setInterval(async () => {
        try {
            const stats = await peerConnection.getStats();
            const qualityMetrics = {
                jitter: 0,
                packetsLost: 0,
                roundTripTime: 0,
                bandwidth: 0
            };
            
            stats.forEach(report => {
                if (report.type === 'inbound-rtp' && report.kind === 'video') {
                    qualityMetrics.jitter = report.jitter;
                    qualityMetrics.packetsLost = report.packetsLost;
                } else if (report.type === 'remote-inbound-rtp') {
                    qualityMetrics.roundTripTime = report.roundTripTime;
                } else if (report.type === 'candidate-pair' && report.state === 'succeeded') {
                    qualityMetrics.bandwidth = report.availableOutgoingBitrate;
                }
            });
            
            // Adjust video quality based on metrics
            adjustVideoQualityBasedOnMetrics(qualityMetrics);
            
        } catch (error) {
            console.error('Error getting WebRTC stats:', error);
        }
    }, 5000);
}

// Adjust video quality based on metrics
function adjustVideoQualityBasedOnMetrics(metrics) {
    // Log quality metrics
    console.log('Session quality metrics:', metrics);
    
    // Update quality indicator in UI
    updateQualityIndicator(metrics);
    
    // Adjust video quality if needed
    if (metrics.packetsLost > 50 || metrics.jitter > 0.1 || metrics.roundTripTime > 0.5) {
        // Poor connection - switch to low quality
        switchToLowBandwidthMode();
    } else if (metrics.bandwidth < 150000) {
        // Very low bandwidth - switch to audio only
        switchToAudioOnlyMode();
    }
}

// Update quality indicator in UI
function updateQualityIndicator(metrics) {
    const qualityIndicator = document.getElementById('quality-indicator');
    if (!qualityIndicator) return;
    
    // Calculate overall quality score (0-100)
    let qualityScore = 100;
    
    if (metrics.packetsLost > 0) {
        qualityScore -= Math.min(50, metrics.packetsLost / 2);
    }
    
    if (metrics.jitter > 0) {
        qualityScore -= Math.min(25, metrics.jitter * 250);
    }
    
    if (metrics.roundTripTime > 0) {
        qualityScore -= Math.min(25, metrics.roundTripTime * 50);
    }
    
    // Update indicator
    qualityIndicator.textContent = Math.round(qualityScore) + '%';
    
    // Update class based on score
    qualityIndicator.className = 'quality-indicator';
    if (qualityScore < 40) {
        qualityIndicator.classList.add('poor');
    } else if (qualityScore < 70) {
        qualityIndicator.classList.add('fair');
    } else {
        qualityIndicator.classList.add('good');
    }
}