/// BookSourcePart - 書源部分欄位模型 (用於列表顯示)
/// 對應 Android: data/entities/BookSourcePart.kt
class BookSourcePart {
  String bookSourceUrl;
  String bookSourceName;
  String? bookSourceGroup;
  int customOrder;
  bool enabled;
  bool enabledExplore;
  bool hasLoginUrl;
  int lastUpdateTime;
  int respondTime;
  int weight;
  bool hasExploreUrl;

  BookSourcePart({
    this.bookSourceUrl = "",
    this.bookSourceName = "",
    this.bookSourceGroup,
    this.customOrder = 0,
    this.enabled = true,
    this.enabledExplore = true,
    this.hasLoginUrl = false,
    this.lastUpdateTime = 0,
    this.respondTime = 180000,
    this.weight = 0,
    this.hasExploreUrl = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'bookSourceUrl': bookSourceUrl,
      'bookSourceName': bookSourceName,
      'bookSourceGroup': bookSourceGroup,
      'customOrder': customOrder,
      'enabled': enabled,
      'enabledExplore': enabledExplore,
      'hasLoginUrl': hasLoginUrl,
      'lastUpdateTime': lastUpdateTime,
      'respondTime': respondTime,
      'weight': weight,
      'hasExploreUrl': hasExploreUrl,
    };
  }

  factory BookSourcePart.fromJson(Map<String, dynamic> json) {
    return BookSourcePart(
      bookSourceUrl: json['bookSourceUrl'] ?? "",
      bookSourceName: json['bookSourceName'] ?? "",
      bookSourceGroup: json['bookSourceGroup'],
      customOrder: json['customOrder'] ?? 0,
      enabled: json['enabled'] ?? true,
      enabledExplore: json['enabledExplore'] ?? true,
      hasLoginUrl: json['hasLoginUrl'] ?? false,
      lastUpdateTime: json['lastUpdateTime'] ?? 0,
      respondTime: json['respondTime'] ?? 180000,
      weight: json['weight'] ?? 0,
      hasExploreUrl: json['hasExploreUrl'] ?? false,
    );
  }
}
