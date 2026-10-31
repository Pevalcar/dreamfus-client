// Character Select Screen Logic
// Shows available characters and allows selection/creation

export default {
    async init(container, params, { dfui, protocol, uiManager, EventBus }) {
        console.log('[CharacterSelect] Initializing');

        // Listen for character list response from server
        const handleCharacters = async (msg) => {
            console.log('[CharacterSelect] Characters received:', msg);
            this.renderCharacters(container, msg);
        };
        uiManager.registerMessageHandler('charactersList', handleCharacters);

        // Listen for character selection result
        const handleSelectResult = (msg) => {
            console.log('[CharacterSelect] Selection result:', msg);
        };
        uiManager.registerMessageHandler('characterSelected', handleSelectResult);

        // In browser/mock mode, characters are already sent by main.js
        // In Tauri/real mode, we need to request them from the server
        if (protocol.mockMode) {
            console.log('[CharacterSelect] Mock mode - characters already sent by auto-connect');
        } else {
            // Request character list from server
            try {
                await protocol.sendMessage('charactersList', '');
            } catch (e) {
                console.warn('[CharacterSelect] Could not request characters:', e);
            }
        }

        // Set up button handlers
        // Note: The Create button has btnCreateCharacter ID in the DFUI definition
        const createBtn = container.querySelector('#btnNewCharacter') || 
                          container.querySelector('#btnCreateCharacter') ||
                          container.querySelector('[name="btnNewCharacter"]');
        const backBtn = container.querySelector('[data-action="disconnect"]') ||
                        container.querySelector('#btnBack');

        if (createBtn) {
            uiManager.addEventListener(createBtn, 'click', () => {
                uiManager.loadUI('newCharacter');
            });
        }

        if (backBtn) {
            uiManager.addEventListener(backBtn, 'click', () => {
                protocol.disconnect();
                uiManager.loadUI('login');
            });
        }
    },

    renderCharacters(container, message) {
        console.log('[CharacterSelect] renderCharacters called with message:', message);
        
        // Extract characters from message
        let characters = [];
        
        // Try to get characters from raw_payload (mock mode - could be string or Uint8Array)
        try {
            let payloadStr = null;
            
            if (message.raw_payload) {
                if (typeof message.raw_payload === 'string') {
                    payloadStr = message.raw_payload;
                } else if (message.raw_payload instanceof Uint8Array) {
                    payloadStr = new TextDecoder().decode(message.raw_payload);
                }
            }
            
            if (payloadStr) {
                const parsed = JSON.parse(payloadStr);
                if (parsed.characters) {
                    characters = parsed.characters;
                    console.log('[CharacterSelect] Parsed characters from raw_payload:', characters);
                }
            }
        } catch (e) {
            console.warn('[CharacterSelect] Could not parse raw_payload:', e);
        }
        
        // Real mode: characters are in payload field
        if (characters.length === 0 && message.payload && message.payload.characters) {
            characters = message.payload.characters;
        }

        // Fallback to placeholder characters if none received
        if (characters.length === 0) {
            console.log('[CharacterSelect] No characters, using placeholders');
            characters = [
                { name: 'Guerrero', class: 'warrior', level: 1 },
                { name: 'Mago', class: 'mage', level: 1 },
                { name: 'Aventurero', class: 'adventurer', level: 1 }
            ];
        }

        // Defer to next frame to ensure DFUI renderer has finished
        requestAnimationFrame(() => {
            this.populateSlots(container, characters);
        });
        
        console.log('[CharacterSelect] Rendered', characters.length, 'characters');
    },
    
    populateSlots(container, characters) {
        // Find and populate the slot grid - the slots are pre-defined in the DFUI
        // Need to find the actual slot elements created by the DFUI renderer
        
        // Method 1: Find slots by the dfui-slot class and populate them sequentially
        const allSlots = container.querySelectorAll('.dfui-slot');
        
        if (allSlots.length > 0) {
            // Found pre-created slots, populate them
            characters.forEach((char, index) => {
                if (index < allSlots.length) {
                    const slot = allSlots[index];
                    this.populateSlot(slot, char);
                }
            });
            
            // Hide unused slots
            for (let i = characters.length; i < allSlots.length; i++) {
                allSlots[i].style.display = 'none';
            }
        } else {
            console.warn('[CharacterSelect] No dfui-slot elements found');
            // Debug: log what's in the container
            console.log('[CharacterSelect] Container children:', container.children.length);
            container.querySelectorAll('*').forEach(el => {
                if (el.classList && el.classList.contains('dfui-slot')) {
                    console.log('[CharacterSelect] Found slot element:', el);
                }
            });
        }
        
        console.log('[CharacterSelect] Rendered', characters.length, 'characters');
    },
    
    populateSlot(slot, char) {
        const level = char.level || 1;
        const charClass = char.class || 'Unknown';
        slot.dataset.character = char.name;
        slot.innerHTML = `
            <span class="dfui-label">${char.name}</span>
            <span class="dfui-label" style="font-size:10px; color:var(--text-white-60)">Nvl ${level} - ${charClass}</span>
        `;
        slot.style.display = 'block';
        slot.onclick = () => {
            this.selectCharacter(char.name);
        };
    },

    selectCharacter(name) {
        console.log('[CharacterSelect] Selecting:', name);
        protocol.sendMessage('selectCharacter', name);
    }
};