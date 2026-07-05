"use strict";

/* ================= tunable constants ================= */
const RANGE_OPTIONS = [10, 20, 50, 100, 500];
const COUNT_OPTIONS = [5, 10, 15, 20];
const AGE_OPTIONS = [4, 5, 6, 7];
const RANGE_BY_AGE = { 4: 5, 5: 10, 6: 15, 7: 20 };
const KG_SHAPES_MAX = 10;                 // shapes stay countable
const TABLE_MIN = 1, TABLE_MAX = 12;
const MARATHON_MAX_FACTOR = 10;           // times tables run ×1 … ×10
const WEAK_BIAS = 0.4;                    // chance a ×/÷ question is drawn from saved weak facts
const EMOJIS = ["🍎", "⭐", "🎈", "🐟", "🦋", "🍓", "⚽", "🐥"];

// per-question time (seconds), scaled by difficulty
function timeFor(q) {
  if (q.kgStyle === "shapes") return 20;  // counting shapes takes a while
  if (q.kg) return 12;
  if (q.op === "time") return 15;
  if (q.op === "add" || q.op === "sub") {
    const big = Math.max(q.a, q.b, q.answer);
    if (big > 100) return 16;
    if (big > 20) return 12;
    return 8;
  }
  // mul / div: difficulty follows the larger factor of the underlying fact
  const factor = Math.max(q.fa, q.fb);
  let t = factor <= 5 ? 8 : factor <= 9 ? 12 : 15;
  if (q.op === "div") t += 3;
  return t;
}

/* ================= i18n ================= */
const STRINGS = {
  en: {
    title: "Math Stars ⭐",
    mode: "Mode", modeTest: "Quiz", modeKg: "Kindergarten", modeTables: "Times tables",
    ops: "Choose operations",
    add: "Add", sub: "Subtract", mul: "Multiply", div: "Divide", time: "Time",
    whatTime: "What time is it?",
    age: "Age",
    style: "Show questions with", shapes: "Shapes", digits: "Digits",
    range: "Biggest answer (+ / −)",
    tables: "Numbers to practice (× / ÷)",
    tablesNote: "All questions in order: ×1 … ×10, then extra practice for tricky ones",
    timeLevel: "Clock difficulty",
    level1: "Easy: 00 · 15 · 30 · 45", level2: "Every 5 minutes",
    count: "How many questions?",
    start: "Start! 🚀",
    hintOps: "Pick at least one operation",
    hintTables: "Pick at least one number for × / ÷",
    timeUp: "Time's up! ⏰",
    answerIs: "The answer is",
    good: ["Great job! 🎉", "Awesome! ⭐", "You rock! 💪", "Super! 🌟", "Amazing! 🚀"],
    score: "Your score",
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
    age: "العمر",
    style: "شكل الأسئلة", shapes: "أشكال", digits: "أرقام",
    range: "أكبر ناتج (+ / −)",
    tables: "أرقام التدريب (× / ÷)",
    tablesNote: "كل الأسئلة بالترتيب: ×1 … ×10، ثم تدريب إضافي على الأسئلة الصعبة",
    timeLevel: "مستوى الساعة",
    level1: "سهل: 00 · 15 · 30 · 45", level2: "كل 5 دقائق",
    count: "كم عدد الأسئلة؟",
    start: "!ابدأ 🚀",
    hintOps: "اختر عملية واحدة على الأقل",
    hintTables: "اختر رقمًا واحدًا على الأقل للضرب / القسمة",
    timeUp: "انتهى الوقت! ⏰",
    answerIs: "الإجابة الصحيحة",
    good: ["أحسنت! 🎉", "رائع! ⭐", "ممتاز! 💪", "عظيم! 🌟", "مذهل! 🚀"],
    score: "نتيجتك",
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
    age: "Alter",
    style: "Aufgaben zeigen mit", shapes: "Bildern", digits: "Zahlen",
    range: "Größtes Ergebnis (+ / −)",
    tables: "Zahlen zum Üben (× / ÷)",
    tablesNote: "Alle Aufgaben der Reihe nach: ×1 … ×10, dann Extra-Übung für knifflige",
    timeLevel: "Uhr-Schwierigkeit",
    level1: "Leicht: 00 · 15 · 30 · 45", level2: "Alle 5 Minuten",
    count: "Wie viele Aufgaben?",
    start: "Los! 🚀",
    hintOps: "Wähle mindestens eine Rechenart",
    hintTables: "Wähle mindestens eine Zahl für × / ÷",
    timeUp: "Zeit ist um! ⏰",
    answerIs: "Die richtige Antwort ist",
    good: ["Super! 🎉", "Toll! ⭐", "Klasse! 💪", "Spitze! 🌟", "Fantastisch! 🚀"],
    score: "Deine Punkte",
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
  ops: ["add"], range: 20, tables: [2, 3, 4, 5], count: 10, timeLevel: 1,
  kgAge: 5, kgOps: ["add", "sub"], kgStyle: "shapes",
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
      timeLevel: s.timeLevel === 2 ? 2 : 1,
      kgAge: AGE_OPTIONS.includes(s.kgAge) ? s.kgAge : DEFAULTS.kgAge,
      kgOps: kgOps.length ? kgOps : [...DEFAULTS.kgOps],
      kgStyle: s.kgStyle === "digits" ? "digits" : "shapes",
    };
  } catch { return { ...DEFAULTS }; }
}
function saveSettings() {
  try { localStorage.setItem("mathstars-settings", JSON.stringify(settings)); } catch {}
}

/* ================= weak multiplication facts =================
   Facts (n×k) answered wrong are saved with a miss count and drawn
   more often later; correct answers work the count back down. */
function loadWeak() {
  try { return JSON.parse(localStorage.getItem("mathstars-weak")) || {}; } catch { return {}; }
}
function saveWeak(w) {
  try { localStorage.setItem("mathstars-weak", JSON.stringify(w)); } catch {}
}
function factKey(q) { return `${q.fa}x${q.fb}`; }

function recordResult(q, correct) {
  if ((q.op !== "mul" && q.op !== "div") || !q.fa) return;
  const w = loadWeak();
  const key = factKey(q);
  if (correct) {
    if (w[key]) { w[key]--; if (w[key] <= 0) delete w[key]; saveWeak(w); }
  } else {
    w[key] = Math.min(5, (w[key] || 0) + 1);
    saveWeak(w);
  }
}

// weighted pool of [n, k] facts limited to the currently selected tables
function weakPool(tables) {
  const w = loadWeak();
  const pool = [];
  for (const key of Object.keys(w)) {
    const [n, k] = key.split("x").map(Number);
    if (tables.includes(n)) for (let i = 0; i < w[key]; i++) pool.push([n, k]);
  }
  return pool;
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
    const q = makeOne(pick(cfg.ops), cfg);
    const key = `${q.op}:${q.a}:${q.b}`;
    if (!recent.includes(key) || attempt >= 40) {
      recent.push(key);
      if (recent.length > 4) recent.shift();
      return q;
    }
  }
}

function makeOne(op, cfg) {
  if (op === "time") {
    // read an analog clock; level 1 = quarter hours, level 2 = 5-minute steps
    const h = rand(1, 12);
    const m = cfg.timeLevel === 1 ? pick([0, 15, 30, 45]) : rand(0, 11) * 5;
    return { op, a: h, b: m, answer: h * 100 + m }; // 3:15 -> 315
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
  // mul/div are built from a times-table fact: n (chosen table) × k (1–12);
  // saved weak facts are drawn preferentially
  let n, k;
  if (cfg.weak && cfg.weak.length && Math.random() < WEAK_BIAS) {
    [n, k] = pick(cfg.weak);
  } else {
    n = pick(cfg.tables);
    k = rand(TABLE_MIN, TABLE_MAX);
  }
  if (op === "mul") {
    const [a, b] = Math.random() < 0.5 ? [n, k] : [k, n];
    return { op, a, b, fa: n, fb: k, answer: a * b };
  }
  // div: product ÷ one factor = the other
  const product = n * k;
  const [d, ans] = Math.random() < 0.5 ? [n, k] : [k, n];
  return { op, a: product, b: d, fa: n, fb: k, answer: ans };
}

function questionText(q) {
  if (q.op === "time") return T().whatTime;
  if (q.kgStyle === "shapes") {
    return `${q.emoji.repeat(q.a)} ${OP_SYMBOL[q.op]} ${q.emoji.repeat(q.b)} = ?`;
  }
  return `${q.a} ${OP_SYMBOL[q.op]} ${q.b} = ?`;
}

function answerText(q) {
  if (q.op === "time") return `${q.a}:${String(q.b).padStart(2, "0")}`;
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
function clockSVG(h, m) {
  const parts = [];
  parts.push(`<svg viewBox="0 0 200 200" role="img">`);
  parts.push(`<circle cx="100" cy="100" r="94" fill="#fff" stroke="#7c5cff" stroke-width="8"/>`);
  for (let i = 0; i < 60; i++) {
    const major = i % 5 === 0;
    const a = (i * 6) * Math.PI / 180;
    const r1 = major ? 78 : 84, r2 = 88;
    parts.push(`<line x1="${100 + r1 * Math.sin(a)}" y1="${100 - r1 * Math.cos(a)}" x2="${100 + r2 * Math.sin(a)}" y2="${100 - r2 * Math.cos(a)}" stroke="${major ? "#7c5cff" : "#d5cdfa"}" stroke-width="${major ? 3 : 1.5}" stroke-linecap="round"/>`);
  }
  for (let n = 1; n <= 12; n++) {
    const a = (n * 30) * Math.PI / 180;
    parts.push(`<text x="${100 + 64 * Math.sin(a)}" y="${100 - 64 * Math.cos(a)}" font-size="19" font-weight="800" fill="#2d2a45" text-anchor="middle" dominant-baseline="central" font-family="inherit">${n}</text>`);
  }
  const hourDeg = ((h % 12) + m / 60) * 30;
  const minDeg = m * 6;
  parts.push(`<line x1="100" y1="100" x2="100" y2="62" stroke="#2d2a45" stroke-width="8" stroke-linecap="round" transform="rotate(${hourDeg} 100 100)"/>`);
  parts.push(`<line x1="100" y1="100" x2="100" y2="34" stroke="#ff6b81" stroke-width="5" stroke-linecap="round" transform="rotate(${minDeg} 100 100)"/>`);
  parts.push(`<circle cx="100" cy="100" r="6" fill="#ff9f43"/>`);
  parts.push(`</svg>`);
  return parts.join("");
}

/* ================= sounds (tiny WebAudio blips) ================= */
let audioCtx = null;
function beep(freqs, dur) {
  try {
    audioCtx = audioCtx || new (window.AudioContext || window.webkitAudioContext)();
    freqs.forEach((f, i) => {
      const o = audioCtx.createOscillator(), g = audioCtx.createGain();
      o.type = "sine"; o.frequency.value = f;
      g.gain.setValueAtTime(0.15, audioCtx.currentTime + i * dur);
      g.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + (i + 1) * dur);
      o.connect(g).connect(audioCtx.destination);
      o.start(audioCtx.currentTime + i * dur);
      o.stop(audioCtx.currentTime + (i + 1) * dur);
    });
  } catch {}
}
const soundGood = () => beep([660, 880], 0.12);
const soundBad = () => beep([220, 180], 0.18);

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
  makeChips("age-row", AGE_OPTIONS, "age", v => { settings.kgAge = v; });
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
  document.querySelectorAll("#timelevel-row .chip").forEach(chip => {
    chip.onclick = () => { settings.timeLevel = +chip.dataset.timelevel; refreshSetup(); };
  });
  document.querySelectorAll(".lang-chip").forEach(chip => {
    chip.onclick = () => { settings.lang = chip.dataset.lang; applyLang(); refreshSetup(); };
  });
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

  $("ops-group").hidden = marathon;
  $("age-group").hidden = !kg;
  $("style-group").hidden = !kg;
  $("range-group").hidden = !needsRange;
  $("tables-group").hidden = !needsTables;
  $("tables-note").hidden = !marathon;
  $("timelevel-group").hidden = !needsTimeLevel;
  $("count-group").hidden = marathon;

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
  document.querySelectorAll("#age-row .chip").forEach(c => c.classList.toggle("selected", +c.dataset.age === settings.kgAge));
  document.querySelectorAll("#style-row .op-chip").forEach(c => c.classList.toggle("selected", c.dataset.style === settings.kgStyle));
  document.querySelectorAll("#timelevel-row .chip").forEach(c => c.classList.toggle("selected", +c.dataset.timelevel === settings.timeLevel));

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
  $("t-age").textContent = t.age;
  $("t-style").textContent = t.style;
  $("t-range").textContent = t.range;
  $("t-tables").textContent = t.tables;
  $("tables-note").textContent = t.tablesNote;
  $("t-timelevel").textContent = t.timeLevel;
  $("t-count").textContent = t.count;
  $("btn-start").textContent = t.start;
  $("t-score").textContent = t.score;
  $("t-review").textContent = t.review;
  $("btn-again").textContent = t.again;
  $("btn-settings").textContent = t.settings;
  document.querySelectorAll("[data-t]").forEach(el => { el.textContent = t[el.dataset.t]; });
}

/* ================= quiz flow ================= */
function showScreen(name) {
  document.querySelectorAll(".screen").forEach(s => s.classList.remove("active"));
  $("screen-" + name).classList.add("active");
}

function buildQuestions() {
  if (settings.mode === "tables") {
    // the whole selected tables in order: n×1 … n×10, then this pool's weak facts again
    const tables = [...settings.tables].sort((x, y) => x - y);
    const questions = [];
    for (const n of tables) {
      for (let k = 1; k <= MARATHON_MAX_FACTOR; k++) {
        questions.push({ op: "mul", a: n, b: k, fa: n, fb: k, answer: n * k });
      }
    }
    for (const [n, k] of [...new Set(weakPool(tables).map(f => f.join("x")))].map(s => s.split("x").map(Number))) {
      if (k <= MARATHON_MAX_FACTOR) questions.push({ op: "mul", a: n, b: k, fa: n, fb: k, answer: n * k });
    }
    return questions;
  }

  if (settings.mode === "kg") {
    const range = settings.kgStyle === "shapes"
      ? Math.min(RANGE_BY_AGE[settings.kgAge], KG_SHAPES_MAX)
      : RANGE_BY_AGE[settings.kgAge];
    const cfg = { ops: [...settings.kgOps], range };
    const recent = [];
    return Array.from({ length: settings.count }, () => {
      const q = generateQuestion(cfg, recent);
      q.kg = true;
      if (settings.kgStyle === "shapes") { q.kgStyle = "shapes"; q.emoji = pick(EMOJIS); }
      return q;
    });
  }

  // regular quiz
  const cfg = {
    ops: [...settings.ops],
    range: settings.range,
    tables: [...settings.tables].sort((x, y) => x - y),
    timeLevel: settings.timeLevel,
    weak: weakPool(settings.tables),
  };
  const recent = [];
  return Array.from({ length: settings.count }, () => generateQuestion(cfg, recent));
}

function startQuiz() {
  const questions = buildQuestions();
  quiz = { questions, index: 0, correct: 0, points: 0, missed: [], timerId: null, timerStart: 0, timerTotal: 1, locked: false, entry: "" };
  showScreen("quiz");
  nextQuestion();
}

let quiz = null;

function nextQuestion() {
  const q = quiz.questions[quiz.index];
  quiz.entry = "";
  quiz.locked = false;
  const qEl = $("question");
  qEl.textContent = questionText(q);
  qEl.classList.toggle("shapes", q.kgStyle === "shapes");
  const clock = $("clock");
  if (q.op === "time") {
    clock.innerHTML = clockSVG(q.a, q.b);
    clock.hidden = false;
  } else {
    clock.hidden = true;
    clock.innerHTML = "";
  }
  $("answer-box").textContent = " ";
  $("answer-box").className = "answer-box";
  $("feedback").textContent = "";
  $("feedback").className = "feedback";
  $("progress-text").textContent = `${quiz.index + 1} / ${quiz.questions.length}`;
  $("score-pill").textContent = `⭐ ${Math.round(quiz.points)}`;
  startTimer(timeFor(q));
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
  quiz.timerId = setInterval(() => {
    const left = total - (performance.now() - start);
    const frac = Math.max(0, left / total);
    bar.style.width = (frac * 100) + "%";
    bar.className = "timebar" + (frac < 0.25 ? " danger" : frac < 0.5 ? " warn" : "");
    if (left <= 0) { stopTimer(); onTimeout(); }
  }, 100);
}
function stopTimer() {
  if (quiz && quiz.timerId) { clearInterval(quiz.timerId); quiz.timerId = null; }
}

function onKey(key) {
  if (!quiz || quiz.locked) return;
  const q = quiz.questions[quiz.index];
  if (key === "back") quiz.entry = quiz.entry.slice(0, -1);
  else if (key === "ok") { if (quiz.entry !== "") submit(); return; }
  else if (quiz.entry.length < 4) quiz.entry += key;
  $("answer-box").textContent = entryDisplay(quiz.entry, q) || " ";
}

function submit() {
  const q = quiz.questions[quiz.index];
  const frac = Math.max(0, 1 - (performance.now() - quiz.timerStart) / quiz.timerTotal);
  stopTimer();
  quiz.locked = true;
  const given = q.op === "time" ? parseTimeEntry(quiz.entry) : parseInt(quiz.entry, 10);
  if (given === q.answer) {
    // faster answers earn more: full question value instantly, half at the buzzer
    const maxPts = 1000 / quiz.questions.length;
    const pts = maxPts * (0.5 + 0.5 * frac);
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

  const missedWrap = $("missed-wrap");
  const list = $("missed-list");
  list.innerHTML = "";
  if (quiz.missed.length) {
    for (const q of quiz.missed) {
      const li = document.createElement("li");
      li.textContent = q.op === "time"
        ? `🕐 ${answerText(q)}`
        : `${q.a} ${OP_SYMBOL[q.op]} ${q.b} = ${q.answer}`;
      list.appendChild(li);
    }
    missedWrap.hidden = false;
  } else missedWrap.hidden = true;

  quiz = null;
  showScreen("results");
}

/* ================= wiring ================= */
$("numpad").addEventListener("click", e => {
  const key = e.target.closest(".key");
  if (key) onKey(key.dataset.key);
});
document.addEventListener("keydown", e => {
  if (!$("screen-quiz").classList.contains("active")) return;
  if (/^[0-9]$/.test(e.key)) onKey(e.key);
  else if (e.key === "Backspace") onKey("back");
  else if (e.key === "Enter") onKey("ok");
});
$("btn-quit").onclick = () => { stopTimer(); quiz = null; showScreen("setup"); };
$("btn-again").onclick = startQuiz;
$("btn-settings").onclick = () => showScreen("setup");

buildSetup();
applyLang();
refreshSetup();

if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => navigator.serviceWorker.register("sw.js").catch(() => {}));
}
