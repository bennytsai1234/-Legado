import 'dart:convert';
import 'book_source_base.dart';
import 'book_source_rules.dart';

/// BookSource 的序列化與解析擴展
extension BookSourceSerialization on BookSourceBase {
  static dynamic parseRule(dynamic rule) {
    if (rule is String && rule.isNotEmpty) {
      try { return jsonDecode(rule); } catch (_) { return {}; }
    }
    return rule ?? {};
  }

  static Map<String, dynamic> sourceToJson(BookSourceBase source) {
    return {
      'bookSourceUrl': source.bookSourceUrl,
      'bookSourceName': source.bookSourceName,
      'bookSourceGroup': source.bookSourceGroup,
      'bookSourceType': source.bookSourceType,
      'bookUrlPattern': source.bookUrlPattern,
      'customOrder': source.customOrder,
      'enabled': source.enabled ? 1 : 0,
      'enabledExplore': source.enabledExplore ? 1 : 0,
      'jsLib': source.jsLib,
      'enabledCookieJar': source.enabledCookieJar ? 1 : 0,
      'concurrentRate': source.concurrentRate,
      'header': source.header,
      'loginUrl': source.loginUrl,
      'loginUi': source.loginUi,
      'loginCheckJs': source.loginCheckJs,
      'coverDecodeJs': source.coverDecodeJs,
      'bookSourceComment': source.bookSourceComment,
      'variableComment': source.variableComment,
      'lastUpdateTime': source.lastUpdateTime,
      'respondTime': source.respondTime,
      'weight': source.weight,
      'exploreUrl': source.exploreUrl,
      'exploreScreen': source.exploreScreen,
      'ruleExplore': source.ruleExplore?.toJson(),
      'searchUrl': source.searchUrl,
      'ruleSearch': source.ruleSearch?.toJson(),
      'ruleBookInfo': source.ruleBookInfo?.toJson(),
      'ruleToc': source.ruleToc?.toJson(),
      'ruleContent': source.ruleContent?.toJson(),
      'ruleReview': source.ruleReview?.toJson(),
    };
  }
}
