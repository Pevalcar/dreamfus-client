/**
 * Tests for alternatives module
 */

const { 
  generate_alternatives, 
  generate_all_alternatives,
  compare_alternatives,
  identify_category
} = require('../src/alternatives.js');

describe('identify_category', () => {
  test('should identify data_storage category for storage keywords', () => {
    expect(identify_category('usar PostgreSQL para almacenamiento')).toBe('data_storage');
    expect(identify_category('base de datos relacional')).toBe('data_storage');
  });

  test('should identify api_design category for API keywords', () => {
    expect(identify_category('diseñar la API REST')).toBe('api_design');
    expect(identify_category('endpoint de login')).toBe('api_design');
  });

  test('should identify architecture category for architectural keywords', () => {
    expect(identify_category('arquitectura monolítica')).toBe('architecture');
    expect(identify_category('servicio de autenticación')).toBe('architecture');
  });

  test('should identify testing category for test keywords', () => {
    expect(identify_category('pruebas unitarias')).toBe('testing');
    expect(identify_category('test de integración')).toBe('testing');
  });

  test('should return null for unknown keywords', () => {
    expect(identify_category('algo random')).toBeNull();
  });
});

describe('generate_alternatives', () => {
  test('should generate alternatives for architecture decisions', () => {
    const result = generate_alternatives('Decidir arquitectura del sistema', 'architecture');
    
    expect(result.decision_point).toBe('Decidir arquitectura del sistema');
    expect(result.category).toBe('architecture');
    expect(result.alternatives.length).toBeGreaterThan(0);
    expect(result.alternatives[0].name).toBeDefined();
  });

  test('should auto-detect category if not provided', () => {
    const result = generate_alternatives('usar base de datos relacional');
    
    expect(result.category).toBe('data_storage');
  });

  test('should provide recommendation', () => {
    const result = generate_alternatives('diseñar API');
    
    expect(result.recommended).toBeDefined();
    expect(result.recommended.name).toBeDefined();
  });

  test('should score alternatives', () => {
    const result = generate_alternatives('decisión técnica');
    
    result.alternatives.forEach(alt => {
      expect(alt.score).toBeGreaterThanOrEqual(0);
      expect(alt.score).toBeLessThanOrEqual(100);
    });
  });
});

describe('generate_all_alternatives', () => {
  test('should process multiple assumptions', () => {
    const assumptions = [
      { text: 'usar PostgreSQL', line: 5, severity: 'medium', category: 'data' },
      { text: 'API REST', line: 10, severity: 'low', category: 'integration' }
    ];
    
    const result = generate_all_alternatives(assumptions);
    
    expect(result.total_alternatives).toBeGreaterThan(0);
    expect(result.by_assumption.length).toBe(2);
  });

  test('should include recommended alternative for each', () => {
    const assumptions = [
      { text: 'decisión técnica', line: 1, severity: 'high', category: 'general' }
    ];
    
    const result = generate_all_alternatives(assumptions);
    
    expect(result.by_assumption[0].recommended).toBeDefined();
  });
});

describe('compare_alternatives', () => {
  test('should compare two architectural alternatives', () => {
    const altA = {
      name: 'Monolítico',
      pros: ['Simple', 'Rápido'],
      cons: ['No escalable']
    };
    const altB = {
      name: 'Microservicios',
      pros: ['Escalable'],
      cons: ['Complejo', 'Lento']
    };
    
    const result = compare_alternatives('arquitectura', altA, altB);
    
    expect(result.decision).toBe('arquitectura');
    expect(result.alternatives.A).toBe('Monolítico');
    expect(result.alternatives.B).toBe('Microservicios');
    expect(result.matrix.complexity.winner).toBeDefined();
  });
});