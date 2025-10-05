import 'dart:async';
import 'dart:convert';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../utils/notification_file_store.dart';

// ===================== TOP-LEVEL BACKGROUND HANDLER =====================
// Hàm này PHẢI là top-level và có @pragma để không bị tree-shaking
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔵 [BACKGROUND] ========== Message received ==========');
  print('🔵 [BACKGROUND] Message ID: ${message.messageId}');
  print('🔵 [BACKGROUND] Title: ${message.notification?.title}');
  print('🔵 [BACKGROUND] Body: ${message.notification?.body}');
  print('🔵 [BACKGROUND] Data: ${message.data}');
  try {
    final list = await NotificationFileStore.readAll();
    final id = message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();

    // Dedup
    list.removeWhere((m) => m['id'] == id);

    final item = {
      'id': id,
      'title': message.notification?.title ?? 'No title',
      'body': message.notification?.body ?? 'No body',
      'data': message.data,
      'timestamp': DateTime.now().toIso8601String(),
      'isRead': false,
    };
    list.insert(0, item);
    if (list.length > 100) list.removeRange(100, list.length);

    final ok = await NotificationFileStore.writeAll(list);
    print('✅ [BACKGROUND] file save=$ok total=${list.length}');
  } catch (e, st) {
    print('❌ [BACKGROUND] file save error: $e\n$st');
  }
}

// ============================ SERVICE CLASS =============================
@pragma('vm:entry-point')
class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  late final String _baseUrl;
  late final String _sessionToken;

  factory NotificationService() => instance;

  NotificationService._internal();



  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Stream để cập nhật badge realtime
  final StreamController<int> _notificationCountController = StreamController<int>.broadcast();
  Stream<int> get notificationCountStream => _notificationCountController.stream;

  // ---------------------------- Initialize -----------------------------
  Future<void> initialize() async {
    print('🔔 ========== Initializing NotificationService ==========');
    try {
      // 1) Permission
      print('🔔 Step 1: Requesting notification permission...');
      final settings = await _firebaseMessaging.requestPermission(alert: true, badge: true, sound: true);
      print('✅ Permission result: ${settings.authorizationStatus}');

      // 2) Local notifications
      print('🔔 Step 2: Setting up local notifications...');
      await _setupLocalNotifications();
      print('✅ Local notifications setup done.');

      // 3) Token
      print('🔔 Step 3: Getting FCM token...');
      try {
        final token = await _firebaseMessaging
            .getToken()
            .timeout(const Duration(seconds: 10), onTimeout: () => null);
        print('✅ Received FCM Token: $token');
        if (token != null) {
          print('getting FCM token: $token');
        }
      } catch (e, st) {
        print('❌ Error getting FCM token: $e');
      }

      // 4) Background handler
      print('🔔 Step 4: Setting up background message handler...');
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      print('✅ Background message handler set.');

      // 5) Foreground listener
      print('🔔 Step 5: Setting up foreground message listener...');
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        print('🟢 [FOREGROUND] ========== New Message Received ==========');
        print('🟢 [FOREGROUND] Message ID: ${message.messageId}');
        print('🟢 [FOREGROUND] Title: ${message.notification?.title}');
        print('🟢 [FOREGROUND] Body: ${message.notification?.body}');
        print('🟢 [FOREGROUND] Data: ${message.data}');

        await handleForegroundMessage(message);

        // Broadcast cập nhật badge
        print('🟢 [FOREGROUND] Getting unread count...');
        final count = await getUnreadCount();
        print('🟢 [FOREGROUND] Unread count: $count');
        print('🟢 [FOREGROUND] Broadcasting count to stream...');
        _notificationCountController.add(count);
        print('✅ [FOREGROUND] Message processing complete');
      });
      print('✅ Foreground message listener set.');

      // 6) Tap from background
      print('🔔 Step 6: Setting up notification tap handler (background)...');
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
        print('🟡 [TAP] Notification tapped (background): ${message.messageId}');
        print('🟡 [TAP] Title: ${message.notification?.title}');
        print('🟡 [TAP] Data: ${message.data}');
        await Future.delayed(const Duration(milliseconds: 400));
        await notifyBadgeUpdate();
        handleNotificationTap(message);
      });
      print('✅ Notification tap handler set.');

      // 7) Tap from terminated
      print('🔔 Step 7: Checking initial message...');
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        print('🟡 [INITIAL] App opened from terminated: ${initialMessage.messageId}');
        print('🟡 [INITIAL] Title: ${initialMessage.notification?.title}');
        await Future.delayed(const Duration(milliseconds: 350));
        await notifyBadgeUpdate();
        handleNotificationTap(initialMessage);
      } else {
        print('ℹ️ No initial message');
      }

      // 8) Initial badge
      await notifyBadgeUpdate();
      print('✅ ========== NotificationService Initialized Successfully ==========');
    } catch (e, st) {
      print('❌ ========== NotificationService init error ==========');
      print('❌ Error: $e');
      print('❌ Stack trace:\n$st');
    }
  }

  // --------------------- Local notifications setup ---------------------
  Future<void> _setupLocalNotifications() async {
    try {
      print('🔧 Initializing local notifications plugin...');
      const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
          print('🔔 [LOCAL TAP] Local notification tapped');
          print('🔔 [LOCAL TAP] Payload: ${response.payload}');
          if (response.payload != null) {
            try {
              final data = jsonDecode(response.payload!);
              print('🔔 [LOCAL TAP] Parsed data: $data');
              // TODO: điều hướng dựa theo data nếu cần
            } catch (e) {
              print('❌ [LOCAL TAP] Error parsing payload: $e');
            }
          }
        },
      );
      print('✅ Local notifications plugin initialized.');

      // Channel Android
      print('🔧 Creating Android notification channel...');
      const channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      final androidImpl = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl == null) {
        print('⚠️ AndroidFlutterLocalNotificationsPlugin not available.');
      } else {
        await androidImpl.createNotificationChannel(channel);
        print('✅ Notification channel created.');
      }
    } catch (e, st) {
      print('❌ _setupLocalNotifications error: $e');
      print('❌ Stack trace:\n$st');
    }
  }

  // ------------------------ Foreground handler -------------------------
  Future<void> handleForegroundMessage(RemoteMessage message) async {
    try {
      print('🔧 [FOREGROUND HANDLER] Processing message...');
      final notification = message.notification;

      if (notification != null) {
        print('🔧 [FOREGROUND HANDLER] Showing local notification...');
        await _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              channelDescription: 'This channel is used for important notifications.',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@drawable/ic_notification',
              styleInformation: BigTextStyleInformation(''),
            ),
          ),
          payload: jsonEncode(message.data),
        );
        print('✅ [FOREGROUND HANDLER] Local notification shown');

        print('🔧 [FOREGROUND HANDLER] Saving to file...');
        await saveNotificationToLocal(message);
        print('✅ [FOREGROUND HANDLER] Saved to file');
      } else {
        print('⚠️ [FOREGROUND HANDLER] Message has no notification section');
      }
    } catch (e, st) {
      print('❌ handleForegroundMessage error: $e');
      print('❌ Stack trace:\n$st');
    }
  }

  // --------------------------- Tap handler -----------------------------
  void handleNotificationTap(RemoteMessage message) {
    print('👆 [TAP HANDLER] User tapped notification');
    print('👆 [TAP HANDLER] Data: ${message.data}');
    // TODO: Điều hướng tới NotificationsPage hoặc chi tiết
  }

  // ----------------------- Storage read/write (FILE) -------------------
  static bool _saving = false;

  static Future<void> saveNotificationToLocal(RemoteMessage message) async {
    // Mutex tránh 2 ghi đồng thời
    while (_saving) {
      await Future.delayed(const Duration(milliseconds: 30));
    }
    _saving = true;
    try {
      print('💾 [SAVE-FILE] Start save for: ${message.messageId}');
      final list = await NotificationFileStore.readAll();
      print('💾 [SAVE-FILE] Current count(before): ${list.length}');

      final id = message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();

      // Dedup theo id
      list.removeWhere((m) => m['id'] == id);

      final item = {
        'id': id,
        'title': message.notification?.title ?? 'No title',
        'body': message.notification?.body ?? 'No body',
        'data': message.data,
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
      };

      list.insert(0, item);
      if (list.length > 100) list.removeRange(100, list.length);

      final ok = await NotificationFileStore.writeAll(list);
      print('✅ [SAVE-FILE] Done=$ok newCount=${list.length}');
    } catch (e, st) {
      print('❌ [SAVE-FILE] Error: $e\n$st');
    } finally {
      _saving = false;
    }
  }

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final list = await NotificationFileStore.readAll();
    print('📋 [GET-FILE] count=${list.length}');
    return list;
  }

  static Future<void> markAsRead(String notificationId) async {
    while (_saving) {
      await Future.delayed(const Duration(milliseconds: 30));
    }
    _saving = true;
    try {
      final list = await NotificationFileStore.readAll();
      print('✔️ [MARK-FILE] total(before)=${list.length}');
      for (final m in list) {
        if (m['id'] == notificationId) {
          m['isRead'] = true;
          break;
        }
      }
      final ok = await NotificationFileStore.writeAll(list);
      print('✅ [MARK-FILE] ok=$ok total(after)=${list.length}');
    } catch (e, st) {
      print('❌ [MARK-FILE] error: $e\n$st');
    } finally {
      _saving = false;
    }
  }

  static Future<void> clearAllNotifications() async {
    try {
      final ok = await NotificationFileStore.writeAll([]);
      print('✅ [CLEAR-FILE] ok=$ok');
    } catch (e, st) {
      print('❌ [CLEAR-FILE] error: $e\n$st');
    }
  }

  static Future<int> getUnreadCount() async {
    try {
      final items = await NotificationFileStore.readAll();
      final c = items.where((n) => n['isRead'] == false).length;
      print('🔢 [COUNT-FILE] unread=$c');
      return c;
    } catch (e, st) {
      print('❌ [COUNT-FILE] error: $e\n$st');
      return 0;
    }
  }

  static Future<void> deleteNotificationById(String notificationId) async {
    try {
      print('🗑️ [DELETE-FILE] id=$notificationId');
      final list = await NotificationFileStore.readAll();
      final before = list.length;
      list.removeWhere((m) => m['id'] == notificationId);
      final ok = await NotificationFileStore.writeAll(list);
      print('✅ [DELETE-FILE] ok=$ok removed=${before - list.length} left=${list.length}');
    } catch (e, st) {
      print('❌ [DELETE-FILE] error: $e\n$st');
    }
  }

  Future<void> sendTokenToServer({
    required String baseUrl,
    required int userId,
  }) async {
    final fcmToken = await _firebaseMessaging.getToken();
    if (fcmToken == null) return;

    final url = '$baseUrl/plugins/glpimobilenotification/ajax/update_token.php';
    final headers = {
      'Content-Type': 'application/json',
      // 'Session-Token': sessionToken, // có thể bỏ header này
    };
    final body = jsonEncode({
      'user_id': userId,
      'mobile_notification': 'FBT:$fcmToken',
    });

    try {
      final resp = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );
      print('sendTokenToServer status: ${resp.statusCode}');
      print('sendTokenToServer body: ${resp.body}');
    } catch (e) {
      print('sendTokenToServer error: $e');
    }
  }


  Future<void> notifyBadgeUpdate() async {
    print('🔄 [NOTIFY] Updating badge...');
    final c = await getUnreadCount();
    print('🔄 [NOTIFY] Broadcast: $c');
    _notificationCountController.add(c);
  }

  void dispose() {
    print('🛑 [DISPOSE] Closing stream');
    _notificationCountController.close();
  }
}
