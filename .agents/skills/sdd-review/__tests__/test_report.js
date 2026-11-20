/**
 * Tests for report module
 */

const { 
  generate_report, 
  generate_comparison_report,
  generate_summary,
  escape_md
} = require('../src/report.js');

describe('escape_md', () => {
  test('should escape asterisks', () => {
    expect(escape_md('test*multiple*')).toBe('test\\*multiple\\*');
  });

  test('should escape equals signs', () => {
    expect(escape_md('a=b')).toBe('a\\=b');
  });

  test('should escape brackets', () => {
    expect(escape_md('[not a link]')).toBe('\\[not a link\\]');
  });
});

describe('generate_report', () => {
  const mockReviewData = {
    assumptions: {
      total: 3,
      assumptions: [
        { text: 'Test assumption 1', line: 5, severity: 'high', category: 'general' },
        { text: 'Test assumption 2', line: 10, severity: 'medium', category: 'tech' },
        { text: 'Test assumption 3', line: 15, severity: 'low', category: 'data' }
      ]
    },
    doubts: {
      total_questions: 9,
      by_assumption: [
        {
          assumption_text: 'Test assumption 1',
          questions: [{ text: '¿Qué pasa si...?', context: {} }]
        }
      ]
    },
    alternatives: {
      total_alternatives: 6,
      by_assumption: []
    }
  };

  test('should generate markdown report', () => {
    const report = generate_report(mockReviewData, '/path/to/spec.md');
    
    expect(report).toContain('# SDD Review Report');
    expect(report).toContain('## Summary');
    expect(report).toContain('## Assumptions Detected');
    expect(report).toContain('Total assumptions detected: 3');
  });

  test('should include spec and plan paths', () => {
    const report = generate_report(mockReviewData, '/path/to/spec.md', '/path/to/plan.md');
    
    expect(report).toContain('**Source:** /path/to/spec.md');
    expect(report).toContain('**Plan:** /path/to/plan.md');
  });

  test('should format assumptions table correctly', () => {
    const report = generate_report(mockReviewData, '/path/to/spec.md');
    
    expect(report).toContain('| # | Texto | Severidad | Categoría | Línea |');
    expect(report).toContain('Test assumption 1');
    expect(report).toContain('high');
    expect(report).toContain('general');
  });

  test('should handle empty assumptions', () => {
    const emptyData = {
      assumptions: { total: 0, assumptions: [] },
      doubts: { total_questions: 0, by_assumption: [] },
      alternatives: { total_alternatives: 0, by_assumption: [] }
    };
    
    const report = generate_report(emptyData, '/path/to/spec.md');
    
    expect(report).toContain('# SDD Review Report');
  });
});

describe('generate_summary', () => {
  test('should generate quick summary', () => {
    const reviewData = {
      assumptions: {
        total: 5,
        assumptions: [
          { text: 'a', severity: 'high' },
          { text: 'b', severity: 'high' },
          { text: 'c', severity: 'medium' }
        ]
      },
      doubts: { total_questions: 10 },
      alternatives: { total_alternatives: 3 }
    };
    
    const summary = generate_summary(reviewData);
    
    expect(summary).toContain('Assumptions: 5');
    expect(summary).toContain('Questions: 10');
    expect(summary).toContain('Alternatives: 3');
    expect(summary).toContain('High severity: 2');
  });
});

describe('generate_comparison_report', () => {
  test('should generate comparison report', () => {
    const alternatives = [
      {
        assumption_text: 'Decisión sobre base de datos',
        alternatives: [
          { name: 'PostgreSQL', score: 85, pros: ['Reliable'], cons: ['Slow'] },
          { name: 'MongoDB', score: 75, pros: ['Fast'], cons: ['No transactions'] }
        ]
      }
    ];
    
    const report = generate_comparison_report(alternatives);
    
    expect(report).toContain('# Alternative Comparison');
    expect(report).toContain('Decisión sobre base de datos');
    expect(report).toContain('PostgreSQL');
    expect(report).toContain('MongoDB');
  });
});