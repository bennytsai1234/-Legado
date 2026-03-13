import 'dart:convert';
import 'base_source.dart';

/// BookSource - 書源模型
/// 完整相容 Legado 3.0 JSON 書源格式
///
/// 對應 Android: data/entities/BookSource.kt
class BookSource implements BaseSource {
  String bookSourceUrl; // 書源 URL (唯一識別)
  String bookSourceName; // 書源名稱
  String? bookSourceGroup; // 書源分組
  int bookSourceType; // 類型 (0: 文本, 1: 音訊, 2: 圖片, 3: 文件)
  String? bookUrlPattern; // 詳情頁 URL 正則
  int customOrder; // 手動排序
  bool enabled; // 是否啟用
  bool enabledExplore; // 啟用發現
  @override
  String? jsLib; // JS 庫
  @override
  bool enabledCookieJar; // 啟用 CookieJar
  @override
  String? concurrentRate; // 併發率
  @override
  String? header; // 請求頭
  @override
  String? loginUrl; // 登入地址
  @override
  String? loginUi; // 登入 UI
  String? loginCheckJs; // 登入檢查 JS
  String? coverDecodeJs; // 封面解密 JS
  String? bookSourceComment; // 註釋
  String? variableComment; // 變量說明
  int lastUpdateTime; // 最後更新時間
  int respondTime; // 響應時間
  int weight; // 權重
  String? exploreUrl; // 發現 URL
  String? exploreScreen; // 發現篩選規則
  ExploreRule? ruleExplore; // 發現規則
  String? searchUrl; // 搜尋 URL
  SearchRule? ruleSearch; // 搜尋規則
  BookInfoRule? ruleBookInfo; // 書籍訊息規則
  TocRule? ruleToc; // 目錄規則
  ContentRule? ruleContent; // 正文規則
  ReviewRule? ruleReview; // 段評規則

  BookSource({
    this.bookSourceUrl = "",
    this.bookSourceName = "",
    this.bookSourceGroup,
    this.bookSourceType = 0,
    this.bookUrlPattern,
    this.customOrder = 0,
    this.enabled = true,
    this.enabledExplore = true,
    this.jsLib,
    this.enabledCookieJar = true,
    this.concurrentRate,
    this.header,
    this.loginUrl,
    this.loginUi,
    this.loginCheckJs,
    this.coverDecodeJs,
    this.bookSourceComment,
    this.variableComment,
    this.lastUpdateTime = 0,
    this.respondTime = 180000,
    this.weight = 0,
    this.exploreUrl,
    this.exploreScreen,
    this.ruleExplore,
    this.searchUrl,
    this.ruleSearch,
    this.ruleBookInfo,
    this.ruleToc,
    this.ruleContent,
    this.ruleReview,
  });

  @override
  String getTag() => bookSourceName;
  @override
  String getKey() => bookSourceUrl;

  // --- 安全規則獲取 (對標 Android BookSource.get*Rule) ---
  SearchRule getSearchRule() => ruleSearch ??= SearchRule();
  ExploreRule getExploreRule() => ruleExplore ??= ExploreRule();
  BookInfoRule getBookInfoRule() => ruleBookInfo ??= BookInfoRule();
  TocRule getTocRule() => ruleToc ??= TocRule();
  ContentRule getContentRule() => ruleContent ??= ContentRule();
  ReviewRule getReviewRule() => ruleReview ??= ReviewRule();

  // 分組操作邏輯 (高度還原 Android)
  void addGroup(String groups) {
    var currentGroups = bookSourceGroup?.split(RegExp(r'[,，\s]+')).where((s) => s.isNotEmpty).toSet() ?? {};
    currentGroups.addAll(groups.split(RegExp(r'[,，\s]+')).where((s) => s.isNotEmpty));
    bookSourceGroup = currentGroups.join(',');
  }

  void removeGroup(String groups) {
    var currentGroups = bookSourceGroup?.split(RegExp(r'[,，\s]+')).where((s) => s.isNotEmpty).toSet() ?? {};
    currentGroups.removeAll(groups.split(RegExp(r'[,，\s]+')).where((s) => s.isNotEmpty));
    bookSourceGroup = currentGroups.isEmpty ? null : currentGroups.join(',');
  }

  /// 移除失效的分組標記 (對標 Android removeInvalidGroups)
  void removeInvalidGroups() {
    if (bookSourceGroup == null) return;
    final invalidPattern = RegExp(r'失效|校驗超時');
    var currentGroups = bookSourceGroup!.split(RegExp(r'[,，\s]+')).where((s) => s.isNotEmpty).toList();
    currentGroups.removeWhere((g) => invalidPattern.hasMatch(g));
    bookSourceGroup = currentGroups.isEmpty ? null : currentGroups.join(',');
  }

  /// 清除註釋中的錯誤訊息 (對標 Android removeErrorComment)
  void removeErrorComment() {
    if (bookSourceComment == null) return;
    bookSourceComment = bookSourceComment!
        .split('\n\n')
        .where((line) => !line.trim().startsWith('// Error:'))
        .join('\n\n');
  }

  /// 添加錯誤訊息至註釋頂部 (對標 Android addErrorComment)
  void addErrorComment(String error) {
    removeErrorComment();
    final newErrorLine = '// Error: $error';
    bookSourceComment = bookSourceComment == null || bookSourceComment!.isEmpty
        ? newErrorLine
        : '$newErrorLine\n\n$bookSourceComment';
  }

  String getCheckKeyword(String defaultValue) {
    return (ruleSearch?.checkKeyWord != null && ruleSearch!.checkKeyWord!.isNotEmpty) 
        ? ruleSearch!.checkKeyWord! 
        : defaultValue;
  }

  factory BookSource.fromJson(Map<String, dynamic> json) {
    return BookSource(
      bookSourceUrl: json['bookSourceUrl'] ?? "",
      bookSourceName: json['bookSourceName'] ?? "",
      bookSourceGroup: json['bookSourceGroup'],
      bookSourceType: json['bookSourceType'] ?? 0,
      bookUrlPattern: json['bookUrlPattern'],
      customOrder: json['customOrder'] ?? 0,
      enabled: json['enabled'] == 1 || json['enabled'] == true,
      enabledExplore: json['enabledExplore'] == 1 || json['enabledExplore'] == true,
      jsLib: json['jsLib'],
      enabledCookieJar: json['enabledCookieJar'] == 1 || json['enabledCookieJar'] == true,
      concurrentRate: json['concurrentRate']?.toString(),
      header: json['header'],
      loginUrl: json['loginUrl'],
      loginUi: json['loginUi'],
      loginCheckJs: json['loginCheckJs'],
      coverDecodeJs: json['coverDecodeJs'],
      bookSourceComment: json['bookSourceComment'],
      variableComment: json['variableComment'],
      lastUpdateTime: json['lastUpdateTime'] ?? 0,
      respondTime: json['respondTime'] ?? 180000,
      weight: json['weight'] ?? 0,
      exploreUrl: json['exploreUrl'],
      exploreScreen: json['exploreScreen'],
      ruleExplore: json['ruleExplore'] != null ? ExploreRule.fromJson(_parseRule(json['ruleExplore'])) : null,
      searchUrl: json['searchUrl'],
      ruleSearch: json['ruleSearch'] != null ? SearchRule.fromJson(_parseRule(json['ruleSearch'])) : null,
      ruleBookInfo: json['ruleBookInfo'] != null ? BookInfoRule.fromJson(_parseRule(json['ruleBookInfo'])) : null,
      ruleToc: json['ruleToc'] != null ? TocRule.fromJson(_parseRule(json['ruleToc'])) : null,
      ruleContent: json['ruleContent'] != null ? ContentRule.fromJson(_parseRule(json['ruleContent'])) : null,
      ruleReview: json['ruleReview'] != null ? ReviewRule.fromJson(_parseRule(json['ruleReview'])) : null,
    );
  }

  static dynamic _parseRule(dynamic rule) {
    if (rule is String && rule.isNotEmpty) {
      try { return jsonDecode(rule); } catch (_) { return {}; }
    }
    return rule ?? {};
  }

  Map<String, dynamic> toJson() {
    return {
      'bookSourceUrl': bookSourceUrl,
      'bookSourceName': bookSourceName,
      'bookSourceGroup': bookSourceGroup,
      'bookSourceType': bookSourceType,
      'bookUrlPattern': bookUrlPattern,
      'customOrder': customOrder,
      'enabled': enabled ? 1 : 0,
      'enabledExplore': enabledExplore ? 1 : 0,
      'jsLib': jsLib,
      'enabledCookieJar': enabledCookieJar ? 1 : 0,
      'concurrentRate': concurrentRate,
      'header': header,
      'loginUrl': loginUrl,
      'loginUi': loginUi,
      'loginCheckJs': loginCheckJs,
      'coverDecodeJs': coverDecodeJs,
      'bookSourceComment': bookSourceComment,
      'variableComment': variableComment,
      'lastUpdateTime': lastUpdateTime,
      'respondTime': respondTime,
      'weight': weight,
      'exploreUrl': exploreUrl,
      'exploreScreen': exploreScreen,
      'ruleExplore': ruleExplore?.toJson(),
      'searchUrl': searchUrl,
      'ruleSearch': ruleSearch?.toJson(),
      'ruleBookInfo': ruleBookInfo?.toJson(),
      'ruleToc': ruleToc?.toJson(),
      'ruleContent': ruleContent?.toJson(),
      'ruleReview': ruleReview?.toJson(),
    };
  }
}

// --- Rule Classes ---

class SearchRule {
  String? init;
  String? bookList;
  String? name;
  String? author;
  String? kind;
  String? wordCount;
  String? lastChapter;
  String? coverUrl;
  String? intro;
  String? bookUrl;
  String? checkKeyWord;

  SearchRule({
    this.init, this.bookList, this.name, this.author, this.kind, this.wordCount,
    this.lastChapter, this.coverUrl, this.intro, this.bookUrl, this.checkKeyWord
  });

  factory SearchRule.fromJson(Map<String, dynamic> json) => SearchRule(
    init: json['init'], bookList: json['bookList'], name: json['name'], author: json['author'],
    kind: json['kind'], wordCount: json['wordCount'], lastChapter: json['lastChapter'],
    coverUrl: json['coverUrl'], intro: json['intro'], bookUrl: json['bookUrl'],
    checkKeyWord: json['checkKeyWord'],
  );

  Map<String, dynamic> toJson() => {
    'init': init, 'bookList': bookList, 'name': name, 'author': author, 'kind': kind,
    'wordCount': wordCount, 'lastChapter': lastChapter, 'coverUrl': coverUrl,
    'intro': intro, 'bookUrl': bookUrl, 'checkKeyWord': checkKeyWord,
  };
}

class ExploreRule {
  String? init;
  String? bookList;
  String? name;
  String? author;
  String? kind;
  String? wordCount;
  String? lastChapter;
  String? coverUrl;
  String? intro;
  String? bookUrl;

  ExploreRule({
    this.init, this.bookList, this.name, this.author, this.kind, this.wordCount,
    this.lastChapter, this.coverUrl, this.intro, this.bookUrl
  });

  factory ExploreRule.fromJson(Map<String, dynamic> json) => ExploreRule(
    init: json['init'], bookList: json['bookList'], name: json['name'], author: json['author'],
    kind: json['kind'], wordCount: json['wordCount'], lastChapter: json['lastChapter'],
    coverUrl: json['coverUrl'], intro: json['intro'], bookUrl: json['bookUrl'],
  );

  Map<String, dynamic> toJson() => {
    'init': init, 'bookList': bookList, 'name': name, 'author': author, 'kind': kind,
    'wordCount': wordCount, 'lastChapter': lastChapter, 'coverUrl': coverUrl,
    'intro': intro, 'bookUrl': bookUrl,
  };
}

class BookInfoRule {
  String? init;
  String? name;
  String? author;
  String? kind;
  String? wordCount;
  String? lastChapter;
  String? coverUrl;
  String? intro;
  String? tocUrl;
  bool? canReName;

  BookInfoRule({
    this.init, this.name, this.author, this.kind, this.wordCount, this.lastChapter,
    this.coverUrl, this.intro, this.tocUrl, this.canReName
  });

  factory BookInfoRule.fromJson(Map<String, dynamic> json) => BookInfoRule(
    init: json['init'],
    name: json['name'], author: json['author'], kind: json['kind'],
    wordCount: json['wordCount'], lastChapter: json['lastChapter'],
    coverUrl: json['coverUrl'], intro: json['intro'], tocUrl: json['tocUrl'],
    canReName: json['canReName'] == 1 || json['canReName'] == true,
  );

  Map<String, dynamic> toJson() => {
    'init': init,
    'name': name, 'author': author, 'kind': kind, 'wordCount': wordCount,
    'lastChapter': lastChapter, 'coverUrl': coverUrl, 'intro': intro,
    'tocUrl': tocUrl, 'canReName': canReName,
  };
}

class TocRule {
  String? init;
  String? chapterList;
  String? chapterName;
  String? chapterUrl;
  String? isVolume;
  String? isVip;
  String? isPay;
  String? updateTime;
  String? nextTocUrl;
  String? preUpdateJs;

  TocRule({
    this.init, this.chapterList, this.chapterName, this.chapterUrl, this.isVolume,
    this.isVip, this.isPay, this.updateTime, this.nextTocUrl, this.preUpdateJs
  });

  factory TocRule.fromJson(Map<String, dynamic> json) => TocRule(
    init: json['init'],
    chapterList: json['chapterList'], chapterName: json['chapterName'],
    chapterUrl: json['chapterUrl'], isVolume: json['isVolume'],
    isVip: json['isVip'], isPay: json['isPay'], updateTime: json['updateTime'],
    nextTocUrl: json['nextTocUrl'], preUpdateJs: json['preUpdateJs'],
  );

  Map<String, dynamic> toJson() => {
    'init': init,
    'chapterList': chapterList, 'chapterName': chapterName,
    'chapterUrl': chapterUrl, 'isVolume': isVolume, 'isVip': isVip,
    'isPay': isPay, 'updateTime': updateTime, 'nextTocUrl': nextTocUrl,
    'preUpdateJs': preUpdateJs,
  };
}

class ContentRule {
  String? init;
  String? content;
  String? nextContentUrl;
  String? webJs;
  String? sourceRegex;
  String? replaceRegex;
  String? imageStyle;
  String? imageDecode;
  String? payAction;

  ContentRule({
    this.init, this.content, this.nextContentUrl, this.webJs, this.sourceRegex,
    this.replaceRegex, this.imageStyle, this.imageDecode, this.payAction
  });

  factory ContentRule.fromJson(Map<String, dynamic> json) => ContentRule(
    init: json['init'],
    content: json['content'], nextContentUrl: json['nextContentUrl'],
    webJs: json['webJs'], sourceRegex: json['sourceRegex'],
    replaceRegex: json['replaceRegex'], imageStyle: json['imageStyle'],
    imageDecode: json['imageDecode'], payAction: json['payAction'],
  );

  Map<String, dynamic> toJson() => {
    'init': init,
    'content': content, 'nextContentUrl': nextContentUrl, 'webJs': webJs,
    'sourceRegex': sourceRegex, 'replaceRegex': replaceRegex,
    'imageStyle': imageStyle, 'imageDecode': imageDecode, 'payAction': payAction,
  };
}

class ReviewRule {
  String? reviewUrl;
  String? avatarRule;
  String? contentRule;
  String? postTimeRule;
  String? reviewQuoteUrl;
  String? voteUpUrl;
  String? voteDownUrl;
  String? postReviewUrl;
  String? postQuoteUrl;
  String? deleteUrl;

  ReviewRule({
    this.reviewUrl, this.avatarRule, this.contentRule, this.postTimeRule,
    this.reviewQuoteUrl, this.voteUpUrl, this.voteDownUrl, this.postReviewUrl,
    this.postQuoteUrl, this.deleteUrl
  });

  factory ReviewRule.fromJson(Map<String, dynamic> json) => ReviewRule(
    reviewUrl: json['reviewUrl'], avatarRule: json['avatarRule'],
    contentRule: json['contentRule'], postTimeRule: json['postTimeRule'],
    reviewQuoteUrl: json['reviewQuoteUrl'], voteUpUrl: json['voteUpUrl'],
    voteDownUrl: json['voteDownUrl'], postReviewUrl: json['postReviewUrl'],
    postQuoteUrl: json['postQuoteUrl'], deleteUrl: json['deleteUrl'],
  );

  Map<String, dynamic> toJson() => {
    'reviewUrl': reviewUrl, 'avatarRule': avatarRule, 'contentRule': contentRule,
    'postTimeRule': postTimeRule, 'reviewQuoteUrl': reviewQuoteUrl,
    'voteUpUrl': voteUpUrl, 'voteDownUrl': voteDownUrl,
    'postReviewUrl': postReviewUrl, 'postQuoteUrl': postQuoteUrl,
    'deleteUrl': deleteUrl,
  };
}
