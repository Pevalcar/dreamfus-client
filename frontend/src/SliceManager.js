// SliceManager - 9-Slice border image utility for DFUI
// Automatically converts Alea 9-slice arrays to CSS border-image properties

// 9-slice definitions from d3ui/manifest.json (Alea/Dofus 3)
export const SLICE_DEFINITIONS = {
    // Dialog window frames
    dialogBackground: [66, 0, 67, 0],      // [top, right, bottom, left] for dialog background
    dialogHeader: [30, 0, 4, 0],           // Header bar with gradient
    dialogHeaderButton: [16, 16, 16, 16],  // Close/minimize buttons
    
    // Window frames
    charactHeader: [0, 40, 0, 40],         // Character header panel
    playButtonBackground: [12, 12, 12, 12], // Play/start button frame
    
    // UI Panels
    questPanel: [10, 10, 10, 10],
    inventoryPanel: [8, 8, 8, 8],
    tooltipFrame: [4, 4, 4, 4],
    statusFrame: [6, 6, 6, 6],
    
    // Buttons
    buttonPrimary: [4, 4, 4, 4],
    buttonSecondary: [3, 3, 3, 3],
};

// 9-slice image URLs (from Alea assets)
// These would be loaded from the client-patched/ui/Ankama_Web/assets/ folder
export const SLICE_IMAGES = {
    dialogBackground: '/assets/ui/dialogBackground.png',
    dialogHeader: '/assets/ui/dialogHeader.png',
    charactHeader: '/assets/ui/charactHeader.png',
    playButtonBackground: '/assets/ui/playButtonBackground.png',
};

/**
 * Convert 9-slice array to CSS border-image properties
 * @param {string} name - Slice definition name (e.g., 'dialogBackground')
 * @param {string} imageUrl - URL to the 9-slice image (optional, uses default)
 * @param {number} width - Width of the rendered element
 * @param {number} height - Height of the rendered element
 * @returns {Object} CSS properties for border-image
 */
export function createBorderImageStyle(name, imageUrl = null, width = null, height = null) {
    const slice = SLICE_DEFINITIONS[name];
    const image = imageUrl || SLICE_IMAGES[name] || '';
    
    if (!slice) {
        console.warn(`[SliceManager] Unknown slice definition: ${name}`);
        return {};
    }
    
    const [top, right, bottom, left] = slice;
    
    return {
        // Basic border-image setup
        'border-image-source': image,
        'border-image-slice': `${top} ${right} ${bottom} ${left} fill`,
        
        // Optional dimensions for consistent sizing
        ...(width ? { 'width': `${width}px` } : {}),
        ...(height ? { 'height': `${height}px` } : {}),
        
        // Ensure proper rendering
        'border-image-outset': '1',
        'border-image-repeat': 'round',
        
        // Prevent image distortion
        'background-size': 'contain',
        'background-repeat': 'no-repeat',
    };
}

/**
 * Generate inline style string for border-image
 * @param {string} name - Slice definition name
 * @param {string} imageUrl - Optional image URL
 * @returns {string} CSS style string
 */
export function getBorderImageStyle(name, imageUrl = null) {
    const style = createBorderImageStyle(name, imageUrl);
    return Object.entries(style)
        .map(([prop, value]) => `${prop.replace(/([A-Z])/g, '-$1').toLowerCase()}: ${value}`)
        .join('; ') + ';';
}

/**
 * Apply 9-slice to an element
 * @param {HTMLElement} element - DOM element to style
 * @param {string} name - Slice definition name
 * @param {Object} options - Optional settings
 */
export function applySlice(element, name, options = {}) {
    const { imageUrl, width, height } = options;
    const style = createBorderImageStyle(name, imageUrl, width, height);
    
    Object.entries(style).forEach(([prop, value]) => {
        element.style[prop] = value;
    });
    
    return element;
}

/**
 * Parser utility for DFUI to automatically apply 9-slice styles
 * Based on component type and custom properties
 */
export const SliceParser = {
    /**
     * Parse DFUI definition and extract slice information
     * @param {Object} def - DFUI component definition
     * @returns {Object|null} Slice info or null
     */
    extractSliceInfo(def) {
        if (!def || typeof def !== 'object') return null;
        
        // Check for explicit slice reference
        if (def.a) {
            const sliceRef = def.a['slice'];
            if (sliceRef && SLICE_DEFINITIONS[sliceRef]) {
                return {
                    name: sliceRef,
                    imageUrl: def.a['slice-image'] || null,
                    width: def.w ? parseInt(def.w) : null,
                    height: def.h ? parseInt(def.h) : null,
                };
            }
        }
        
        // Infer from component type
        const sliceByComponent = {
            'WindowFigma': 'dialogBackground',
            'DialogBackground': 'dialogBackground',
            'DialogHeader': 'dialogHeader',
            'CharacterHeader': 'charactHeader',
            'PlayButtonBackground': 'playButtonBackground',
        };
        
        const componentName = def.t;
        if (componentName && sliceByComponent[componentName]) {
            return {
                name: sliceByComponent[componentName],
                width: def.w ? parseInt(def.w) : null,
                height: def.h ? parseInt(def.h) : null,
            };
        }
        
        return null;
    },
    
    /**
     * Apply 9-slice styles to element based on its DFUI definition
     */
    applyToElement(element, def) {
        const sliceInfo = this.extractSliceInfo(def);
        if (sliceInfo) {
            return applySlice(element, sliceInfo.name, {
                imageUrl: sliceInfo.imageUrl,
                width: sliceInfo.width,
                height: sliceInfo.height,
            });
        }
        return element;
    }
};

export default { createBorderImageStyle, getBorderImageStyle, applySlice, SliceParser, SLICE_DEFINITIONS };