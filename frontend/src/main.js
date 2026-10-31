// DreamFus Client - Main Entry Point
// This file initializes the application and loads the DFUI system
// Auto-connects to Jondo server at localhost:5555 with default credentials

import { dfui } from './dfui/index.js';
import { protocol } from './protocol.js';
import { uiManager } from './ui/UIManager.js';
import { EventBus } from './EventBus.js';

// Default server configuration
const DEFAULT_HOST = 'localhost';
const DEFAULT_PORT = 5555;
const DEFAULT_USERNAME = 'keka';
const DEFAULT_PASSWORD = 'test';

/**
 * Send the mock login flow for browser testing
 * Simulates: connection established -> auth -> characters list
 */
function sendMockLoginFlow() {
    // Simulate welcome message from server
    const welcomeMsg = {
        direction: 'ServerPush',
        opcode: 'hello',
        opcode_str: 'hello',
        raw_payload: new TextEncoder().encode(JSON.stringify({ 
            opcode: 'hello', 
            message: 'Welcome, ' + DEFAULT_USERNAME,
            sessionId: 'mock-session-12345'
        }))
    };
    EventBus.handleServerMessage(welcomeMsg);
    
    // Simulate character list with Jondo server classes
    const charactersListMsg = {
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
    EventBus.handleServerMessage(charactersListMsg);
}

/**
 * Auto-connect to the Jondo server
 * In browser, this will use mock mode since WebSocket is not compatible with Jondo's TCP protocol
 */
async function autoConnect(host, port) {
    try {
        // Load character select first (to register handlers)
        await uiManager.loadUI('characterSelect');

        // Attempt connection (WebSocket will fail, fallback to mock mode in browser)
        const result = await protocol.connect(host, port);

        if (result.success) {
            console.log(`[DreamFus] Connected successfully (mock: ${result.mock})`);

            if (result.mock) {
                // In mock mode, simulate authentication and send welcome/message
                console.log(`[DreamFus] Mock mode - simulating login for ${DEFAULT_USERNAME}`);
                
                // Send mock welcome and characters list for character select screen
                sendMockLoginFlow();
            } else {
                // For real Tauri/desktop connections, the server sends real messages
                // Wait for characters list or use mock as fallback
                setTimeout(() => {
                    if (!EventBus.serverHandlers.has('charactersList')) {
                        console.log('[DreamFus] No real characters received, activating mock mode');
                        protocol.mockMode = true;
                        sendMockLoginFlow();
                    }
                }, 3000);
            }
        } else {
            console.error('[DreamFus] Connection failed:', result.message);
            // Activate mock mode as ultimate fallback - NEVER show login screen
            console.log('[DreamFus] Activating mock mode as fallback');
            protocol.mockMode = true;
            sendMockLoginFlow();
        }
    } catch (e) {
        console.error('[DreamFus] Auto-connect error:', e);
        // Activate mock mode as fallback - NEVER show login screen
        console.log('[DreamFus] Activating mock mode due to error');
        protocol.mockMode = true;
        sendMockLoginFlow();
    }
}

// Initialize DFUI system
async function init() {
    console.log('[DreamFus] Initializing client...');

    try {
        // Load base UI definitions (components, themes, 9-slice definitions)
        await dfui.loadBaseDefinitions();

        // Initialize UI Manager
        await uiManager.init();

        console.log('[DreamFus] Client initialized, attempting auto-connection...');

        // Auto-connect to server silently (no login screen shown to user)
        await autoConnect(DEFAULT_HOST, DEFAULT_PORT);

        console.log('[DreamFus] Client ready');

        // Expose to global for debugging
        window.dreamfus = { dfui, protocol, uiManager, EventBus };

    } catch (e) {
        console.error('[DreamFus] Initialization failed:', e);
        // NEVER show login screen on error - activate mock mode instead
        protocol.mockMode = true;
        uiManager.loadUI('characterSelect').then(() => {
            sendMockLoginFlow();
        });
    }
}

// Start the application
init().catch((e) => {
    console.error('[DreamFus] Initialization failed:', e);
    // NEVER show login screen on error - activate mock mode instead
    protocol.mockMode = true;
    uiManager.loadUI('characterSelect').then(() => {
        sendMockLoginFlow();
    });
});

// Handle unhandled server messages globally (for debugging via EventBus)
EventBus.on('server-message', (msg) => {
    console.log('[DreamFus] Server message received:', msg);
});