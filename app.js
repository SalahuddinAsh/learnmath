"use strict";

const APP_VERSION = "1.11.1";

/* ================= tunable constants ================= */
const RANGE_OPTIONS = [10, 20, 50, 100, 500, 1000];
const COUNT_OPTIONS = [5, 10, 15, 20];
const KG_RANGE_OPTIONS = [5, 10, 15, 20]; // kindergarten "biggest answer" choices
const KG_SHAPES_MAX = 10;                 // shapes stay countable
const TABLE_MIN = 1, TABLE_MAX = 12;
const WEAK_BIAS = 0.4;                    // chance a ×/÷ question is drawn from saved weak facts
const EMOJIS = ["🍎", "⭐", "🎈", "🐟", "🦋", "🍓", "⚽", "🐥"];

// per-question time comes from the chosen difficulty; on easy, answering
// after the buzzer still counts but earns fewer points
const DIFF_SECONDS = { easy: 30, medium: 20, hard: 10 };
const OVERTIME_FACTOR = 0.3; // share of the question's points for an overtime answer
function timeFor() { return DIFF_SECONDS[settings.difficulty] || 20; }

/* ================= i18n ================= */
const STRINGS = {
  en: {
    title: "Math Stars ⭐",
    mode: "Mode", modeTest: "Quiz", modeKg: "Kindergarten", modeTables: "Times tables",
    ops: "Choose operations",
    add: "Add", sub: "Subtract", mul: "Multiply", div: "Divide", time: "Time",
    whatTime: "What time is it?",
    style: "Show questions with", shapes: "Shapes", digits: "Digits",
    kgTimer: "Timer", timerOn: "⏱️ On", timerOff: "🚫 Off",
    kgSize: "Shape size", sizeS: "Small", sizeM: "Medium", sizeL: "Large",
    range: "Biggest answer (+ / −)",
    tables: "Numbers to practice (× / ÷)",
    factorMax: "Multiplication up to",
    tablesNote: "All questions in order: ×1 … ×10, then extra practice for tricky ones",
    timeLevel: "Clock difficulty",
    level1: "Easy: 00 · 15 · 30 · 45", level2: "Every 5 minutes",
    clockMode: "Clock type", c12: "12-hour", c24: "24-hour", cDual: "Two answers: 7:15 + 19:15",
    whatTime2: "What time is it? Give both answers!",
    timeInput: "Answer the time by", inputPick: "Picking buttons", inputType: "Typing",
    qFormat: "Question style",
    fmtResult: "Result only: 5 × 6 = ?", fmtMixed: "Mix in blanks: 5 × _ = 30",
    auto: "Answer entry", autoOn: "⚡ Instant", autoOff: "✓ With OK button",
    mistakesTitle: "Mistakes Log 📋", mistakesEmpty: "No mistakes recorded yet 🎉",
    mistakesHoldHint: "Hold to open 👆",
    mistakesChild: "Child answered", mistakesCorrect: "Correct answer", mistakesNoAnswer: "No answer (time ran out)",
    mistakesClear: "Clear log", mistakesClose: "Close",
    diff: "Difficulty", diffEasy: "😌 Easy · 30s", diffMed: "🙂 Medium · 20s", diffHard: "🔥 Hard · 10s",
    diffNote: "Easy: answering after time runs out still counts, for fewer points",
    overtime: "⏰ Keep going — fewer points now",
    game: "Game unlock score", gameOff: "🚫 Off",
    gameNote: "Score at least this much in a test to unlock one round of Meteor Blaster ☄️ (or Clock Blaster ⏰ if Time is selected)",
    gamePlay: "🎮 Play Meteor Blaster!",
    gamePlayClock: "⏰ Play Clock Blaster!",
    gamePlayMixed: "🎮⏰ Play the Mix!",
    gameOver: "Game over! ☄️",
    hours: "Hours", minutes: "Minutes",
    morning: "in the morning ☀️", afternoon: "in the afternoon 🌇", evening: "in the evening 🌙",
    count: "How many questions?",
    start: "Start! 🚀",
    hintOps: "Pick at least one operation",
    hintTables: "Pick at least one number for × / ÷",
    timeUp: "Time's up! ⏰",
    answerIs: "The answer is",
    good: ["Great job! 🎉", "Awesome! ⭐", "You rock! 💪", "Super! 🌟", "Amazing! 🚀"],
    score: "Your score",
    best: "Best score", newRecord: "🏆 New record!",
    review: "Review these",
    again: "Play again 🔁",
    settings: "Change settings ⚙️",
    cheer3: "Fantastic! You're a math star!",
    cheer2: "Great work! Keep practicing!",
    cheer1: "Good try! You'll get better!",
    cheer0: "Keep practicing, you can do it!",
  },
  ar: {
    title: "نجوم الحساب ⭐",
    mode: "الوضع", modeTest: "اختبار", modeKg: "روضة", modeTables: "جدول الضرب",
    ops: "اختر العمليات",
    add: "جمع", sub: "طرح", mul: "ضرب", div: "قسمة", time: "الوقت",
    whatTime: "كم الساعة الآن؟",
    style: "شكل الأسئلة", shapes: "أشكال", digits: "أرقام",
    kgTimer: "المؤقت", timerOn: "⏱️ يعمل", timerOff: "🚫 بدون",
    kgSize: "حجم الأشكال", sizeS: "صغير", sizeM: "وسط", sizeL: "كبير",
    range: "أكبر ناتج (+ / −)",
    tables: "أرقام التدريب (× / ÷)",
    factorMax: "جدول الضرب حتى",
    tablesNote: "كل الأسئلة بالترتيب: ×1 … ×10، ثم تدريب إضافي على الأسئلة الصعبة",
    timeLevel: "مستوى الساعة",
    level1: "سهل: 00 · 15 · 30 · 45", level2: "كل 5 دقائق",
    clockMode: "نوع الساعة", c12: "12 ساعة", c24: "24 ساعة", cDual: "إجابتان: 7:15 و 19:15",
    whatTime2: "كم الساعة؟ أعطِ الإجابتين!",
    timeInput: "طريقة إجابة الوقت", inputPick: "اختيار الأزرار", inputType: "كتابة",
    qFormat: "نمط الأسئلة",
    fmtResult: "الناتج فقط (5 × 6 = ?)", fmtMixed: "مع فراغات (5 × _ = 30)",
    auto: "إدخال الإجابة", autoOn: "⚡ فوري", autoOff: "✓ بزر التأكيد",
    mistakesTitle: "سجلّ الأخطاء 📋", mistakesEmpty: "!لا توجد أخطاء مسجّلة بعد 🎉",
    mistakesHoldHint: "اضغط مطولًا لفتحه 👆",
    mistakesChild: "إجابة الطفل", mistakesCorrect: "الإجابة الصحيحة", mistakesNoAnswer: "لا توجد إجابة (انتهى الوقت)",
    mistakesClear: "امسح السجلّ", mistakesClose: "إغلاق",
    diff: "مستوى الصعوبة", diffEasy: "😌 سهل · 30 ث", diffMed: "🙂 وسط · 20 ث", diffHard: "🔥 صعب · 10 ث",
    diffNote: "سهل: يمكن الإجابة بعد انتهاء الوقت لكن بنقاط أقل",
    overtime: "⏰ أكمل — النقاط أقل الآن",
    game: "نقاط فتح اللعبة", gameOff: "🚫 إيقاف",
    gameNote: "احصل على هذه النقاط في الاختبار لتفتح جولة من صائد النيازك ☄️ (أو صائد الساعات ⏰ إذا اخترت الوقت)",
    gamePlay: "!العب صائد النيازك 🎮",
    gamePlayClock: "!العب صائد الساعات ⏰",
    gamePlayMixed: "!العب الخليط 🎮⏰",
    gameOver: "انتهت اللعبة! ☄️",
    hours: "الساعات", minutes: "الدقائق",
    morning: "صباحًا ☀️", afternoon: "بعد الظهر 🌇", evening: "مساءً 🌙",
    count: "كم عدد الأسئلة؟",
    start: "!ابدأ 🚀",
    hintOps: "اختر عملية واحدة على الأقل",
    hintTables: "اختر رقمًا واحدًا على الأقل للضرب / القسمة",
    timeUp: "انتهى الوقت! ⏰",
    answerIs: "الإجابة الصحيحة",
    good: ["أحسنت! 🎉", "رائع! ⭐", "ممتاز! 💪", "عظيم! 🌟", "مذهل! 🚀"],
    score: "نتيجتك",
    best: "أفضل نتيجة", newRecord: "🏆 رقم قياسي جديد!",
    review: "راجع هذه الأسئلة",
    again: "العب مرة أخرى 🔁",
    settings: "غيّر الإعدادات ⚙️",
    cheer3: "!مدهش! أنت نجم في الحساب",
    cheer2: "!عمل رائع! واصل التدريب",
    cheer1: "!محاولة جيدة! ستتحسن",
    cheer0: "!واصل التدريب، أنت تستطيع",
  },
  de: {
    title: "Mathe-Sterne ⭐",
    mode: "Modus", modeTest: "Quiz", modeKg: "Kindergarten", modeTables: "Einmaleins",
    ops: "Rechenarten wählen",
    add: "Plus", sub: "Minus", mul: "Mal", div: "Geteilt", time: "Uhrzeit",
    whatTime: "Wie spät ist es?",
    style: "Aufgaben zeigen mit", shapes: "Bildern", digits: "Zahlen",
    kgTimer: "Zeitlimit", timerOn: "⏱️ An", timerOff: "🚫 Aus",
    kgSize: "Größe der Bilder", sizeS: "Klein", sizeM: "Mittel", sizeL: "Groß",
    range: "Größtes Ergebnis (+ / −)",
    tables: "Zahlen zum Üben (× / ÷)",
    factorMax: "Einmaleins bis",
    tablesNote: "Alle Aufgaben der Reihe nach: ×1 … ×10, dann Extra-Übung für knifflige",
    timeLevel: "Uhr-Schwierigkeit",
    level1: "Leicht: 00 · 15 · 30 · 45", level2: "Alle 5 Minuten",
    clockMode: "Uhrformat", c12: "12-Stunden", c24: "24-Stunden", cDual: "Zwei Antworten: 7:15 + 19:15",
    whatTime2: "Wie spät ist es? Nenne beide Antworten!",
    timeInput: "Uhrzeit eingeben per", inputPick: "Auswählen", inputType: "Tippen",
    qFormat: "Aufgabenstil",
    fmtResult: "Nur Ergebnis: 5 × 6 = ?", fmtMixed: "Mit Lücken: 5 × _ = 30",
    auto: "Antwort-Eingabe", autoOn: "⚡ Sofort", autoOff: "✓ Mit OK-Taste",
    mistakesTitle: "Fehlerprotokoll 📋", mistakesEmpty: "Noch keine Fehler aufgezeichnet 🎉",
    mistakesHoldHint: "Gedrückt halten 👆",
    mistakesChild: "Kind hat geantwortet", mistakesCorrect: "Richtige Antwort", mistakesNoAnswer: "Keine Antwort (Zeit abgelaufen)",
    mistakesClear: "Protokoll löschen", mistakesClose: "Schließen",
    diff: "Schwierigkeit", diffEasy: "😌 Leicht · 30s", diffMed: "🙂 Mittel · 20s", diffHard: "🔥 Schwer · 10s",
    diffNote: "Leicht: Antworten nach Ablauf zählt noch, gibt aber weniger Punkte",
    overtime: "⏰ Weiter — jetzt weniger Punkte",
    game: "Punkte fürs Spiel", gameOff: "🚫 Aus",
    gameNote: "Erreiche diese Punktzahl im Test, um eine Runde Meteor-Blaster freizuschalten ☄️ (oder Uhren-Blaster ⏰, wenn Uhrzeit ausgewählt ist)",
    gamePlay: "🎮 Meteor-Blaster spielen!",
    gamePlayClock: "⏰ Uhren-Blaster spielen!",
    gamePlayMixed: "🎮⏰ Mix spielen!",
    gameOver: "Game over! ☄️",
    hours: "Stunden", minutes: "Minuten",
    morning: "morgens ☀️", afternoon: "nachmittags 🌇", evening: "abends 🌙",
    count: "Wie viele Aufgaben?",
    start: "Los! 🚀",
    hintOps: "Wähle mindestens eine Rechenart",
    hintTables: "Wähle mindestens eine Zahl für × / ÷",
    timeUp: "Zeit ist um! ⏰",
    answerIs: "Die richtige Antwort ist",
    good: ["Super! 🎉", "Toll! ⭐", "Klasse! 💪", "Spitze! 🌟", "Fantastisch! 🚀"],
    score: "Deine Punkte",
    best: "Bester Punktestand", newRecord: "🏆 Neuer Rekord!",
    review: "Diese nochmal üben",
    again: "Nochmal spielen 🔁",
    settings: "Einstellungen ⚙️",
    cheer3: "Fantastisch! Du bist ein Mathe-Star!",
    cheer2: "Super gemacht! Weiter so!",
    cheer1: "Guter Versuch! Übung macht den Meister!",
    cheer0: "Weiter üben, du schaffst das!",
  },
};

/* ================= settings ================= */
const DEFAULTS = {
  lang: "en", mode: "test",
  ops: ["add"], range: 20, tables: [2, 3, 4, 5], count: 10, factorMax: 10,
  timeLevel: 1, clockMode: "12", timeInput: "type", qFormat: "result",
  kgRange: 10, kgOps: ["add", "sub"], kgStyle: "shapes", kgTimer: true, kgSize: "l",
  sound: true, autoSubmit: true, difficulty: "medium", gameScore: 700,
};
let settings = loadSettings();

function loadSettings() {
  try {
    const s = JSON.parse(localStorage.getItem("mathstars-settings"));
    if (!s) return { ...DEFAULTS };
    const ops = Array.isArray(s.ops) ? s.ops.filter(o => ["add", "sub", "mul", "div", "time"].includes(o)) : [];
    const kgOps = Array.isArray(s.kgOps) ? s.kgOps.filter(o => ["add", "sub"].includes(o)) : [];
    return {
      lang: ["en", "ar", "de"].includes(s.lang) ? s.lang : DEFAULTS.lang,
      mode: ["test", "kg", "tables"].includes(s.mode) ? s.mode : DEFAULTS.mode,
      ops: ops.length ? ops : [...DEFAULTS.ops],
      range: RANGE_OPTIONS.includes(s.range) ? s.range : DEFAULTS.range,
      tables: Array.isArray(s.tables) ? s.tables.filter(n => n >= TABLE_MIN && n <= TABLE_MAX) : [...DEFAULTS.tables],
      count: COUNT_OPTIONS.includes(s.count) ? s.count : DEFAULTS.count,
      factorMax: s.factorMax === 12 ? 12 : 10,
      timeLevel: s.timeLevel === 2 ? 2 : 1,
      clockMode: ["12", "24", "dual"].includes(s.clockMode) ? s.clockMode : (s.clock24 === true ? "24" : "12"),
      timeInput: s.timeInput === "pick" ? "pick" : "type",
      qFormat: s.qFormat === "mixed" ? "mixed" : "result",
      kgRange: KG_RANGE_OPTIONS.includes(s.kgRange) ? s.kgRange
        : ({ 4: 5, 5: 10, 6: 15, 7: 20 }[s.kgAge] || DEFAULTS.kgRange), // migrate old "age" setting
      kgOps: kgOps.length ? kgOps : [...DEFAULTS.kgOps],
      kgStyle: s.kgStyle === "digits" ? "digits" : "shapes",
      kgTimer: s.kgTimer !== false,
      kgSize: ["s", "m", "l"].includes(s.kgSize) ? s.kgSize : DEFAULTS.kgSize,
      sound: s.sound !== false,
      autoSubmit: s.autoSubmit !== false,
      difficulty: ["easy", "medium", "hard"].includes(s.difficulty) ? s.difficulty : DEFAULTS.difficulty,
      gameScore: [0, 500, 700, 800, 900].includes(s.gameScore) ? s.gameScore : DEFAULTS.gameScore,
    };
  } catch { return { ...DEFAULTS }; }
}
function saveSettings() {
  try { localStorage.setItem("mathstars-settings", JSON.stringify(settings)); } catch {}
}

/* ================= weak questions =================
   Anything answered wrong is saved with a miss count and drawn more
   often in later quizzes; correct answers work the count back down.
   Keys: "f:3x7" (×/÷ fact), "add:5:7", "sub:12:4", "time:15:30". */
function loadWeak() {
  try {
    const w = JSON.parse(localStorage.getItem("mathstars-weak")) || {};
    for (const k of Object.keys(w)) { // migrate v1 fact keys ("3x7")
      if (/^\d+x\d+$/.test(k)) { w["f:" + k] = w[k]; delete w[k]; }
    }
    return w;
  } catch { return {}; }
}
function saveWeak(w) {
  try { localStorage.setItem("mathstars-weak", JSON.stringify(w)); } catch {}
}
function missKey(q) {
  if (q.op === "mul" || q.op === "div") return `f:${q.fa}x${q.fb}`;
  return `${q.op}:${q.a}:${q.b}`; // operands survive the blank transform
}

function recordResult(q, correct) {
  const w = loadWeak();
  const key = missKey(q);
  if (correct) {
    if (w[key]) { w[key]--; if (w[key] <= 0) delete w[key]; saveWeak(w); }
  } else {
    w[key] = Math.min(5, (w[key] || 0) + 1);
    saveWeak(w);
  }
}

// weighted pool of [n, k] facts for the marathon review round
function weakPool(tables) {
  const w = loadWeak();
  const pool = [];
  for (const key of Object.keys(w)) {
    const m = key.match(/^f:(\d+)x(\d+)$/);
    if (m && tables.includes(+m[1])) {
      for (let i = 0; i < w[key]; i++) pool.push([+m[1], +m[2]]);
    }
  }
  return pool;
}

// weighted pool of saved weak questions that fit the current quiz settings
function weakQuestions(cfg) {
  const w = loadWeak();
  const pool = [];
  for (const key of Object.keys(w)) {
    const q = weakToQuestion(key, cfg);
    if (q) for (let i = 0; i < w[key]; i++) pool.push(q);
  }
  return pool;
}

function weakToQuestion(key, cfg) {
  let m = key.match(/^f:(\d+)x(\d+)$/);
  if (m) {
    const n = +m[1], k = +m[2];
    const ops = ["mul", "div"].filter(o => cfg.ops.includes(o));
    if (!ops.length || !cfg.tables.includes(n) || k > (cfg.factorMax || TABLE_MAX)) return null;
    if (pick(ops) === "mul") {
      const [a, b] = Math.random() < 0.5 ? [n, k] : [k, n];
      return { op: "mul", a, b, fa: n, fb: k, answer: a * b };
    }
    const [d, ans] = Math.random() < 0.5 ? [n, k] : [k, n];
    return { op: "div", a: n * k, b: d, fa: n, fb: k, answer: ans };
  }
  m = key.match(/^(add|sub|time):(\d+):(\d+)$/);
  if (!m || !cfg.ops.includes(m[1])) return null;
  const op = m[1], a = +m[2], b = +m[3];
  if (op === "add") return a + b <= cfg.range ? { op, a, b, answer: a + b } : null;
  if (op === "sub") return a <= cfg.range && b < a ? { op, a, b, answer: a - b } : null;
  if (cfg.timeLevel === 1 && b % 15 !== 0) return null;
  const mode = cfg.clockMode || "12";
  if (mode === "dual") {
    const base = a > 12 ? a - 12 : a;
    if (base < 0 || base > 11) return null;
    return { op: "time", a: base, b, dual: true, answer: base * 100 + b, answer2: (base + 12) * 100 + b };
  }
  if (mode !== "24" && (a < 1 || a > 12)) return null; // 12-hour clocks never show 0
  return { op: "time", a, b, clock24: mode === "24", answer: a * 100 + b };
}

/* ================= high scores ================= */
function loadBest() {
  try { return JSON.parse(localStorage.getItem("mathstars-best")) || {}; } catch { return {}; }
}
function saveBest(b) {
  try { localStorage.setItem("mathstars-best", JSON.stringify(b)); } catch {}
}

/* ================= parent mistake log =================
   Every wrong/timed-out answer is recorded here, independent of the
   per-fact weak-memory above. Viewed only via a long-press (see wiring). */
function loadMistakes() {
  try { return JSON.parse(localStorage.getItem("mathstars-mistakes")) || []; } catch { return []; }
}
function saveMistakes(list) {
  try { localStorage.setItem("mathstars-mistakes", JSON.stringify(list.slice(-200))); } catch {}
}
function mistakePromptText(q) {
  return q.op === "time" ? "🕐" : questionText(q);
}
function recordMistake(q, givenLabel) {
  const list = loadMistakes();
  list.push({ prompt: mistakePromptText(q), correct: answerText(q), given: givenLabel, ts: Date.now() });
  saveMistakes(list);
}

/* ================= helpers ================= */
const $ = id => document.getElementById(id);
const rand = (lo, hi) => lo + Math.floor(Math.random() * (hi - lo + 1)); // inclusive
const pick = arr => arr[Math.floor(Math.random() * arr.length)];
const T = () => STRINGS[settings.lang];

/* ================= question generation ================= */
const OP_SYMBOL = { add: "+", sub: "−", mul: "×", div: "÷" };

function generateQuestion(cfg, recent) {
  for (let attempt = 0; attempt < 50; attempt++) {
    // previously missed questions come back more often
    const q = (cfg.weakQs && cfg.weakQs.length && Math.random() < WEAK_BIAS)
      ? { ...pick(cfg.weakQs) }
      : makeOne(pick(cfg.ops), cfg);
    // mixed style: half the arithmetic questions hide the middle operand instead
    if (cfg.qFormat === "mixed" && q.op !== "time" && Math.random() < 0.5) toBlank(q);
    const key = `${q.op}:${q.a}:${q.b}:${q.blank ? "_" : ""}`;
    if (!recent.includes(key) || attempt >= 40) {
      recent.push(key);
      if (recent.length > 4) recent.shift();
      return q;
    }
  }
}

function makeOne(op, cfg) {
  if (op === "time") {
    // read an analog clock; level 1 = quarter hours, level 2 = 5-minute steps.
    // "24": badge + converted hour. "dual": the face is ambiguous — both readings required.
    const mode = cfg.clockMode || "12";
    const m = cfg.timeLevel === 1 ? pick([0, 15, 30, 45]) : rand(0, 11) * 5;
    if (mode === "dual") {
      const h = rand(0, 11); // skip 12 so the two answers are always distinct and < 24 (0 pairs with 12)
      return { op, a: h, b: m, dual: true, answer: h * 100 + m, answer2: (h + 12) * 100 + m };
    }
    const h = mode === "24" ? rand(0, 23) : rand(1, 12); // 24-hour mode includes midnight (0:MM)
    return { op, a: h, b: m, clock24: mode === "24", answer: h * 100 + m }; // 3:15 -> 315
  }
  if (op === "add") {
    const a = rand(1, Math.max(1, cfg.range - 1));
    const b = rand(1, Math.max(1, cfg.range - a));
    return { op, a, b, answer: a + b };
  }
  if (op === "sub") {
    const a = rand(2, cfg.range);
    const b = rand(1, a - 1);
    return { op, a, b, answer: a - b };
  }
  // mul/div are built from a times-table fact: n (chosen table) × k (1–factorMax)
  const n = pick(cfg.tables);
  const k = rand(TABLE_MIN, cfg.factorMax || TABLE_MAX);
  if (op === "mul") {
    const [a, b] = Math.random() < 0.5 ? [n, k] : [k, n];
    return { op, a, b, fa: n, fb: k, answer: a * b };
  }
  // div: product ÷ one factor = the other
  const product = n * k;
  const [d, ans] = Math.random() < 0.5 ? [n, k] : [k, n];
  return { op, a: product, b: d, fa: n, fb: k, answer: ans };
}

// turn "a ∘ b = ?" into "a ∘ _ = result"; the kid finds the hidden operand.
// For × the visible operand is always a chosen table number, so an unchosen
// number never appears on the left side.
function toBlank(q) {
  if (q.op === "mul") { q.a = q.fa; q.b = q.fb; }
  q.result = q.op === "mul" ? q.fa * q.fb : q.answer;
  q.answer = q.b;
  q.blank = true;
  return q;
}

function questionText(q) {
  if (q.op === "time") return q.dual ? T().whatTime2 : T().whatTime;
  if (q.blank) return `${q.a} ${OP_SYMBOL[q.op]} _ = ${q.result}`;
  return `${q.a} ${OP_SYMBOL[q.op]} ${q.b} = ?`;
}

// kindergarten shapes: each operand packed into a square-ish block so the
// whole equation stays on one line; big counts step the size down a notch
function shapesHTML(q) {
  const cols = n => Math.ceil(Math.sqrt(n));
  const group = n =>
    `<div class="shape-group" style="grid-template-columns: repeat(${cols(n)}, auto)">` +
    Array.from({ length: n }, () => `<span>${q.emoji}</span>`).join("") +
    `</div>`;
  const sizes = ["s", "m", "l"];
  let si = sizes.indexOf(settings.kgSize);
  const total = q.a + q.b;
  if (total > 8) si--;
  if (total > 14) si--;
  const size = sizes[Math.max(0, si)];
  return `<div class="shape-q size-${size}">${group(q.a)}<div class="shape-op">${OP_SYMBOL[q.op]}</div>${group(q.b)}<div class="shape-op">= ?</div></div>`;
}

function daypartKey(h) { return h < 12 ? "morning" : h < 18 ? "afternoon" : "evening"; }

// shrink the whole shapes equation until it fits inside the question card
function fitShapes() {
  const qEl = $("question");
  const row = qEl.querySelector(".shape-q");
  if (!row) return;
  row.style.zoom = "";
  const avail = qEl.clientWidth;
  const need = row.scrollWidth;
  if (need > avail) row.style.zoom = Math.max(0.4, (avail / need) * 0.97);
}
window.addEventListener("resize", fitShapes);

function fmtTime(v) { return `${Math.floor(v / 100)}:${String(v % 100).padStart(2, "0")}`; }

function answerText(q) {
  if (q.op === "time") return q.dual ? `${fmtTime(q.answer)} / ${fmtTime(q.answer2)}` : fmtTime(q.answer);
  return String(q.answer);
}

// entry digits -> display string ("315" -> "3:15" in time mode)
function entryDisplay(entry, q) {
  if (q.op === "time" && entry.length >= 3) {
    return entry.slice(0, -2) + ":" + entry.slice(-2);
  }
  return entry;
}

// parse a time-mode entry into the h*100+m form; "3" means 3:00
function parseTimeEntry(entry) {
  if (entry.length <= 2) return parseInt(entry, 10) * 100;
  return parseInt(entry.slice(0, -2), 10) * 100 + parseInt(entry.slice(-2), 10);
}

/* ================= analog clock (SVG) ================= */
// night: dark clock face for evening hours on the 24h clock
function clockSVG(h, m, night) {
  const face = night ? "#1e2a4a" : "#fff";
  const majorTick = night ? "#a5b4fc" : "#7c5cff";
  const minorTick = night ? "#46538a" : "#d5cdfa";
  const numbers = night ? "#f1f5f9" : "#2d2a45";
  const hourHand = night ? "#f8fafc" : "#2d2a45";
  const parts = [];
  parts.push(`<svg viewBox="0 0 200 200" role="img">`);
  parts.push(`<circle cx="100" cy="100" r="94" fill="${face}" stroke="#7c5cff" stroke-width="8"/>`);
  for (let i = 0; i < 60; i++) {
    const major = i % 5 === 0;
    const a = (i * 6) * Math.PI / 180;
    const r1 = major ? 78 : 84, r2 = 88;
    parts.push(`<line x1="${100 + r1 * Math.sin(a)}" y1="${100 - r1 * Math.cos(a)}" x2="${100 + r2 * Math.sin(a)}" y2="${100 - r2 * Math.cos(a)}" stroke="${major ? majorTick : minorTick}" stroke-width="${major ? 3 : 1.5}" stroke-linecap="round"/>`);
  }
  for (let n = 1; n <= 12; n++) {
    const a = (n * 30) * Math.PI / 180;
    parts.push(`<text x="${100 + 64 * Math.sin(a)}" y="${100 - 64 * Math.cos(a)}" font-size="19" font-weight="800" fill="${numbers}" text-anchor="middle" dominant-baseline="central" font-family="inherit">${n}</text>`);
  }
  const hourDeg = ((h % 12) + m / 60) * 30;
  const minDeg = m * 6;
  parts.push(`<line x1="100" y1="100" x2="100" y2="62" stroke="${hourHand}" stroke-width="8" stroke-linecap="round" transform="rotate(${hourDeg} 100 100)"/>`);
  parts.push(`<line x1="100" y1="100" x2="100" y2="34" stroke="#ff6b81" stroke-width="5" stroke-linecap="round" transform="rotate(${minDeg} 100 100)"/>`);
  parts.push(`<circle cx="100" cy="100" r="6" fill="#ff9f43"/>`);
  parts.push(`</svg>`);
  return parts.join("");
}

// on the 24h clock, every hour from 12:00 on shows the dark face
function isNightHour(q) { return !!q.clock24 && q.a >= 12; }

/* ================= sounds (tiny WebAudio blips) ================= */
let audioCtx = null;
function beep(freqs, dur, vol = 0.15) {
  if (!settings.sound) return;
  try {
    audioCtx = audioCtx || new (window.AudioContext || window.webkitAudioContext)();
    freqs.forEach((f, i) => {
      const o = audioCtx.createOscillator(), g = audioCtx.createGain();
      o.type = "sine"; o.frequency.value = f;
      g.gain.setValueAtTime(vol, audioCtx.currentTime + i * dur);
      g.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + (i + 1) * dur);
      o.connect(g).connect(audioCtx.destination);
      o.start(audioCtx.currentTime + i * dur);
      o.stop(audioCtx.currentTime + (i + 1) * dur);
    });
  } catch {}
}
const soundGood = () => beep([660, 880], 0.12);
const soundBad = () => beep([220, 180], 0.18);
const soundTick = () => beep([1250], 0.05, 0.07);

/* ================= setup screen ================= */
function makeChips(rowId, values, dataKey, onTap) {
  const row = $(rowId);
  row.innerHTML = "";
  for (const v of values) {
    const b = document.createElement("button");
    b.type = "button"; b.className = "chip"; b.textContent = v; b.dir = "ltr";
    b.dataset[dataKey] = v;
    b.onclick = () => { onTap(v); refreshSetup(); };
    row.appendChild(b);
  }
}

function buildSetup() {
  makeChips("range-row", RANGE_OPTIONS, "range", v => { settings.range = v; });
  makeChips("count-row", COUNT_OPTIONS, "count", v => { settings.count = v; });
  makeChips("kgrange-row", KG_RANGE_OPTIONS, "kgrange", v => { settings.kgRange = v; });
  makeChips("tables-row", Array.from({ length: TABLE_MAX }, (_, i) => i + 1), "table", v => {
    const i = settings.tables.indexOf(v);
    i >= 0 ? settings.tables.splice(i, 1) : settings.tables.push(v);
  });

  document.querySelectorAll(".mode-chip").forEach(chip => {
    chip.onclick = () => { settings.mode = chip.dataset.mode; refreshSetup(); };
  });
  document.querySelectorAll("#op-row .op-chip").forEach(chip => {
    chip.onclick = () => {
      const op = chip.dataset.op;
      const list = settings.mode === "kg" ? settings.kgOps : settings.ops;
      const i = list.indexOf(op);
      i >= 0 ? list.splice(i, 1) : list.push(op);
      refreshSetup();
    };
  });
  document.querySelectorAll("#style-row .op-chip").forEach(chip => {
    chip.onclick = () => { settings.kgStyle = chip.dataset.style; refreshSetup(); };
  });
  document.querySelectorAll("#kgtimer-row .chip").forEach(chip => {
    chip.onclick = () => { settings.kgTimer = chip.dataset.kgtimer === "1"; refreshSetup(); };
  });
  document.querySelectorAll("#kgsize-row .chip").forEach(chip => {
    chip.onclick = () => { settings.kgSize = chip.dataset.kgsize; refreshSetup(); };
  });
  document.querySelectorAll("#timelevel-row .chip").forEach(chip => {
    chip.onclick = () => { settings.timeLevel = +chip.dataset.timelevel; refreshSetup(); };
  });
  document.querySelectorAll("#clockmode-row .chip").forEach(chip => {
    chip.onclick = () => { settings.clockMode = chip.dataset.cmode; refreshSetup(); };
  });
  document.querySelectorAll("#timeinput-row .chip").forEach(chip => {
    chip.onclick = () => { settings.timeInput = chip.dataset.timeinput; refreshSetup(); };
  });
  document.querySelectorAll("#qformat-row .chip").forEach(chip => {
    chip.onclick = () => { settings.qFormat = chip.dataset.qformat; refreshSetup(); };
  });
  document.querySelectorAll("#factor-row .chip").forEach(chip => {
    chip.onclick = () => { settings.factorMax = +chip.dataset.factor; refreshSetup(); };
  });
  document.querySelectorAll("#auto-row .chip").forEach(chip => {
    chip.onclick = () => { settings.autoSubmit = chip.dataset.auto === "1"; refreshSetup(); };
  });
  document.querySelectorAll("#diff-row .chip").forEach(chip => {
    chip.onclick = () => { settings.difficulty = chip.dataset.diff; refreshSetup(); };
  });
  document.querySelectorAll("#game-row .chip").forEach(chip => {
    chip.onclick = () => { settings.gameScore = +chip.dataset.game; refreshSetup(); };
  });
  document.querySelectorAll(".lang-chip:not(.sound-btn)").forEach(chip => {
    chip.onclick = () => { settings.lang = chip.dataset.lang; applyLang(); refreshSetup(); };
  });
  $("btn-sound").onclick = () => { settings.sound = !settings.sound; refreshSetup(); };
  $("btn-start").onclick = startQuiz;
}

function refreshSetup() {
  const mode = settings.mode;
  const kg = mode === "kg";
  const marathon = mode === "tables";
  const activeOps = kg ? settings.kgOps : settings.ops;

  const needsRange = mode === "test" && (settings.ops.includes("add") || settings.ops.includes("sub"));
  const needsTables = marathon || (mode === "test" && (settings.ops.includes("mul") || settings.ops.includes("div")));
  const needsTimeLevel = mode === "test" && settings.ops.includes("time");

  const arithSelected = settings.ops.some(o => o !== "time");
  $("ops-group").hidden = marathon;
  $("qformat-group").hidden = !(mode === "test" && arithSelected);
  $("kgrange-group").hidden = !kg;
  $("style-group").hidden = !kg;
  $("kgsize-group").hidden = !(kg && settings.kgStyle === "shapes");
  $("kgtimer-group").hidden = !kg;
  $("range-group").hidden = !needsRange;
  $("tables-group").hidden = !needsTables;
  $("factor-group").hidden = !needsTables;
  $("tables-note").hidden = !marathon;
  $("timelevel-group").hidden = !needsTimeLevel;
  $("clockmode-group").hidden = !needsTimeLevel;
  $("timeinput-group").hidden = !needsTimeLevel;
  $("count-group").hidden = marathon;
  $("btn-sound").textContent = settings.sound ? "🔊" : "🔇";

  // kindergarten only offers + and −
  document.querySelectorAll("#op-row .op-chip").forEach(c => {
    const op = c.dataset.op;
    c.hidden = kg && op !== "add" && op !== "sub";
    c.classList.toggle("selected", activeOps.includes(op));
  });

  document.querySelectorAll(".mode-chip").forEach(c => c.classList.toggle("selected", c.dataset.mode === mode));
  document.querySelectorAll(".lang-chip").forEach(c => c.classList.toggle("selected", c.dataset.lang === settings.lang));
  document.querySelectorAll("#range-row .chip").forEach(c => c.classList.toggle("selected", +c.dataset.range === settings.range));
  document.querySelectorAll("#tables-row .chip").forEach(c => c.classList.toggle("selected", settings.tables.includes(+c.dataset.table)));
  document.querySelectorAll("#count-row .chip").forEach(c => c.classList.toggle("selected", +c.dataset.count === settings.count));
  document.querySelectorAll("#kgrange-row .chip").forEach(c => c.classList.toggle("selected", +c.dataset.kgrange === settings.kgRange));
  document.querySelectorAll("#style-row .op-chip").forEach(c => c.classList.toggle("selected", c.dataset.style === settings.kgStyle));
  document.querySelectorAll("#kgtimer-row .chip").forEach(c => c.classList.toggle("selected", (c.dataset.kgtimer === "1") === settings.kgTimer));
  document.querySelectorAll("#kgsize-row .chip").forEach(c => c.classList.toggle("selected", c.dataset.kgsize === settings.kgSize));
  document.querySelectorAll("#timelevel-row .chip").forEach(c => c.classList.toggle("selected", +c.dataset.timelevel === settings.timeLevel));
  document.querySelectorAll("#clockmode-row .chip").forEach(c => c.classList.toggle("selected", c.dataset.cmode === settings.clockMode));
  document.querySelectorAll("#timeinput-row .chip").forEach(c => c.classList.toggle("selected", c.dataset.timeinput === settings.timeInput));
  document.querySelectorAll("#qformat-row .chip").forEach(c => c.classList.toggle("selected", c.dataset.qformat === settings.qFormat));
  document.querySelectorAll("#factor-row .chip").forEach(c => c.classList.toggle("selected", +c.dataset.factor === settings.factorMax));
  document.querySelectorAll("#auto-row .chip").forEach(c => c.classList.toggle("selected", (c.dataset.auto === "1") === settings.autoSubmit));
  $("diff-group").hidden = kg && !settings.kgTimer;
  document.querySelectorAll("#diff-row .chip").forEach(c => c.classList.toggle("selected", c.dataset.diff === settings.difficulty));
  document.querySelectorAll("#game-row .chip").forEach(c => c.classList.toggle("selected", +c.dataset.game === settings.gameScore));

  let hint = "";
  if (!marathon && activeOps.length === 0) hint = T().hintOps;
  else if (needsTables && settings.tables.length === 0) hint = T().hintTables;
  $("setup-hint").textContent = hint;
  $("btn-start").disabled = !!hint;
  saveSettings();
}

function applyLang() {
  const t = T();
  document.documentElement.lang = settings.lang;
  document.documentElement.dir = settings.lang === "ar" ? "rtl" : "ltr";
  $("t-title").textContent = t.title;
  $("t-mode").textContent = t.mode;
  $("t-ops").textContent = t.ops;
  $("t-kgrange").textContent = t.range;
  $("t-style").textContent = t.style;
  $("t-kgtimer").textContent = t.kgTimer;
  $("t-kgsize").textContent = t.kgSize;
  $("t-range").textContent = t.range;
  $("t-tables").textContent = t.tables;
  $("t-factor").textContent = t.factorMax;
  $("tables-note").textContent = t.tablesNote;
  $("t-timelevel").textContent = t.timeLevel;
  $("t-clockmode").textContent = t.clockMode;
  $("t-timeinput").textContent = t.timeInput;
  $("t-qformat").textContent = t.qFormat;
  $("t-auto").textContent = t.auto;
  $("t-diff").textContent = t.diff;
  $("diff-note").textContent = t.diffNote;
  $("t-game").textContent = t.game;
  $("game-note").textContent = t.gameNote;
  $("btn-play-game").textContent = t.gamePlay; // finishQuiz() picks the exact label per kind
  $("go-title").textContent = t.gameOver;
  $("t-hours").textContent = t.hours;
  $("t-minutes").textContent = t.minutes;
  $("t-count").textContent = t.count;
  $("btn-start").textContent = t.start;
  $("t-score").textContent = t.score;
  $("t-review").textContent = t.review;
  $("btn-again").textContent = t.again;
  $("btn-settings").textContent = t.settings;
  $("t-mistakesTitle").textContent = t.mistakesTitle;
  $("btn-clear-mistakes").textContent = t.mistakesClear;
  $("btn-mistakes-close").textContent = t.mistakesClose;
  $("parent-hint").textContent = t.mistakesHoldHint;
  document.querySelectorAll("[data-t]").forEach(el => { el.textContent = t[el.dataset.t]; });
  renderMistakes(); // keep the log's labels current if it's open during a language switch
}

/* ================= quiz flow ================= */
function showScreen(name) {
  document.querySelectorAll(".screen").forEach(s => s.classList.remove("active"));
  $("screen-" + name).classList.add("active");
}

function buildQuestions() {
  if (settings.mode === "tables") {
    // the whole selected tables in order: n×1 … n×factorMax, then this pool's weak facts again
    const fmax = settings.factorMax;
    const tables = [...settings.tables].sort((x, y) => x - y);
    const questions = [];
    for (const n of tables) {
      for (let k = 1; k <= fmax; k++) {
        questions.push({ op: "mul", a: n, b: k, fa: n, fb: k, answer: n * k });
      }
    }
    for (const [n, k] of [...new Set(weakPool(tables).map(f => f.join("x")))].map(s => s.split("x").map(Number))) {
      if (k <= fmax) questions.push({ op: "mul", a: n, b: k, fa: n, fb: k, answer: n * k });
    }
    return questions;
  }

  if (settings.mode === "kg") {
    const range = settings.kgStyle === "shapes"
      ? Math.min(settings.kgRange, KG_SHAPES_MAX)
      : settings.kgRange;
    const cfg = { ops: [...settings.kgOps], range };
    const recent = [];
    return Array.from({ length: settings.count }, () => {
      const q = generateQuestion(cfg, recent);
      q.kg = true;
      if (!settings.kgTimer) q.untimed = true;
      if (settings.kgStyle === "shapes") { q.kgStyle = "shapes"; q.emoji = pick(EMOJIS); }
      return q;
    });
  }

  // regular quiz
  const cfg = {
    ops: [...settings.ops],
    range: settings.range,
    tables: [...settings.tables].sort((x, y) => x - y),
    factorMax: settings.factorMax,
    timeLevel: settings.timeLevel,
    clockMode: settings.clockMode,
    qFormat: settings.qFormat,
  };
  cfg.weakQs = weakQuestions(cfg);
  const recent = [];
  return Array.from({ length: settings.count }, () => generateQuestion(cfg, recent));
}

function startQuiz() {
  const questions = buildQuestions();
  quiz = { questions, mode: settings.mode, index: 0, correct: 0, points: 0, missed: [], timerId: null, timerStart: 0, timerTotal: 1, locked: false, entry: "" };
  showScreen("quiz");
  nextQuestion();
}

let quiz = null;

function usesPick(q) {
  return q.op === "time" && settings.timeInput === "pick";
}

function nextQuestion() {
  const q = quiz.questions[quiz.index];
  quiz.entry = "";
  quiz.pickH = null;
  quiz.pickM = null;
  quiz.locked = false;
  quiz.overtime = false;
  const qEl = $("question");
  if (q.kgStyle === "shapes") {
    qEl.innerHTML = shapesHTML(q);
    qEl.classList.add("shapes");
    requestAnimationFrame(fitShapes);
  } else {
    qEl.textContent = questionText(q);
    qEl.classList.remove("shapes");
  }
  $("quiz-wrap").classList.toggle("time-side", q.op === "time");
  const clock = $("clock");
  const daypart = $("daypart");
  if (q.op === "time") {
    clock.innerHTML = clockSVG(q.a, q.b, isNightHour(q));
    clock.hidden = false;
    daypart.textContent = q.clock24 ? T()[daypartKey(q.a)] : "";
    daypart.hidden = !q.clock24;
  } else {
    clock.hidden = true;
    clock.innerHTML = "";
    daypart.hidden = true;
  }
  quiz.dualLeft = q.dual ? new Set([q.answer, q.answer2]) : null;
  const pick = usesPick(q);
  $("numpad").hidden = pick;
  $("numpad").classList.toggle("no-ok", settings.autoSubmit);
  $("time-pick").hidden = !pick;
  $("pick-ok").hidden = settings.autoSubmit;
  if (pick) buildPickRows(q);
  $("answer-box").textContent = " ";
  $("answer-box").className = "answer-box";
  $("feedback").textContent = "";
  $("feedback").className = "feedback";
  $("progress-text").textContent = `${quiz.index + 1} / ${quiz.questions.length}`;
  $("score-pill").textContent = `⭐ ${Math.round(quiz.points)}`;
  $("timebar-row").hidden = !!q.untimed;
  if (q.untimed) {
    // no time pressure: full speed bonus for every correct answer
    stopTimer();
    quiz.timerStart = performance.now();
    quiz.timerTotal = Infinity;
  } else {
    // two readings take longer than one
    startTimer(q.dual ? Math.round(timeFor() * 1.5) : timeFor());
  }
}

/* ---- pick-style time input: a row of hours, a row of minutes ---- */
function buildPickRows(q) {
  // 24-hour and dual modes include midnight (0); plain 12-hour clocks never show 0
  const hours = (q.clock24 || q.dual)
    ? Array.from({ length: 24 }, (_, i) => i)
    : Array.from({ length: 12 }, (_, i) => i + 1);
  const minutes = settings.timeLevel === 1 ? [0, 15, 30, 45] : Array.from({ length: 12 }, (_, i) => i * 5);
  fillPickRow("hour-row", hours, h => String(h), h => { quiz.pickH = h; pickUpdate(); });
  fillPickRow("minute-row", minutes, m => String(m).padStart(2, "0"), m => { quiz.pickM = m; pickUpdate(); });
  pickUpdate();
}

function fillPickRow(rowId, values, label, onTap) {
  const row = $(rowId);
  row.innerHTML = "";
  for (const v of values) {
    const b = document.createElement("button");
    b.type = "button"; b.className = "pchip"; b.textContent = label(v);
    b.onclick = () => { if (quiz && !quiz.locked) onTap(v); };
    b.dataset.val = v;
    row.appendChild(b);
  }
}

function pickUpdate() {
  const h = quiz.pickH, m = quiz.pickM;
  document.querySelectorAll("#hour-row .pchip").forEach(b => b.classList.toggle("selected", +b.dataset.val === h));
  document.querySelectorAll("#minute-row .pchip").forEach(b => b.classList.toggle("selected", +b.dataset.val === m));
  $("answer-box").textContent = `${h == null ? "–" : h}:${m == null ? "––" : String(m).padStart(2, "0")}`;
  $("pick-ok").disabled = h == null || m == null;
  // instant mode: submit as soon as both hour and minute are chosen
  if (settings.autoSubmit && h != null && m != null && !quiz.locked) submit();
}

function startTimer(seconds) {
  stopTimer();
  const total = seconds * 1000;
  const start = performance.now();
  quiz.timerStart = start;
  quiz.timerTotal = total;
  const bar = $("timebar");
  bar.className = "timebar";
  bar.style.width = "100%";
  $("time-left").textContent = seconds;
  let lastTick = -1;
  quiz.timerId = setInterval(() => {
    const left = total - (performance.now() - start);
    const frac = Math.max(0, left / total);
    const secLeft = Math.max(0, Math.ceil(left / 1000));
    bar.style.width = (frac * 100) + "%";
    bar.className = "timebar" + (frac < 0.25 ? " danger" : frac < 0.5 ? " warn" : "");
    $("time-left").textContent = secLeft;
    if (secLeft <= 5 && secLeft >= 1 && secLeft !== lastTick) { lastTick = secLeft; soundTick(); }
    if (left <= 0) {
      stopTimer();
      // easy mode keeps accepting answers after the buzzer, for fewer points
      if (settings.difficulty === "easy") enterOvertime();
      else onTimeout();
    }
  }, 100);
}

function enterOvertime() {
  quiz.overtime = true;
  $("timebar").style.width = "0%";
  $("timebar").className = "timebar danger";
  $("time-left").textContent = "0";
  $("feedback").textContent = T().overtime;
  $("feedback").className = "feedback";
}
function stopTimer() {
  if (quiz && quiz.timerId) { clearInterval(quiz.timerId); quiz.timerId = null; }
}

// how many digits a fully-typed answer should be. For time questions this must
// come from the hour itself (String(q.a).length), not String(q.answer).length —
// a midnight hour (0) contributes no digits to the numeric answer value, so
// deriving expected length from the answer alone would under-count by one.
function expectedEntryLength(q) {
  if (q.op === "time") return String(q.a).length + 2; // hour digits + always-2-digit minutes
  return String(q.answer).length;
}

function onKey(key) {
  if (!quiz || quiz.locked) return;
  const q = quiz.questions[quiz.index];
  if (usesPick(q)) return; // this question is answered with the hour/minute rows
  if (key === "back") { quiz.entry = quiz.entry.slice(0, -1); }
  else if (key === "ok") { if (quiz.entry !== "") submit(); return; }
  else if (quiz.entry.length < 4) {
    quiz.entry += key;
    // instant mode: submit as soon as the expected number of digits is typed
    // (dual clock: either reading may come first, so match against both)
    const full = q.dual
      ? (quiz.dualLeft && quiz.dualLeft.has(parseTimeEntry(quiz.entry))) || quiz.entry.length >= 4
      : quiz.entry.length >= expectedEntryLength(q);
    if (settings.autoSubmit && full) {
      $("answer-box").textContent = entryDisplay(quiz.entry, q);
      submit();
      return;
    }
  }
  $("answer-box").textContent = entryDisplay(quiz.entry, q) || " ";
}

function submit() {
  const q = quiz.questions[quiz.index];
  const given = q.op === "time"
    ? (usesPick(q) ? quiz.pickH * 100 + quiz.pickM : parseTimeEntry(quiz.entry))
    : parseInt(quiz.entry, 10);
  // dual clock: the first correct reading keeps the question open for the second
  if (q.dual && quiz.dualLeft.size === 2 && quiz.dualLeft.has(given)) {
    quiz.dualLeft.delete(given);
    quiz.entry = "";
    $("feedback").textContent = `✓ ${fmtTime(given)}`;
    $("feedback").className = "feedback good";
    if (usesPick(q)) { quiz.pickH = null; pickUpdate(); }
    else $("answer-box").textContent = " ";
    beep([880], 0.09);
    return;
  }
  const frac = Math.max(0, 1 - (performance.now() - quiz.timerStart) / quiz.timerTotal);
  stopTimer();
  quiz.locked = true;
  const good = q.dual ? quiz.dualLeft.has(given) : given === q.answer;
  if (good) {
    // faster answers earn more: full question value instantly, half at the buzzer,
    // and a small share for overtime answers on easy difficulty
    const maxPts = 1000 / quiz.questions.length;
    const pts = quiz.overtime ? maxPts * OVERTIME_FACTOR : maxPts * (0.5 + 0.5 * frac);
    quiz.correct++;
    quiz.points += pts;
    recordResult(q, true);
    $("answer-box").classList.add("correct");
    $("feedback").textContent = `${pick(T().good)} +${Math.round(pts)}`;
    $("feedback").classList.add("good");
    $("score-pill").textContent = `⭐ ${Math.round(quiz.points)}`;
    soundGood();
    setTimeout(advance, 900);
  } else {
    quiz.missed.push(q);
    recordResult(q, false);
    recordMistake(q, q.op === "time" ? fmtTime(given) : String(given));
    $("answer-box").classList.add("wrong");
    $("feedback").textContent = `${T().answerIs}: ${answerText(q)}`;
    $("feedback").classList.add("bad");
    soundBad();
    setTimeout(advance, 2000);
  }
}

function onTimeout() {
  const q = quiz.questions[quiz.index];
  quiz.locked = true;
  quiz.missed.push(q);
  recordResult(q, false);
  recordMistake(q, null);
  $("answer-box").textContent = answerText(q);
  $("answer-box").classList.add("wrong");
  $("feedback").textContent = `${T().timeUp} ${T().answerIs}: ${answerText(q)}`;
  $("feedback").classList.add("bad");
  soundBad();
  setTimeout(advance, 2200);
}

function advance() {
  if (!quiz) return; // quit was pressed during feedback
  quiz.index++;
  if (quiz.index >= quiz.questions.length) finishQuiz();
  else nextQuestion();
}

function finishQuiz() {
  stopTimer();
  const total = quiz.questions.length;
  const score = Math.round(quiz.points);
  const stars = score >= 900 ? 3 : score >= 700 ? 2 : score >= 450 ? 1 : 0;
  $("stars").textContent = stars ? "⭐".repeat(stars) : "🌱";
  $("final-score").innerHTML = `${score} <span class="of-1000">/ 1000</span>`;
  $("sub-score").textContent = `✓ ${quiz.correct} / ${total}`;
  $("cheer").textContent = T()["cheer" + stars];

  // qualifying score earns one round of the reward game. A quiz that mixed
  // Time with other operations earns the mixed game (falling clocks AND
  // equations together); a quiz of just one kind earns that game alone.
  const gk = gameKindForCurrentSettings();
  const label = gk === "mixed" ? T().gamePlayMixed : gk === "clock" ? T().gamePlayClock : T().gamePlay;
  $("btn-play-game").textContent = label;
  $("btn-play-game").hidden = !(settings.gameScore > 0 && score >= settings.gameScore);

  const best = loadBest();
  const bestLine = $("best-line");
  if (score > (best[quiz.mode] || 0)) {
    best[quiz.mode] = score;
    saveBest(best);
    bestLine.textContent = T().newRecord;
    bestLine.classList.add("record");
  } else {
    bestLine.textContent = `${T().best}: ${best[quiz.mode] || 0}`;
    bestLine.classList.remove("record");
  }

  const missedWrap = $("missed-wrap");
  const list = $("missed-list");
  list.innerHTML = "";
  if (quiz.missed.length) {
    for (const q of quiz.missed) {
      const li = document.createElement("li");
      li.textContent = q.op === "time"
        ? `🕐 ${answerText(q)}`
        : q.blank
          ? `${q.a} ${OP_SYMBOL[q.op]} ${q.b} = ${q.result}`
          : `${q.a} ${OP_SYMBOL[q.op]} ${q.b} = ${q.answer}`;
      list.appendChild(li);
    }
    missedWrap.hidden = false;
  } else missedWrap.hidden = true;

  quiz = null;
  showScreen("results");
}

/* ================= Meteor Blaster (reward game) ================= */
let game = null;

// Which reward game a just-finished quiz earns. Kindergarten/tables modes never
// include Time, so they're always "num". A quiz that mixed Time with other
// operations earns "mixed" — a single game where falling clocks and falling
// equations both appear, matching what was actually practiced.
function gameKindForCurrentSettings() {
  if (settings.mode !== "test") return "num";
  const hasTime = settings.ops.includes("time");
  const hasOther = settings.ops.some(o => o !== "time");
  if (hasTime && hasOther) return "mixed";
  return hasTime ? "clock" : "num";
}

function gameCfg() {
  let ops = (settings.mode === "kg" ? settings.kgOps : settings.ops).filter(o => o !== "time");
  if (settings.mode === "tables") ops = ["mul"];
  if (!ops.length) ops = ["add"];
  const cfg = {
    ops,
    range: settings.mode === "kg" ? settings.kgRange : settings.range,
    tables: settings.tables.length ? [...settings.tables] : [2, 3, 4, 5],
    factorMax: settings.factorMax,
    qFormat: "result",
  };
  cfg.weakQs = weakQuestions(cfg); // the game drills tricky facts too
  return cfg;
}

// the same minute set the quiz's clock questions use for this difficulty level —
// Clock Blaster matches it exactly and never changes it mid-game
function clockMinuteSet() {
  return settings.timeLevel === 1 ? [0, 15, 30, 45] : Array.from({ length: 12 }, (_, i) => i * 5);
}

// clock times the kid has previously misread, so Clock Blaster can bring them
// back — filtered to the minute set actually in play this game, so a mismatched
// leftover (e.g. saved from a quiz run at the other clock difficulty) never appears
function loadWeakClockTimes(minutes) {
  const w = loadWeak();
  const out = [];
  for (const key of Object.keys(w)) {
    const m = key.match(/^time:(\d+):(\d+)$/);
    if (m && minutes.includes(+m[2])) for (let i = 0; i < w[key]; i++) out.push({ h: +m[1], m: +m[2] });
  }
  return out;
}

// Hours run the full 0-23 (24-hour) range, including midnight (0); the clock
// face itself still only ever shows 1-12 (that's all an analog face can show,
// with 0 rendering at the same "12" position as 12 itself), so the dark/light
// face is the only cue for which half of the day it is — same convention as
// the quiz's 24-hour clock (isNightHour: dark from 12:00 onward). The minute
// set is fixed for the whole game, matching whatever the quiz's clock difficulty
// was set to — it never changes mid-game.
function randomClockTime(minutes, weakTimes) {
  if (weakTimes && weakTimes.length && Math.random() < WEAK_BIAS) {
    const t = pick(weakTimes);
    return { h: t.h, m: t.m, answer: t.h * 100 + t.m, night: t.h >= 12 };
  }
  const h = rand(0, 23);
  const m = pick(minutes);
  return { h, m, answer: h * 100 + m, night: h >= 12 };
}

function startGame() {
  if ($("btn-play-game").hidden) return; // no ticket, no game
  $("btn-play-game").hidden = true; // the ticket is spent
  document.querySelectorAll("#sky .meteor").forEach(m => m.remove());
  $("game-over").hidden = true;
  const kind = gameKindForCurrentSettings(); // "num" | "clock" | "mixed"
  // "clock" and "mixed" both show exactly one object at a time: it falls, gets
  // answered (or lands), then there's a clear empty-sky pause before the next
  // one appears. "mixed" additionally alternates between a falling equation
  // and a falling clock, switching the input UI (numpad vs picker) to match
  // whichever is currently live.
  const singleObject = kind !== "num";
  const clockMinutes = clockMinuteSet(); // fixed for the whole game — matches the quiz's clock difficulty
  game = {
    kind,
    cfg: kind !== "clock" ? gameCfg() : null, recent: [],
    clockMinutes, weakTimes: kind !== "num" ? loadWeakClockTimes(clockMinutes) : [],
    pickH: null, pickM: null, currentIsClock: false,
    lanes: singleObject ? [null] : null,
    score: 0, lives: 3, meteors: [], entry: "",
    // the single-object games start noticeably slower than Meteor Blaster —
    // reading a clock face (or watching for either kind) takes longer than
    // just reading digits. spawnEvery is the empty-sky pause between one
    // object resolving and the next appearing.
    speed: singleObject ? 10 : 26,
    spawnEvery: singleObject ? 2600 : 3000,
    sinceSpawn: singleObject ? 1000 : 2500,
    maxItems: singleObject ? 1 : 4,
    over: false, prev: performance.now(), raf: null,
  };
  updateGameHud();
  if (kind === "clock") renderGamePickRows();
  else if (kind === "mixed") renderGamePickRows(); // built once, reused whenever a clock spawns
  switchInputUI(kind === "clock");
  showScreen("game");
  game.raf = requestAnimationFrame(gameTick);
}

// toggles the numpad vs the hour/minute picker — called once at game start for
// "num"/"clock", and again on every spawn in "mixed" mode since the type varies
function switchInputUI(isClock) {
  game.currentIsClock = isClock;
  $("sky").classList.toggle("clock-sky", isClock);
  $("game-numpad").hidden = isClock;
  $("game-pick").hidden = !isClock;
  game.entry = "";
  game.pickH = null; game.pickM = null;
  document.querySelectorAll(".game-hour-pick .pchip, #game-minute-row .pchip").forEach(b => b.classList.remove("selected", "wrongflash"));
  $("game-entry").textContent = " ";
}

function updateGameHud() {
  $("game-lives").textContent = "❤️".repeat(game.lives) || "💔";
  $("game-score").textContent = `${game.currentIsClock ? "⏰" : "☄️"} ${game.score}`;
}

function gameTick(now) {
  if (!game || game.over) return;
  const dt = Math.min(0.1, (now - game.prev) / 1000);
  game.prev = now;
  const sky = $("sky");
  const H = sky.clientHeight;
  game.sinceSpawn += dt * 1000;
  if (game.sinceSpawn >= game.spawnEvery && game.meteors.length < game.maxItems) {
    spawnMeteor();
    game.sinceSpawn = 0;
  }
  for (const m of [...game.meteors]) {
    m.y += game.speed * dt;
    m.el.style.top = m.y + "px";
    // clock faces are bigger and their size is responsive, so measure the
    // actual element instead of assuming a fixed footprint like the meteors
    const landY = H - (m.el.offsetHeight || (m.isClock ? 110 : 52));
    if (m.y > landY) meteorLanded(m);
  }
  game.raf = requestAnimationFrame(gameTick);
}

function spawnMeteor() {
  if (game.kind === "clock") { spawnClockMeteor(); return; }
  if (game.kind === "num") { spawnNumMeteor(); return; }
  // mixed: a coin flip decides what falls next, then the input UI switches to match
  if (Math.random() < 0.5) spawnClockMeteor(); else spawnNumMeteor();
}

function spawnNumMeteor() {
  const q = generateQuestion(game.cfg, game.recent);
  const el = document.createElement("div");
  el.className = "meteor";
  el.dir = "ltr"; // equations always read left-to-right, even in the Arabic UI
  el.textContent = `${q.a} ${OP_SYMBOL[q.op]} ${q.b}`;
  el.style.left = (5 + Math.random() * 62) + "%";
  el.style.top = "-50px";
  $("sky").appendChild(el);
  game.meteors.push({ q, el, y: -50, isClock: false });
  if (game.kind === "mixed") switchInputUI(false);
}

function spawnClockMeteor() {
  const lane = game.lanes.indexOf(null);
  if (lane === -1) return; // every lane occupied — wait for one to clear
  let t;
  for (let attempt = 0; attempt < 8; attempt++) {
    t = randomClockTime(game.clockMinutes, game.weakTimes);
    if (!game.meteors.some(x => x.answer === t.answer)) break;
  }
  const el = document.createElement("div");
  el.className = "meteor clock-meteor";
  el.dir = "ltr";
  el.innerHTML = clockSVG(t.h, t.m, t.night);
  el.style.top = "-160px";
  const sky = $("sky");
  sky.appendChild(el);
  // fixed side-by-side lanes computed from the clock's actual rendered size —
  // this is what actually prevents overlap, not the fall speed or spawn timing
  const skyW = sky.clientWidth || 300;
  const size = el.offsetWidth || 110;
  const laneW = skyW / game.lanes.length;
  let x = lane * laneW + (laneW - size) / 2;
  x = Math.max(4, Math.min(skyW - size - 4, x));
  el.style.left = x + "px";
  const meteor = { answer: t.answer, el, y: -160, lane, isClock: true };
  game.lanes[lane] = meteor;
  game.meteors.push(meteor);
  if (game.kind === "mixed") switchInputUI(true);
}

function removeMeteor(m) {
  game.meteors = game.meteors.filter(x => x !== m);
  m.el.remove();
}

function meteorLanded(m) {
  m.el.textContent = "💥";
  m.el.classList.add("boom");
  const el = m.el;
  game.meteors = game.meteors.filter(x => x !== m);
  setTimeout(() => el.remove(), 400);
  if (m.isClock && m.lane != null) game.lanes[m.lane] = null;
  game.lives--;
  updateGameHud();
  soundBad();
  if (game.lives <= 0) { endGame(); return; }
  // fresh sky after losing a life: clear everything, keep the pace,
  // and leave a short breather before objects fall again
  for (const other of game.meteors) other.el.remove();
  if (game.lanes) game.lanes.fill(null);
  game.meteors = [];
  game.entry = "";
  $("game-entry").textContent = " ";
  game.sinceSpawn = -1500;
  if (m.isClock) {
    game.pickH = null; game.pickM = null;
    document.querySelectorAll(".game-hour-pick .pchip, #game-minute-row .pchip").forEach(b => b.classList.remove("selected", "wrongflash"));
  }
}

function blast(m) {
  m.el.textContent = "💥";
  m.el.classList.add("boom");
  const el = m.el;
  game.meteors = game.meteors.filter(x => x !== m);
  setTimeout(() => el.remove(), 400);
  if (m.isClock && m.lane != null) game.lanes[m.lane] = null;
  game.score += 10;
  // every blast makes the sky a little angrier
  game.speed += 1.5;
  if (game.kind === "num") {
    game.spawnEvery = Math.max(1300, game.spawnEvery - 55);
  } else {
    // clock or mixed: single-object pacing — the pause always starts counting
    // from THIS moment (when the object is resolved), not from whenever it
    // originally fell — that's what guarantees a real gap before the next one,
    // however fast the answer was. Clock minute difficulty stays fixed all
    // game (matches the quiz's clock setting); only pace ramps up with hits.
    game.sinceSpawn = 0;
    game.spawnEvery = Math.max(1800, game.spawnEvery - 55);
  }
  updateGameHud();
  beep([880, 1320], 0.08);
}

function gameKey(key) {
  if (!game || game.over) return;
  if (game.currentIsClock) { gameKeyClock(key); return; }
  if (key === "back") game.entry = game.entry.slice(0, -1);
  else if (game.entry.length < 4) game.entry += key;
  const val = parseInt(game.entry, 10);
  // the lowest matching meteor is the most urgent one
  const hit = game.meteors.filter(m => !m.isClock && m.q.answer === val).sort((a, b) => b.y - a.y)[0];
  if (hit) {
    blast(hit);
    game.entry = "";
  } else {
    const numAnswers = game.meteors.filter(m => !m.isClock).map(m => String(m.q.answer).length);
    if (numAnswers.length && game.entry.length >= Math.max(1, ...numAnswers)) {
      game.entry = ""; // full-length miss: clear for the next try
    }
  }
  $("game-entry").textContent = game.entry || " ";
}

// digit-typing fallback for a physical keyboard; the on-screen UI for clock
// kind shows the hour/minute picker below instead (see renderGamePickRows)
function gameKeyClock(key) {
  if (key === "back") game.entry = game.entry.slice(0, -1);
  else if (game.entry.length < 4) game.entry += key;
  const val = game.entry ? parseTimeEntry(game.entry) : NaN;
  const hit = game.meteors.filter(m => m.isClock && m.answer === val).sort((a, b) => b.y - a.y)[0];
  if (hit) {
    blast(hit);
    game.entry = "";
  } else if (game.entry.length >= 4) {
    game.entry = ""; // exhausted digits without a match: start over
  }
  $("game-entry").textContent = game.entry ? entryDisplay(game.entry, { op: "time" }) : " ";
}

/* ---- Clock Blaster's hour/minute picker: tap, no typing ---- */
function fillGamePickRow(rowId, values, label, onTap) {
  const row = $(rowId);
  row.innerHTML = "";
  for (const v of values) {
    const b = document.createElement("button");
    b.type = "button"; b.className = "pchip"; b.textContent = label(v);
    b.onclick = () => { if (game && !game.over) onTap(v); };
    b.dataset.val = v;
    row.appendChild(b);
  }
}

function renderGamePickRows() {
  // full 24-hour range (0-23, including midnight) split evenly across two rows:
  // 0-11, then 12-23 — the clock face's dark/light color is the only cue for
  // which row the answer is in (light for 0-11, dark for 12-23)
  const hours1 = Array.from({ length: 12 }, (_, i) => i);
  const hours2 = Array.from({ length: 12 }, (_, i) => i + 12);
  // fixed for the whole game — matches the quiz's clock difficulty setting
  fillGamePickRow("game-hour-row", hours1, h => String(h), h => { game.pickH = h; gamePickTry(); });
  fillGamePickRow("game-hour-row2", hours2, h => String(h), h => { game.pickH = h; gamePickTry(); });
  fillGamePickRow("game-minute-row", game.clockMinutes, m => String(m).padStart(2, "0"), m => { game.pickM = m; gamePickTry(); });
  $("game-entry").textContent = " ";
}

function gamePickTry() {
  const h = game.pickH, m = game.pickM;
  document.querySelectorAll(".game-hour-pick .pchip").forEach(b => b.classList.toggle("selected", +b.dataset.val === h));
  document.querySelectorAll("#game-minute-row .pchip").forEach(b => b.classList.toggle("selected", +b.dataset.val === m));
  $("game-entry").textContent = `${h == null ? "–" : h}:${m == null ? "––" : String(m).padStart(2, "0")}`;
  if (h == null || m == null) return;
  const val = h * 100 + m;
  const hit = game.meteors.filter(x => x.isClock && x.answer === val).sort((a, b) => b.y - a.y)[0];
  if (hit) {
    blast(hit);
    game.pickH = null; game.pickM = null;
    document.querySelectorAll(".game-hour-pick .pchip, #game-minute-row .pchip").forEach(b => b.classList.remove("selected"));
    $("game-entry").textContent = " ";
  } else {
    // no falling clock shows that exact time yet: flash red, then let them try again
    document.querySelectorAll(".game-hour-pick .pchip.selected, #game-minute-row .pchip.selected").forEach(b => {
      b.classList.remove("wrongflash"); void b.offsetWidth; b.classList.add("wrongflash");
    });
    soundBad();
    setTimeout(() => {
      if (!game || game.over) return;
      game.pickH = null; game.pickM = null;
      document.querySelectorAll(".game-hour-pick .pchip, #game-minute-row .pchip").forEach(b => b.classList.remove("selected", "wrongflash"));
      $("game-entry").textContent = " ";
    }, 380);
  }
}

function endGame() {
  game.over = true;
  if (game.raf) cancelAnimationFrame(game.raf);
  const best = loadBest();
  const bestKey = game.kind === "clock" ? "clockBlaster" : game.kind === "mixed" ? "mixedBlaster" : "meteor";
  const prev = best[bestKey] || 0;
  $("go-title").textContent = game.kind === "num" ? T().gameOver : T().gameOver.replace("☄️", game.kind === "mixed" ? "🎮⏰" : "⏰");
  $("go-score").textContent = `${game.kind === "num" ? "☄️" : game.kind === "mixed" ? "🎮⏰" : "⏰"} ${game.score}`;
  if (game.score > prev) {
    best[bestKey] = game.score;
    saveBest(best);
    $("go-best").textContent = T().newRecord;
  } else {
    $("go-best").textContent = `${T().best}: ${prev}`;
  }
  $("game-over").hidden = false;
}

function quitGame(target) {
  if (game && game.raf) cancelAnimationFrame(game.raf);
  game = null;
  showScreen(target);
}

$("game-numpad").addEventListener("click", e => {
  const key = e.target.closest(".key");
  if (key) gameKey(key.dataset.key);
});
$("btn-play-game").onclick = startGame;
$("btn-game-quit").onclick = () => quitGame("results");
$("btn-game-done").onclick = () => quitGame("results");

/* ================= wiring ================= */
$("numpad").addEventListener("click", e => {
  const key = e.target.closest(".key");
  if (key) onKey(key.dataset.key);
});
$("pick-ok").onclick = () => {
  if (quiz && !quiz.locked && quiz.pickH != null && quiz.pickM != null) submit();
};
document.addEventListener("keydown", e => {
  if (e.key === "Escape" && !$("mistakes-modal").hidden) { closeMistakesModal(); return; }
  if ($("screen-game").classList.contains("active")) {
    if (/^[0-9]$/.test(e.key)) gameKey(e.key);
    else if (e.key === "Backspace") gameKey("back");
    return;
  }
  if (!$("screen-quiz").classList.contains("active")) return;
  if (/^[0-9]$/.test(e.key)) onKey(e.key);
  else if (e.key === "Backspace") onKey("back");
  else if (e.key === "Enter") onKey("ok");
});
$("btn-quit").onclick = () => { stopTimer(); quiz = null; showScreen("setup"); };
$("btn-again").onclick = startQuiz;
$("btn-settings").onclick = () => showScreen("setup");

/* ================= parent mistakes log: opens on long-press only ================= */
function renderMistakes() {
  const t = T();
  const list = loadMistakes();
  const ul = $("mistake-list");
  ul.innerHTML = "";
  $("mistakes-empty").hidden = list.length > 0;
  $("mistakes-empty").textContent = t.mistakesEmpty;
  for (const m of [...list].reverse()) {
    const li = document.createElement("li");
    const date = new Date(m.ts).toLocaleString(settings.lang === "ar" ? "ar" : settings.lang === "de" ? "de" : "en", {
      month: "short", day: "numeric", hour: "2-digit", minute: "2-digit",
    });
    li.innerHTML = `
      <div class="mistake-q" dir="ltr">${m.prompt}</div>
      <div class="mistake-line given">${m.given == null ? t.mistakesNoAnswer : `${t.mistakesChild}: ${m.given}`}</div>
      <div class="mistake-line correct">${t.mistakesCorrect}: ${m.correct}</div>
      <div class="mistake-ts">${date}</div>`;
    ul.appendChild(li);
  }
}

// popup, not a screen: opens over whatever's behind it, closes with a single tap
function openMistakesModal() {
  renderMistakes();
  $("mistakes-modal").hidden = false;
}
function closeMistakesModal() {
  $("mistakes-modal").hidden = true;
}
(() => {
  const btn = $("btn-parent");
  const hint = $("parent-hint");
  const HOLD_MS = 600;
  let timer = null;
  let hintTimer = null;
  const cancel = () => { clearTimeout(timer); timer = null; btn.classList.remove("pressing"); };
  const showHint = () => {
    hint.hidden = false;
    clearTimeout(hintTimer);
    hintTimer = setTimeout(() => { hint.hidden = true; }, 1400);
  };
  btn.addEventListener("pointerdown", e => {
    e.preventDefault();
    btn.classList.add("pressing");
    hint.hidden = true;
    timer = setTimeout(() => { cancel(); openMistakesModal(); }, HOLD_MS);
  });
  btn.addEventListener("pointerup", () => {
    const wasPending = timer !== null; // released before the hold finished
    cancel();
    if (wasPending) showHint(); // a quick tap gets a hint instead of silence
  });
  btn.addEventListener("pointerleave", cancel);
  btn.addEventListener("pointercancel", cancel);
  btn.addEventListener("contextmenu", e => e.preventDefault()); // no iOS callout on long-press
})();
$("btn-mistakes-close").onclick = closeMistakesModal;
$("mistakes-backdrop").onclick = closeMistakesModal; // tap outside the card to dismiss
$("btn-clear-mistakes").onclick = () => { saveMistakes([]); renderMistakes(); };

buildSetup();
applyLang();
refreshSetup();
$("app-version").textContent = "v" + APP_VERSION;

if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => navigator.serviceWorker.register("sw.js").catch(() => {}));
}
