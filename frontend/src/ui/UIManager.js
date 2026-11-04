// UI Manager - Handles loading and managing DFUI screens
// Integrates with EventBus for server message synchronization

import { dfui } from '../dfui/index.js';
import { protocol } from '../protocol.js';
import { EventBus } from '../EventBus.js';

export const uiManager = {
    // Current active UI
    currentUI: null,
    currentContainer: null,
    
    // UI definitions cache
    uiCache: new Map(),
    
    // Root container
    root: null,
    
    /**
     * Initialize UI Manager
     */
    async init() {
        this.root = document.getElementById('app');
        if (!this.root) {
            throw new Error('Root element #app not found');
        }
        
        // Set up protocol message handling through EventBus
        EventBus.on('server-message', (msg) => this.handleServerMessage(msg));
        protocol.on('message', (msg) => this.handleServerMessage(msg));
        
        console.log('[UIManager] Initialized');
    },
    
    /**
     * Load and display a UI screen
     */
    async loadUI(name, params = {}) {
        // Unload current UI if exists
        if (this.currentUI) {
            await this.unloadUI();
        }
        
        try {
            // Load UI definition
            const definition = await this.loadUIDefinition(name);
            
            // Create container for this UI
            this.currentContainer = document.createElement('div');
            this.currentContainer.className = `dfui-screen dfui-screen-${name}`;
            this.currentContainer.dataset.uiName = name;
            
            // Initialize UI state for cleanup tracking before loading UI logic
            this.currentUI = { 
                name, 
                definition, 
                params,
                handlers: {},
                eventListeners: [],
                cleanupFunctions: []
            };
            
            // Render the UI
            dfui.render(definition, this.currentContainer);
            
            // Add to DOM
            this.root.appendChild(this.currentContainer);
            
            // Initialize UI logic
            await this.initUILogic(name, definition, params);
            
            console.log(`[UIManager] Loaded UI: ${name}`);
            return true;
        } catch (e) {
            console.error(`[UIManager] Failed to load UI ${name}:`, e);
            return false;
        }
    },
    
    /**
     * Load UI definition from file or cache
     */
    async loadUIDefinition(name) {
        if (this.uiCache.has(name)) {
            return this.uiCache.get(name);
        }
        
        // Try to load from /ui/{name}.dfui
        const definition = await dfui.loadUI(`/ui/${name}.dfui`);
        this.uiCache.set(name, definition);
        return definition;
    },
    
    /**
     * Initialize UI-specific logic (event handlers, etc.)
     */
    async initUILogic(name, definition, params) {
        // Look for UI-specific module
        try {
            const module = await import(`./screens/${name}.js`);
            if (module.default && typeof module.default.init === 'function') {
                await module.default.init(this.currentContainer, params, { 
                    dfui, 
                    protocol, 
                    uiManager: this,
                    EventBus 
                });
            }
        } catch (e) {
            // No specific logic module, use generic handlers
            this.setupGenericHandlers(this.currentContainer);
        }
        
        // Set up draggable windows
        this.setupDraggableWindows(this.currentContainer);
        
        // Set up button handlers
        this.setupButtonHandlers(this.currentContainer);
    },
    
    /**
     * Set up generic event handlers for common components
     */
    setupGenericHandlers(container) {
        const self = this;
        // Close buttons
        container.querySelectorAll('[data-close], [data-action="close"]').forEach(btn => {
            self.addEventListener(btn, 'click', (e) => {
                e.stopPropagation();
                self.unloadUI();
            });
        });
    },
    
    /**
     * Make an element draggable
     */
    makeDraggable(element) {
        let isDragging = false;
        let offsetX = 0, offsetY = 0;
        
        const handle = element.querySelector('.dfui-window-header, [data-drag-handle]') || element;
        
        const onMouseDown = (e) => {
            // Don't start drag on interactive elements
            const target = e.target;
            if (target.tagName === 'BUTTON' || 
                target.tagName === 'INPUT' || 
                target.tagName === 'TEXTAREA' ||
                target.closest('button') ||
                target.closest('input')) return;
            
            isDragging = true;
            const rect = element.getBoundingClientRect();
            offsetX = e.clientX - rect.left;
            offsetY = e.clientY - rect.top;
            element.style.position = 'fixed';
            element.style.zIndex = '1000';
            element.style.pointerEvents = 'auto';
            
            document.body.style.userSelect = 'none';
        };
        
        const onMouseMove = (e) => {
            if (!isDragging) return;
            element.style.left = `${e.clientX - offsetX}px`;
            element.style.top = `${e.clientY - offsetY}px`;
        };
        
        const onMouseUp = () => {
            if (isDragging) {
                isDragging = false;
                document.body.style.userSelect = '';
            }
        };
        
        handle.addEventListener('mousedown', onMouseDown);
        document.addEventListener('mousemove', onMouseMove);
        document.addEventListener('mouseup', onMouseUp);
        
        // Return cleanup function
        return () => {
            handle.removeEventListener('mousedown', onMouseDown);
            document.removeEventListener('mousemove', onMouseMove);
            document.removeEventListener('mouseup', onMouseUp);
        };
    },
    
    /**
     * Set up draggable windows
     */
    setupDraggableWindows(container) {
        const cleanups = [];
        container.querySelectorAll('.dfui-window[data-is-movable="true"]').forEach(w => {
            const cleanup = this.makeDraggable(w);
            if (cleanup) {
                cleanups.push(cleanup);
            }
        });
        
        // Track for cleanup
        if (cleanups.length > 0 && this.currentUI) {
            const combinedCleanup = () => cleanups.forEach(c => c());
            if (!this.currentUI.eventListeners) {
                this.currentUI.eventListeners = [];
            }
            this.currentUI.eventListeners.push(combinedCleanup);
        }
    },
    
    /**
     * Set up button handlers
     */
    setupButtonHandlers(container) {
        const self = this;
        container.querySelectorAll('[data-action]').forEach(btn => {
            const clickHandler = (e) => {
                // Prevent event bubbling to map/canvas
                e.stopPropagation();
                
                const action = btn.dataset.action;
                const target = btn.dataset.target;
                
                switch (action) {
                    case 'load-ui':
                        self.loadUI(target);
                        break;
                    case 'send-message':
                        protocol.sendMessage(target, btn.dataset.payload || '');
                        break;
                    case 'close':
                    case 'disconnect':
                        self.unloadUI();
                        break;
                    case 'dialog-close':
                        btn.closest('.dfui-modal-overlay')?.remove();
                        break;
                }
            };
            self.addEventListener(btn, 'click', clickHandler);
        });
    },
    
    /**
     * Handle incoming server messages
     * Routes through EventBus for centralized handling
     */
    handleServerMessage(message) {
        console.log('[UIManager] Server message:', message);
        // Note: EventBus is already the central hub, no need to re-dispatch
        // The message is already processed by EventBus.handleServerMessage
    },
    
    /**
     * Unload current UI and cleanup handlers
     */
    async unloadUI() {
        // Run cleanup functions (including EventBus unsubscribe functions)
        if (this.currentUI && this.currentUI.cleanupFunctions) {
            this.currentUI.cleanupFunctions.forEach(fn => fn());
            this.currentUI.cleanupFunctions = [];
        }
        
        // Run onUnload callbacks first (for explicit cleanup)
        if (this.currentUI && typeof this.currentUI.onUnload === 'function') {
            await this.currentUI.onUnload();
        }
        
        // Clean up server message handlers registered via uiManager
        if (this.currentUI && this.currentUI.handlers) {
            Object.keys(this.currentUI.handlers).forEach(opcode => {
                this.unregisterMessageHandler(opcode);
            });
        }
        
        // Clear event listeners
        if (this.currentUI && this.currentUI.eventListeners) {
            this.currentUI.eventListeners.forEach(listener => listener());
        }
        
        if (this.currentContainer) {
            this.currentContainer.remove();
            this.currentContainer = null;
        }
        this.currentUI = null;
        
        console.log('[UIManager] UI unloaded');
    },
    
    /**
     * Show a modal dialog
     */
    async showModal(name, params = {}) {
        const modalContainer = document.createElement('div');
        modalContainer.className = 'dfui-modal-overlay';
        modalContainer.dataset.uiName = `modal-${name}`;
        
        // Click outside closes modal
        modalContainer.addEventListener('click', (e) => {
            if (e.target === modalContainer) {
                modalContainer.remove();
            }
        });
        
        const definition = await this.loadUIDefinition(name);
        dfui.render(definition, modalContainer);
        
        document.body.appendChild(modalContainer);
        
        // Initialize modal logic
        try {
            const module = await import(`./screens/${name}.js`);
            if (module.default && typeof module.default.init === 'function') {
                await module.default.init(modalContainer, params, { 
                    dfui, 
                    protocol, 
                    uiManager: this,
                    EventBus 
                });
            }
        } catch (e) {
            // No specific logic, just render
        }
        
        return modalContainer;
    },
    
    /**
     * Register a server message handler for current screen
     */
    registerMessageHandler(opcode, handler) {
        EventBus.onServerMessage(opcode, handler);
        
        // Also store for cleanup
        if (!this.currentUI) return;
        if (!this.currentUI.handlers) {
            this.currentUI.handlers = {};
        }
        this.currentUI.handlers[opcode] = handler;
    },
    
    /**
     * Register an event listener that will be cleaned up when UI unloads
     */
    addEventListener(element, event, handler) {
        element.addEventListener(event, handler);
        
        // Track for cleanup
        if (!this.currentUI) return;
        if (!this.currentUI.eventListeners) {
            this.currentUI.eventListeners = [];
        }
        const unbind = () => element.removeEventListener(event, handler);
        this.currentUI.eventListeners.push(unbind);
    },
    
    /**
     * Unregister a handler (for cleanup)
     */
    unregisterMessageHandler(opcode) {
        EventBus.offServerMessage(opcode);
        if (this.currentUI && this.currentUI.handlers) {
            delete this.currentUI.handlers[opcode];
        }
    },
    
    /**
     * Register a cleanup function that will be called when UI unloads
     * @param {Function} cleanupFn - Function to call on unload
     */
    registerCleanup(cleanupFn) {
        if (!this.currentUI) return;
        if (!this.currentUI.cleanupFunctions) {
            this.currentUI.cleanupFunctions = [];
        }
        this.currentUI.cleanupFunctions.push(cleanupFn);
    },
    
    /**
     * Navigate to another screen (alias for loadUI)
     */
    navigate(screenName, params = {}) {
        return this.loadUI(screenName, params);
    }
};

export default uiManager;