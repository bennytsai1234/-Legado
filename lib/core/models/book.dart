/// Book - 書籍模型
/// 對應 Android: data/entities/Book.kt
library;

class Book {
  String bookUrl; // 書籍 URL (唯一識別)
  String name; // 書名
  String? author; // 作者
  String? kind; // 分類
  String? coverUrl; // 封面 URL
  String? intro; // 簡介
  String? wordCount; // 字數
  String? latestChapterTitle; // 最新章節名
  int latestChapterTime; // 最新章節時間
  int lastCheckTime; // 最後更新檢查時間
  int lastCheckCount; // 新增章節數
  int totalChapterNum; // 章節總數
  int durChapterIndex; // 當前閱讀章節索引
  int durChapterPos; // 當前閱讀進度位置
  String? durChapterTitle; // 當前閱讀章節名
  String? durChapterTime; // 當前閱讀時間
  String origin; // 書源 URL
  String? originName; // 書源名稱
  int originOrder; // 書源排序
  int type; // 0: 文字, 1: 音頻, 2: 漫畫
  String? group; // 書架分組
  int order; // 書架排序
  bool canUpdate; // 是否可更新
  String? variable; // 暫存變數
  String? readConfig; // 閱讀設定
  bool isInBookshelf; // 是否在書架中

  String tocUrl; // 目錄 URL
  String? infoHtml; // 詳情頁 HTML 緩存
  String? tocHtml; // 目錄頁 HTML 緩存

  Book({
    required this.bookUrl,
    required this.name,
    this.tocUrl = '',
    this.infoHtml,
    this.tocHtml,
    this.author,
    this.kind,
    this.coverUrl,
    this.intro,
    this.wordCount,
    this.latestChapterTitle,
    this.latestChapterTime = 0,
    this.lastCheckTime = 0,
    this.lastCheckCount = 0,
    this.totalChapterNum = 0,
    this.durChapterIndex = 0,
    this.durChapterPos = 0,
    this.durChapterTitle,
    this.durChapterTime,
    required this.origin,
    this.originName,
    this.originOrder = 0,
    this.type = 0,
    this.group,
    this.order = 0,
    this.canUpdate = true,
    this.variable,
    this.readConfig,
    this.isInBookshelf = false,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      bookUrl: json['bookUrl'] ?? '',
      name: json['name'] ?? '',
      tocUrl: json['tocUrl'] ?? '',
      infoHtml: json['infoHtml'],
      tocHtml: json['tocHtml'],
      author: json['author'],
      kind: json['kind'],
      coverUrl: json['coverUrl'],
      intro: json['intro'],
      wordCount: json['wordCount'],
      latestChapterTitle: json['latestChapterTitle'],
      latestChapterTime: json['latestChapterTime'] ?? 0,
      lastCheckTime: json['lastCheckTime'] ?? 0,
      lastCheckCount: json['lastCheckCount'] ?? 0,
      totalChapterNum: json['totalChapterNum'] ?? 0,
      durChapterIndex: json['durChapterIndex'] ?? 0,
      durChapterPos: json['durChapterPos'] ?? 0,
      durChapterTitle: json['durChapterTitle'],
      durChapterTime: json['durChapterTime'],
      origin: json['origin'] ?? '',
      originName: json['originName'],
      originOrder: json['originOrder'] ?? 0,
      type: json['type'] ?? 0,
      group: json['group'],
      order: json['order'] ?? 0,
      canUpdate: json['canUpdate'] ?? true,
      variable: json['variable'],
      readConfig: json['readConfig'],
      isInBookshelf: json['isInBookshelf'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookUrl': bookUrl,
      'name': name,
      'author': author,
      'kind': kind,
      'coverUrl': coverUrl,
      'intro': intro,
      'wordCount': wordCount,
      'latestChapterTitle': latestChapterTitle,
      'latestChapterTime': latestChapterTime,
      'lastCheckTime': lastCheckTime,
      'lastCheckCount': lastCheckCount,
      'totalChapterNum': totalChapterNum,
      'durChapterIndex': durChapterIndex,
      'durChapterPos': durChapterPos,
      'durChapterTitle': durChapterTitle,
      'durChapterTime': durChapterTime,
      'tocUrl': tocUrl,
      'infoHtml': infoHtml,
      'tocHtml': tocHtml,
      'origin': origin,
      'originName': originName,
      'originOrder': originOrder,
      'type': type,
      'group': group,
      'order': order,
      'canUpdate': canUpdate,
      'variable': variable,
      'readConfig': readConfig,
      'isInBookshelf': isInBookshelf,
    };
  }

  /// Create a copy with updated fields
  Book copyWith({
    String? bookUrl,
    String? name,
    String? author,
    String? kind,
    String? coverUrl,
    String? intro,
    int? durChapterIndex,
    int? durChapterPos,
    String? durChapterTitle,
    bool? isInBookshelf,
    int? totalChapterNum,
    String? latestChapterTitle,
  }) {
    return Book(
      bookUrl: bookUrl ?? this.bookUrl,
      name: name ?? this.name,
      author: author ?? this.author,
      kind: kind ?? this.kind,
      coverUrl: coverUrl ?? this.coverUrl,
      intro: intro ?? this.intro,
      wordCount: wordCount,
      latestChapterTitle: latestChapterTitle ?? this.latestChapterTitle,
      latestChapterTime: latestChapterTime,
      lastCheckTime: lastCheckTime,
      lastCheckCount: lastCheckCount,
      totalChapterNum: totalChapterNum ?? this.totalChapterNum,
      durChapterIndex: durChapterIndex ?? this.durChapterIndex,
      durChapterPos: durChapterPos ?? this.durChapterPos,
      durChapterTitle: durChapterTitle ?? this.durChapterTitle,
      durChapterTime: durChapterTime,
      origin: origin,
      originName: originName,
      originOrder: originOrder,
      type: type,
      group: group,
      order: order,
      canUpdate: canUpdate,
      variable: variable,
      readConfig: readConfig,
      isInBookshelf: isInBookshelf ?? this.isInBookshelf,
    );
  }
}
