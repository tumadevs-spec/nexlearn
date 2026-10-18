const assert = require("node:assert/strict");
const {normalizeAdventureV2} = require("../lib/spec_v2");

// Generation format (what Gemini returns).
const base = () => ({
  title: "The Quiet Workshop",
  story: "Something stopped the little robot.",
  learningSummary: "Practice with counting and order.",
  environment: {
    name: "Workshop", floorColor: "#EDE9FE",
    wallColor: "#B9A3EC", accentColor: "#7C3AED",
  },
  spawn: {x: 0.5, y: 0.88},
  obstacles: [{x: 0.45, y: 0.55, width: 0.1, height: 0.05}],
  evidence: [
    {id: "ev_1", name: "Tray", x: 0.18, y: 0.74,
     text: "3 rows of 4 cells.", requires: [], lockedText: ""},
    {id: "ev_2", name: "Manual", x: 0.82, y: 0.74,
     text: "Plug in, switch on, wait, press start.", requires: [],
     lockedText: ""},
    {id: "ev_3", name: "Label", x: 0.18, y: 0.34,
     text: "The robot needs power to move.", requires: [], lockedText: ""},
  ],
  puzzles: [
    {id: "puzzle_1", type: "codeLock", prompt: "How many cells in total?",
     config: {answer: "12"}, feedbackCorrect: "Click!",
     feedbackWrong: "Count again.", hint: "3 groups of 4.",
     skill: "multiplication", name: "Counter", x: 0.40, y: 0.74,
     sceneText: "A number lock.", requires: ["ev_1"],
     lockedText: "Look around first."},
    {id: "puzzle_2", type: "sequence", prompt: "Order the steps.",
     config: {items: ["Plug in", "Switch on", "Wait", "Press start"]},
     feedbackCorrect: "Lit up!", feedbackWrong: "Check the manual.",
     hint: "", skill: "sequencing", name: "Panel", x: 0.62, y: 0.74,
     sceneText: "A start panel.", requires: ["ev_2"],
     lockedText: "Read the manual."},
    {id: "puzzle_3", type: "matching", prompt: "Match each part.",
     config: {pairs: [
       {left: "Battery", right: "Gives power"},
       {left: "Wire", right: "Carries power"},
       {left: "Switch", right: "Turns it on"},
     ]},
     feedbackCorrect: "Connected!", feedbackWrong: "Try again.",
     hint: "", skill: "vocabulary", name: "Parts", x: 0.40, y: 0.34,
     sceneText: "A parts board.",
     requires: ["puzzle_1", "puzzle_2", "ev_3"], lockedText: "Not yet."},
    {id: "puzzle_final", type: "choice", prompt: "Why was it asleep?",
     config: {options: [
       {text: "Broken", isCorrect: false},
       {text: "No power", isCorrect: true},
       {text: "Tired", isCorrect: false},
     ]},
     feedbackCorrect: "Yes!", feedbackWrong: "Look at the label.",
     hint: "", skill: "reasoning", name: "Case board", x: 0.70, y: 0.34,
     sceneText: "Who is to blame?", requires: ["puzzle_3"],
     lockedText: "Solve the parts first."},
  ],
  door: {name: "Robot bay", x: 0.5, y: 0.16, text: "The robot wakes up!",
         lockedText: "Sealed."},
  finalPuzzleId: "puzzle_final",
});

const run = (name, change, check) => {
  const input = base();
  change(input);
  const result = normalizeAdventureV2(input);
  check(result);
  console.log("ok -", name);
};

const has = (list, text) => list.some((item) => item.includes(text));

run("valid spec passes and converts to engine format", () => {}, (r) => {
  assert.deepEqual(r.issues, []);
  assert.equal(r.spec.specVersion, 2);
  assert.equal(r.spec.entities.length, 8);
  assert.equal(r.spec.puzzles.length, 4);
  const door = r.spec.entities.find((e) => e.type === "door");
  assert.deepEqual(door.requires, ["puzzle_final"]);
  const spot = r.spec.entities.find((e) => e.puzzleId === "puzzle_1");
  assert.deepEqual(spot.requires, ["ev_1"]);
  assert.equal(r.spec.obstacles.length, 1);
});

run("choice shuffle keeps the right answer", () => {}, (r) => {
  const c = r.spec.puzzles[3].config;
  assert.equal(c.options[c.correctIndex], "No power");
});

run("unsupported mechanic is rejected",
  (s) => { s.puzzles[0].type = "jumping"; },
  (r) => assert.ok(has(r.issues, "unsupported")));

run("cycle is rejected",
  (s) => { s.evidence[0].requires = ["puzzle_final"]; },
  (r) => assert.ok(has(r.issues, "cycle")));

run("unknown requirement id is dropped",
  (s) => { s.puzzles[2].requires.push("nothing_here"); },
  (r) => {
    assert.deepEqual(r.issues, []);
    assert.ok(has(r.repairs, "unknown"));
  });

run("unreferenced evidence is added to the door",
  (s) => {
    s.evidence.push({id: "ev_4", name: "Extra", x: 0.82, y: 0.34,
      text: "An extra clue.", requires: [], lockedText: ""});
  },
  (r) => {
    assert.deepEqual(r.issues, []);
    const door = r.spec.entities.find((e) => e.type === "door");
    assert.ok(door.requires.includes("ev_4"));
  });

run("codeLock without evidence is rejected",
  (s) => { s.puzzles[0].requires = []; },
  (r) => assert.ok(has(r.issues, "codeLock")));

run("final puzzle without evidence is rejected",
  (s) => { s.puzzles[3].requires = []; },
  (r) => assert.ok(has(r.issues, "finalPuzzleId")));

run("links in text are rejected",
  (s) => { s.title = "Visit http://example.com now"; },
  (r) => assert.ok(has(r.issues, "title")));

run("fewer than 3 evidence items is rejected",
  (s) => { s.evidence.pop(); },
  (r) => assert.ok(has(r.issues, "evidence:")));

run("a missing door is rejected",
  (s) => { delete s.door; },
  (r) => assert.ok(has(r.issues, "door")));

run("obstacle on an entity is dropped",
  (s) => { s.obstacles = [{x: 0.38, y: 0.72, width: 0.1, height: 0.05}]; },
  (r) => assert.equal(r.spec.obstacles.length, 0));

run("a wall that cuts the room drops all obstacles",
  (s) => {
    s.obstacles = [
      {x: 0.05, y: 0.5, width: 0.3, height: 0.12},
      {x: 0.35, y: 0.5, width: 0.3, height: 0.12},
      {x: 0.65, y: 0.5, width: 0.3, height: 0.12},
    ];
  },
  (r) => {
    assert.equal(r.spec.obstacles.length, 0);
    assert.ok(has(r.repairs, "unreachable"));
  });

run("older choice format with correctOption text still works",
  (s) => {
    s.puzzles[3].config = {
      options: ["Broken", "No power", "Tired"],
      correctOption: "No power",
    };
  },
  (r) => {
    assert.deepEqual(r.issues, []);
    const c = r.spec.puzzles[3].config;
    assert.equal(c.options[c.correctIndex], "No power");
  });

run("choice with no correct option is rejected",
  (s) => {
    s.puzzles[3].config = {options: [
      {text: "Broken", isCorrect: false},
      {text: "Tired", isCorrect: false},
    ]};
  },
  (r) => assert.ok(has(r.issues, "isCorrect")));

run("choice with two correct options is rejected",
  (s) => {
    s.puzzles[3].config = {options: [
      {text: "Broken", isCorrect: true},
      {text: "No power", isCorrect: true},
    ]};
  },
  (r) => assert.ok(has(r.issues, "exactly one")));

run("entities that are too close are moved apart, not rejected",
  (s) => {
    s.door.y = 0.12;
    s.puzzles[3].x = 0.5;
    s.puzzles[3].y = 0.2;
  },
  (r) => {
    assert.deepEqual(r.issues, []);
    assert.ok(has(r.repairs, "moved apart"));
    const door = r.spec.entities.find((e) => e.type === "door");
    const last = r.spec.entities.find((e) => e.puzzleId === "puzzle_final");
    assert.ok(Math.hypot(door.x - last.x, door.y - last.y) >= 0.09);
  });

run("a sequence with only 2 steps is rejected",
  (s) => { s.puzzles[1].config = {items: ["Plug in", "Switch on"]}; },
  (r) => assert.ok(has(r.issues, "items")));

run("matching with only 2 pairs is rejected",
  (s) => {
    s.puzzles[2].config = {pairs: [
      {left: "Battery", right: "Gives power"},
      {left: "Wire", right: "Carries power"},
    ]};
  },
  (r) => assert.ok(has(r.issues, "pairs")));

run("an id shared by evidence and a puzzle is rejected",
  (s) => { s.puzzles[0].id = "ev_1"; },
  (r) => assert.ok(has(r.issues, "duplicate")));

console.log("All validator checks passed.");