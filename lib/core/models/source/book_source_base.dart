import '../base_source.dart';
import 'book_source_rules.dart';

/// BookSource 的基礎屬性與欄位定義
abstract class BookSourceBase implements BaseSource {
  String bookSourceUrl = ""; // 書源 URL (唯一識別)
  String bookSourceName = ""; // 書源名稱
  String? bookSourceGroup; // 書源分組
  int bookSourceType = 0; // 類型 (0: 文本, 1: 音訊, 2: 圖片, 3: 文件)
  String? bookUrlPattern; // 詳情頁 URL 正則
  int customOrder = 0; // 手動排序
  bool enabled = true; // 是否啟用
  bool enabledExplore = true; // 啟用發現
  String? icon; // 書源圖標

  @override String? jsLib;
  @override bool enabledCookieJar = true;
  @override String? concurrentRate;
  @override String? header;
  @override String? loginUrl;
  @override String? loginUi;
  @override String? loginCheckJs;
  @override String? coverDecodeJs;

  String? bookSourceComment; // 註釋
  String? variableComment; // 變量說明
  int lastUpdateTime = 0; // 最後更新時間
  int respondTime = 180000; // 響應時間
  int weight = 0; // 權重
  String? exploreUrl; // 發現 URL
  String? exploreScreen; // 發現篩選規則
  
  ExploreRule? ruleExplore;
  String? searchUrl;
  SearchRule? ruleSearch;
  BookInfoRule? ruleBookInfo;
  TocRule? ruleToc;
  ContentRule? ruleContent;
  ReviewRule? ruleReview;

  @override String getTag() => bookSourceName;
  @override String getKey() => bookSourceUrl;
}
