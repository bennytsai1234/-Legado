import 'dart:convert';
import 'base_rss_article.dart';

/// RssArticle - RSS 文章模型
/// 對應 Android: data/entities/RssArticle.kt
class RssArticle extends BaseRssArticle {
  @override
  String origin;
  String sort;
  String title;
  int order;
  @override
  String link;
  String? pubDate;
  String? description;
  String? content;
  String? image;
  String group;
  bool read;
  @override
  String? variable;

  @override
  final Map<String, String> variableMap;

  RssArticle({
    this.origin = "",
    this.sort = "",
    this.title = "",
    this.order = 0,
    this.link = "",
    this.pubDate,
    this.description,
    this.content,
    this.image,
    this.group = "默认分组",
    this.read = false,
    this.variable,
  }) : variableMap = variable != null ? Map<String, String>.from(jsonDecode(variable)) : {};

  Map<String, dynamic> toJson() {
    return {
      'origin': origin,
      'sort': sort,
      'title': title,
      'order': order,
      'link': link,
      'pubDate': pubDate,
      'description': description,
      'content': content,
      'image': image,
      'group': group,
      'read': read,
      'variable': variable,
    };
  }

  factory RssArticle.fromJson(Map<String, dynamic> json) {
    return RssArticle(
      origin: json['origin'] ?? "",
      sort: json['sort'] ?? "",
      title: json['title'] ?? "",
      order: json['order'] ?? 0,
      link: json['link'] ?? "",
      pubDate: json['pubDate'],
      description: json['description'],
      content: json['content'],
      image: json['image'],
      group: json['group'] ?? "默认分组",
      read: json['read'] ?? false,
      variable: json['variable'],
    );
  }
}
