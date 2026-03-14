import 'analyze_url/analyze_url_base.dart';
import 'analyze_url/analyze_url_parser.dart';
import 'analyze_url/analyze_url_fetcher.dart';
import 'analyze_url/analyze_url_utils.dart';

export 'analyze_url/analyze_url_fetcher.dart';
export 'analyze_url/analyze_url_utils.dart';

/// AnalyzeUrl - URL 構建與請求引擎 (重構後)
/// 對應 Android: model/analyzeRule/AnalyzeUrl.kt
/// 透過繼承與 Extension 將邏輯拆分至各個子檔案
class AnalyzeUrl extends AnalyzeUrlBase {
  AnalyzeUrl(
    super.mUrl, {
    super.key,
    super.page,
    super.speakText,
    super.speakSpeed,
    super.voiceName,
    super.baseUrl,
    super.analyzer,
    super.source,
    super.initialHeaders,
  }) {
    initUrl();
  }
}
