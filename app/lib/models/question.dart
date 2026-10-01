const Map<String, String> kOpSymbol = {
  "add": "+",
  "sub": "−",
  "mul": "×",
  "div": "÷",
};

/// One quiz question — mirrors the plain `q` objects built by makeOne()/
/// makeTimeQuestion()/toBlank() in app.js. Mutable because toBlank() rewrites
/// a generated question in place, exactly like the JS.
class Question {
  final String op; // add sub mul div time
  int a;
  int b;
  int answer;

  // × / ÷ are built from a times-table fact n × k
  int? fa;
  int? fb;

  // "mixed" question style: a ∘ _ = result
  bool blank = false;
  int? result;

  // time questions (the face shows a:b)
  int shift = 0; // hours added (+) or subtracted (−); 0 = plain reading
  int ansH = 0; // the answer's hour
  bool dual = false; // both 12h and 24h readings required
  int? answer2;
  bool clock24 = false;

  // kindergarten
  bool kg = false;
  bool untimed = false;
  String? kgStyle;
  String? emoji;

  Question({
    required this.op,
    required this.a,
    required this.b,
    required this.answer,
    this.fa,
    this.fb,
  });

  Question copy() =>
      Question(op: op, a: a, b: b, answer: answer, fa: fa, fb: fb)
        ..blank = blank
        ..result = result
        ..shift = shift
        ..ansH = ansH
        ..dual = dual
        ..answer2 = answer2
        ..clock24 = clock24
        ..kg = kg
        ..untimed = untimed
        ..kgStyle = kgStyle
        ..emoji = emoji;

  bool get isTime => op == "time";

  /// Weak-memory key — mirrors missKey(): "f:3x7", "add:5:7", "time:9:15", "time:9:15:5".
  String get weakKey {
    if (op == "mul" || op == "div") return "f:${fa}x$fb";
    if (isTime && shift != 0) return "time:$a:$b:$shift";
    return "$op:$a:$b";
  }

  /// Key used to avoid repeating one of the last few questions.
  String get recentKey =>
      "$op:$a:$b:${shift == 0 ? "" : shift}:${blank ? "_" : ""}";

  /// Digits a fully typed answer has; time answers count hour digits + 2 minute
  /// digits from ansH, since a midnight hour adds no digits to `answer` itself.
  int get expectedEntryLength => isTime ? "$ansH".length + 2 : "$answer".length;

  /// "7 + 5 = 12" — the solved equation, for the review list.
  String get solvedText => blank
      ? "$a ${kOpSymbol[op]} $b = $result"
      : "$a ${kOpSymbol[op]} $b = $answer";
}

String fmtTime(int v) => "${v ~/ 100}:${(v % 100).toString().padLeft(2, "0")}";
