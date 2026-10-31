// Protocol wrapper for Tauri backend communication
// Integrates with central EventBus for server message handling
// Supports both Tauri invoke (desktop) and WebSocket (web/browser testing)

import { EventBus } from './EventBus.js';

// Check if we're running in Tauri environment
const isTauri = typeof window !== 'undefined' && window.__TAURI_INJECTED__;

export const protocol = {
    // Connection state
    connected: false,
    host: 'localhost',
    port: 5555,
    ws: null, // WebSocket instance for web mode
    mockMode: false, // Simulate connection for testing
    
    // Event listeners
    listeners: new Map(),
    messageListener: null,
    
    /**
     * Connect to the game server
     */
    async connect(host = 'localhost', port = 5555) {
        this.host = host;
        this.port = port;
        
        if (isTauri) {
            // Use Tauri invoke for desktop app
            return this.connectTauri(host, port);
        } else {
            // Try WebSocket first, fall back to mock mode for testing
            try {
                const result = await this.connectWebSocket(host, port, true);
                return result;
            } catch (e) {
                console.warn('[Protocol] WebSocket connection failed, using mock mode:', e.message);
                return this.connectMock();
            }
        }
    },
    
    /**
     * Connect via Tauri invoke (desktop mode)
     */
    async connectTauri(host, port) {
        try {
            const { invoke } = await import('@tauri-apps/api/core');
            const result = await invoke('connect_server', { host, port });
            this.connected = true;
            this.setupTauriMessageListener();
            return { success: true, message: result };
        } catch (e) {
            this.connected = false;
            return { success: false, message: e.toString() };
        }
    },
    
    /**
     * Connect via WebSocket (web/browser testing mode)
     */
    async connectWebSocket(host, port, allowFallback = false) {
        return new Promise((resolve) => {
            try {
                const wsUrl = `ws://${host}:${port}`;
                this.ws = new WebSocket(wsUrl);
                
                const timeout = setTimeout(() => {
                    if (this.ws && this.ws.readyState !== WebSocket.OPEN) {
                        this.ws.onerror = null;
                        this.ws.close();
                        this.ws = null;
                        if (allowFallback) {
                            this.mockMode = true;
                            resolve({ success: true, message: 'Connected (mock mode)', mock: true });
                        } else {
                            resolve({ success: false, message: 'WebSocket connection timeout' });
                        }
                    }
                }, 3000);
                
                this.ws.onopen = () => {
                    clearTimeout(timeout);
                    this.connected = true;
                    this.mockMode = false;
                    console.log(`[Protocol] WebSocket connected to ${wsUrl}`);
                    resolve({ success: true, message: `Connected to ${wsUrl}`, mock: false });
                };
                
                this.ws.onmessage = (event) => {
                    // Parse the message - expected format: JSON with opcode
                    try {
                        const data = JSON.parse(event.data);
                        const message = {
                            direction: data.direction || 'ServerPush',
                            opcode: data.opcode,
                            opcode_str: data.opcode || 'raw',
                            raw_payload: new TextEncoder().encode(event.data),
                            payload: data.payload || null
                        };
                        EventBus.handleServerMessage(message);
                        this.emit('message', message);
                    } catch (e) {
                        console.warn('[Protocol] Could not parse WebSocket message as JSON:', event.data);
                        // Raw message for unknown formats
                        const message = {
                            direction: 'ServerPush',
                            opcode: 'raw',
                            opcode_str: 'raw',
                            raw_payload: new TextEncoder().encode(event.data)
                        };
                        EventBus.handleServerMessage(message);
                        this.emit('message', message);
                    }
                };
                
                this.ws.onclose = () => {
                    clearTimeout(timeout);
                    this.connected = false;
                    console.log('[Protocol] WebSocket disconnected');
                };
                
                this.ws.onerror = (error) => {
                    clearTimeout(timeout);
                    console.error('[Protocol] WebSocket error:', error);
                    this.connected = false;
                    if (!allowFallback) {
                        resolve({ success: false, message: 'WebSocket connection failed' });
                    }
                };
                
            } catch (e) {
                this.connected = false;
                if (allowFallback) {
                    this.mockMode = true;
                    resolve({ success: true, message: 'Connected (mock mode)', mock: true });
                } else {
                    resolve({ success: false, message: e.toString() });
                }
            }
        });
    },
    
    /**
     * Connect in mock mode (simulated server for testing)
     */
    async connectMock() {
        this.connected = true;
        this.mockMode = true;
        console.log('[Protocol] Mock connection established');
        
        // Send mock welcome message
        const mockMessage = {
            direction: 'ServerPush',
            opcode: 'hello',
            opcode_str: 'hello',
            raw_payload: new TextEncoder().encode(JSON.stringify({ opcode: 'hello', message: 'Mock hello' }))
        };
        EventBus.handleServerMessage(mockMessage);
        this.emit('message', mockMessage);
        
        return { success: true, message: 'Mock connection established', mock: true };
    },
    
    /**
     * Disconnect from the game server
     */
    async disconnect() {
        if (isTauri) {
            return this.disconnectTauri();
        } else {
            return this.disconnectWebSocket();
        }
    },
    
    /**
     * Disconnect via Tauri (desktop mode)
     */
    async disconnectTauri() {
        // Clean up message listener
        if (this.messageListener) {
            this.messageListener();
            this.messageListener = null;
        }
        
        // Clear EventBus server handlers
        EventBus.serverHandlers.clear();
        
        try {
            const { invoke } = await import('@tauri-apps/api/core');
            const result = await invoke('disconnect_server');
            this.connected = false;
            this.mockMode = false;
            return { success: true, message: result };
        } catch (e) {
            return { success: false, message: e.toString() };
        }
    },
    
    /**
     * Disconnect via WebSocket (web mode)
     */
    disconnectWebSocket() {
        if (this.ws) {
            this.ws.close();
            this.ws = null;
        }
        this.connected = false;
        this.mockMode = false;
        EventBus.serverHandlers.clear();
        return { success: true, message: 'Disconnected' };
    },
    
    /**
     * Get current connection status
     */
    async getStatus() {
        if (isTauri) {
            try {
                const { invoke } = await import('@tauri-apps/api/core');
                const status = await invoke('get_server_status');
                this.connected = status !== 'Disconnected';
                return { success: true, message: status, connected: this.connected };
            } catch (e) {
                return { success: false, message: e.toString(), connected: false };
            }
        } else {
            return { success: true, message: this.connected ? 'Connected' : 'Disconnected', connected: this.connected, mock: this.mockMode };
        }
    },
    
    /**
     * Send a message to the server
     */
    async sendMessage(opcode, payloadHex = '') {
        if (!this.connected) {
            return { success: false, message: 'Not connected' };
        }
        
        if (this.mockMode) {
            // In mock mode, simulate message sent and emit response
            this.sendMockResponse(opcode);
            return { success: true, message: 'Mock message sent' };
        }
        
        if (isTauri) {
            return this.sendMessageTauri(opcode, payloadHex);
        } else {
            return this.sendMessageWebSocket(opcode, payloadHex);
        }
    },
    
    /**
     * Send a mock response for testing
     */
    sendMockResponse(opcode) {
        let mockMessage = null;
        
        switch (opcode) {
            case 'charactersList':
                mockMessage = {
                    direction: 'ServerReply',
                    opcode: 'charactersList',
                    opcode_str: 'charactersList',
                    raw_payload: new TextEncoder().encode(JSON.stringify({ 
                        characters: [
                            { name: 'Aldric', class: 'Sadida', level: 15, breed: 10, sprite: 1, sex: 1 },
                            { name: 'Yuki', class: 'Xelor', level: 12, breed: 5, sprite: 2, sex: 2 }
                        ]
                    }))
                };
                break;
            case 'ankamaFriendsList':
                mockMessage = {
                    direction: 'ServerPush',
                    opcode: 'ankamaFriendsList',
                    opcode_str: 'ankamaFriendsList',
                    raw_payload: new TextEncoder().encode(JSON.stringify({ 
                        friends: [
                            { name: 'PlayerOne', status: 'online', level: 45 },
                            { name: 'PlayerTwo', status: 'offline', level: 32 }
                        ]
                    }))
                };
                break;
            default:
                mockMessage = {
                    direction: 'ServerReply',
                    opcode: opcode,
                    opcode_str: opcode,
                    raw_payload: new TextEncoder().encode(JSON.stringify({ result: 'ok' }))
                };
        }
        
        if (mockMessage) {
            setTimeout(() => {
                EventBus.handleServerMessage(mockMessage);
                this.emit('message', mockMessage);
            }, 100);
        }
    },
    
    /**
     * Send message via Tauri (desktop mode)
     */
    async sendMessageTauri(opcode, payloadHex) {
        try {
            const { invoke } = await import('@tauri-apps/api/core');
            const result = await invoke('send_message', { opcode, payloadHex });
            return { success: true, message: result };
        } catch (e) {
            return { success: false, message: e.toString() };
        }
    },
    
    /**
     * Send message via WebSocket (web mode)
     */
    sendMessageWebSocket(opcode, payloadHex) {
        if (!this.ws || this.ws.readyState !== WebSocket.OPEN) {
            return { success: false, message: 'WebSocket not open' };
        }
        
        try {
            const message = { opcode, payload: payloadHex };
            this.ws.send(JSON.stringify(message));
            return { success: true, message: 'Sent' };
        } catch (e) {
            return { success: false, message: e.toString() };
        }
    },
    
    /**
     * Send a raw hex message (for protocol testing)
     */
    async sendRaw(hexString) {
        return this.sendMessage('raw', hexString);
    },
    
    /**
     * Set up listener for server messages - Tauri mode
     */
    async setupTauriMessageListener() {
        if (this.messageListener) return;
        
        try {
            const { listen } = await import('@tauri-apps/api/event');
            // Tauri v2 listen returns a promise that resolves to an unsubscribe function
            const unsubscribe = await listen('server-message', (event) => {
                // Route through EventBus for centralized handling
                EventBus.handleServerMessage(event.payload);
                // Also emit to local listeners for backward compatibility
                this.emit('message', event.payload);
            });
            this.messageListener = unsubscribe;
        } catch (e) {
            console.warn('[Protocol] Could not setup Tauri listener:', e);
        }
    },
    
    // Legacy event emitter methods (for backward compatibility)
    on(event, callback) {
        if (!this.listeners.has(event)) {
            this.listeners.set(event, new Set());
        }
        this.listeners.get(event).add(callback);
    },
    
    off(event, callback) {
        if (this.listeners.has(event)) {
            this.listeners.get(event).delete(callback);
        }
    },
    
    emit(event, data) {
        if (this.listeners.has(event)) {
            this.listeners.get(event).forEach(cb => cb(data));
        }
    }
};

export default protocol;