/**
 * Alternative generator for SDD review
 * Generates alternative approaches for decisions
 */

const alternative_templates = {
  architecture: [
    {
      name: 'Monolítico',
      approach: 'Implementar todo en un solo servicio/componente',
      pros: ['Menos complejidad de deployment', 'Más fácil de debuggear inicialmente', 'Menos networking'],
      cons: ['Difícil de escalar', 'Acoplamiento alto', 'Límites claros difíciles']
    },
    {
      name: 'Modular/Distributed',
      approach: 'Separar funcionalidades en componentes independientes',
      pros: ['Mayor escalabilidad', 'Equipos pueden trabajar independientemente', 'Mejor mantenibilidad'],
      cons: ['Complejidad de integración', 'Más puntos de falla', 'Latencia de networking']
    },
    {
      name: 'Híbrido',
      approach: 'Módulos críticos separados, operaciones secundarias integradas',
      pros: ['Mejor equilibrio entre simplicidad y escalabilidad', 'Optimizado para casos de uso reales'],
      cons: ['Requiere análisis cuidadoso para elegir divisiones', 'Puede ser complejo de mantener']
    }
  ],
  data_storage: [
    {
      name: 'JSON/Archivo plano',
      approach: 'Almacenar datos en archivos JSON o CSV',
      pros: ['Simple de implementar', 'Fácil de versionar', 'Sin infraestructura extra'],
      cons: ['No escala para grandes volúmenes', 'Peor rendimiento', 'Sin consultas complejas']
    },
    {
      name: 'Base de datos relacional',
      approach: 'Usar PostgreSQL, MySQL o similar',
      pros: ['Transaccional', 'Consultas complejas', 'Escalable'],
      cons: ['Más complejo de operar', 'Overhead para datasets pequeños', 'Migraciones']
    },
    {
      name: 'Base de datos NoSQL',
      approach: 'Usar MongoDB, Redis, o similar',
      pros: ['Flexible esquema', 'Alto rendimiento para ciertos workloads', 'Escalabilidad horizontal'],
      cons: ['Sin transacciones ACID', 'Curva de aprendizaje', 'Overhead adicional']
    }
  ],
  api_design: [
    {
      name: 'REST tradicional',
      approach: 'Endpoints CRUD clásicos con HTTP verbs',
      pros: ['Amplamente entendido', 'Herramientas disponibles', 'Cacheable'],
      cons: ['Overhead de HTTP', 'Anidación compleja de recursos', 'No es ideal para updates parciales']
    },
    {
      name: 'GraphQL',
      approach: 'API única con consultas flexibles',
      pros: ['Over-fetching reducido', 'Un endpoint para todo', 'Tipado fuerte'],
      cons: ['Curva de aprendizaje', 'Complejidad de cache', 'Overhead de ejecución']
    },
    {
      name: 'gRPC',
      approach: 'APIs con protocol buffers',
      pros: ['Alto rendimiento', 'Tipos fuerte', 'Streaming nativo'],
      cons: ['Más complejo que REST', 'Requiere generación de código', 'Debug más difícil']
    }
  ],
  testing: [
    {
      name: 'Unit tests only',
      approach: 'Solo pruebas unitarias para lógica de negocio',
      pros: ['Rápido de escribir y ejecutar', 'Cobertura alta de código'],
      cons: ['No detecta problemas de integración', 'Mocks pueden ser incorrectos']
    },
    {
      name: 'Integration tests',
      approach: 'Tests que cubren componentes integrados',
      pros: ['Detecta problemas de conexión', 'Más realista'],
      cons: ['Más lentos', 'Complejidad de setup', 'Frágiles']
    },
    {
      name: 'Contract tests',
      approach: 'Tests de contrato entre servicios',
      pros: ['Detecta breaking changes', 'Documenta interfaces', 'E2E sin setup completo'],
      cons: ['Requiere framework adicional', 'Complejidad inicial']
    }
  ]
};

const pattern_mapping = {
  'almacenamiento': 'data_storage',
  'persistencia': 'data_storage',
  'base de datos': 'data_storage',
  'api': 'api_design',
  'endpoint': 'api_design',
  'arquitectura': 'architecture',
  'servicio': 'architecture',
  'microservicio': 'architecture',
  'compónente': 'architecture',
  'prueba': 'testing',
  'test': 'testing',
  'unitario': 'testing',
  'integración': 'testing'
};

/**
 * Identify the relevant alternative category for an assumption
 * @param {string} assumption - The assumption text
 * @returns {string|null} - Category key or null
 */
function identify_category(assumption) {
  const lowerAssumption = assumption.toLowerCase();
  
  for (const [keyword, category] of Object.entries(pattern_mapping)) {
    if (lowerAssumption.includes(keyword)) {
      return category;
    }
  }
  
  return null;
}

/**
 * Generate alternatives for a given decision context
 * @param {string} decision_point - Description of the decision
 * @param {string} category - Category of decision (architecture, data, api, testing)
 * @returns {Object} - Alternative approaches with pros and cons
 */
function generate_alternatives(decision_point, category = null) {
  // Auto-detect category if not provided
  if (!category) {
    category = identify_category(decision_point);
  }
  
  // Default to architecture if still not found
  const alternativeCategory = category || 'architecture';
  
  // Get templates for this category
  const alternatives = alternative_templates[alternativeCategory] || 
                       alternative_templates.architecture;
  
  // Score each alternative based on typical criteria
  const scoredAlternatives = alternatives.map(alt => ({
    ...alt,
    score: calculate_score(alt, decision_point)
  }));
  
  // Sort by score (highest first)
  scoredAlternatives.sort((a, b) => b.score - a.score);
  
  return {
    decision_point: decision_point,
    category: alternativeCategory,
    alternatives: scoredAlternatives,
    recommended: scoredAlternatives[0]
  };
}

/**
 * Calculate a score for an alternative (simple heuristic)
 * @param {Object} alternative - Alternative object with pros and cons
 * @param {string} context - The decision context
 * @returns {number} - Score out of 100
 */
function calculate_score(alternative, context) {
  let score = 50; // Base score
  
  // Add points for pros
  score += alternative.pros.length * 10;
  
  // Subtract points for cons
  score -= alternative.cons.length * 5;
  
  // Bonus for "simple" approaches in lightweight projects
  const lowerContext = context.toLowerCase();
  if (lowerContext.includes('rápido') || lowerContext.includes('simple') || lowerContext.includes('prototipo')) {
    if (alternative.name === 'Monolítico' || alternative.name === 'JSON/Archivo plano') {
      score += 15;
    }
  }
  
  // Penalty for complex solutions in simple contexts
  const complexNames = ['gRPC', 'GraphQL', 'NoSQL', 'Contract tests', 'Distributed'];
  for (const name of complexNames) {
    if (alternative.name.includes(name) && !lowerContext.includes('complejo') && !lowerContext.includes('alta carga')) {
      score -= 10;
    }
  }
  
  // Clamp score between 0 and 100
  return Math.max(0, Math.min(100, score));
}

/**
 * Generate alternatives for multiple assumptions
 * @param {Array} assumptions - Array of assumption objects
 * @returns {Object} - Map of assumption -> alternatives
 */
function generate_all_alternatives(assumptions) {
  const results = {
    total_alternatives: 0,
    by_assumption: []
  };
  
  for (const assumption of assumptions) {
    const alternatives = generate_alternatives(assumption.text, assumption.category);
    
    results.by_assumption.push({
      assumption_text: assumption.text,
      category: assumption.category,
      alternatives: alternatives.alternatives,
      recommended: alternatives.recommended.name
    });
    
    results.total_alternatives += alternatives.alternatives.length;
  }
  
  return results;
}

/**
 * Compare two alternatives in detail
 * @param {string} decision - Decision being made
 * @param {Object} altA - First alternative
 * @param {Object} altB - Second alternative
 * @returns {Object} - Comparison matrix
 */
function compare_alternatives(decision, altA, altB) {
  const criteria = ['pros', 'cons', 'complexity', 'maintenance', 'performance', 'learning_curve'];
  
  const comparison = {
    decision: decision,
    alternatives: {
      A: altA.name,
      B: altB.name
    },
    matrix: {}
  };
  
  // Simple comparison based on pros/cons count
  comparison.matrix.complexity = {
    A: altA.cons.length,
    B: altB.cons.length,
    winner: altA.cons.length <= altB.cons.length ? 'A' : 'B'
  };
  
  comparison.matrix.maintenance = {
    A: altA.pros.filter(p => p.includes('fácil') || p.includes('simple')).length,
    B: altB.pros.filter(p => p.includes('fácil') || p.includes('simple')).length,
    winner: altA.pros.filter(p => p.includes('fácil') || p.includes('simple')).length >= 
            altB.pros.filter(p => p.includes('fácil') || p.includes('simple')).length ? 'A' : 'B'
  };
  
  return comparison;
}

module.exports = {
  generate_alternatives,
  generate_all_alternatives,
  compare_alternatives,
  identify_category
};