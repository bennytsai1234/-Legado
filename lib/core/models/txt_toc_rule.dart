/// TxtTocRule - 本地 TXT 目錄解析規則模型
/// 對應 Android: data/entities/TxtTocRule.kt
class TxtTocRule {
  int id;
  String name;
  String rule;
  String? example;
  int serialNumber;
  bool enable;

  TxtTocRule({
    required this.id,
    this.name = "",
    this.rule = "",
    this.example,
    this.serialNumber = -1,
    this.enable = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rule': rule,
      'example': example,
      'serialNumber': serialNumber,
      'enable': enable,
    };
  }

  factory TxtTocRule.fromJson(Map<String, dynamic> json) {
    return TxtTocRule(
      id: json['id'] ?? 0,
      name: json['name'] ?? "",
      rule: json['rule'] ?? "",
      example: json['example'],
      serialNumber: json['serialNumber'] ?? -1,
      enable: json['enable'] ?? true,
    );
  }
}
