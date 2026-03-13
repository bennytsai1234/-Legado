/// AppConst - 全域常數定義 (對標 Android constant/AppConst.kt)
class AppConst {
  AppConst._();

  // AI_PORT: GAP-CONST-01 derived from [AppConst.kt]
  static const String appTag = "Legado";
  static const String uaName = "User-Agent";
  static const int maxThread = 9;
  static const int defaultWebDavId = -1;

  static const List<String> charsets = [
    "UTF-8",
    "GB2312",
    "GB18030",
    "GBK",
    "Unicode",
    "UTF-16",
    "UTF-16LE",
    "ASCII",
  ];

  // 離線快取通道 (對標 channelId)
  static const String channelIdDownload = "channel_download";
  static const String channelIdReadAloud = "channel_read_aloud";
  static const String channelIdWeb = "channel_web";
}

/// PlaybackStatus - 播放狀態 (對標 Android constant/Status.kt)
enum PlaybackStatus {
  stop,
  play,
  pause,
}

/// AppTheme - 主題類型 (對標 Android constant/Theme.kt)
enum AppTheme {
  dark,
  light,
  auto,
  transparent,
  eInk,
}
