/// ReplaceRule - 替換淨化規則模型
/// 對應 Android: data/entities/ReplaceRule.kt
library;

class ReplaceRule {
  int id;
  String name; // 規則名稱
  String? group; // 分組
  String pattern; // 替換正則
  String replacement; // 替換為
  String? scope; // 作用範圍 (書名 or 書源 URL)
  String? scopeContent; // 作用範圍內容
  bool isEnabled; // 是否啟用
  bool isRegex; // 是否正則
  int order; // 排序

  ReplaceRule({
    this.id = 0,
    required this.name,
    this.group,
    required this.pattern,
    this.replacement = '',
    this.scope,
    this.scopeContent,
    this.isEnabled = true,
    this.isRegex = true,
    this.order = 0,
  });

  factory ReplaceRule.fromJson(Map<String, dynamic> json) {
    return ReplaceRule(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      group: json['group'],
      pattern: json['pattern'] ?? '',
      replacement: json['replacement'] ?? '',
      scope: json['scope'],
      scopeContent: json['scopeContent'],
      isEnabled: json['isEnabled'] ?? true,
      isRegex: json['isRegex'] ?? true,
      order: json['order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'group': group,
    'pattern': pattern,
    'replacement': replacement,
    'scope': scope,
    'scopeContent': scopeContent,
    'isEnabled': isEnabled,
    'isRegex': isRegex,
    'order': order,
  };
}
