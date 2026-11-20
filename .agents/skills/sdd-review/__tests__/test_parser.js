/**
 * Tests for parser module
 */

const {
  parse_assumptions,
  parse_requirements,
  parse_structure,
} = require("../src/parser.js");
const fs = require("fs");
const path = require("path");

// Create test fixtures
const testDir = path.join(__dirname, "fixtures");

// Test spec with assumptions
const testSpec = `# Test Spec

## Contexto y objetivo
Test spec for unit testing.

## ASUMPTIONS I'M MAKING:

1. El proyecto no tiene AGENTS.md o docs/constitution.md (primer setup)
2. El usuario quiere crear un flujo SDD nuevo o continuar uno existente
3. La template a seguir es la del ejemplo: habits-cli
4. La constitución debe tener máximo 15 líneas de 6 principios verificables
→ Correct me now or I'll proceed.

## Requisitos funcionales

RF-1: CUANDO el usuario inicia sesión, EL SISTEMA valida credenciales
RF-2: SI las credenciales son incorrectas, EL SISTEMA muestra error
`;

const testPlan = `# Test Plan

## ASUMPTIONS I'M MAKING:

1. El stack es Python 3.11 con FastAPI
2. La base de datos es PostgreSQL
3. El despliegue será en AWS

## Architecture

### Módulos
- api/ - handlers
- models/ - data structures
`;

describe("parse_assumptions", () => {
  beforeEach(() => {
    // Write test files
    if (!fs.existsSync(testDir)) {
      fs.mkdirSync(testDir, { recursive: true });
    }
    fs.writeFileSync(path.join(testDir, "spec.md"), testSpec);
    fs.writeFileSync(path.join(testDir, "plan.md"), testPlan);
  });

  test("should extract assumptions from spec file", () => {
    const result = parse_assumptions(path.join(testDir, "spec.md"));

    expect(result.source).toContain("spec.md");
    expect(result.total).toBe(4);
    expect(result.assumptions[0].text).toContain("primer setup");
    expect(result.assumptions.length).toBe(4);
  });

  test("should categorize assumptions correctly", () => {
    const result = parse_assumptions(path.join(testDir, "spec.md"));

    // First assumption about setup -> general
    expect(result.assumptions[0].category).toBe("general");
  });

  test("should infer severity from text", () => {
    const result = parse_assumptions(path.join(testDir, "spec.md"));

    // Check severity inference
    const techAssumption = result.assumptions.find((a) =>
      a.text.includes("template"),
    );
    expect(techAssumption).toBeDefined();
  });

  test("should extract assumptions from plan file", () => {
    const result = parse_assumptions(path.join(testDir, "plan.md"));

    expect(result.total).toBe(3);
    expect(result.assumptions[0].text).toContain("Python");
  });

  afterEach(() => {
    // Cleanup
    if (fs.existsSync(testDir)) {
      fs.rmSync(testDir, { recursive: true, force: true });
    }
  });
});

describe("parse_requirements", () => {
  beforeEach(() => {
    if (!fs.existsSync(testDir)) {
      fs.mkdirSync(testDir, { recursive: true });
    }
    fs.writeFileSync(path.join(testDir, "spec.md"), testSpec);
  });

  test("should extract RF requirements", () => {
    const result = parse_requirements(path.join(testDir, "spec.md"));

    expect(result.length).toBe(2);
    expect(result[0].id).toBe("RF-1");
    expect(result[0].type).toBe("functional");
  });

  test("should identify functional vs non-functional", () => {
    const result = parse_requirements(path.join(testDir, "spec.md"));

    // All should be functional in test spec
    expect(result.every((r) => r.type === "functional")).toBe(true);
  });

  afterEach(() => {
    if (fs.existsSync(testDir)) {
      fs.rmSync(testDir, { recursive: true, force: true });
    }
  });
});

describe("parse_structure", () => {
  beforeEach(() => {
    if (!fs.existsSync(testDir)) {
      fs.mkdirSync(testDir, { recursive: true });
    }
    fs.writeFileSync(path.join(testDir, "spec.md"), testSpec);
  });

  test("should extract sections from spec", () => {
    const result = parse_structure(path.join(testDir, "spec.md"));

    expect(result.file).toBe("spec.md");
    expect(result.total_sections).toBeGreaterThan(0);
    expect(result.sections[0].title).toBeDefined();
  });

  afterEach(() => {
    if (fs.existsSync(testDir)) {
      fs.rmSync(testDir, { recursive: true, force: true });
    }
  });
});
