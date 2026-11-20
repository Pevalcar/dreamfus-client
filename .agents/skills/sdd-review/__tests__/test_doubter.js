/**
 * Tests for doubter module
 */

const {
  generate_doubt_questions,
  generate_all_doubts,
  generate_alternative_challenges,
} = require("../src/doubter.js");

describe("generate_doubt_questions", () => {
  test("should generate questions for an assumption", () => {
    const assumption = "El proyecto no tiene AGENTS.md o docs/constitution.md";
    const questions = generate_doubt_questions(assumption, "general");

    expect(questions.length).toBeGreaterThanOrEqual(3);
    expect(questions[0].text).toBeDefined();
  });

  test("should generate scope-related questions for scope assumptions", () => {
    const assumption = "El alcance del proyecto incluye todos los features";
    const questions = generate_doubt_questions(assumption, "scope");

    const hasScopeQuestion = questions.some((q) =>
      q.text.toLowerCase().includes("scope"),
    );
    expect(hasScopeQuestion).toBe(true);
  });

  test("should generate tech-related questions for tech assumptions", () => {
    const assumption = "Usaremos React para la interfaz de usuario";
    const questions = generate_doubt_questions(assumption, "tech");

    expect(questions.length).toBeGreaterThanOrEqual(2);
  });

  test("should include context in questions", () => {
    const assumption = "El stack mínimo necesario es Python";
    const questions = generate_doubt_questions(assumption);

    expect(questions[0].context).toBeDefined();
    expect(questions[0].context.assumption).toBe(assumption);
  });
});

describe("generate_all_doubts", () => {
  test("should process multiple assumptions", () => {
    const assumptions = [
      {
        text: "El proyecto no tiene AGENTS.md",
        line: 5,
        severity: "high",
        category: "general",
      },
      {
        text: "Usaremos Python 3.11",
        line: 10,
        severity: "medium",
        category: "tech",
      },
      {
        text: "La base de datos es PostgreSQL",
        line: 15,
        severity: "low",
        category: "data",
      },
    ];

    const result = generate_all_doubts(assumptions);

    expect(result.total_questions).toBeGreaterThan(0);
    expect(result.by_assumption.length).toBe(3);
    expect(result.by_assumption[0].question_count).toBeGreaterThan(0);
  });

  test("should include severity in output", () => {
    const assumptions = [
      { text: "Test", line: 1, severity: "high", category: "general" },
    ];

    const result = generate_all_doubts(assumptions);

    expect(result.by_assumption[0].severity).toBe("high");
  });
});

describe("generate_alternative_challenges", () => {
  test("should generate capacity challenges for time assumptions", () => {
    const assumptions = [
      {
        text: "El tiempo estimado es de 2 semanas",
        line: 1,
        severity: "medium",
        category: "general",
      },
    ];

    const challenges = generate_alternative_challenges(assumptions);

    expect(challenges.length).toBeGreaterThan(0);
    expect(challenges[0].type).toBe("capacity");
  });

  test("should generate lock-in challenges for tech assumptions", () => {
    const assumptions = [
      {
        text: "Usaremos React para la interfaz",
        line: 1,
        severity: "low",
        category: "tech",
      },
    ];

    const challenges = generate_alternative_challenges(assumptions);

    expect(challenges.some((c) => c.type === "lock_in")).toBe(true);
  });

  test("should handle empty assumptions", () => {
    const challenges = generate_alternative_challenges([]);

    expect(challenges).toBeInstanceOf(Array);
    expect(challenges.length).toBe(0);
  });
});
