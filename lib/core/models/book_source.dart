library;

import 'base_source.dart';
import 'dart:convert';

/// BookSource - 書源模型
/// 完整相容 Legado 3.0 JSON 書源格式
///
/// 對應 Android: data/entities/BookSource.kt
class BookSource implements BaseSource {
  @override
  String bookSourceUrl; // 書源 URL (唯一識別)
  String bookSourceName; // 書源名稱
  int bookSourceType; // 0: 文字, 1: 音頻, 2: 圖片/漫畫, 3: 檔案
  String? bookSourceGroup; // 書源分組
  String? bookSourceComment; // 書源說明
  
  @override
  String? loginUrl; // 登入 URL
  
  @override
  String? loginUi; // 登入 UI JSON
  
  String? loginCheckJs; // 登入檢測 JS
  String? bookUrlPattern; // 書籍 URL 正則
  
  @override
  String? header; // 自訂 Header JSON
  
  String? variableComment; // 變數說明
  String? variable; // 暫存變數
  int customOrder; // 自訂排序
  int weight; // 權重
  bool enabled; // 是否啟用
  bool enabledExplore; // 是否啟用發現
  
  @override
  bool? enabledCookieJar; // 是否啟用 CookieJar
  
  int lastUpdateTime; // 最後更新時間
  int respondTime; // 回應時間
  
  @override
  String? jsLib; // JS 共享庫
  
  int concurrentRateInt; // 併發速率

  @override
  String? get concurrentRate => concurrentRateInt.toString();

  // === 搜尋規則 ===
  SearchRule? ruleSearch;
  // === 發現規則 ===
  ExploreRule? ruleExplore;
  // === 書籍資訊規則 ===
  BookInfoRule? ruleBookInfo;
  // === 目錄規則 ===
  TocRule? ruleToc;
  // === 正文規則 ===
  ContentRule? ruleContent;
  // === 發現 URL ===
  String? exploreUrl;
  // === 搜尋 URL ===
  String? searchUrl;

  BookSource({
    required this.bookSourceUrl,
    required this.bookSourceName,
    this.bookSourceType = 0,
    this.bookSourceGroup,
    this.bookSourceComment,
    this.loginUrl,
    this.loginUi,
    this.loginCheckJs,
    this.bookUrlPattern,
    this.header,
    this.variableComment,
    this.variable,
    this.customOrder = 0,
    this.weight = 0,
    this.enabled = true,
    this.enabledExplore = true,
    this.enabledCookieJar = false,
    this.lastUpdateTime = 0,
    this.respondTime = 180000,
    this.jsLib,
    this.concurrentRateInt = 0,
    this.ruleSearch,
    this.ruleExplore,
    this.ruleBookInfo,
    this.ruleToc,
    this.ruleContent,
    this.exploreUrl,
    this.searchUrl,
  });

  factory BookSource.fromJson(Map<String, dynamic> json) {
    return BookSource(
      bookSourceUrl: json['bookSourceUrl'] ?? '',
      bookSourceName: json['bookSourceName'] ?? '',
      bookSourceType: json['bookSourceType'] ?? 0,
      bookSourceGroup: json['bookSourceGroup'],
      bookSourceComment: json['bookSourceComment'],
      loginUrl: json['loginUrl'],
      loginUi: json['loginUi'],
      loginCheckJs: json['loginCheckJs'],
      bookUrlPattern: json['bookUrlPattern'],
      header: json['header'],
      variableComment: json['variableComment'],
      variable: json['variable'],
      customOrder: json['customOrder'] ?? 0,
      weight: json['weight'] ?? 0,
      enabled: json['enabled'] ?? true,
      enabledExplore: json['enabledExplore'] ?? true,
      enabledCookieJar: json['enabledCookieJar'] ?? false,
      lastUpdateTime: json['lastUpdateTime'] ?? 0,
      respondTime: json['respondTime'] ?? 180000,
      jsLib: json['jsLib'],
      concurrentRateInt: json['concurrentRate'] ?? 0,
      ruleSearch: json['ruleSearch'] != null
          ? SearchRule.fromJson(json['ruleSearch'])
          : null,
      ruleExplore: json['ruleExplore'] != null
          ? ExploreRule.fromJson(json['ruleExplore'])
          : null,
      ruleBookInfo: json['ruleBookInfo'] != null
          ? BookInfoRule.fromJson(json['ruleBookInfo'])
          : null,
      ruleToc: json['ruleToc'] != null
          ? TocRule.fromJson(json['ruleToc'])
          : null,
      ruleContent: json['ruleContent'] != null
          ? ContentRule.fromJson(json['ruleContent'])
          : null,
      exploreUrl: json['exploreUrl'],
      searchUrl: json['searchUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookSourceUrl': bookSourceUrl,
      'bookSourceName': bookSourceName,
      'bookSourceType': bookSourceType,
      'bookSourceGroup': bookSourceGroup,
      'bookSourceComment': bookSourceComment,
      'loginUrl': loginUrl,
      'loginUi': loginUi,
      'loginCheckJs': loginCheckJs,
      'bookUrlPattern': bookUrlPattern,
      'header': header,
      'variableComment': variableComment,
      'variable': variable,
      'customOrder': customOrder,
      'weight': weight,
      'enabled': enabled,
      'enabledExplore': enabledExplore,
      'enabledCookieJar': enabledCookieJar,
      'lastUpdateTime': lastUpdateTime,
      'respondTime': respondTime,
      'jsLib': jsLib,
      'concurrentRate': concurrentRateInt,
      'ruleSearch': ruleSearch?.toJson(),
      'ruleExplore': ruleExplore?.toJson(),
      'ruleBookInfo': ruleBookInfo?.toJson(),
      'ruleToc': ruleToc?.toJson(),
      'ruleContent': ruleContent?.toJson(),
      'exploreUrl': exploreUrl,
      'searchUrl': searchUrl,
    };
  }

  @override
  String getTag() => bookSourceName;

  @override
  String getKey() => bookSourceUrl;
}

/// 搜尋規則
/// 對應 Android: data/entities/rule/SearchRule.kt
class SearchRule {
  String? bookList;
  String? name;
  String? author;
  String? intro;
  String? kind;
  String? lastChapter;
  String? updateTime;
  String? bookUrl;
  String? coverUrl;
  String? wordCount;
  String? checkKeyWord;

  SearchRule({
    this.bookList,
    this.name,
    this.author,
    this.intro,
    this.kind,
    this.lastChapter,
    this.updateTime,
    this.bookUrl,
    this.coverUrl,
    this.wordCount,
    this.checkKeyWord,
  });

  factory SearchRule.fromJson(Map<String, dynamic> json) {
    return SearchRule(
      bookList: json['bookList'],
      name: json['name'],
      author: json['author'],
      intro: json['intro'],
      kind: json['kind'],
      lastChapter: json['lastChapter'],
      updateTime: json['updateTime'],
      bookUrl: json['bookUrl'],
      coverUrl: json['coverUrl'],
      wordCount: json['wordCount'],
      checkKeyWord: json['checkKeyWord'],
    );
  }

  Map<String, dynamic> toJson() => {
        'bookList': bookList,
        'name': name,
        'author': author,
        'intro': intro,
        'kind': kind,
        'lastChapter': lastChapter,
        'updateTime': updateTime,
        'bookUrl': bookUrl,
        'coverUrl': coverUrl,
        'wordCount': wordCount,
        'checkKeyWord': checkKeyWord,
      };
}

/// 發現規則
/// 對應 Android: data/entities/rule/ExploreRule.kt
class ExploreRule {
  String? bookList;
  String? name;
  String? author;
  String? intro;
  String? kind;
  String? lastChapter;
  String? updateTime;
  String? bookUrl;
  String? coverUrl;
  String? wordCount;

  ExploreRule({
    this.bookList,
    this.name,
    this.author,
    this.intro,
    this.kind,
    this.lastChapter,
    this.updateTime,
    this.bookUrl,
    this.coverUrl,
    this.wordCount,
  });

  factory ExploreRule.fromJson(Map<String, dynamic> json) {
    return ExploreRule(
      bookList: json['bookList'],
      name: json['name'],
      author: json['author'],
      intro: json['intro'],
      kind: json['kind'],
      lastChapter: json['lastChapter'],
      updateTime: json['updateTime'],
      bookUrl: json['bookUrl'],
      coverUrl: json['coverUrl'],
      wordCount: json['wordCount'],
    );
  }

  Map<String, dynamic> toJson() => {
        'bookList': bookList,
        'name': name,
        'author': author,
        'intro': intro,
        'kind': kind,
        'lastChapter': lastChapter,
        'updateTime': updateTime,
        'bookUrl': bookUrl,
        'coverUrl': coverUrl,
        'wordCount': wordCount,
      };
}

/// 書籍資訊規則
/// 對應 Android: data/entities/rule/BookInfoRule.kt
class BookInfoRule {
  String? init;
  String? name;
  String? author;
  String? intro;
  String? kind;
  String? lastChapter;
  String? updateTime;
  String? coverUrl;
  String? tocUrl;
  String? wordCount;
  String? canReName;
  String? downloadUrls;

  BookInfoRule({
    this.init,
    this.name,
    this.author,
    this.intro,
    this.kind,
    this.lastChapter,
    this.updateTime,
    this.coverUrl,
    this.tocUrl,
    this.wordCount,
    this.canReName,
    this.downloadUrls,
  });

  factory BookInfoRule.fromJson(Map<String, dynamic> json) {
    return BookInfoRule(
      init: json['init'],
      name: json['name'],
      author: json['author'],
      intro: json['intro'],
      kind: json['kind'],
      lastChapter: json['lastChapter'],
      updateTime: json['updateTime'],
      coverUrl: json['coverUrl'],
      tocUrl: json['tocUrl'],
      wordCount: json['wordCount'],
      canReName: json['canReName'],
      downloadUrls: json['downloadUrls'],
    );
  }

  Map<String, dynamic> toJson() => {
        'init': init,
        'name': name,
        'author': author,
        'intro': intro,
        'kind': kind,
        'lastChapter': lastChapter,
        'updateTime': updateTime,
        'coverUrl': coverUrl,
        'tocUrl': tocUrl,
        'wordCount': wordCount,
        'canReName': canReName,
        'downloadUrls': downloadUrls,
      };
}

/// 目錄規則
/// 對應 Android: data/entities/rule/TocRule.kt
class TocRule {
  String? preUpdateJs;
  String? chapterList;
  String? chapterName;
  String? chapterUrl;
  String? formatJs;
  String? isVolume;
  String? isVip;
  String? isPay;
  String? updateTime;
  String? nextTocUrl;

  TocRule({
    this.preUpdateJs,
    this.chapterList,
    this.chapterName,
    this.chapterUrl,
    this.formatJs,
    this.isVolume,
    this.isVip,
    this.isPay,
    this.updateTime,
    this.nextTocUrl,
  });

  factory TocRule.fromJson(Map<String, dynamic> json) {
    return TocRule(
      preUpdateJs: json['preUpdateJs'],
      chapterList: json['chapterList'],
      chapterName: json['chapterName'],
      chapterUrl: json['chapterUrl'],
      formatJs: json['formatJs'],
      isVolume: json['isVolume'],
      isVip: json['isVip'],
      isPay: json['isPay'],
      updateTime: json['updateTime'],
      nextTocUrl: json['nextTocUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
        'preUpdateJs': preUpdateJs,
        'chapterList': chapterList,
        'chapterName': chapterName,
        'chapterUrl': chapterUrl,
        'formatJs': formatJs,
        'isVolume': isVolume,
        'isVip': isVip,
        'isPay': isPay,
        'updateTime': updateTime,
        'nextTocUrl': nextTocUrl,
      };
}

/// 正文規則
/// 對應 Android: data/entities/rule/ContentRule.kt
class ContentRule {
  String? content;
  String? nextContentUrl;
  String? webJs;
  String? sourceRegex;
  String? replaceRegex;
  String? imageStyle;
  String? imageDecode;
  String? payAction;

  ContentRule({
    this.content,
    this.nextContentUrl,
    this.webJs,
    this.sourceRegex,
    this.replaceRegex,
    this.imageStyle,
    this.imageDecode,
    this.payAction,
  });

  factory ContentRule.fromJson(Map<String, dynamic> json) {
    return ContentRule(
      content: json['content'],
      nextContentUrl: json['nextContentUrl'],
      webJs: json['webJs'],
      sourceRegex: json['sourceRegex'],
      replaceRegex: json['replaceRegex'],
      imageStyle: json['imageStyle'],
      imageDecode: json['imageDecode'],
      payAction: json['payAction'],
    );
  }

  Map<String, dynamic> toJson() => {
        'content': content,
        'nextContentUrl': nextContentUrl,
        'webJs': webJs,
        'sourceRegex': sourceRegex,
        'replaceRegex': replaceRegex,
        'imageStyle': imageStyle,
        'imageDecode': imageDecode,
        'payAction': payAction,
      };
}
