// Validation for NexLearn adventure spec v2.
//
// Gemini writes a "generation format" (separate evidence list, puzzles that
// carry their own position, and a door). normalizeAdventureV2() validates it
// and converts it into the engine format that lib/game/spec/adventure_spec.dart
// expects (a flat list of entities plus a list of puzzles). It is deliberately
// strict: the server must never return something the engine cannot play.

export const SUPPORTED_MECHANICS = [
  "codeLock",
  "sequence",
  "matching",
  "choice",
] as const;
export type MechanicType = typeof SUPPORTED_MECHANICS[number];

export const ENTITY_TYPES = ["evidence", "puzzle", "door"] as const;
export type EntityType = typeof ENTITY_TYPES[number];

export const TEXT_LIMITS = {
  title: 100,
  story: 700,
  learningSummary: 300,
  environmentName: 80,
  entityName: 60,
  entityText: 300,
  lockedText: 180,
  prompt: 300,
  feedback: 250,
  hint: 200,
  skill: 80,
  choice: 60,
};

export const POINT_RANGE = {minX: 0.08, maxX: 0.92, minY: 0.12, maxY: 0.88};

export const OBSTACLE_RANGE = {
  minX: 0.05,
  maxX: 0.85,
  minY: 0.12,
  maxY: 0.82,
  minWidth: 0.04,
  maxWidth: 0.3,
  minHeight: 0.02,
  maxHeight: 0.12,
  rightEdge: 0.95,
  bottomEdge: 0.92,
};

export const COUNTS = {
  minEvidence: 3,
  maxEvidence: 6,
  minPuzzles: 2,
  maxPuzzles: 5,
  maxObstacles: 8,
  minSequenceItems: 3,
  maxSequenceItems: 6,
  minMatchingPairs: 3,
  maxMatchingPairs: 5,
};

const KEEP_OUT_MARGIN = 0.06;
const MIN_ENTITY_DISTANCE = 0.09;
const DOOR_KEY = "#door";
const DEFAULT_LOCKED_TEXT = "Something is still missing. Keep investigating.";
const DEFAULT_COLORS = {
  floorColor: "#EDE9FE",
  wallColor: "#B9A3EC",
  accentColor: "#7C3AED",
};
const UNSAFE_TEXT = /https?:\/\/|www\.|<\/?[a-z][^>]*>|```|javascript:/i;

// ---------------------------------------------------------------------------
// Types (engine format, returned to Flutter)
// ---------------------------------------------------------------------------
export type Point = {x: number; y: number};
export type Obstacle = Point & {width: number; height: number};

export type PuzzleConfig = {
  answer?: string;
  items?: string[];
  pairs?: {left: string; right: string}[];
  options?: string[];
  correctIndex?: number;
};

export type EntitySpec = Point & {
  id: string;
  type: EntityType;
  name: string;
  text: string;
  requires: string[];
  lockedText: string;
  puzzleId?: string;
};

export type PuzzleSpec = {
  id: string;
  type: MechanicType;
  prompt: string;
  config: PuzzleConfig;
  feedbackCorrect: string;
  feedbackWrong: string;
  hint: string;
  skill: string;
};

export type AdventureSpecV2 = {
  specVersion: 2;
  title: string;
  story: string;
  learningSummary: string;
  environment: {
    name: string;
    floorColor: string;
    wallColor: string;
    accentColor: string;
  };
  spawn: Point;
  obstacles: Obstacle[];
  entities: EntitySpec[];
  puzzles: PuzzleSpec[];
  finalPuzzleId: string;
};

export type Report = {
  // Problems that cannot be repaired. Any issue rejects the adventure.
  issues: string[];
  // Small automatic fixes.
  repairs: string[];
};

export type NormalizeResult = Report & {spec: AdventureSpecV2 | null};

// Internal shapes used while validating the generation format.
type Node = Point & {
  id: string;
  name: string;
  text: string;
  lockedText: string;
  requires: string[];
};
type PuzzleItem = {puzzle: PuzzleSpec; place: Node};
type DoorNode = Point & {name: string; text: string; lockedText: string};

// ---------------------------------------------------------------------------
// Basic helpers
// ---------------------------------------------------------------------------

/**
 * Checks whether a value is a non-null, non-array object.
 * @param {unknown} value - The value to inspect.
 * @return {boolean} Whether the value is a record.
 */
export function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" &&
    value !== null &&
    !Array.isArray(value);
}

/**
 * Restricts a number to a range.
 * @param {number} value - The number to restrict.
 * @param {number} min - The lowest allowed value.
 * @param {number} max - The highest allowed value.
 * @return {number} The restricted number.
 */
function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max);
}

/**
 * Shortens text to fit a limit, preferring to end at a full sentence.
 * @param {string} text - Whitespace-normalized text.
 * @param {number} max - The maximum length.
 * @return {string} Text no longer than max characters.
 */
function shorten(text: string, max: number): string {
  const slice = text.slice(0, max);
  const sentenceEnd = /[.!?](?=\s|$)/g;
  let lastEnd = -1;
  let match: RegExpExecArray | null = sentenceEnd.exec(slice);

  while (match !== null) {
    lastEnd = match.index;
    match = sentenceEnd.exec(slice);
  }

  if (lastEnd >= max * 0.5) return slice.slice(0, lastEnd + 1);

  const lastSpace = slice.lastIndexOf(" ", max - 1);
  const cut = lastSpace > 0 ?
    slice.slice(0, lastSpace) :
    slice.slice(0, max - 1);
  return cut.replace(/[\s,;:]+$/, "") + "…";
}

/**
 * Returns a shuffled copy of a list.
 * @param {T[]} list - The list to shuffle.
 * @return {T[]} A new shuffled list.
 */
function shuffled<T>(list: T[]): T[] {
  const copy = [...list];
  for (let i = copy.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [copy[i], copy[j]] = [copy[j], copy[i]];
  }
  return copy;
}

/**
 * Checks that all strings differ, ignoring case.
 * @param {string[]} list - The strings to compare.
 * @return {boolean} Whether all strings are unique.
 */
function allDistinct(list: string[]): boolean {
  return new Set(list.map((s) => s.toLowerCase())).size === list.length;
}

// ---------------------------------------------------------------------------
// Field readers
// ---------------------------------------------------------------------------

/**
 * Reads a required record, recording an issue if it is missing.
 * @param {Report} report - Collects issues and repairs.
 * @param {string} path - Field path used in diagnostics.
 * @param {unknown} value - The value to read.
 * @return {Record<string, unknown>} The record, or an empty object.
 */
function readRecord(
  report: Report,
  path: string,
  value: unknown,
): Record<string, unknown> {
  if (isRecord(value)) return value;
  report.issues.push(`${path}: missing or not an object`);
  return {};
}

/**
 * Reads required text, shortening it if too long and rejecting links,
 * markup, and code.
 * @param {Report} report - Collects issues and repairs.
 * @param {string} path - Field path used in diagnostics.
 * @param {unknown} value - The value to read.
 * @param {number} max - The maximum permitted length.
 * @return {string} The text, or an empty string if invalid.
 */
function readText(
  report: Report,
  path: string,
  value: unknown,
  max: number,
): string {
  if (typeof value !== "string" || value.trim().length === 0) {
    report.issues.push(`${path}: missing or empty text`);
    return "";
  }

  const clean = value.replace(/\s+/g, " ").trim();

  if (UNSAFE_TEXT.test(clean)) {
    report.issues.push(`${path}: contains a link, markup, or code`);
    return "";
  }

  if (clean.length <= max) return clean;

  report.repairs.push(`${path}: shortened from ${clean.length} to ${max}`);
  return shorten(clean, max);
}

/**
 * Reads optional text, using a fallback when it is missing.
 * @param {Report} report - Collects issues and repairs.
 * @param {string} path - Field path used in diagnostics.
 * @param {unknown} value - The value to read.
 * @param {number} max - The maximum permitted length.
 * @param {string} fallback - Text to use when the value is missing.
 * @return {string} The text or the fallback.
 */
function readOptionalText(
  report: Report,
  path: string,
  value: unknown,
  max: number,
  fallback: string,
): string {
  if (typeof value !== "string" || value.trim().length === 0) {
    return fallback;
  }
  return readText(report, path, value, max);
}

/**
 * Reads a number and moves it into range if it is outside.
 * @param {Report} report - Collects issues and repairs.
 * @param {string} path - Field path used in diagnostics.
 * @param {unknown} value - The value to read.
 * @param {number} min - The lowest allowed value.
 * @param {number} max - The highest allowed value.
 * @return {number} The number inside the range.
 */
function readNumber(
  report: Report,
  path: string,
  value: unknown,
  min: number,
  max: number,
): number {
  if (typeof value !== "number" || !Number.isFinite(value)) {
    report.issues.push(`${path}: missing or not a number`);
    return min;
  }

  if (value < min || value > max) {
    report.repairs.push(`${path}: ${value} moved into ${min}-${max}`);
    return clamp(value, min, max);
  }

  return value;
}

/**
 * Reads x and y game coordinates, moving them inside the playable room.
 * @param {Report} report - Collects issues and repairs.
 * @param {string} path - Field path used in diagnostics.
 * @param {Record<string, unknown>} source - Object holding x and y.
 * @return {Point} A valid point.
 */
function readPoint(
  report: Report,
  path: string,
  source: Record<string, unknown>,
): Point {
  return {
    x: readNumber(
      report, `${path}.x`, source.x, POINT_RANGE.minX, POINT_RANGE.maxX),
    y: readNumber(
      report, `${path}.y`, source.y, POINT_RANGE.minY, POINT_RANGE.maxY),
  };
}

/**
 * Reads a six-digit hex color, fixing common formatting slips.
 * @param {Report} report - Collects issues and repairs.
 * @param {string} path - Field path used in diagnostics.
 * @param {unknown} value - The value to read.
 * @param {string} fallback - The color to use if the value is unusable.
 * @return {string} A color such as "#7C3AED".
 */
function readColor(
  report: Report,
  path: string,
  value: unknown,
  fallback: string,
): string {
  if (typeof value === "string") {
    let hex = value.trim().replace(/^#/, "");

    if (/^[0-9A-Fa-f]{3}$/.test(hex)) {
      hex = hex.split("").map((c) => c + c).join("");
    }

    if (/^[0-9A-Fa-f]{6}$/.test(hex)) {
      const color = `#${hex.toUpperCase()}`;
      if (color !== value) report.repairs.push(`${path}: color reformatted`);
      return color;
    }
  }

  report.repairs.push(`${path}: invalid color replaced with default`);
  return fallback;
}

/**
 * Reads an id. Ids are never auto-repaired because other fields refer to
 * them, so a bad or duplicate id rejects the adventure.
 * @param {Report} report - Collects issues and repairs.
 * @param {string} path - Field path used in diagnostics.
 * @param {unknown} value - The value to read.
 * @param {Set<string>} used - Ids already taken.
 * @return {string} The id, or an empty string if invalid.
 */
function readStrictId(
  report: Report,
  path: string,
  value: unknown,
  used: Set<string>,
): string {
  const id = typeof value === "string" ? value.trim() : "";

  if (!/^[A-Za-z0-9_]{1,40}$/.test(id)) {
    report.issues.push(`${path}: id must be 1-40 letters, digits, or _`);
    return "";
  }

  if (used.has(id)) {
    report.issues.push(`${path}: duplicate id "${id}"`);
    return id;
  }

  used.add(id);
  return id;
}

/**
 * Reads a "requires" list of ids.
 * @param {Report} report - Collects issues and repairs.
 * @param {string} path - Field path used in diagnostics.
 * @param {unknown} value - The raw value.
 * @return {string[]} The ids.
 */
function readRequires(
  report: Report,
  path: string,
  value: unknown,
): string[] {
  if (Array.isArray(value)) {
    return value
      .filter((r: unknown): r is string => typeof r === "string")
      .map((r) => r.trim())
      .filter((r) => r.length > 0);
  }
  if (value !== undefined) {
    report.repairs.push(`${path}.requires: not a list, cleared`);
  }
  return [];
}

/**
 * Reads a list of short strings.
 * @param {Report} report - Collects issues and repairs.
 * @param {string} path - Field path used in diagnostics.
 * @param {unknown} value - The value to read.
 * @param {number} min - Minimum list length.
 * @param {number} max - Maximum list length.
 * @param {number} maxLength - Maximum length of each string.
 * @return {string[]} The strings.
 */
function readStringList(
  report: Report,
  path: string,
  value: unknown,
  min: number,
  max: number,
  maxLength: number,
): string[] {
  if (!Array.isArray(value)) {
    report.issues.push(`${path}: missing or not a list`);
    return [];
  }

  if (value.length < min || value.length > max) {
    report.issues.push(`${path}: needs ${min}-${max} items`);
  }

  return value.slice(0, max).map((item: unknown, index: number) =>
    readText(report, `${path}[${index}]`, item, maxLength));
}

// ---------------------------------------------------------------------------
// Mechanic configs. Keep in sync with lib/game/engine/mechanic_registry.dart
// ---------------------------------------------------------------------------

/**
 * Reads and validates a puzzle config for one mechanic type. Only the
 * fields that belong to the type are kept; anything else is ignored.
 * @param {Report} report - Collects issues and repairs.
 * @param {string} path - Field path used in diagnostics.
 * @param {MechanicType} type - The mechanic.
 * @param {unknown} value - The raw config.
 * @return {PuzzleConfig} The clean config.
 */
function readConfig(
  report: Report,
  path: string,
  type: MechanicType,
  value: unknown,
): PuzzleConfig {
  const raw = readRecord(report, path, value);

  switch (type) {
    case "codeLock": {
      let answer = raw.answer;
      if (typeof answer === "number" && Number.isInteger(answer)) {
        report.repairs.push(`${path}.answer: number converted to text`);
        answer = String(answer);
      }
      const text = typeof answer === "string" ? answer.trim() : "";
      if (!/^\d{1,6}$/.test(text)) {
        report.issues.push(`${path}.answer: must be 1-6 digits`);
        return {};
      }
      return {answer: text};
    }

    case "sequence": {
      const items = readStringList(
        report, `${path}.items`, raw.items,
        COUNTS.minSequenceItems, COUNTS.maxSequenceItems, TEXT_LIMITS.choice);
      if (!allDistinct(items)) {
        report.issues.push(`${path}.items: must all be different`);
      }
      return {items};
    }

    case "matching": {
      if (
        !Array.isArray(raw.pairs) ||
        raw.pairs.length < COUNTS.minMatchingPairs ||
        raw.pairs.length > COUNTS.maxMatchingPairs
      ) {
        report.issues.push(
          `${path}.pairs: needs ${COUNTS.minMatchingPairs}-` +
          `${COUNTS.maxMatchingPairs} pairs`);
        return {};
      }
      const pairs = raw.pairs.map((pair: unknown, index: number) => {
        const record = readRecord(report, `${path}.pairs[${index}]`, pair);
        return {
          left: readText(
            report, `${path}.pairs[${index}].left`,
            record.left, TEXT_LIMITS.choice),
          right: readText(
            report, `${path}.pairs[${index}].right`,
            record.right, TEXT_LIMITS.choice),
        };
      });
      if (
        !allDistinct(pairs.map((p) => p.left)) ||
        !allDistinct(pairs.map((p) => p.right))
      ) {
        report.issues.push(`${path}.pairs: each side must be unique`);
      }
      return {pairs};
    }

    case "choice": {
      if (!Array.isArray(raw.options)) {
        report.issues.push(`${path}.options: missing or not a list`);
        return {};
      }
      if (raw.options.length < 2 || raw.options.length > 4) {
        report.issues.push(`${path}.options: needs 2-4 options`);
      }

      const options: string[] = [];
      let correctIndex = -1;
      let correctCount = 0;
      const count = Math.min(raw.options.length, 4);

      for (let index = 0; index < count; index++) {
        const option: unknown = raw.options[index];
        const optionPath = `${path}.options[${index}]`;

        if (isRecord(option)) {
          options.push(readText(
            report, `${optionPath}.text`, option.text, TEXT_LIMITS.choice));
          if (option.isCorrect === true) {
            correctIndex = index;
            correctCount++;
          }
        } else {
          // Plain strings are accepted too (older format).
          options.push(
            readText(report, optionPath, option, TEXT_LIMITS.choice));
        }
      }

      // Older formats named the answer outside the options.
      if (correctCount === 0) {
        if (typeof raw.correctOption === "string") {
          const wanted =
            raw.correctOption.replace(/\s+/g, " ").trim().toLowerCase();
          const found = options.findIndex((o) => o.toLowerCase() === wanted);
          if (found >= 0) {
            correctIndex = found;
            correctCount = 1;
          }
        } else if (
          typeof raw.correctIndex === "number" &&
          Number.isInteger(raw.correctIndex) &&
          raw.correctIndex >= 0 &&
          raw.correctIndex < options.length
        ) {
          correctIndex = raw.correctIndex;
          correctCount = 1;
        }
      }

      if (correctCount !== 1) {
        report.issues.push(
          `${path}.options: exactly one option must have isCorrect true`);
        return {};
      }
      if (!allDistinct(options)) {
        report.issues.push(`${path}.options: must all be different`);
      }

      // Models tend to favor certain positions, so shuffle and remap.
      const correct = options[correctIndex];
      const mixed = shuffled(options);
      return {options: mixed, correctIndex: mixed.indexOf(correct)};
    }

    default:
      return {};
  }
}

// ---------------------------------------------------------------------------
// Section readers
// ---------------------------------------------------------------------------

/**
 * Reads the evidence list.
 * @param {Report} report - Collects issues and repairs.
 * @param {unknown} value - The raw evidence value.
 * @param {Set<string>} used - Ids already taken.
 * @return {Node[]} The evidence items.
 */
function readEvidence(
  report: Report,
  value: unknown,
  used: Set<string>,
): Node[] {
  if (!Array.isArray(value)) {
    report.issues.push("evidence: missing or not a list");
    return [];
  }

  if (value.length < COUNTS.minEvidence) {
    report.issues.push(
      `evidence: ${value.length} found, at least ${COUNTS.minEvidence} required`,
    );
  }

  if (value.length > COUNTS.maxEvidence) {
    report.repairs.push(
      `evidence: kept first ${COUNTS.maxEvidence} of ${value.length}`);
  }

  return value.slice(0, COUNTS.maxEvidence).map(
    (item: unknown, index: number): Node => {
      const path = `evidence[${index}]`;
      const raw = readRecord(report, path, item);
      const point = readPoint(report, path, raw);

      return {
        id: readStrictId(report, `${path}.id`, raw.id, used),
        name: readText(
          report, `${path}.name`, raw.name, TEXT_LIMITS.entityName),
        x: point.x,
        y: point.y,
        text: readText(
          report, `${path}.text`, raw.text, TEXT_LIMITS.entityText),
        lockedText: readOptionalText(
          report, `${path}.lockedText`, raw.lockedText,
          TEXT_LIMITS.lockedText, DEFAULT_LOCKED_TEXT),
        requires: readRequires(report, path, raw.requires),
      };
    });
}

/**
 * Reads the puzzle list. Each puzzle carries its own position in the room.
 * @param {Report} report - Collects issues and repairs.
 * @param {unknown} value - The raw puzzles value.
 * @param {Set<string>} used - Ids already taken.
 * @return {PuzzleItem[]} The puzzles and where they stand.
 */
function readPuzzles(
  report: Report,
  value: unknown,
  used: Set<string>,
): PuzzleItem[] {
  if (!Array.isArray(value)) {
    report.issues.push("puzzles: missing or not a list");
    return [];
  }

  if (value.length < COUNTS.minPuzzles) {
    report.issues.push(
      `puzzles: ${value.length} found, at least ${COUNTS.minPuzzles} required`,
    );
  }

  if (value.length > COUNTS.maxPuzzles) {
    report.repairs.push(
      `puzzles: kept first ${COUNTS.maxPuzzles} of ${value.length}`);
  }

  return value.slice(0, COUNTS.maxPuzzles).map(
    (item: unknown, index: number): PuzzleItem => {
      const path = `puzzles[${index}]`;
      const raw = readRecord(report, path, item);
      const id = readStrictId(report, `${path}.id`, raw.id, used);
      const type = SUPPORTED_MECHANICS.find((m) => m === raw.type);

      if (!type) {
        report.issues.push(
          `${path}.type: unsupported mechanic ` +
          `"${String(raw.type).slice(0, 30)}"`,
        );
      }

      const point = readPoint(report, path, raw);

      const puzzle: PuzzleSpec = {
        id,
        type: type ?? "choice",
        prompt: readText(
          report, `${path}.prompt`, raw.prompt, TEXT_LIMITS.prompt),
        config: type ?
          readConfig(report, `${path}.config`, type, raw.config) :
          {},
        feedbackCorrect: readText(
          report, `${path}.feedbackCorrect`,
          raw.feedbackCorrect, TEXT_LIMITS.feedback),
        feedbackWrong: readText(
          report, `${path}.feedbackWrong`,
          raw.feedbackWrong, TEXT_LIMITS.feedback),
        hint: readOptionalText(
          report, `${path}.hint`, raw.hint, TEXT_LIMITS.hint, ""),
        skill: readText(report, `${path}.skill`, raw.skill, TEXT_LIMITS.skill),
      };

      const place: Node = {
        id,
        name: readText(
          report, `${path}.name`, raw.name, TEXT_LIMITS.entityName),
        x: point.x,
        y: point.y,
        text: readText(
          report, `${path}.sceneText`, raw.sceneText, TEXT_LIMITS.entityText),
        lockedText: readOptionalText(
          report, `${path}.lockedText`, raw.lockedText,
          TEXT_LIMITS.lockedText, DEFAULT_LOCKED_TEXT),
        requires: readRequires(report, path, raw.requires),
      };

      return {puzzle, place};
    });
}

/**
 * Reads the exit door.
 * @param {Report} report - Collects issues and repairs.
 * @param {unknown} value - The raw door value.
 * @return {DoorNode} The door.
 */
function readDoor(report: Report, value: unknown): DoorNode {
  const raw = readRecord(report, "door", value);
  const point = readPoint(report, "door", raw);

  return {
    x: point.x,
    y: point.y,
    name: readText(report, "door.name", raw.name, TEXT_LIMITS.entityName),
    text: readText(report, "door.text", raw.text, TEXT_LIMITS.entityText),
    lockedText: readOptionalText(
      report, "door.lockedText", raw.lockedText,
      TEXT_LIMITS.lockedText, DEFAULT_LOCKED_TEXT),
  };
}

/**
 * Checks whether a point sits on or very near an obstacle.
 * @param {Obstacle} obstacle - The obstacle rectangle.
 * @param {Point} point - The point to test.
 * @return {boolean} Whether the obstacle blocks the point.
 */
function blocksPoint(obstacle: Obstacle, point: Point): boolean {
  return point.x >= obstacle.x - KEEP_OUT_MARGIN &&
    point.x <= obstacle.x + obstacle.width + KEEP_OUT_MARGIN &&
    point.y >= obstacle.y - KEEP_OUT_MARGIN &&
    point.y <= obstacle.y + obstacle.height + KEEP_OUT_MARGIN;
}

/**
 * Reads the optional obstacles. Broken ones are moved into range or
 * dropped, and any covering an important location are dropped.
 * @param {Report} report - Collects issues and repairs.
 * @param {unknown} value - The raw obstacles value.
 * @param {Point[]} importantPoints - Spawn and entities.
 * @return {Obstacle[]} The valid obstacles.
 */
function readObstacles(
  report: Report,
  value: unknown,
  importantPoints: Point[],
): Obstacle[] {
  if (!Array.isArray(value)) {
    report.repairs.push("obstacles: missing, using an empty list");
    return [];
  }

  if (value.length > COUNTS.maxObstacles) {
    report.repairs.push(
      `obstacles: kept first ${COUNTS.maxObstacles} of ${value.length}`);
  }

  const obstacles: Obstacle[] = [];

  value.slice(0, COUNTS.maxObstacles).forEach(
    (item: unknown, index: number) => {
      const path = `obstacles[${index}]`;

      if (!isRecord(item)) {
        report.repairs.push(`${path}: dropped (not an object)`);
        return;
      }

      const numbers = [item.x, item.y, item.width, item.height];
      if (numbers.some((n) => typeof n !== "number" || !Number.isFinite(n))) {
        report.repairs.push(`${path}: dropped (invalid number)`);
        return;
      }

      const width = clamp(
        item.width as number,
        OBSTACLE_RANGE.minWidth,
        OBSTACLE_RANGE.maxWidth,
      );
      const height = clamp(
        item.height as number,
        OBSTACLE_RANGE.minHeight,
        OBSTACLE_RANGE.maxHeight,
      );
      const x = clamp(
        item.x as number,
        OBSTACLE_RANGE.minX,
        Math.min(OBSTACLE_RANGE.maxX, OBSTACLE_RANGE.rightEdge - width),
      );
      const y = clamp(
        item.y as number,
        OBSTACLE_RANGE.minY,
        Math.min(OBSTACLE_RANGE.maxY, OBSTACLE_RANGE.bottomEdge - height),
      );

      const obstacle: Obstacle = {x, y, width, height};

      if (importantPoints.some((point) => blocksPoint(obstacle, point))) {
        report.repairs.push(`${path}: dropped (covers something important)`);
        return;
      }

      obstacles.push(obstacle);
    });

  return obstacles;
}

// ---------------------------------------------------------------------------
// Structure and solvability
// ---------------------------------------------------------------------------

/**
 * Checks the dependency structure: requirement ids, cycles, dead ends, and
 * that the final deduction rests on evidence. Cleans "requires" lists in
 * place (recorded as repairs).
 * @param {Report} report - Collects issues and repairs.
 * @param {Node[]} evidence - The evidence items.
 * @param {PuzzleItem[]} items - The puzzles with their positions.
 * @param {string} finalPuzzleId - The final deduction puzzle.
 * @return {string[]} What the door requires.
 */
function checkStructure(
  report: Report,
  evidence: Node[],
  items: PuzzleItem[],
  finalPuzzleId: string,
): string[] {
  const evidenceIds = new Set(evidence.map((e) => e.id));
  const puzzleIds = new Set(items.map((i) => i.puzzle.id));
  const known = new Set<string>([...evidenceIds, ...puzzleIds]);

  if (!puzzleIds.has(finalPuzzleId)) {
    report.issues.push("finalPuzzleId: does not match any puzzle");
    return [];
  }

  const cleanRequires = (owner: string, refs: string[]): string[] => {
    const fixed: string[] = [];
    for (const ref of refs) {
      if (ref === owner) {
        report.repairs.push(`"${owner}": self requirement dropped`);
        continue;
      }
      if (!known.has(ref)) {
        report.repairs.push(`"${owner}": unknown requirement "${ref}" dropped`);
        continue;
      }
      if (!fixed.includes(ref)) fixed.push(ref);
    }
    return fixed;
  };

  for (const e of evidence) e.requires = cleanRequires(e.id, e.requires);
  for (const i of items) {
    i.place.requires = cleanRequires(i.puzzle.id, i.place.requires);
  }

  const doorRequires: string[] = [finalPuzzleId];
  const deps = new Map<string, string[]>();
  for (const e of evidence) deps.set(e.id, e.requires);
  for (const i of items) deps.set(i.puzzle.id, i.place.requires);
  deps.set(DOOR_KEY, doorRequires);

  const depsOf = (node: string): string[] => deps.get(node) ?? [];

  // Cycle detection (1 = in progress, 2 = finished).
  const state = new Map<string, number>();
  const hasCycle = (node: string): boolean => {
    if (state.get(node) === 2) return false;
    if (state.get(node) === 1) return true;
    state.set(node, 1);
    for (const next of depsOf(node)) {
      if (hasCycle(next)) return true;
    }
    state.set(node, 2);
    return false;
  };

  if ([DOOR_KEY, ...known].some((n) => hasCycle(n))) {
    report.issues.push("requirements contain a cycle");
    return doorRequires;
  }

  const ancestors = (start: string): Set<string> => {
    const seen = new Set<string>();
    const stack = [...depsOf(start)];
    while (stack.length > 0) {
      const node = stack.pop() as string;
      if (seen.has(node)) continue;
      seen.add(node);
      stack.push(...depsOf(node));
    }
    return seen;
  };

  // Everything must matter: anything the door does not need yet is added.
  const needed = ancestors(DOOR_KEY);
  for (const node of known) {
    if (!needed.has(node)) {
      doorRequires.push(node);
      report.repairs.push(`door: now also requires "${node}"`);
    }
  }

  const evidenceBehind = (node: string): number =>
    [...ancestors(node)].filter((id) => evidenceIds.has(id)).length;

  for (const i of items) {
    if (i.puzzle.type === "codeLock" && evidenceBehind(i.puzzle.id) < 1) {
      report.issues.push(
        `puzzle "${i.puzzle.id}": a codeLock must depend on evidence`);
    }
  }

  if (evidenceBehind(finalPuzzleId) < 2) {
    report.issues.push(
      "finalPuzzleId: the final deduction must rest on 2+ evidence items");
  }

  return doorRequires;
}

/**
 * Builds the engine's flat entity list.
 * @param {Node[]} evidence - The evidence items.
 * @param {PuzzleItem[]} items - The puzzles with their positions.
 * @param {DoorNode} door - The exit door.
 * @param {string[]} doorRequires - What the door requires.
 * @return {EntitySpec[]} Evidence, puzzle spots, and the door.
 */
function buildEntities(
  evidence: Node[],
  items: PuzzleItem[],
  door: DoorNode,
  doorRequires: string[],
): EntitySpec[] {
  const taken = new Set<string>([
    ...evidence.map((e) => e.id),
    ...items.map((i) => i.puzzle.id),
  ]);

  const unique = (base: string): string => {
    let id = base;
    let suffix = 2;
    while (taken.has(id)) {
      id = `${base}_${suffix}`;
      suffix++;
    }
    taken.add(id);
    return id;
  };

  const entities: EntitySpec[] = [];

  for (const e of evidence) {
    entities.push({
      id: e.id,
      type: "evidence",
      name: e.name,
      x: e.x,
      y: e.y,
      text: e.text,
      requires: [...e.requires],
      lockedText: e.lockedText,
    });
  }

  items.forEach((item, index) => {
    entities.push({
      id: unique(`spot_${index + 1}`),
      type: "puzzle",
      name: item.place.name,
      x: item.place.x,
      y: item.place.y,
      text: item.place.text,
      requires: [...item.place.requires],
      lockedText: item.place.lockedText,
      puzzleId: item.puzzle.id,
    });
  });

  entities.push({
    id: unique("door_1"),
    type: "door",
    name: door.name,
    x: door.x,
    y: door.y,
    text: door.text,
    requires: [...doorRequires],
    lockedText: door.lockedText,
  });

  return entities;
}

/**
 * Nudges entities that overlap or sit too close apart, instead of
 * rejecting the whole adventure for a layout slip.
 * @param {Report} report - Collects issues and repairs.
 * @param {EntitySpec[]} entities - The entities (moved in place).
 */
function spreadEntities(report: Report, entities: EntitySpec[]): void {
  const min = MIN_ENTITY_DISTANCE + 0.015;
  let moved = false;

  for (let round = 0; round < 60; round++) {
    let changed = false;

    for (let i = 0; i < entities.length; i++) {
      for (let j = i + 1; j < entities.length; j++) {
        const a = entities[i];
        const b = entities[j];
        const dx = b.x - a.x;
        const dy = b.y - a.y;
        const d = Math.hypot(dx, dy);
        if (d >= min) continue;

        changed = true;
        moved = true;

        const ux = d < 1e-6 ? 1 : dx / d;
        const uy = d < 1e-6 ? 0 : dy / d;
        const push = (min - d) / 2 + 0.002;

        a.x = clamp(a.x - ux * push, POINT_RANGE.minX, POINT_RANGE.maxX);
        a.y = clamp(a.y - uy * push, POINT_RANGE.minY, POINT_RANGE.maxY);
        b.x = clamp(b.x + ux * push, POINT_RANGE.minX, POINT_RANGE.maxX);
        b.y = clamp(b.y + uy * push, POINT_RANGE.minY, POINT_RANGE.maxY);
      }
    }

    if (!changed) break;
  }

  if (moved) report.repairs.push("entities: moved apart so none overlap");
}

/**
 * Rejects entities that are still too close after spreading them.
 * @param {Report} report - Collects issues and repairs.
 * @param {EntitySpec[]} entities - The entities.
 */
function checkSeparation(report: Report, entities: EntitySpec[]): void {
  for (let i = 0; i < entities.length; i++) {
    for (let j = i + 1; j < entities.length; j++) {
      const a = entities[i];
      const b = entities[j];
      if (Math.hypot(a.x - b.x, a.y - b.y) < MIN_ENTITY_DISTANCE) {
        report.issues.push(
          `entities "${a.id}" and "${b.id}" are too close together`);
      }
    }
  }
}

/**
 * Checks that the player can walk from the spawn to within interaction
 * range of every target, using a coarse grid.
 * @param {Point} spawn - Where the player starts.
 * @param {Point[]} targets - Entities that must be reachable.
 * @param {Obstacle[]} obstacles - Blocking rectangles.
 * @return {boolean} Whether every target is reachable.
 */
function allReachable(
  spawn: Point,
  targets: Point[],
  obstacles: Obstacle[],
): boolean {
  const n = 40;
  const pad = 0.045;
  const at = (i: number): number => i / (n - 1);
  const cell = (v: number): number =>
    clamp(Math.round(v * (n - 1)), 0, n - 1);

  const blocked = (x: number, y: number): boolean => {
    if (x < 0.05 || x > 0.95 || y < 0.05 || y > 0.95) return true;
    return obstacles.some((o) =>
      x >= o.x - pad && x <= o.x + o.width + pad &&
      y >= o.y - pad && y <= o.y + o.height + pad);
  };

  const start = cell(spawn.y) * n + cell(spawn.x);
  const seen = new Set<number>([start]);
  const queue: number[] = [start];
  const steps: Array<[number, number]> = [[1, 0], [-1, 0], [0, 1], [0, -1]];

  while (queue.length > 0) {
    const current = queue.shift() as number;
    const cx = current % n;
    const cy = Math.floor(current / n);

    for (const [dx, dy] of steps) {
      const nx = cx + dx;
      const ny = cy + dy;
      if (nx < 0 || ny < 0 || nx >= n || ny >= n) continue;
      const key = ny * n + nx;
      if (seen.has(key) || blocked(at(nx), at(ny))) continue;
      seen.add(key);
      queue.push(key);
    }
  }

  return targets.every((target) => {
    for (const key of seen) {
      const x = at(key % n);
      const y = at(Math.floor(key / n));
      if (Math.hypot(x - target.x, y - target.y) <= 0.1) return true;
    }
    return false;
  });
}

// ---------------------------------------------------------------------------
// Whole-adventure validation + conversion
// ---------------------------------------------------------------------------

/**
 * Validates a generated adventure (generation format), repairing small
 * problems, and converts it to the engine format. Reports only field paths,
 * ids, and numbers, never the story text.
 * @param {unknown} raw - The parsed Gemini response.
 * @return {NormalizeResult} The clean spec (or null) plus diagnostics.
 */
export function normalizeAdventureV2(raw: unknown): NormalizeResult {
  const report: Report = {issues: [], repairs: []};

  if (!isRecord(raw)) {
    report.issues.push("root: response is not a JSON object");
    return {spec: null, ...report};
  }

  const title = readText(report, "title", raw.title, TEXT_LIMITS.title);
  const story = readText(report, "story", raw.story, TEXT_LIMITS.story);
  const learningSummary = readText(
    report, "learningSummary", raw.learningSummary,
    TEXT_LIMITS.learningSummary);

  const env = readRecord(report, "environment", raw.environment);
  const environment = {
    name: readText(
      report, "environment.name", env.name, TEXT_LIMITS.environmentName),
    floorColor: readColor(
      report, "environment.floorColor", env.floorColor,
      DEFAULT_COLORS.floorColor),
    wallColor: readColor(
      report, "environment.wallColor", env.wallColor,
      DEFAULT_COLORS.wallColor),
    accentColor: readColor(
      report, "environment.accentColor", env.accentColor,
      DEFAULT_COLORS.accentColor),
  };

  const spawn = readPoint(
    report, "spawn", readRecord(report, "spawn", raw.spawn));

  // Evidence ids and puzzle ids share one id space, because "requires" may
  // name either.
  const used = new Set<string>();
  const evidence = readEvidence(report, raw.evidence, used);
  const items = readPuzzles(report, raw.puzzles, used);
  const door = readDoor(report, raw.door);
  const finalPuzzleId =
    typeof raw.finalPuzzleId === "string" ? raw.finalPuzzleId.trim() : "";

  const doorRequires = checkStructure(report, evidence, items, finalPuzzleId);
  const entities = buildEntities(evidence, items, door, doorRequires);

  spreadEntities(report, entities);
  checkSeparation(report, entities);

  let obstacles = readObstacles(report, raw.obstacles, [spawn, ...entities]);
  if (obstacles.length > 0 && !allReachable(spawn, entities, obstacles)) {
    report.repairs.push(
      "obstacles: all dropped because an entity was unreachable");
    obstacles = [];
  }

  if (report.issues.length > 0) return {spec: null, ...report};

  return {
    spec: {
      specVersion: 2,
      title,
      story,
      learningSummary,
      environment,
      spawn,
      obstacles,
      entities,
      puzzles: items.map((i) => i.puzzle),
      finalPuzzleId,
    },
    ...report,
  };
}