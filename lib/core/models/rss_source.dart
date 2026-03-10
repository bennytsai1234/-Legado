import 'base_source.dart';

/// RssSource - RSS 訂閱源模型
/// 對應 Android: data/entities/RssSource.kt
class RssSource implements BaseSource {
  String sourceUrl;
  String sourceName;
  String sourceIcon;
  String? sourceGroup;
  String? sourceComment;
  bool enabled;
  String? variableComment;
  
  @override
  String? jsLib;
  
  @override
  bool? enabledCookieJar;
  
  @override
  String? concurrentRate;
  
  @override
  String? header;
  
  @override
  String? loginUrl;
  
  @override
  String? loginUi;
  
  String? loginCheckJs;
  String? coverDecodeJs;
  String? sortUrl;
  bool singleUrl;
  
  int articleStyle; // 0, 1, 2
  String? ruleArticles;
  String? ruleNextPage;
  String? ruleTitle;
  String? rulePubDate;
  String? ruleDescription;
  String? ruleImage;
  String? ruleLink;
  String? ruleContent;
  String? contentWhitelist;
  String? contentBlacklist;
  String? shouldOverrideUrlLoading;
  String? style;
  bool enableJs;
  bool loadWithBaseUrl;
  String? injectJs;
  int lastUpdateTime;
  int customOrder;

  RssSource({
    this.sourceUrl = "",
    this.sourceName = "",
    this.sourceIcon = "",
    this.sourceGroup,
    this.sourceComment,
    this.enabled = true,
    this.variableComment,
    this.jsLib,
    this.enabledCookieJar = true,
    this.concurrentRate,
    this.header,
    this.loginUrl,
    this.loginUi,
    this.loginCheckJs,
    this.coverDecodeJs,
    this.sortUrl,
    this.singleUrl = false,
    this.articleStyle = 0,
    this.ruleArticles,
    this.ruleNextPage,
    this.ruleTitle,
    this.rulePubDate,
    this.ruleDescription,
    this.ruleImage,
    this.ruleLink,
    this.ruleContent,
    this.contentWhitelist,
    this.contentBlacklist,
    this.shouldOverrideUrlLoading,
    this.style,
    this.enableJs = true,
    this.loadWithBaseUrl = true,
    this.injectJs,
    this.lastUpdateTime = 0,
    this.customOrder = 0,
  });

  @override
  String getTag() => sourceName;

  @override
  String getKey() => sourceUrl;

  Map<String, dynamic> toJson() {
    return {
      'sourceUrl': sourceUrl,
      'sourceName': sourceName,
      'sourceIcon': sourceIcon,
      'sourceGroup': sourceGroup,
      'sourceComment': sourceComment,
      'enabled': enabled,
      'variableComment': variableComment,
      'jsLib': jsLib,
      'enabledCookieJar': enabledCookieJar,
      'concurrentRate': concurrentRate,
      'header': header,
      'loginUrl': loginUrl,
      'loginUi': loginUi,
      'loginCheckJs': loginCheckJs,
      'coverDecodeJs': coverDecodeJs,
      'sortUrl': sortUrl,
      'singleUrl': singleUrl,
      'articleStyle': articleStyle,
      'ruleArticles': ruleArticles,
      'ruleNextPage': ruleNextPage,
      'ruleTitle': ruleTitle,
      'rulePubDate': rulePubDate,
      'ruleDescription': ruleDescription,
      'ruleImage': ruleImage,
      'ruleLink': ruleLink,
      'ruleContent': ruleContent,
      'contentWhitelist': contentWhitelist,
      'contentBlacklist': contentBlacklist,
      'shouldOverrideUrlLoading': shouldOverrideUrlLoading,
      'style': style,
      'enableJs': enableJs,
      'loadWithBaseUrl': loadWithBaseUrl,
      'injectJs': injectJs,
      'lastUpdateTime': lastUpdateTime,
      'customOrder': customOrder,
    };
  }

  factory RssSource.fromJson(Map<String, dynamic> json) {
    return RssSource(
      sourceUrl: json['sourceUrl'] ?? "",
      sourceName: json['sourceName'] ?? "",
      sourceIcon: json['sourceIcon'] ?? "",
      sourceGroup: json['sourceGroup'],
      sourceComment: json['sourceComment'],
      enabled: json['enabled'] ?? true,
      variableComment: json['variableComment'],
      jsLib: json['jsLib'],
      enabledCookieJar: json['enabledCookieJar'],
      concurrentRate: json['concurrentRate'],
      header: json['header'],
      loginUrl: json['loginUrl'],
      loginUi: json['loginUi'],
      loginCheckJs: json['loginCheckJs'],
      coverDecodeJs: json['coverDecodeJs'],
      sortUrl: json['sortUrl'],
      singleUrl: json['singleUrl'] ?? false,
      articleStyle: json['articleStyle'] ?? 0,
      ruleArticles: json['ruleArticles'],
      ruleNextPage: json['ruleNextPage'],
      ruleTitle: json['ruleTitle'],
      rulePubDate: json['rulePubDate'],
      ruleDescription: json['ruleDescription'],
      ruleImage: json['ruleImage'],
      ruleLink: json['ruleLink'],
      ruleContent: json['ruleContent'],
      contentWhitelist: json['contentWhitelist'],
      contentBlacklist: json['contentBlacklist'],
      shouldOverrideUrlLoading: json['shouldOverrideUrlLoading'],
      style: json['style'],
      enableJs: json['enableJs'] ?? true,
      loadWithBaseUrl: json['loadWithBaseUrl'] ?? true,
      injectJs: json['injectJs'],
      lastUpdateTime: json['lastUpdateTime'] ?? 0,
      customOrder: json['customOrder'] ?? 0,
    );
  }

  RssSource copyWith({
    String? sourceUrl,
    String? sourceName,
    String? sourceIcon,
    String? sourceGroup,
    String? sourceComment,
    bool? enabled,
    String? variableComment,
    String? jsLib,
    bool? enabledCookieJar,
    String? concurrentRate,
    String? header,
    String? loginUrl,
    String? loginUi,
    String? loginCheckJs,
    String? coverDecodeJs,
    String? sortUrl,
    bool? singleUrl,
    int? articleStyle,
    String? ruleArticles,
    String? ruleNextPage,
    String? ruleTitle,
    String? rulePubDate,
    String? ruleDescription,
    String? ruleImage,
    String? ruleLink,
    String? ruleContent,
    String? contentWhitelist,
    String? contentBlacklist,
    String? shouldOverrideUrlLoading,
    String? style,
    bool? enableJs,
    bool? loadWithBaseUrl,
    String? injectJs,
    int? lastUpdateTime,
    int? customOrder,
  }) {
    return RssSource(
      sourceUrl: sourceUrl ?? this.sourceUrl,
      sourceName: sourceName ?? this.sourceName,
      sourceIcon: sourceIcon ?? this.sourceIcon,
      sourceGroup: sourceGroup ?? this.sourceGroup,
      sourceComment: sourceComment ?? this.sourceComment,
      enabled: enabled ?? this.enabled,
      variableComment: variableComment ?? this.variableComment,
      jsLib: jsLib ?? this.jsLib,
      enabledCookieJar: enabledCookieJar ?? this.enabledCookieJar,
      concurrentRate: concurrentRate ?? this.concurrentRate,
      header: header ?? this.header,
      loginUrl: loginUrl ?? this.loginUrl,
      loginUi: loginUi ?? this.loginUi,
      loginCheckJs: loginCheckJs ?? this.loginCheckJs,
      coverDecodeJs: coverDecodeJs ?? this.coverDecodeJs,
      sortUrl: sortUrl ?? this.sortUrl,
      singleUrl: singleUrl ?? this.singleUrl,
      articleStyle: articleStyle ?? this.articleStyle,
      ruleArticles: ruleArticles ?? this.ruleArticles,
      ruleNextPage: ruleNextPage ?? this.ruleNextPage,
      ruleTitle: ruleTitle ?? this.ruleTitle,
      rulePubDate: rulePubDate ?? this.rulePubDate,
      ruleDescription: ruleDescription ?? this.ruleDescription,
      ruleImage: ruleImage ?? this.ruleImage,
      ruleLink: ruleLink ?? this.ruleLink,
      ruleContent: ruleContent ?? this.ruleContent,
      contentWhitelist: contentWhitelist ?? this.contentWhitelist,
      contentBlacklist: contentBlacklist ?? this.contentBlacklist,
      shouldOverrideUrlLoading: shouldOverrideUrlLoading ?? this.shouldOverrideUrlLoading,
      style: style ?? this.style,
      enableJs: enableJs ?? this.enableJs,
      loadWithBaseUrl: loadWithBaseUrl ?? this.loadWithBaseUrl,
      injectJs: injectJs ?? this.injectJs,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      customOrder: customOrder ?? this.customOrder,
    );
  }
}
