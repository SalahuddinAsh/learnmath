"use strict";

/* ================= tunable constants ================= */
const RANGE_OPTIONS = [10, 20, 50, 100, 500];
const COUNT_OPTIONS = [5, 10, 15, 20];
const TABLE_MIN = 1, TABLE_MAX = 12;

// per-question time (seconds), scaled by difficulty
function timeFor(q) {
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
    ops: "Choose operations",
    add: "Add", sub: "Subtract", mul: "Multiply", div: "Divide",
    range: "Biggest answer (+ / −)",
    tables: "Numbers to practice (× / ÷)",
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
    langBtn: "العربية",
  },
  ar: {
    title: "نجوم الحساب ⭐",
    ops: "اختر العمليات",
    add: "جمع", sub: "طرح", mul: "ضرب", div: "قسمة",
    range: "أكبر ناتج (+ / −)",
    tables: "أرقام التدريب (× / ÷)",
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
    langBtn: "English",
  },
};

/* ================= state ================= */
const DEFAULTS = { lang: "en", ops: ["add"], range: 20, tables: [2, 3, 4, 5], count: 10 };
let settings = loadSettings();

let quiz = null; // { questions, index, correct, missed, timerId, deadline, total, locked }

function loadSettings() {
  try {
    const s = JSON.parse(localStorage.getItem("mathstars-settings"));
    if (!s) return { ...DEFAULTS };
    return {
      lang: s.lang === "ar" ? "ar" : "en",
      ops: Array.isArray(s.ops) && s.ops.length ? s.ops.filter(o => ["add", "sub", "mul", "div"].includes(o)) : [...DEFAULTS.ops],
      range: RANGE_OPTIONS.includes(s.range) ? s.range : DEFAULTS.range,
      tables: Array.isArray(s.tables) ? s.tables.filter(n => n >= TABLE_MIN && n <= TABLE_MAX) : [...DEFAULTS.tables],
      count: COUNT_OPTIONS.includes(s.count) ? s.count : DEFAULTS.count,
    };
  } catch { return { ...DEFAULTS }; }
}
function saveSettings() {
  try { localStorage.setItem("mathstars-settings", JSON.stringify(settings)); } catch {}
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
  // mul/div are built from a times-table fact: n (chosen table) × k (1–12)
  const n = pick(cfg.tables);
  const k = rand(TABLE_MIN, TABLE_MAX);
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
  return `${q.a} ${OP_SYMBOL[q.op]} ${q.b} = ?`;
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
function buildSetup() {
  // range chips
  $("range-row").innerHTML = "";
  for (const r of RANGE_OPTIONS) {
    const b = document.createElement("button");
    b.type = "button"; b.className = "chip"; b.textContent = r; b.dir = "ltr";
    b.onclick = () => { settings.range = r; refreshSetup(); };
    b.dataset.range = r;
    $("range-row").appendChild(b);
  }
  // table chips 1..12
  $("tables-row").innerHTML = "";
  for (let n = TABLE_MIN; n <= TABLE_MAX; n++) {
    const b = document.createElement("button");
    b.type = "button"; b.className = "chip"; b.textContent = n; b.dir = "ltr";
    b.onclick = () => {
      const i = settings.tables.indexOf(n);
      i >= 0 ? settings.tables.splice(i, 1) : settings.tables.push(n);
      refreshSetup();
    };
    b.dataset.table = n;
    $("tables-row").appendChild(b);
  }
  // count chips
  $("count-row").innerHTML = "";
  for (const c of COUNT_OPTIONS) {
    const b = document.createElement("button");
    b.type = "button"; b.className = "chip"; b.textContent = c; b.dir = "ltr";
    b.onclick = () => { settings.count = c; refreshSetup(); };
    b.dataset.count = c;
    $("count-row").appendChild(b);
  }
  document.querySelectorAll(".op-chip").forEach(chip => {
    chip.onclick = () => {
      const op = chip.dataset.op;
      const i = settings.ops.indexOf(op);
      i >= 0 ? settings.ops.splice(i, 1) : settings.ops.push(op);
      refreshSetup();
    };
  });
  $("btn-lang").onclick = () => {
    settings.lang = settings.lang === "en" ? "ar" : "en";
    applyLang(); refreshSetup();
  };
  $("btn-start").onclick = startQuiz;
}

function refreshSetup() {
  const needsRange = settings.ops.includes("add") || settings.ops.includes("sub");
  const needsTables = settings.ops.includes("mul") || settings.ops.includes("div");
  $("range-group").hidden = !needsRange;
  $("tables-group").hidden = !needsTables;

  document.querySelectorAll(".op-chip").forEach(c => c.classList.toggle("selected", settings.ops.includes(c.dataset.op)));
  document.querySelectorAll("#range-row .chip").forEach(c => c.classList.toggle("selected", +c.dataset.range === settings.range));
  document.querySelectorAll("#tables-row .chip").forEach(c => c.classList.toggle("selected", settings.tables.includes(+c.dataset.table)));
  document.querySelectorAll("#count-row .chip").forEach(c => c.classList.toggle("selected", +c.dataset.count === settings.count));

  let hint = "";
  if (settings.ops.length === 0) hint = T().hintOps;
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
  $("t-ops").textContent = t.ops;
  $("t-range").textContent = t.range;
  $("t-tables").textContent = t.tables;
  $("t-count").textContent = t.count;
  $("btn-start").textContent = t.start;
  $("t-score").textContent = t.score;
  $("t-review").textContent = t.review;
  $("btn-again").textContent = t.again;
  $("btn-settings").textContent = t.settings;
  $("btn-lang").textContent = t.langBtn;
  document.querySelectorAll("[data-t]").forEach(el => { el.textContent = t[el.dataset.t]; });
}

/* ================= quiz flow ================= */
function showScreen(name) {
  document.querySelectorAll(".screen").forEach(s => s.classList.remove("active"));
  $("screen-" + name).classList.add("active");
}

function startQuiz() {
  const cfg = {
    ops: [...settings.ops],
    range: settings.range,
    tables: [...settings.tables].sort((x, y) => x - y),
    count: settings.count,
  };
  const recent = [];
  const questions = Array.from({ length: cfg.count }, () => generateQuestion(cfg, recent));
  quiz = { questions, index: 0, correct: 0, missed: [], timerId: null, locked: false, entry: "" };
  showScreen("quiz");
  nextQuestion();
}

function nextQuestion() {
  const q = quiz.questions[quiz.index];
  quiz.entry = "";
  quiz.locked = false;
  $("question").textContent = questionText(q);
  $("answer-box").textContent = " ";
  $("answer-box").className = "answer-box";
  $("feedback").textContent = "";
  $("feedback").className = "feedback";
  $("progress-text").textContent = `${quiz.index + 1} / ${quiz.questions.length}`;
  $("score-pill").textContent = `⭐ ${quiz.correct}`;
  startTimer(timeFor(q));
}

function startTimer(seconds) {
  stopTimer();
  const total = seconds * 1000;
  const start = performance.now();
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
  if (key === "back") quiz.entry = quiz.entry.slice(0, -1);
  else if (key === "ok") { if (quiz.entry !== "") submit(); return; }
  else if (quiz.entry.length < 4) quiz.entry += key;
  $("answer-box").textContent = quiz.entry || " ";
}

function submit() {
  const q = quiz.questions[quiz.index];
  stopTimer();
  quiz.locked = true;
  const good = parseInt(quiz.entry, 10) === q.answer;
  if (good) {
    quiz.correct++;
    $("answer-box").classList.add("correct");
    $("feedback").textContent = pick(T().good);
    $("feedback").classList.add("good");
    $("score-pill").textContent = `⭐ ${quiz.correct}`;
    soundGood();
    setTimeout(advance, 900);
  } else {
    quiz.missed.push(q);
    $("answer-box").classList.add("wrong");
    $("feedback").textContent = `${T().answerIs}: ${q.answer}`;
    $("feedback").classList.add("bad");
    soundBad();
    setTimeout(advance, 2000);
  }
}

function onTimeout() {
  const q = quiz.questions[quiz.index];
  quiz.locked = true;
  quiz.missed.push(q);
  $("answer-box").textContent = String(q.answer);
  $("answer-box").classList.add("wrong");
  $("feedback").textContent = `${T().timeUp} ${T().answerIs}: ${q.answer}`;
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
  const score = quiz.correct;
  const pct = score / total;
  const stars = pct >= 0.9 ? 3 : pct >= 0.7 ? 2 : pct >= 0.5 ? 1 : 0;
  $("stars").textContent = stars ? "⭐".repeat(stars) : "🌱";
  $("final-score").textContent = `${score} / ${total}`;
  $("cheer").textContent = T()["cheer" + stars];

  const missedWrap = $("missed-wrap");
  const list = $("missed-list");
  list.innerHTML = "";
  if (quiz.missed.length) {
    for (const q of quiz.missed) {
      const li = document.createElement("li");
      li.textContent = `${q.a} ${OP_SYMBOL[q.op]} ${q.b} = ${q.answer}`;
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
