// DFUI System - Data-driven UI for DreamFus Client
// Supports .dfui (JSON structure) and .dfss (CSS-like styling) files
// Includes automatic 9-slice border image handling from Alea assets

import { SliceParser } from '../SliceManager.js';

export const dfui = {
    // Cache for loaded definitions
    cache: new Map(),
    
    // Slice image registry (loaded from Alea manifest)
    sliceImages: new Map(),
    
    // Base component registry (inspired by Alea's UXML components)
    components: {
        // Container components
        'WindowFigma': { 
            tag: 'div', 
            class: 'dfui-window',
            defaults: { 'is-modal': 'false', 'is-movable': 'true', 'has-shadow': 'true' }
        },
        'DofusVisualElement': { 
            tag: 'div', 
            class: 'dfui-visual-element' 
        },
        'VisualElement': { 
            tag: 'div', 
            class: 'dfui-visual-element' 
        },
        
        // Text components
        'DofusLabel': { 
            tag: 'span', 
            class: 'dfui-label' 
        },
        'Label': { 
            tag: 'span', 
            class: 'dfui-label' 
        },
        
        // Input components
        'TextInput': { 
            tag: 'input', 
            class: 'dfui-text-input',
            defaults: { type: 'text' }
        },
        
        // Button components
        'DofusButtonCustom': { 
            tag: 'button', 
            class: 'dfui-button',
            defaults: { 'main-style': 'primary' }
        },
        
        // Layout components
        'DofusTab': { 
            tag: 'div', 
            class: 'dfui-tab-container' 
        },
        'DofusTabButton': { 
            tag: 'button', 
            class: 'dfui-tab-button' 
        },
        
        // Slot/Grid components
        'SlotGrid': { 
            tag: 'div', 
            class: 'dfui-slot-grid' 
        },
        'Slot': { 
            tag: 'div', 
            class: 'dfui-slot' 
        },
        
        // List components
        'ListView': { 
            tag: 'div', 
            class: 'dfui-list-view' 
        },
        'ListItem': { 
            tag: 'div', 
            class: 'dfui-list-item' 
        }
    },

    /**
     * Load base UI definitions (components, themes)
     */
    async loadBaseDefinitions() {
        try {
            // Load component style definitions (used for CSS generation, not component registry)
            const response = await fetch('/dfui/components.dfui');
            if (response.ok) {
                const componentStyles = await response.json();
                this.applyComponentStyles(componentStyles);
            }
        } catch (e) {
            console.warn('[DFUI] Could not load component definitions, using defaults');
        }

        // Load theme variables
        await this.loadTheme('/dfui/theme.dfss');
    },

    /**
     * Apply component styles from DFUI definition file
     * Generates CSS rules for each component type based on their style definitions
     */
    applyComponentStyles(componentStyles) {
        const style = document.createElement('style');
        let css = '';

        Object.entries(componentStyles).forEach(([name, def]) => {
            const className = `dfui-${name.toLowerCase()}`;
            if (def.s) {
                css += `.${className} { ${def.s} }\n`;
            }
            // Apply child component styles
            if (def.k) {
                const children = Array.isArray(def.k) ? def.k : [def.k];
                children.forEach(child => {
                    if (child.s && child.n) {
                        const childClass = `dfui-${child.t.toLowerCase()}`;
                        css += `.${className} .${child.n} { ${child.s} }\n`;
                    }
                });
            }
        });

        style.textContent = css;
        document.head.appendChild(style);
    },

    /**
     * Load theme variables from DFSS file
     */
    async loadTheme(url) {
        try {
            const response = await fetch(url);
            if (response.ok) {
                const css = await response.text();
                this.applyTheme(css);
            }
        } catch (e) {
            console.warn('[DFUI] Could not load theme:', url);
        }
    },

    /**
     * Apply CSS custom properties as theme
     */
    applyTheme(css) {
        const style = document.createElement('style');
        style.textContent = css;
        document.head.appendChild(style);
    },

    /**
     * Parse and load a DFUI file
     */
    async loadUI(url) {
        if (this.cache.has(url)) {
            return this.cache.get(url);
        }

        try {
            const response = await fetch(url);
            if (!response.ok) throw new Error(`Failed to load ${url}`);
            
            const definition = await response.json();
            this.cache.set(url, definition);
            return definition;
        } catch (e) {
            console.error('[DFUI] Failed to load UI:', url, e);
            throw e;
        }
    },

    /**
     * Render a DFUI definition into DOM elements
     */
    render(definition, container = document.body) {
        const element = this.createElement(definition);
        container.appendChild(element);
        return element;
    },

    /**
     * Create DOM element from DFUI definition
     */
    createElement(def) {
        if (!def || !def.t) {
            console.warn('[DFUI] Invalid definition:', def);
            return document.createComment('invalid-dfui');
        }

        const component = this.components[def.t] || { tag: 'div', class: 'dfui-unknown' };
        const element = document.createElement(component.tag);
        
        // Apply component class
        if (component.class) {
            element.classList.add(component.class);
        }
        
        // Apply type-specific class
        element.classList.add(`dfui-${def.t.toLowerCase()}`);
        
        // Apply attributes (def.a)
        if (def.a) {
            Object.entries(def.a).forEach(([key, value]) => {
                // Handle known HTML attributes that should be applied directly
                const htmlAttributes = ['placeholder', 'value', 'type', 'name', 'src', 'href', 'alt', 'disabled', 'checked', 'readonly', 'multiple', 'autocomplete'];
                const knownHtmlAttr = htmlAttributes.includes(key) || key === 'id' || key === 'tabindex' || key.startsWith('data-');

                if (key === 'text') {
                    // 'text' attribute sets the text content
                    element.textContent = value;
                } else if (key === 'placeholder-text') {
                    // Special case: placeholder-text -> placeholder
                    element.setAttribute('placeholder', value);
                } else if (key === 'data-action') {
                    // Special case: data-action should be applied as-is
                    element.setAttribute('data-action', value);
                } else if (knownHtmlAttr) {
                    // Apply as HTML attribute (convert hyphenated keys like placeholder-text to placeholder)
                    const attrName = key.replace(/-text$/, ''); // placeholder-text -> placeholder
                    element.setAttribute(attrName, value);
                } else {
                    // Custom properties as data attributes (use setAttribute to support hyphenated keys)
                    element.setAttribute('data-' + key, value);
                }
            });
        }

        // Apply inline styles (def.s)
        if (def.s) {
            element.style.cssText = def.s;
        }

        // Apply CSS classes (def.c)
        if (def.c) {
            const classes = Array.isArray(def.c) ? def.c : [def.c];
            classes.forEach(c => element.classList.add(c));
        }

        // Apply children (def.k)
        if (def.k) {
            const children = Array.isArray(def.k) ? def.k : [def.k];
            children.forEach(childDef => {
                const child = this.createElement(childDef);
                element.appendChild(child);
            });
        }

        // Apply text content (def.txt) - also supported as alternative to a.text
        if (def.txt !== undefined) {
            element.textContent = def.txt;
        }
        
        // Apply 9-slice if requested
        if (def.a && def.a.slice) {
            SliceParser.applyToElement(element, def);
        }
        
        return element;
    },

    /**
     * Register a custom component
     */
    registerComponent(name, config) {
        this.components[name] = config;
    },

    /**
     * Get component configuration
     */
    getComponent(name) {
        return this.components[name];
    },

    /**
     * Load slice image for 9-slice rendering
     * @param {string} name - Slice definition name
     */
    async loadSliceImage(name) {
        if (this.sliceImages.has(name)) {
            return this.sliceImages.get(name);
        }
        
        // Default image URL pattern for Alea assets
        const imageUrl = `/assets/ui/${name}.png`;
        this.sliceImages.set(name, imageUrl);
        return imageUrl;
    }
};