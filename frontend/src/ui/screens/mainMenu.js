// Main Menu Screen Logic
// Post-login menu with navigation to game, friends, etc.

export default {
    async init(container, params, { dfui, protocol, uiManager, EventBus }) {
        console.log('[MainMenu] Initializing');

        // Set up button handlers
        const buttons = container.querySelectorAll('[data-action]');
        buttons.forEach(btn => {
            const action = btn.dataset.action;
            const target = btn.dataset.target;

            if (action === 'load-ui' && target) {
                uiManager.addEventListener(btn, 'click', () => {
                    uiManager.loadUI(target);
                });
            } else if (action === 'disconnect') {
                uiManager.addEventListener(btn, 'click', async () => {
                    await protocol.disconnect();
                    uiManager.loadUI('login');
                });
            }
        });

        // Listen for server messages with proper cleanup
        const unsubscribe = EventBus.on('server-message', (msg) => {
            console.log('[MainMenu] Server message:', msg);
        });

        // Register cleanup for this screen
        uiManager.registerCleanup(() => {
            if (unsubscribe) unsubscribe();
        });
    }
};