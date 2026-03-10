/// DictRule - 字典規則模型
/// 對應 Android: data/entities/DictRule.kt
class DictRule {
  String name;
  String urlRule;
  String showRule;
  bool enabled;
  int sortNumber;

  DictRule({
    this.name = "",
    this.urlRule = "",
    this.showRule = "",
    this.enabled = true,
    this.sortNumber = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'urlRule': urlRule,
      'showRule': showRule,
      'enabled': enabled,
      'sortNumber': sortNumber,
    };
  }

  factory DictRule.fromJson(Map<String, dynamic> json) {
    return DictRule(
      name: json['name'] ?? "",
      urlRule: json['urlRule'] ?? "",
      showRule: json['showRule'] ?? "",
      enabled: json['enabled'] ?? true,
      sortNumber: json['sortNumber'] ?? 0,
    );
  }
}
