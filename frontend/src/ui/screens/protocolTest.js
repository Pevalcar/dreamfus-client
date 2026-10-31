// Protocol Test Screen Logic
// Integrated with EventBus for server message visualization

export default {
    async init(container, params, { dfui, protocol, uiManager, EventBus }) {
        console.log('[ProtocolTest] Initializing');
        
        const hostInput = container.querySelector('#hostInput');
        const portInput = container.querySelector('#portInput');
        const connectBtn = container.querySelector('#connectBtn');
        const disconnectBtn = container.querySelector('#disconnectBtn');
        const statusText = container.querySelector('#statusText');
        const customPanel = container.querySelector('#customMessagePanel');
        const customOpcode = container.querySelector('#customOpcode');
        const customPayload = container.querySelector('#customPayload');
        const sendCustomBtn = container.querySelector('#sendCustomBtn');
        const logContainer = container.querySelector('#logContainer');
        const clearLogBtn = container.querySelector('#clearLogBtn');
        
        let isConnected = false;
        
        // Update connection state UI
        function updateConnectionUI(connected) {
            isConnected = connected;
            if (connectBtn) {
                connectBtn.disabled = connected;
                connectBtn.style.opacity = connected ? '0.5' : '1';
            }
            if (disconnectBtn) {
                disconnectBtn.disabled = !connected;
                disconnectBtn.style.opacity = connected ? '1' : '0.5';
            }
            if (statusText) {
                statusText.textContent = connected ? 'Conectado' : 'Desconectado';
                statusText.className = connected ? 'text-success font-bold' : 'text-error font-bold';
            }
        }
        
        // Check initial status
        const status = await protocol.getStatus();
        updateConnectionUI(status.connected);
        
        // Message handler - registered via uiManager for proper cleanup
        const handleMessage = (msg) => {
            addLogEntry(msg);
        };

        // Register global server message listener
        const unsubscribe = EventBus.on('server-message', handleMessage);

        // Also register for specific opcodes via uiManager
        ['hello', 'knx', 'kuf'].forEach(opcode => {
            uiManager.registerMessageHandler(opcode, handleMessage);
        });

        // Register cleanup for this screen
        if (unsubscribe) {
            uiManager.registerCleanup(() => unsubscribe());
        }
        
        // Connect handler
        if (connectBtn) {
            uiManager.addEventListener(connectBtn, 'click', async () => {
                const host = hostInput?.value || 'localhost';
                const port = parseInt(portInput?.value) || 5555;
                
                connectBtn.disabled = true;
                connectBtn.textContent = 'Conectando...';
                
                const result = await protocol.connect(host, port);
                
                if (result.success) {
                    updateConnectionUI(true);
                    addLogEntry({ opcode_str: 'SYSTEM', direction: 0, raw_payload: new TextEncoder().encode('Conectado a ' + host + ':' + port) });
                } else {
                    updateConnectionUI(false);
                    addLogEntry({ opcode_str: 'ERROR', direction: 0, raw_payload: new TextEncoder().encode('Error: ' + result.message) });
                }
                
                connectBtn.disabled = false;
                connectBtn.textContent = 'Conectar';
            });
        }
        
        // Disconnect handler
        if (disconnectBtn) {
            uiManager.addEventListener(disconnectBtn, 'click', async () => {
                const result = await protocol.disconnect();
                if (result.success) {
                    updateConnectionUI(false);
                    addLogEntry({ opcode_str: 'SYSTEM', direction: 0, raw_payload: new TextEncoder().encode('Desconectado') });
                }
            });
        }
        
        // Quick opcode buttons
        container.querySelectorAll('[data-action="send-message"]').forEach(btn => {
            uiManager.addEventListener(btn, 'click', async (e) => {
                const opcode = btn.dataset.target;
                if (!isConnected) {
                    addLogEntry({ opcode_str: 'ERROR', direction: 0, raw_payload: new TextEncoder().encode('No conectado') });
                    return;
                }
                
                const result = await protocol.sendMessage(opcode, '');
                addLogEntry({ opcode_str: opcode, direction: 2, raw_payload: new TextEncoder().encode('Enviado: ' + result.message) });
            });
        });
        
        // Custom message button
        if (customPanel) {
            uiManager.addEventListener(customPanel, 'click', (e) => {
                // Check if click was on the button
                if (e.target.dataset?.action === 'send-custom') {
                    customPanel.style.display = customPanel.style.display === 'none' ? 'flex' : 'none';
                }
            });
            
            if (sendCustomBtn) {
                uiManager.addEventListener(sendCustomBtn, 'click', async () => {
                    if (!isConnected) {
                        addLogEntry({ opcode_str: 'ERROR', direction: 0, raw_payload: new TextEncoder().encode('No conectado') });
                        return;
                    }
                    
                    const opcode = customOpcode?.value || '';
                    const payloadHex = customPayload?.value || '';
                    
                    if (!opcode) {
                        addLogEntry({ opcode_str: 'ERROR', direction: 0, raw_payload: new TextEncoder().encode('Opcode requerido') });
                        return;
                    }
                    
                    const result = await protocol.sendMessage(opcode, payloadHex);
                    addLogEntry({ opcode_str: opcode, direction: 2, raw_payload: new TextEncoder().encode('Enviado: ' + result.message + ' | Payload: ' + payloadHex) });
                });
            }
        }
        
        // Clear log
        if (clearLogBtn) {
            uiManager.addEventListener(clearLogBtn, 'click', () => {
                if (logContainer) {
                    logContainer.innerHTML = '';
                }
            });
        }
        
        // Add log entry helper
        function addLogEntry(msg) {
            if (!logContainer) return;
            
            const entry = document.createElement('div');
            entry.className = 'log-entry';
            entry.style.padding = '4px 8px';
            entry.style.borderBottom = '1px solid rgba(255,255,255,0.05)';
            entry.style.fontFamily = "'Courier New', monospace";
            entry.style.fontSize = '12px';
            entry.style.lineHeight = '1.5';
            
            const timestamp = new Date().toLocaleTimeString();
            let directionClass = '';
            let directionText = '';
            
            if (msg.direction === 1) { directionClass = 'server-push'; directionText = '[PUSH] '; }
            else if (msg.direction === 2) { directionClass = 'client-request'; directionText = '[REQ] '; }
            else if (msg.direction === 3) { directionClass = 'server-reply'; directionText = '[REPLY] '; }
            
            const opcode = msg.opcode_str || 'unknown';
            const hex = Array.from(msg.raw_payload || []).map(b => b.toString(16).padStart(2, '0')).join(' ');
            const directionColor = getDirectionColor(msg.direction);
            
            entry.innerHTML = `
                <span style="color:#888">[${timestamp}]</span> 
                <span style="color:${directionColor}">${directionText}</span>
                <span style="color:#aaa">${opcode}</span>
                ${hex ? '<br><span style="color:#666; margin-left: 20px;">' + hex + '</span>' : ''}
            `;
            
            logContainer.insertBefore(entry, logContainer.firstChild);
            
            // Limit entries
            while (logContainer.children.length > 200) {
                logContainer.removeChild(logContainer.lastChild);
            }
        }
        
        function getDirectionColor(dir) {
            switch (dir) {
                case 1: return '#4ecca3'; // server push - green
                case 2: return '#4fc3f7'; // client request - blue
                case 3: return '#ffaa00'; // server reply - orange
                default: return '#888';
            }
        }
    }
};