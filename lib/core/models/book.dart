import 'dart:convert';
export '../constant/book_type.dart';

/// Book - 書籍模型
/// 對應 Android: data/entities/Book.kt
class Book {
  String bookUrl; // 書籍 URL (唯一識別)
  String tocUrl; // 目錄 URL
  String origin; // 書源 URL 或 localTag
  String originName; // 書源名稱或本地檔名
  String name; // 書名
  String author; // 作者
  String? kind; // 分類 (書源獲取)
  String? customTag; // 分類 (用戶修改)
  String? coverUrl; // 封面 URL (書源獲取)
  String? customCoverUrl; // 封面 URL (用戶修改)
  String? intro; // 簡介 (書源獲取)
  String? customIntro; // 簡介 (用戶修改)
  String? charset; // 自定義字符集 (本地書)
  int type; // 書籍類型 (0: 文本, 2: 音訊, 等)
  int group; // 自定義分組索引 (位運算)
  String? latestChapterTitle; // 最新章節標題
  int latestChapterTime; // 最新章節更新時間
  int lastCheckTime; // 最近一次檢查時間
  int lastCheckCount; // 最近一次發現新章節數量
  int totalChapterNum; // 章節總數
  String? durChapterTitle; // 目前章節標題
  int durChapterIndex; // 目前章節索引
  int durChapterPos; // 目前閱讀位置 (首行字索引)
  int durChapterTime; // 最近一次閱讀時間
  String? wordCount; // 字數
  bool canUpdate; // 是否自動更新
  int order; // 手動排序
  int originOrder; // 書源排序
  String? variable; // 自定義變量
  ReadConfig? readConfig; // 閱讀設置
  int syncTime; // 同步時間
  bool isInBookshelf; // 是否在書架上 (iOS 特有標記)

  // --- 延遲加載屬性 (對標 Android Book.variableMap) ---
  Map<String, String>? _variableMap;
  Map<String, String> get variableMap {
    if (_variableMap == null) {
      if (variable != null && variable!.isNotEmpty) {
        try {
          final decoded = jsonDecode(variable!);
          if (decoded is Map) {
            _variableMap = decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
          }
        } catch (_) {}
      }
      _variableMap ??= {};
    }
    return _variableMap!;
  }

  void setVariable(String key, String value) {
    final map = Map<String, String>.from(variableMap);
    map[key] = value;
    _variableMap = map;
    variable = jsonEncode(map);
  }

  // --- 類型感知屬性 (對標 Android BookExtensions.kt) ---
  bool get isAudio => (type & 2) != 0; // BookType.audio = 2
  bool get isImage => (type & 4) != 0; // BookType.image = 4
  bool get isEpub => bookUrl.toLowerCase().endsWith('.epub');
  bool get isLocal => origin == "local" || origin.startsWith("webdav");
  bool get isUpdate => lastCheckCount > 0;

  Book({
    this.bookUrl = "",
    this.tocUrl = "",
    this.origin = "local",
    this.originName = "",
    this.name = "",
    this.author = "",
    this.kind,
    this.customTag,
    this.coverUrl,
    this.customCoverUrl,
    this.intro,
    this.customIntro,
    this.charset,
    this.type = 0,
    this.group = 0,
    this.latestChapterTitle,
    this.latestChapterTime = 0,
    this.lastCheckTime = 0,
    this.lastCheckCount = 0,
    this.totalChapterNum = 0,
    this.durChapterTitle,
    this.durChapterIndex = 0,
    this.durChapterPos = 0,
    this.durChapterTime = 0,
    this.wordCount,
    this.canUpdate = true,
    this.order = 0,
    this.originOrder = 0,
    this.variable,
    this.readConfig,
    this.syncTime = 0,
    this.isInBookshelf = false,
  });

  // 核心業務方法
  String getRealAuthor() => author.replaceAll(RegExp(r'\(.*?\)|\[.*?\]|（.*?）|【.*?】'), '').trim();

  String? getDisplayCover() => (customCoverUrl == null || customCoverUrl!.isEmpty) ? coverUrl : customCoverUrl;

  String? getDisplayIntro() => (customIntro == null || customIntro!.isEmpty) ? intro : customIntro;

  /// 是否使用淨化替換規則 (對標 Android Book.getUseReplaceRule)
  /// 自動判斷：圖片類或 Epub 本地書籍默認關閉淨化，以提升性能並防止內容損壞。
  bool getUseReplaceRule() {
    final explicitValue = readConfig?.useReplaceRule;
    if (explicitValue != null) return explicitValue;

    // 圖片類、音訊類或 Epub 本地書籍默認關閉
    if (isImage || isAudio || isEpub) return false;
    
    return true; // 默認開啟
  }

  bool getReSegment() {
    return readConfig?.reSegment ?? false;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      bookUrl: json['bookUrl'] ?? "",
      tocUrl: json['tocUrl'] ?? "",
      origin: json['origin'] ?? "local",
      originName: json['originName'] ?? "",
      name: json['name'] ?? "",
      author: json['author'] ?? "",
      kind: json['kind'],
      customTag: json['customTag'],
      coverUrl: json['coverUrl'],
      customCoverUrl: json['customCoverUrl'],
      intro: json['intro'],
      customIntro: json['customIntro'],
      charset: json['charset'],
      type: _toInt(json['type']),
      group: _toInt(json['group']),
      latestChapterTitle: json['latestChapterTitle'],
      latestChapterTime: _toInt(json['latestChapterTime']),
      lastCheckTime: _toInt(json['lastCheckTime']),
      lastCheckCount: _toInt(json['lastCheckCount']),
      totalChapterNum: _toInt(json['totalChapterNum']),
      durChapterTitle: json['durChapterTitle'],
      durChapterIndex: _toInt(json['durChapterIndex']),
      durChapterPos: _toInt(json['durChapterPos']),
      durChapterTime: _toInt(json['durChapterTime']),
      wordCount: json['wordCount'],
      canUpdate: json['canUpdate'] == 1 || json['canUpdate'] == true,
      order: _toInt(json['order']),
      originOrder: _toInt(json['originOrder']),
      variable: json['variable'],
      readConfig: json['readConfig'] != null ? ReadConfig.fromJson(json['readConfig'] is String ? jsonDecode(json['readConfig']) : json['readConfig']) : null,
      syncTime: _toInt(json['syncTime']),
      isInBookshelf: json['isInBookshelf'] == 1 || json['isInBookshelf'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookUrl': bookUrl,
      'tocUrl': tocUrl,
      'origin': origin,
      'originName': originName,
      'name': name,
      'author': author,
      'kind': kind,
      'customTag': customTag,
      'coverUrl': coverUrl,
      'customCoverUrl': customCoverUrl,
      'intro': intro,
      'customIntro': customIntro,
      'charset': charset,
      'type': type,
      'group': group,
      'latestChapterTitle': latestChapterTitle,
      'latestChapterTime': latestChapterTime,
      'lastCheckTime': lastCheckTime,
      'lastCheckCount': lastCheckCount,
      'totalChapterNum': totalChapterNum,
      'durChapterTitle': durChapterTitle,
      'durChapterIndex': durChapterIndex,
      'durChapterPos': durChapterPos,
      'durChapterTime': durChapterTime,
      'wordCount': wordCount,
      'canUpdate': canUpdate ? 1 : 0,
      'order': order,
      'originOrder': originOrder,
      'variable': variable,
      'readConfig': readConfig != null ? jsonEncode(readConfig!.toJson()) : null,
      'syncTime': syncTime,
      'isInBookshelf': isInBookshelf ? 1 : 0,
    };
  }

  Book copyWith({
    String? bookUrl,
    String? tocUrl,
    String? origin,
    String? originName,
    String? name,
    String? author,
    String? kind,
    String? customTag,
    String? coverUrl,
    String? customCoverUrl,
    String? intro,
    String? customIntro,
    String? charset,
    int? type,
    int? group,
    String? latestChapterTitle,
    int? latestChapterTime,
    int? lastCheckTime,
    int? lastCheckCount,
    int? totalChapterNum,
    String? durChapterTitle,
    int? durChapterIndex,
    int? durChapterPos,
    int? durChapterTime,
    String? wordCount,
    bool? canUpdate,
    int? order,
    int? originOrder,
    String? variable,
    ReadConfig? readConfig,
    int? syncTime,
    bool? isInBookshelf,
  }) {
    return Book(
      bookUrl: bookUrl ?? this.bookUrl,
      tocUrl: tocUrl ?? this.tocUrl,
      origin: origin ?? this.origin,
      originName: originName ?? this.originName,
      name: name ?? this.name,
      author: author ?? this.author,
      kind: kind ?? this.kind,
      customTag: customTag ?? this.customTag,
      coverUrl: coverUrl ?? this.coverUrl,
      customCoverUrl: customCoverUrl ?? this.customCoverUrl,
      intro: intro ?? this.intro,
      customIntro: customIntro ?? this.customIntro,
      charset: charset ?? this.charset,
      type: type ?? this.type,
      group: group ?? this.group,
      latestChapterTitle: latestChapterTitle ?? this.latestChapterTitle,
      latestChapterTime: latestChapterTime ?? this.latestChapterTime,
      lastCheckTime: lastCheckTime ?? this.lastCheckTime,
      lastCheckCount: lastCheckCount ?? this.lastCheckCount,
      totalChapterNum: totalChapterNum ?? this.totalChapterNum,
      durChapterTitle: durChapterTitle ?? this.durChapterTitle,
      durChapterIndex: durChapterIndex ?? this.durChapterIndex,
      durChapterPos: durChapterPos ?? this.durChapterPos,
      durChapterTime: durChapterTime ?? this.durChapterTime,
      wordCount: wordCount ?? this.wordCount,
      canUpdate: canUpdate ?? this.canUpdate,
      order: order ?? this.order,
      originOrder: originOrder ?? this.originOrder,
      variable: variable ?? this.variable,
      readConfig: readConfig ?? this.readConfig,
      syncTime: syncTime ?? this.syncTime,
      isInBookshelf: isInBookshelf ?? this.isInBookshelf,
    );
  }

  /// 深度還原：書籍遷移邏輯 (對標 Android Book.migrateTo)
  /// 在書源更新時，嘗試根據章節標題對齊閱讀進度，防止進度丟失。
  Book migrateTo(Book newBook, List<dynamic>? newChapters) {
    int alignedIndex = durChapterIndex;
    if (newChapters != null && newChapters.isNotEmpty) {
      alignedIndex = _getDurChapter(
        durChapterIndex,
        durChapterTitle,
        newChapters,
        totalChapterNum,
      );
    }

    return newBook.copyWith(
      group: group,
      order: order,
      canUpdate: canUpdate,
      durChapterIndex: alignedIndex,
      durChapterPos: durChapterPos,
      durChapterTitle: alignedIndex < (newChapters?.length ?? 0)
          ? newChapters![alignedIndex].title
          : durChapterTitle,
      durChapterTime: durChapterTime,
      readConfig: readConfig,
    );
  }

  /// 根據標題或索引位置找回章節進度 (對標 Android BookHelp.getDurChapter)
  int _getDurChapter(
    int oldIndex,
    String? oldName,
    List<dynamic> newChapters,
    int oldTotalNum,
  ) {
    if (oldIndex <= 0) return 0;
    if (newChapters.isEmpty) return oldIndex;

    final newSize = newChapters.length;
    // 1. 嘗試直接根據名稱完全匹配
    if (oldName != null && oldName.isNotEmpty) {
      for (int i = 0; i < newSize; i++) {
        if (newChapters[i].title == oldName) return i;
      }
    }

    // 2. 嘗試提取「第 X 章」的數字進行匹配
    final int? oldChapterNum = _extractChapterNum(oldName);
    if (oldChapterNum != null) {
      for (int i = 0; i < newSize; i++) {
        if (_extractChapterNum(newChapters[i].title) == oldChapterNum) return i;
      }
    }

    // 3. 退而求其次，根據比例位置估計
    int estimateIndex = oldIndex;
    if (oldTotalNum > 0) {
      estimateIndex = (oldIndex * newSize / oldTotalNum).round();
    }

    return estimateIndex.clamp(0, newSize - 1);
  }

  int? _extractChapterNum(String? title) {
    if (title == null) return null;
    final match = RegExp(r'第\s*(\d+)\s*[章节篇回集话]').firstMatch(title);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }
}

/// Book 位元運算擴展 (高度還原 Android BookExtensions.kt)
extension BookBitwiseExtension on Book {
  // --- 類型相關 ---
  bool isType(int typeMask) => (type & typeMask) != 0;
  void addType(int typeMask) => type |= typeMask;
  void removeType(int typeMask) => type &= ~typeMask;

  // --- 分組相關 ---
  bool hasGroup(int groupIdMask) {
    if (groupIdMask <= 0) return true; // 特殊分組如 IdAll 處理
    return (group & groupIdMask) != 0;
  }
  void addGroup(int groupIdMask) => group |= groupIdMask;
  void removeGroup(int groupIdMask) => group &= ~groupIdMask;
}

/// ReadConfig - 閱讀設置模型 (內嵌於 Book)
class ReadConfig {
  bool reverseToc; // 目錄反序
  int? pageAnim; // 翻頁動畫
  bool reSegment; // 強制分段
  String? imageStyle; // 圖片樣式
  bool? useReplaceRule; // 正文使用淨化規則
  int delTag; // 去除標籤位元
  String? ttsEngine; // TTS 引擎
  bool splitLongChapter; // 拆分超長章節
  bool readSimulating; // 模擬更新
  String? startDate; // 模擬起始日期
  int? startChapter; // 模擬起始章節
  int dailyChapters; // 每日更新章節數

  ReadConfig({
    this.reverseToc = false,
    this.pageAnim,
    this.reSegment = false,
    this.imageStyle,
    this.useReplaceRule,
    this.delTag = 0,
    this.ttsEngine,
    this.splitLongChapter = true,
    this.readSimulating = false,
    this.startDate,
    this.startChapter,
    this.dailyChapters = 3,
  });

  factory ReadConfig.fromJson(Map<String, dynamic> json) {
    return ReadConfig(
      reverseToc: json['reverseToc'] ?? false,
      pageAnim: json['pageAnim'],
      reSegment: json['reSegment'] ?? false,
      imageStyle: json['imageStyle'],
      useReplaceRule: json['useReplaceRule'],
      delTag: json['delTag'] ?? 0,
      ttsEngine: json['ttsEngine'],
      splitLongChapter: json['splitLongChapter'] ?? true,
      readSimulating: json['readSimulating'] ?? false,
      startDate: json['startDate'],
      startChapter: json['startChapter'],
      dailyChapters: json['dailyChapters'] ?? 3,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reverseToc': reverseToc,
      'pageAnim': pageAnim,
      'reSegment': reSegment,
      'imageStyle': imageStyle,
      'useReplaceRule': useReplaceRule,
      'delTag': delTag,
      'ttsEngine': ttsEngine,
      'splitLongChapter': splitLongChapter,
      'readSimulating': readSimulating,
      'startDate': startDate,
      'startChapter': startChapter,
      'dailyChapters': dailyChapters,
    };
  }

  ReadConfig copyWith({
    bool? reverseToc,
    int? pageAnim,
    bool? reSegment,
    String? imageStyle,
    bool? useReplaceRule,
    int? delTag,
    String? ttsEngine,
    bool? splitLongChapter,
    bool? readSimulating,
    String? startDate,
    int? startChapter,
    int? dailyChapters,
  }) {
    return ReadConfig(
      reverseToc: reverseToc ?? this.reverseToc,
      pageAnim: pageAnim ?? this.pageAnim,
      reSegment: reSegment ?? this.reSegment,
      imageStyle: imageStyle ?? this.imageStyle,
      useReplaceRule: useReplaceRule ?? this.useReplaceRule,
      delTag: delTag ?? this.delTag,
      ttsEngine: ttsEngine ?? this.ttsEngine,
      splitLongChapter: splitLongChapter ?? this.splitLongChapter,
      readSimulating: readSimulating ?? this.readSimulating,
      startDate: startDate ?? this.startDate,
      startChapter: startChapter ?? this.startChapter,
      dailyChapters: dailyChapters ?? this.dailyChapters,
    );
  }
}
