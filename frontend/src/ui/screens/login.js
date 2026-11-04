// Login Screen Logic
// Handles server connection and authentication
// Shown as fallback when auto-connect fails, or for manual reconnection

import { EventBus } from '../../EventBus.js';

export default {
    async init(container, params, { dfui, protocol, uiManager, EventBus }) {
        console.log('[Login] Initializing');
        
        // Default credentials for mock mode
        const DEFAULT_USERNAME = 'keka';
        const DEFAULT_PASSWORD = 'test';

        // Get form elements
        const serverInput = container.querySelector('#serverInput');
        const portInput = container.querySelector('#portInput');
        const userInput = container.querySelector('#userInput');
        const passwordInput = container.querySelector('#passwordInput');
        const connectBtn = container.querySelector('#connectBtn');
        const statusEl = container.querySelector('#status');
        const statusText = container.querySelector('#statusText');

        // Set default values
        if (portInput && !portInput.value) portInput.value = '5555';
        if (userInput && !userInput.value) userInput.value = DEFAULT_USERNAME;
        if (passwordInput && !passwordInput.value) passwordInput.value = DEFAULT_PASSWORD;

        // Focus on password field for better UX
        if (passwordInput) {
            passwordInput.focus();
        }

        // Show status message
        const showStatus = (message, isError = false) => {
            if (statusEl && statusText) {
                statusEl.style.display = 'flex';
                statusText.textContent = message;
                statusEl.style.background = isError
                    ? 'rgba(233, 69, 69, 0.2)'
                    : 'rgba(76, 178, 23, 0.2)';
                statusEl.style.color = isError ? 'var(--error)' : 'var(--success)';
            }
        };

        // Hide status
        const hideStatus = () => {
            if (statusEl) statusEl.style.display = 'none';
        };

        // Hide status initially
        hideStatus();

        // Send mock login flow (welcome message + characters list)
        // First loads characterSelect, then sends messages
        const sendMockAndNavigate = () => {
            console.log('[Login] Sending mock login flow');
            
            // First, load character select (to register handlers)
            uiManager.loadUI('characterSelect').then(() => {
                // Simulate welcome message from server
                const welcomeMsg = {
                    direction: 'ServerPush',
                    opcode: 'hello',
                    opcode_str: 'hello',
                    raw_payload: new TextEncoder().encode(JSON.stringify({ 
                        opcode: 'hello', 
                        message: 'Welcome, ' + DEFAULT_USERNAME,
                        sessionId: 'mock-session-' + Date.now()
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
            });
        };

        // Manual connect button handler (for retry or if auto-connect was disabled)
        if (connectBtn) {
            uiManager.addEventListener(connectBtn, 'click', async () => {
                // Skip if already connected or connecting
                if (protocol.connected || connectBtn.disabled) return;

                const host = serverInput?.value || 'localhost';
                const port = parseInt(portInput?.value) || 5555;
                const username = userInput?.value || DEFAULT_USERNAME;
                const password = userInput?.value || DEFAULT_PASSWORD;

                connectBtn.disabled = true;
                connectBtn.textContent = 'Conectando...';
                showStatus('Conectando automáticamente...');

                try {
                    const result = await protocol.connect(host, port);
                    if (result.success) {
                        showStatus('Conectado. Redirigiendo...', false);
                        
                        if (result.mock || protocol.mockMode) {
                            console.log('[Login] Mock mode - simulating login for:', username);
                            // Send mock login flow with welcome and character list
                            sendMockAndNavigate();
                        } else {
                            // Real connection - wait for server to send characters list
                            setTimeout(() => {
                                if (!EventBus.serverHandlers.has('charactersList')) {
                                    // No characters received, activate mock mode
                                    console.log('[Login] No real characters, activating mock mode');
                                    sendMockAndNavigate();
                                } else {
                                    uiManager.loadUI('characterSelect');
                                }
                            }, 2000);
                        }
                    } else {
                        showStatus('Error: ' + result.message, true);
                        console.log('[Login] Connection failed, activating mock mode as fallback');
                        // Activate mock mode as fallback
                        sendMockAndNavigate();
                    }
                } catch (e) {
                    showStatus('Error: ' + e.message, true);
                    console.log('[Login] Connection error, activating mock mode as fallback');
                    // Activate mock mode as fallback
                    sendMockAndNavigate();
                }
                
                connectBtn.disabled = false;
                connectBtn.textContent = 'Entrar';
            });
        }

        // Listen for server messages with proper cleanup
        const unsubscribe = EventBus.on('server-message', (msg) => {
            console.log('[Login] Server message:', msg);
        });

        // Register cleanup function for this screen
        uiManager.registerCleanup(() => {
            if (unsubscribe) unsubscribe();
        });
    }
};