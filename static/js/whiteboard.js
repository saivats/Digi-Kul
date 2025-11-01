/**
 * Whiteboard functionality for live sessions
 */

// Point normalization for consistent drawing across different screen sizes
function normalizePoint(x, y, canvas) {
    return {
        x: x / canvas.width,
        y: y / canvas.height
    };
}

// Point denormalization to convert normalized coordinates back to screen coordinates
function denormalizePoint(point, canvas) {
    return {
        x: point.x * canvas.width,
        y: point.y * canvas.height
    };
}

// Canvas resize handler to maintain drawing proportions
function attachCanvasResizeHandler(canvas, context, drawHistory) {
    let resizeTimeout;
    
    window.addEventListener('resize', function() {
        clearTimeout(resizeTimeout);
        resizeTimeout = setTimeout(function() {
            // Save current dimensions and content
            const tempCanvas = document.createElement('canvas');
            const tempContext = tempCanvas.getContext('2d');
            tempCanvas.width = canvas.width;
            tempCanvas.height = canvas.height;
            tempContext.drawImage(canvas, 0, 0);
            
            // Resize canvas to fit container
            const container = canvas.parentElement;
            canvas.width = container.clientWidth;
            canvas.height = container.clientHeight;
            
            // Clear and redraw content
            context.clearRect(0, 0, canvas.width, canvas.height);
            context.drawImage(tempCanvas, 0, 0, tempCanvas.width, tempCanvas.height, 
                             0, 0, canvas.width, canvas.height);
            
            // Redraw from history if available
            if (drawHistory && drawHistory.length > 0) {
                redrawFromHistory(drawHistory, canvas, context);
            }
        }, 200);
    });
}

// Redraw canvas from history
function redrawFromHistory(history, canvas, context) {
    context.clearRect(0, 0, canvas.width, canvas.height);
    
    history.forEach(function(item) {
        if (item.type === 'path') {
            drawPath(item.points, item.color, item.width, canvas, context);
        } else if (item.type === 'clear') {
            // Skip as we've already cleared
        }
    });
}

// Draw a path from points
function drawPath(points, color, width, canvas, context) {
    if (points.length < 2) return;
    
    context.beginPath();
    context.strokeStyle = color;
    context.lineWidth = width;
    context.lineCap = 'round';
    context.lineJoin = 'round';
    
    const start = denormalizePoint(points[0], canvas);
    context.moveTo(start.x, start.y);
    
    for (let i = 1; i < points.length; i++) {
        const point = denormalizePoint(points[i], canvas);
        context.lineTo(point.x, point.y);
    }
    
    context.stroke();
}

// Initialize whiteboard for student view
function initializeStudentWhiteboard(canvas, socket) {
    const context = canvas.getContext('2d');
    const drawHistory = [];
    
    // Set initial canvas size
    const container = canvas.parentElement;
    canvas.width = container.clientWidth;
    canvas.height = container.clientHeight;
    
    // Attach resize handler
    attachCanvasResizeHandler(canvas, context, drawHistory);
    
    // Listen for drawing events from teacher
    socket.on('draw_update', function(data) {
        if (data.type === 'path') {
            drawPath(data.points, data.color, data.width, canvas, context);
            drawHistory.push(data);
        } else if (data.type === 'clear') {
            context.clearRect(0, 0, canvas.width, canvas.height);
            drawHistory.length = 0;
            drawHistory.push(data);
        }
    });
    
    return {
        canvas: canvas,
        context: context,
        drawHistory: drawHistory
    };
}

// Initialize whiteboard for teacher view with drawing capabilities
function initializeTeacherWhiteboard(canvas, socket) {
    const context = canvas.getContext('2d');
    const drawHistory = [];
    let isDrawing = false;
    let currentPath = null;
    let currentColor = '#000000';
    let currentWidth = 2;
    
    // Set initial canvas size
    const container = canvas.parentElement;
    canvas.width = container.clientWidth;
    canvas.height = container.clientHeight;
    
    // Attach resize handler
    attachCanvasResizeHandler(canvas, context, drawHistory);
    
    // Mouse event handlers
    canvas.addEventListener('mousedown', startDrawing);
    canvas.addEventListener('mousemove', draw);
    canvas.addEventListener('mouseup', stopDrawing);
    canvas.addEventListener('mouseleave', stopDrawing);
    
    // Touch event handlers
    canvas.addEventListener('touchstart', handleTouchStart);
    canvas.addEventListener('touchmove', handleTouchMove);
    canvas.addEventListener('touchend', handleTouchEnd);
    
    function handleTouchStart(e) {
        e.preventDefault();
        const touch = e.touches[0];
        const mouseEvent = new MouseEvent('mousedown', {
            clientX: touch.clientX,
            clientY: touch.clientY
        });
        canvas.dispatchEvent(mouseEvent);
    }
    
    function handleTouchMove(e) {
        e.preventDefault();
        const touch = e.touches[0];
        const mouseEvent = new MouseEvent('mousemove', {
            clientX: touch.clientX,
            clientY: touch.clientY
        });
        canvas.dispatchEvent(mouseEvent);
    }
    
    function handleTouchEnd(e) {
        e.preventDefault();
        const mouseEvent = new MouseEvent('mouseup', {});
        canvas.dispatchEvent(mouseEvent);
    }
    
    function startDrawing(e) {
        isDrawing = true;
        const rect = canvas.getBoundingClientRect();
        const x = e.clientX - rect.left;
        const y = e.clientY - rect.top;
        
        currentPath = {
            type: 'path',
            points: [normalizePoint(x, y, canvas)],
            color: currentColor,
            width: currentWidth
        };
        
        context.beginPath();
        context.strokeStyle = currentColor;
        context.lineWidth = currentWidth;
        context.lineCap = 'round';
        context.lineJoin = 'round';
        context.moveTo(x, y);
    }
    
    function draw(e) {
        if (!isDrawing) return;
        
        const rect = canvas.getBoundingClientRect();
        const x = e.clientX - rect.left;
        const y = e.clientY - rect.top;
        
        currentPath.points.push(normalizePoint(x, y, canvas));
        
        context.lineTo(x, y);
        context.stroke();
    }
    
    function stopDrawing() {
        if (!isDrawing) return;
        isDrawing = false;
        
        if (currentPath && currentPath.points.length > 0) {
            drawHistory.push(currentPath);
            socket.emit('draw_update', currentPath);
            currentPath = null;
        }
    }
    
    function clearWhiteboard() {
        context.clearRect(0, 0, canvas.width, canvas.height);
        drawHistory.length = 0;
        
        const clearEvent = { type: 'clear' };
        drawHistory.push(clearEvent);
        socket.emit('draw_update', clearEvent);
    }
    
    function setColor(color) {
        currentColor = color;
    }
    
    function setLineWidth(width) {
        currentWidth = width;
    }
    
    return {
        canvas: canvas,
        context: context,
        drawHistory: drawHistory,
        clearWhiteboard: clearWhiteboard,
        setColor: setColor,
        setLineWidth: setLineWidth
    };
}