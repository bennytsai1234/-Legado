/// RuleSub - 規則訂閱模型 (例如訂閱正則或解析規則)
/// 對應 Android: data/entities/RuleSub.kt
class RuleSub {
  final int id;
  String name;
  String url;
  int type;
  int customOrder;
  bool autoUpdate;
  int update;

  RuleSub({
    required this.id,
    this.name = "",
    this.url = "",
    this.type = 0,
    this.customOrder = 0,
    this.autoUpdate = false,
    this.update = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'type': type,
      'customOrder': customOrder,
      'autoUpdate': autoUpdate,
      'update': update,
    };
  }

  factory RuleSub.fromJson(Map<String, dynamic> json) {
    return RuleSub(
      id: json['id'] ?? 0,
      name: json['name'] ?? "",
      url: json['url'] ?? "",
      type: json['type'] ?? 0,
      customOrder: json['customOrder'] ?? 0,
      autoUpdate: json['autoUpdate'] ?? false,
      update: json['update'] ?? 0,
    );
  }
}
