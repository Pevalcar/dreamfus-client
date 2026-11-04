// Friends/Social Screen Logic
// Communicates with server via EventBus for friend list updates

export default {
    async init(container, params, { dfui, protocol, uiManager, EventBus }) {
        console.log('[Friends] Initializing');
        
        // Check connection
        const status = await protocol.getStatus();
        if (!status.connected) {
            uiManager.loadUI('login');
            return;
        }
        
        // Load friends list
        await this.loadFriends(container);
        
        // Setup button handlers with proper cleanup tracking
        const addFriendBtn = container.querySelector('[data-action="open-add-friend"]');
        const refreshBtn = container.querySelector('[data-action="refresh-friends"]');
        const backBtn = container.querySelector('[data-action="disconnect"]');
        
        if (addFriendBtn) {
            uiManager.addEventListener(addFriendBtn, 'click', () => {
                this.openAddFriendDialog(uiManager);
            });
        }
        
        if (refreshBtn) {
            uiManager.addEventListener(refreshBtn, 'click', () => {
                this.refreshFriends(container);
            });
        }
        
        if (backBtn) {
            uiManager.addEventListener(backBtn, 'click', (e) => {
                e.stopPropagation();
                uiManager.loadUI('mainMenu');
            });
        }
        
        // Register for server friend list updates via EventBus with proper cleanup
        const handleFriendsList = (msg) => {
            console.log('[Friends] Received friends list update:', msg);
            this.updateFriendsFromServer(container, msg);
        };
        uiManager.registerMessageHandler('ankamaFriendsList', handleFriendsList);
    },
    
    async loadFriends(container) {
        console.log('[Friends] Loading friends list...');
        
        // In a real implementation, this would fetch from the server
        // For now, use placeholder data
        const listView = container.querySelector('.dfui-list-view');
        
        if (listView) {
            // Clear existing content
            listView.innerHTML = '';
            
            // Placeholder friends list
            const friends = [
                { name: 'PlayerOne', status: 'online', level: 45 },
                { name: 'PlayerTwo', status: 'offline', level: 32 },
                { name: 'PlayerThree', status: 'online', level: 67 }
            ];
            
            friends.forEach(friend => {
                const listItem = this.createFriendItem(friend);
                listView.appendChild(listItem);
            });
        }
    },
    
    createFriendItem(friend) {
        const item = document.createElement('div');
        item.className = 'dfui-list-item friend-item';
        item.dataset.name = friend.name;
        item.dataset.status = friend.status;
        item.dataset.action = 'friend-click';
        
        const nameSpan = document.createElement('span');
        nameSpan.className = 'dfui-label';
        nameSpan.textContent = friend.name;
        nameSpan.style.fontWeight = '600';
        
        const statusSpan = document.createElement('span');
        statusSpan.className = 'dfui-label';
        statusSpan.style.fontSize = '12px';
        statusSpan.style.color = 'var(--text-white-60)';
        statusSpan.textContent = friend.status === 'online' ? 'En línea' : 'Fuera de línea';
        
        const levelSpan = document.createElement('span');
        levelSpan.className = 'dfui-label';
        levelSpan.style.fontSize = '12px';
        levelSpan.style.color = 'var(--text-white-40)';
        levelSpan.textContent = `Nivel ${friend.level}`;
        
        item.appendChild(nameSpan);
        item.appendChild(statusSpan);
        item.appendChild(levelSpan);
        
        const self = this;
        item.addEventListener('click', () => {
            self.onFriendClick(friend);
        });
        
        return item;
    },
    
    async refreshFriends(container) {
        console.log('[Friends] Refreshing friends list...');
        await this.loadFriends(container);
    },
    
    onFriendClick(friend) {
        console.log('[Friends] Friend clicked:', friend.name);
        // In a real implementation, this would open a context menu or send a whisper
    },
    
    updateFriendsFromServer(container, message) {
        console.log('[Friends] Updating from server:', message);
        // Parse server data if available
        // This would need implementation based on actual protocol
    },
    
    openAddFriendDialog(uiManager) {
        uiManager.showModal('addFriend').then(modal => {
            console.log('[Friends] Add friend dialog opened');
        }).catch(e => {
            console.error('[Friends] Error opening add friend dialog:', e);
        });
    }
};