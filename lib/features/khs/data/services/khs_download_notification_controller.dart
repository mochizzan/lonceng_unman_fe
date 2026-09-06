// khs - Download notification controller
//
// Decoupled controller for KHS PDF download notifications (Play Store-like).
// Approach 2: cubit stays lean, controller owns the notification lifecycle.

import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lonceng_unman_fe/core/constants/app_strings.dart';
import 'package:lonceng_unman_fe/core/constants/notification_config.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/core/services/notification_service.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

/// Controller for KHS PDF download progress notifications.
///
/// ID tunggal `notificationId` — setiap show menggantikan notifikasi sebelumnya
/// (Play Store pattern). Blocking sequential: satu unduhan pada satu waktu.
///
/// Diuji via fake [NotificationService]/[FlutterLocalNotificationsPlugin].
class KhsDownloadNotificationController {
  KhsDownloadNotificationController({
    NotificationService? notificationService,
    Future<bool> Function(String filePath)? openFile,
    Future<void> Function(String filePath)? shareFile,
    void Function(String message)? onFeedback,
  }) : _service = notificationService ?? Services.get<NotificationService>(),
       _openFile = openFile ?? _defaultOpenFile,
       _shareFile = shareFile ?? _defaultShareFile,
       _onFeedback =
           onFeedback; // ignore: prefer_initializing_formals — fallback logic needs explicit assign

  final NotificationService _service;
  final Future<bool> Function(String filePath) _openFile;
  final Future<void> Function(String filePath) _shareFile;
  final void Function(String message)? _onFeedback;

  /// Single notification ID — updates in-place. Range 7000-7999 reserved.
  static const int notificationId = 7001;

  /// Last semester requested — used by retry action.
  String? _lastSemester;

  /// Last file path for share/open retry.
  String? _lastFilePath;

  /// Callback to retry download — set by cubit wiring.
  Future<void> Function(String semester)? onRetryRequested;

  String? get lastSemester => _lastSemester;

  // ── Permission soft-gate ────────────────────────────────────────────

  /// Check POST_NOTIFICATIONS gate: existing → true, else request once.
  /// Returns false only if user still denies — caller must still download
  /// without notification (soft-gate).
  Future<bool> ensurePermission() async {
    debugPrint(
      '[KhsDownloadNotification] ensurePermission: checking status...',
    );
    try {
      final already = await _service.checkPermissionStatus();
      debugPrint(
        '[KhsDownloadNotification] ensurePermission: alreadyGranted=$already',
      );
      if (already) return true;
      debugPrint(
        '[KhsDownloadNotification] ensurePermission: requesting permission...',
      );
      final granted = await _service.requestPermission();
      debugPrint(
        '[KhsDownloadNotification] ensurePermission: requested → granted=$granted',
      );
      return granted;
    } catch (e, st) {
      debugPrint('[KhsDownloadNotification] ensurePermission error: $e\n$st');
      return false;
    }
  }

  // ── Show phases ─────────────────────────────────────────────────────

  Future<void> showOngoing({required String fileName}) async {
    debugPrint(
      '[KhsDownloadNotification] showOngoing called: fileName=$fileName lastSemester=$_lastSemester',
    );
    _lastFilePath = null;
    try {
      await _service.show(
        id: notificationId,
        title: AppStrings.khsDownloadNotificationOngoingTitle,
        body: fileName,
        channel: NotificationChannel.downloads,
        payload: fileName,
        ongoing: true,
        autoCancel: false,
      );
      debugPrint(
        '[KhsDownloadNotification] showOngoing success: $fileName id=$notificationId',
      );
    } catch (e, st) {
      debugPrint('[KhsDownloadNotification] showOngoing failed: $e\n$st');
    }
  }

  /// Track semester at start so retry knows what to re-download.
  void notifyDownloadStarted(String semester) {
    _lastSemester = semester;
  }

  Future<void> showCompleted({
    required String fileName,
    required String filePath,
  }) async {
    debugPrint(
      '[KhsDownloadNotification] showCompleted called: fileName=$fileName filePath=$filePath',
    );
    _lastFilePath = filePath;
    try {
      final fileExists = File(filePath).existsSync();
      debugPrint(
        '[KhsDownloadNotification] showCompleted fileExists=$fileExists lastSemester=$_lastSemester',
      );
      await _service.show(
        id: notificationId,
        title: AppStrings.khsDownloadNotificationCompletedTitle,
        body:
            '$fileName — ${AppStrings.khsDownloadNotificationCompletedLocation} — ${AppStrings.khsDownloadNotificationHint}',
        channel: NotificationChannel.downloads,
        payload: filePath,
        ongoing: false,
        autoCancel: true,
        actions: const [
          AndroidNotificationAction(
            'open',
            AppStrings.khsDownloadActionOpen,
            showsUserInterface: true,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            'share',
            AppStrings.khsDownloadActionShare,
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      );
      debugPrint(
        '[KhsDownloadNotification] showCompleted success: $fileName id=$notificationId payload=$filePath',
      );
    } catch (e, st) {
      debugPrint('[KhsDownloadNotification] showCompleted failed: $e\n$st');
    }
  }

  Future<void> showError({
    required String fileName,
    required String reason,
    bool withRetry = true,
  }) async {
    debugPrint(
      '[KhsDownloadNotification] showError called: fileName=$fileName reason=$reason withRetry=$withRetry payload=${_lastFilePath ?? fileName}',
    );
    try {
      await _service.show(
        id: notificationId,
        title: AppStrings.khsDownloadNotificationErrorTitle,
        body: '$fileName — $reason',
        channel: NotificationChannel.downloads,
        payload: _lastFilePath ?? fileName,
        ongoing: false,
        autoCancel: true,
        actions: withRetry
            ? const [
                AndroidNotificationAction(
                  'retry',
                  AppStrings.khsDownloadActionRetry,
                  showsUserInterface: true,
                  cancelNotification: true,
                ),
              ]
            : null,
      );
      debugPrint(
        '[KhsDownloadNotification] showError success: $reason id=$notificationId',
      );
    } catch (e, st) {
      debugPrint('[KhsDownloadNotification] showError failed: $e\n$st');
    }
  }

  Future<void> cancel() async {
    try {
      await _service.cancel(notificationId);
    } catch (e) {
      debugPrint('[KhsDownloadNotification] cancel failed: $e');
    }
  }

  // ── Tap / action routing ────────────────────────────────────────────

  void _showFeedback(String message) {
    debugPrint('[KhsDownloadNotification] feedback: $message');
    final feedback = _onFeedback;
    if (feedback != null) {
      try {
        feedback(message);
        return;
      } catch (e) {
        debugPrint('[KhsDownloadNotification] onFeedback failed: $e');
      }
    }
    try {
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
      debugPrint('[KhsDownloadNotification] toast shown: $message');
    } catch (e) {
      debugPrint('[KhsDownloadNotification] toast failed: $e');
    }
  }

  void handleResponse(NotificationResponse response) {
    debugPrint(
      '[KhsDownloadNotification] handleResponse raw: id=${response.id} '
      'actionId=${response.actionId} payload=${response.payload} '
      'type=${response.notificationResponseType} input=${response.input}',
    );
    // Only handle our ID; ignore class reminder taps.
    if (response.id != notificationId) {
      debugPrint(
        '[KhsDownloadNotification] handleResponse ignored: id ${response.id} != $notificationId',
      );
      return;
    }

    final payload = response.payload;
    final actionId = response.actionId;

    debugPrint(
      '[KhsDownloadNotification] handleResponse routing: actionId=$actionId payload=$payload '
      'lastSemester=$_lastSemester lastFilePath=$_lastFilePath hasRetryHandler=${onRetryRequested != null}',
    );

    // Tap on body with no actionId → treat as open when we have a file path.
    if (actionId == null || actionId.isEmpty) {
      debugPrint('[KhsDownloadNotification] handleResponse → body tap → open');
      if (payload != null && payload.isNotEmpty) {
        _handleOpen(payload);
      } else {
        debugPrint(
          '[KhsDownloadNotification] handleResponse body tap: empty payload, ignored',
        );
        _showFeedback(AppStrings.khsDownloadFileNotFound);
      }
      return;
    }

    switch (actionId) {
      case 'open':
        debugPrint('[KhsDownloadNotification] handleResponse → open action');
        if (payload != null && payload.isNotEmpty) {
          _handleOpen(payload);
        } else {
          debugPrint('[KhsDownloadNotification] open action: empty payload');
          _showFeedback(AppStrings.khsDownloadFileNotFound);
        }
        break;
      case 'share':
        debugPrint('[KhsDownloadNotification] handleResponse → share action');
        if (payload != null && payload.isNotEmpty) {
          _handleShare(payload);
        } else {
          debugPrint('[KhsDownloadNotification] share action: empty payload');
          _showFeedback(AppStrings.khsDownloadFileNotFound);
        }
        break;
      case 'retry':
        debugPrint(
          '[KhsDownloadNotification] handleResponse → retry action lastSemester=$_lastSemester',
        );
        final sem = _lastSemester;
        if (sem != null && onRetryRequested != null) {
          debugPrint('[KhsDownloadNotification] retry firing: $sem');
          // Fire-and-forget; cubit will re-enter its own flow and re-show ongoing.
          onRetryRequested!(sem);
        } else {
          debugPrint(
            '[KhsDownloadNotification] retry ignored: no semester/handler '
            '(lastSemester=$_lastSemester hasHandler=${onRetryRequested != null})',
          );
          _showFeedback(AppStrings.khsDownloadFileNotFound);
        }
        break;
      default:
        debugPrint('[KhsDownloadNotification] unknown actionId: $actionId');
    }
  }

  Future<void> _handleOpen(String filePath) async {
    debugPrint('[KhsDownloadNotification] _handleOpen called: $filePath');
    final file = File(filePath);
    final exists = file.existsSync();
    debugPrint(
      '[KhsDownloadNotification] _handleOpen existsSync=$exists path=$filePath',
    );
    if (!exists) {
      debugPrint('[KhsDownloadNotification] open: file not found $filePath');
      _showFeedback(AppStrings.khsDownloadFileNotFound);
      return;
    }
    try {
      debugPrint(
        '[KhsDownloadNotification] _handleOpen → calling openFile: $filePath',
      );
      final result = await _openFile(filePath);
      debugPrint(
        '[KhsDownloadNotification] _handleOpen openFile result=$result path=$filePath',
      );
      if (!result) {
        debugPrint(
          '[KhsDownloadNotification] open: no app to handle $filePath',
        );
        _showFeedback(AppStrings.khsDownloadNoViewer);
      } else {
        debugPrint('[KhsDownloadNotification] open success: $filePath');
      }
    } catch (e, st) {
      debugPrint(
        '[KhsDownloadNotification] open failed: $e\n$st path=$filePath',
      );
      _showFeedback(AppStrings.khsDownloadNoViewer);
    }
  }

  Future<void> _handleShare(String filePath) async {
    debugPrint('[KhsDownloadNotification] _handleShare called: $filePath');
    final file = File(filePath);
    final exists = file.existsSync();
    debugPrint(
      '[KhsDownloadNotification] _handleShare existsSync=$exists path=$filePath',
    );
    if (!exists) {
      debugPrint('[KhsDownloadNotification] share: file not found $filePath');
      _showFeedback(AppStrings.khsDownloadFileNotFound);
      return;
    }
    try {
      debugPrint(
        '[KhsDownloadNotification] _handleShare → calling shareFile: $filePath',
      );
      await _shareFile(filePath);
      debugPrint('[KhsDownloadNotification] share success: $filePath');
    } catch (e, st) {
      debugPrint(
        '[KhsDownloadNotification] share failed: $e\n$st path=$filePath',
      );
      _showFeedback(AppStrings.khsDownloadShareFailed);
    }
  }

  static Future<bool> _defaultOpenFile(String filePath) async {
    final result = await OpenFilex.open(filePath);
    return result.type == ResultType.done;
  }

  static Future<void> _defaultShareFile(String filePath) async {
    await SharePlus.instance.share(ShareParams(files: [XFile(filePath)]));
  }
}
