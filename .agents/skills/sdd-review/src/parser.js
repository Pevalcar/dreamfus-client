/**
 * Parser for SDD skills - extracts assumptions and structure from specs
 */

const fs = require('fs');
const path = require('path');

/**
 * Extract assumptions section from a spec.md or plan.md file
 * @param {string} filePath - Path to the spec/plan file
 * @returns {Object} - Assumptions object with array of assumptions
 */
function parse_assumptions(filePath) {
  const content = fs.readFileSync(filePath, 'utf-8');
  const lines = content.split('\n');
  
  const assumptions = [];
  let inAssumptionsSection = false;
  let currentNumber = 0;
  
  // Patterns to match
  const assumptionPatterns = [
    /^##\s*ASUMPTIONS/i,
    /^##\s*🛡️\s*ASUMPTIONS/i,
    /^###\s*ASUMPTIONS/i
  ];
  
  const assumptionLinePatterns = [
    /^\s*\d+\.\s*(.+)/,           // "1. text"
    /^\s*-\s*([•\-]\s*)?(.+)/,     // "- text" or "• text"
    /^\s*\*\s*(.+)/                 // "* text"
  ];
  
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    
    // Check if we're entering assumptions section
    if (assumptionPatterns.some(pattern => pattern.test(line))) {
      inAssumptionsSection = true;
      continue;
    }
    
    // Check if we're leaving assumptions section
    if (inAssumptionsSection && /^##\s+/i.test(line) && !assumptionPatterns.some(p => p.test(line))) {
      break;
    }
    
    if (inAssumptionsSection) {
      // Try to match assumption lines
      for (const pattern of assumptionLinePatterns) {
        const match = line.match(pattern);
        if (match) {
          currentNumber++;
          assumptions.push({
            text: match[2] || match[1],
            line: i + 1,
            severity: infer_severity(match[2] || match[1]),
            category: categorize_assumption(match[2] || match[1])
          });
          break;
        }
      }
    }
  }
  
  return {
    source: filePath,
    total: assumptions.length,
    assumptions: assumptions
  };
}

/**
 * Infer severity based on keywords in assumption
 * @param {string} text - Assumption text
 * @returns {string} - Severity level
 */
function infer_severity(text) {
  const highKeywords = ['obligatorio', 'debe', 'requiere', 'crítico', 'urgente', 'sin' ];
  const mediumKeywords = ['debería', 'preferible', 'recomendado', 'considerar', 'posible'];
  
  const lowerText = text.toLowerCase();
  
  if (highKeywords.some(k => lowerText.includes(k))) return 'high';
  if (mediumKeywords.some(k => lowerText.includes(k))) return 'medium';
  return 'low';
}

/**
 * Categorize assumption by domain
 * @param {string} text - Assumption text
 * @returns {string} - Category
 */
function categorize_assumption(text) {
  const lowerText = text.toLowerCase();
  
  if (lowerText.includes('tecnología') || lowerText.includes('stack') || 
      lowerText.includes('lenguaje') || lowerText.includes('framework')) {
    return 'tech';
  }
  if (lowerText.includes('usuario') || lowerText.includes('rol') || 
      lowerText.includes('interfaz') || lowerText.includes('interacción')) {
    return 'user';
  }
  if (lowerText.includes('datos') || lowerText.includes('base de datos') || 
      lowerText.includes('almacenamiento') || lowerText.includes('persistencia')) {
    return 'data';
  }
  if (lowerText.includes('api') || lowerText.includes('servicio') || 
      lowerText.includes('integración') || lowerText.includes('endpoint')) {
    return 'integration';
  }
  
  return 'general';
}

/**
 * Extract RF (Requirements Functionales) from spec
 * @param {string} filePath - Path to the spec file
 * @returns {Array} - Array of RF objects
 */
function parse_requirements(filePath) {
  const content = fs.readFileSync(filePath, 'utf-8');
  const lines = content.split('\n');
  
  const requirements = [];
  
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    
    // Match EARS format: RF-1: CUANDO...
    const rfMatch = line.match(/^(RF-\d+|RNF-\d+):\s*(.+)/i);
    if (rfMatch) {
      requirements.push({
        id: rfMatch[1],
        text: rfMatch[2].trim(),
        line: i + 1,
        type: rfMatch[1].startsWith('RF') ? 'functional' : 'non-functional'
      });
    }
  }
  
  return requirements;
}

/**
 * Parse structure from spec file
 * @param {string} filePath - Path to the spec file
 * @returns {Object} - Structure with sections
 */
function parse_structure(filePath) {
  const content = fs.readFileSync(filePath, 'utf-8');
  const lines = content.split('\n');
  
  const sections = [];
  
  for (const line of lines) {
    const sectionMatch = line.match(/^#{2,}\s+(.+)/);
    if (sectionMatch) {
      sections.push({
        title: sectionMatch[1].trim(),
        anchors: []
      });
    }
  }
  
  return {
    file: path.basename(filePath),
    total_sections: sections.length,
    sections: sections
  };
}

module.exports = {
  parse_assumptions,
  parse_requirements,
  parse_structure
};