const List<int> kRangeOptions = [10, 20, 50, 100, 500, 1000];
const List<int> kCountOptions = [5, 10, 15, 20];
const List<int> kKgRangeOptions = [5, 10, 15, 20];
const List<int> kGameScoreOptions = [0, 500, 700, 800, 900];
const int kTableMin = 1, kTableMax = 12;
const List<String> kLanguages = ["en", "ar", "de"];
const Map<String, int> kDiffSeconds = {"easy": 30, "medium": 20, "hard": 10};

/// All user settings — mirrors DEFAULTS/loadSettings() in app.js field for
/// field, including modes the native app doesn't show yet, so the stored
/// format never has to change as features are ported.
class Settings {
  String lang;
  String mode; // test | kg | tables
  List<String> ops; // add sub mul div time
  int range;
  List<int> tables;
  int count;
  int factorMax;
  int timeLevel;
  String clockMode; // 12 | 24 | dual
  String clockTask; // read | shift | both
  String timeInput; // pick | type
  String qFormat; // result | mixed
  int kgRange;
  List<String> kgOps;
  String kgStyle; // shapes | digits
  bool kgTimer;
  String kgSize; // s | m | l
  bool sound;
  bool autoSubmit;
  String difficulty; // easy | medium | hard
  int gameScore;

  Settings({
    this.lang = "en",
    this.mode = "test",
    List<String>? ops,
    this.range = 20,
    List<int>? tables,
    this.count = 10,
    this.factorMax = 10,
    this.timeLevel = 1,
    this.clockMode = "12",
    this.clockTask = "both",
    this.timeInput = "type",
    this.qFormat = "result",
    this.kgRange = 10,
    List<String>? kgOps,
    this.kgStyle = "shapes",
    this.kgTimer = true,
    this.kgSize = "l",
    this.sound = true,
    this.autoSubmit = true,
    this.difficulty = "medium",
    this.gameScore = 700,
  }) : ops = ops ?? ["add"],
       tables = tables ?? [2, 3, 4, 5],
       kgOps = kgOps ?? ["add", "sub"];

  int get secondsPerQuestion => kDiffSeconds[difficulty] ?? 20;

  factory Settings.fromJson(Map<String, dynamic> s) {
    final d = Settings();
    List<T> listOf<T>(Object? v) =>
        v is List ? v.whereType<T>().toList() : <T>[];
    final ops = listOf<String>(
      s["ops"],
    ).where(["add", "sub", "mul", "div", "time"].contains).toList();
    final kgOps = listOf<String>(
      s["kgOps"],
    ).where(["add", "sub"].contains).toList();
    T oneOf<T>(Object? v, List<T> allowed, T fallback) =>
        allowed.contains(v) ? v as T : fallback;
    return Settings(
      lang: oneOf(s["lang"], kLanguages, d.lang),
      mode: oneOf(s["mode"], ["test", "kg", "tables"], d.mode),
      ops: ops.isNotEmpty ? ops : d.ops,
      range: oneOf(s["range"], kRangeOptions, d.range),
      tables: s["tables"] is List
          ? listOf<int>(
              s["tables"],
            ).where((n) => n >= kTableMin && n <= kTableMax).toList()
          : d.tables,
      count: oneOf(s["count"], kCountOptions, d.count),
      factorMax: s["factorMax"] == 12 ? 12 : 10,
      timeLevel: s["timeLevel"] == 2 ? 2 : 1,
      clockMode: oneOf(s["clockMode"], ["12", "24", "dual"], d.clockMode),
      clockTask: oneOf(s["clockTask"], ["read", "shift", "both"], d.clockTask),
      timeInput: s["timeInput"] == "pick" ? "pick" : "type",
      qFormat: s["qFormat"] == "mixed" ? "mixed" : "result",
      kgRange: oneOf(s["kgRange"], kKgRangeOptions, d.kgRange),
      kgOps: kgOps.isNotEmpty ? kgOps : d.kgOps,
      kgStyle: s["kgStyle"] == "digits" ? "digits" : "shapes",
      kgTimer: s["kgTimer"] != false,
      kgSize: oneOf(s["kgSize"], ["s", "m", "l"], d.kgSize),
      sound: s["sound"] != false,
      autoSubmit: s["autoSubmit"] != false,
      difficulty: oneOf(s["difficulty"], [
        "easy",
        "medium",
        "hard",
      ], d.difficulty),
      gameScore: oneOf(s["gameScore"], kGameScoreOptions, d.gameScore),
    );
  }

  Map<String, dynamic> toJson() => {
    "lang": lang,
    "mode": mode,
    "ops": ops,
    "range": range,
    "tables": tables,
    "count": count,
    "factorMax": factorMax,
    "timeLevel": timeLevel,
    "clockMode": clockMode,
    "clockTask": clockTask,
    "timeInput": timeInput,
    "qFormat": qFormat,
    "kgRange": kgRange,
    "kgOps": kgOps,
    "kgStyle": kgStyle,
    "kgTimer": kgTimer,
    "kgSize": kgSize,
    "sound": sound,
    "autoSubmit": autoSubmit,
    "difficulty": difficulty,
    "gameScore": gameScore,
  };

  Settings copy() => Settings.fromJson(toJson());
}
