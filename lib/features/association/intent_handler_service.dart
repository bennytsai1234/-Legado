import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'intent/intent_base.dart';
import 'intent/intent_uri_handler.dart';
import 'intent/intent_file_handler.dart';
import 'intent/intent_dialog_helper.dart';

export 'intent/intent_base.dart';
export 'intent/intent_uri_handler.dart';
export 'intent/intent_file_handler.dart';
export 'intent/intent_dialog_helper.dart';

/// IntentHandlerService - 外部連結與分享處理服務 (重構後)
/// 對應 Android: ui/main/IntentHandler.kt
class IntentHandlerService extends IntentBase with IntentUriHandler, IntentFileHandler, IntentDialogHelper {
  static final IntentHandlerService _instance = IntentHandlerService._internal();
  factory IntentHandlerService() => _instance;
  IntentHandlerService._internal();

  @override
  void init(BuildContext context, {Function(BuildContext, Uri)? onUri, Function(BuildContext, List<dynamic>)? onMedia}) {
    appLinks = AppLinks();

    // 1. Deep Link (legado://)
    linkSubscription = appLinks.uriLinkStream.listen((uri) {
      if (context.mounted) handleUri(context, uri, showImportDialog);
    });

    // 2. Sharing Intent (File/Text)
    sharedMediaSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((value) {
      if (context.mounted) handleSharedMedia(context, value, showImportDialog, (ctx, path) => showForceImportDialog(ctx, path, _handleSharedBook));
    }, onError: (err) => debugPrint("SharingIntent error: $err"));

    // Check initial intents
    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      if (value.isNotEmpty && context.mounted) handleSharedMedia(context, value, showImportDialog, (ctx, path) => showForceImportDialog(ctx, path, _handleSharedBook));
    });

    appLinks.getInitialLink().then((uri) {
      if (uri != null && context.mounted) handleUri(context, uri, showImportDialog);
    });
  }

  // Wrapper for private book handling from Mixin if needed, or using direct call
  void _handleSharedBook(BuildContext ctx, String path) => (this as IntentFileHandler)._handleSharedBook(ctx, path);
}
