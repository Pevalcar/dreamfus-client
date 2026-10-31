// EventBus - Centralized event system for server messages and UI events
// Allows all screens to react to server push messages without tight coupling

export const EventBus = {
    // Event listeners registry
    listeners: new Map(),
    
    // Server message handlers registry
    serverHandlers: new Map(),
    
    /**
     * Subscribe to global events
     * @param {string} event - Event name
     * @param {Function} callback - Event handler
     * @returns {Function} Unsubscribe function
     */
    on(event, callback) {
        if (!this.listeners.has(event)) {
            this.listeners.set(event, new Set());
        }
        this.listeners.get(event).add(callback);
        
        // Return unsubscribe function
        return () => this.off(event, callback);
    },
    
    /**
     * Unsubscribe from global events
     */
    off(event, callback) {
        if (this.listeners.has(event)) {
            this.listeners.get(event).delete(callback);
        }
    },
    
    /**
     * Emit a global event
     */
    emit(event, data) {
        if (this.listeners.has(event)) {
            this.listeners.get(event).forEach(cb => cb(data));
        }
    },
    
    /**
     * Register a server message handler for a specific opcode
     * @param {string} opcode - Server opcode (e.g., 'hello', 'knx', 'kuf')
     * @param {Function} handler - Handler function
     */
    onServerMessage(opcode, handler) {
        if (!this.serverHandlers.has(opcode)) {
            this.serverHandlers.set(opcode, new Set());
        }
        this.serverHandlers.get(opcode).add(handler);
    },
    
    /**
     * Unregister a server message handler
     */
    offServerMessage(opcode, handler) {
        if (this.serverHandlers.has(opcode)) {
            this.serverHandlers.get(opcode).delete(handler);
        }
    },
    
    /**
     * Handle incoming server message and dispatch to appropriate handlers
     * @param {Object} message - ServerMessage from Tauri backend
     */
    handleServerMessage(message) {
        // Emit to all global listeners
        this.emit('server-message', message);
        
        // Dispatch to opcode-specific handlers
        if (message.opcode_str && this.serverHandlers.has(message.opcode_str)) {
            this.serverHandlers.get(message.opcode_str).forEach(handler => {
                try {
                    handler(message);
                } catch (e) {
                    console.error(`[EventBus] Error in ${message.opcode_str} handler:`, e);
                }
            });
        }
        
        // Also emit with opcode as event name for backward compatibility
        if (message.opcode_str) {
            this.emit(message.opcode_str, message);
        }
    },
    
    /**
     * Clear all listeners (useful for debugging or screen transitions)
     */
    clear() {
        this.listeners.clear();
        this.serverHandlers.clear();
    }
};

// Singleton instance
export default EventBus;