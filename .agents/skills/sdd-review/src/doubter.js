/**
 * Doubt generator for SDD review
 * Generates adversarial questions to validate assumptions
 */

const doubt_templates = {
  scope: [
    '¿Qué pasa si el scope crece más de lo esperado?',
    '¿Hay funcionalidades no mencionadas que deberían estar incluidas?',
    '¿Qué se hace si la integración con <dependency> falla?',
    '¿Hay requisitos no declarados del negocio?',
    '¿El tiempo estimado es realista o hay presión forzando suposiciones?'
  ],
  tech: [
    '¿Existe una alternativa más simple o con menor complejidad?',
    '¿Hay algún trade-off no documentado (performance vs simplicidad)?',
    '¿Esta decisión técnica está validada con datos o es por intuición?',
    '¿Hay un stack o herramienta alternativo que hubiera sido mejor?',
    '¿Esta dependencia es realmente necesaria o una over-engineering?'
  ],
  data: [
    '¿Qué pasa si los datos de entrada son invalídos o incompletos?',
    '¿Hay casos de unicidad o colisión que no manejamos?',
    '¿Qué pasa si hay crecimiento exponencial de datos?',
    '¿La estructura de datos elegida escala con los requerimientos?',
    '¿Hay formas de datos alternativas que necesitemos?'
  ],
  integration: [
    '¿Qué pasa si el endpoint externo está caído?',
    '¿Hay un plan de fallback o circuit breaker?',
    '¿Las APIs externas están versionadas o pueden romper?',
    '¿Qué pasa si hay rate limiting en los servicios externos?',
    '¿La autenticación con este servicio es robusta?'
  ],
  edge_case: [
    '¿Qué pasa con datos nulos o vacíos?',
    '¿Hay un límite máximo de entradas que no está claro?',
    '¿Qué pasa si hay dos usuarios concurrentes?',
    '¿Cómo manejamos el error si la base de datos se corrompe?',
    '¿Qué pasa en modo offline o sin conexión?'
  ]
};

const assumption_keywords = {
  'proporcionar': ['funcionalidad', 'capacidad', 'método', 'api'],
  'usar': ['tecnología', 'lenguaje', 'framework', 'servicio', 'api'],
  'implementar': ['lógica', 'algoritmo', 'estructura', 'modelo'],
  'guardar': ['persistencia', 'almacenamiento', 'base de datos', 'archivo'],
  'validar': ['entrada', 'datos', 'usuario', 'token', 'sesión'],
  'comunicicar': ['servicio', 'api', 'endpoint', 'cliente'],
  'optimizar': ['rendimiento', 'velocidad', 'caché', 'memoria'],
  'restringir': ['acceso', 'permisos', 'roles', 'seguridad']
};

/**
 * Generate doubt questions for an assumption
 * @param {string} assumption - The assumption text
 * @param {string} category - Category of assumption (tech, scope, data, integration)
 * @returns {Array} - Array of doubt questions
 */
function generate_doubt_questions(assumption, category = 'general') {
  const questions = [];
  const lowerAssumption = assumption.toLowerCase();
  
  // Use category-based templates
  const templates = doubt_templates[category] || doubt_templates.scope;
  
  // Pick 2-3 relevant templates
  const selectedTemplates = templates.slice(0, Math.min(3, templates.length));
  
  for (const template of selectedTemplates) {
    questions.push({
      text: template,
      context: { assumption: assumption, category: category }
    });
  }
  
  // Check for keyword-based doubts
  for (const [keyword, relatedTerms] of Object.entries(assumption_keywords)) {
    if (lowerAssumption.includes(keyword)) {
      for (const term of relatedTerms.slice(0, 2)) {
        if (!lowerAssumption.includes(term)) {
          questions.push({
            text: `¿Has considerado el caso donde ${term} es relevante?`,
            context: { 
              assumption: assumption, 
              keyword: keyword,
              related_term: term 
            }
          });
        }
      }
    }
  }
  
  // Generic doubt for assumptions without specific keywords
  if (questions.length < 3) {
    questions.push({
      text: '¿Qué evidencia respalda esta suposición?',
      context: { assumption: assumption, type: 'evidence_check' }
    });
  }
  
  return questions;
}

/**
 * Generate all doubt questions for a set of assumptions
 * @param {Array} assumptions - Array of assumption objects
 * @returns {Object} - Object with assumption ID and questions
 */
function generate_all_doubts(assumptions) {
  const results = {
    total_questions: 0,
    by_assumption: []
  };
  
  for (const assumption of assumptions) {
    const questions = generate_doubt_questions(assumption.text, assumption.category);
    
    results.by_assumption.push({
      assumption_text: assumption.text,
      line: assumption.line,
      severity: assumption.severity,
      category: assumption.category,
      questions: questions,
      question_count: questions.length
    });
    
    results.total_questions += questions.length;
  }
  
  return results;
}

/**
 * Generate specific challenges for common assumption pitfalls
 * @param {Array} assumptions - Array of assumptions
 * @returns {Array} - Array of challenge objects
 */
function generate_alternative_challenges(assumptions) {
  const challenges = [];
  
  const assumption_texts = assumptions.map(a => a.text.toLowerCase()).join(' ');
  
  // Challenge: Assumption about team capacity
  if (assumption_texts.includes('tiempo') || assumption_texts.includes('desarrollo')) {
    challenges.push({
      type: 'capacity',
      assumption: 'El tiempo estimado es realista',
      challenge: '¿Qué pasa si hay imprevistos o re-trabajo?',
      alternative_question: '¿Has considerado un margen de seguridad del 30%?'
    });
  }
  
  // Challenge: Technology lock-in
  if (assumption_texts.includes('usar') || assumption_texts.includes('tecnología')) {
    challenges.push({
      type: 'lock_in',
      assumption: 'La tecnología elegida es la adecuada',
      challenge: '¿Podrías implementar esto con la mitad de dependencias?',
      alternative_question: '¿Qué pasaría si eliminas esta dependencia?'
    });
  }
  
  // Challenge: Scope creep
  if (assumption_texts.includes('funcionalidad') || assumption_texts.includes('requerimiento')) {
    challenges.push({
      type: 'scope',
      assumption: 'El scope está bien definido',
      challenge: '¿Cómo manejas funcionalidades no planeadas?',
      alternative_question: '¿Tienes un proceso para rechazar scope creep?'
    });
  }
  
  return challenges;
}

module.exports = {
  generate_doubt_questions,
  generate_all_doubts,
  generate_alternative_challenges
};