import 'package:html/dom.dart';
import 'css/analyze_by_css_base.dart';
import 'css/analyze_by_css_core.dart';

export 'css/analyze_by_css_core.dart';

/// AnalyzeByCss - CSS 選擇器解析器 (重構後)
/// 對應 Android: model/analyzeRule/AnalyzeByJSoup.kt
/// 透過 Extension 將邏輯拆分至各個子檔案
class AnalyzeByCss extends AnalyzeByCssBase {
  AnalyzeByCss([dynamic doc]) {
    if (doc != null) {
      setContent(doc);
    }
  }
}
