import 'package:flutter/foundation.dart';
import '../../core/database/dao/rss_source_dao.dart';
import '../../core/models/rss_source.dart';

class RssSourceProvider extends ChangeNotifier {
  final RssSourceDao _dao = RssSourceDao();
  List<RssSource> _sources = [];
  bool _isLoading = false;

  List<RssSource> get sources => _sources;
  bool get isLoading => _isLoading;

  RssSourceProvider() {
    loadSources();
  }

  Future<void> loadSources() async {
    _isLoading = true;
    notifyListeners();
    
    _sources = await _dao.getAll();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleEnabled(RssSource source) async {
    final newState = !source.enabled;
    await _dao.updateEnabled(source.sourceUrl, newState);
    source.enabled = newState;
    notifyListeners();
  }

  Future<void> deleteSource(RssSource source) async {
    await _dao.delete(source.sourceUrl);
    _sources.removeWhere((s) => s.sourceUrl == source.sourceUrl);
    notifyListeners();
  }
}
