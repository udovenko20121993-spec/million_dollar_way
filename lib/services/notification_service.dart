import 'dart:ui' show Color;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Канали для різних типів сповіщень
  static const String _syncChannelId = 'sync_channel';
  static const String _dividendsChannelId = 'dividends_channel';
  static const String _alertsChannelId = 'alerts_channel';

  Future<void> init(String userId) async {
    // Запит дозволу у користувача
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: true,
      criticalAlert: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // Отримуємо токен пристрою для Firebase
      String? token = await _fcm.getToken();

      if (token != null) {
        // Зберігаємо токен у базу, щоб сервер міг надіслати пуш
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'fcmToken': token,
          'notificationsEnabled': true,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // Налаштування каналів для Android
      await _setupAndroidChannels();

      // Ініціалізація локальних сповіщень
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      await _localNotifications.initialize(
        const InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      // Слухаємо повідомлення, коли додаток відкритий (foreground)
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Слухаємо натискання на повідомлення (background/terminated)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Оновлюємо токен при зміні
      _fcm.onTokenRefresh.listen((newToken) {
        FirebaseFirestore.instance.collection('users').doc(userId).update({
          'fcmToken': newToken,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
      });
    }
  }

  Future<void> _setupAndroidChannels() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin == null) return;

    // Канал для дивідендів (найвищий пріоритет)
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _dividendsChannelId,
        'Дивіденди',
        description: 'Сповіщення про отримані дивіденди',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
        ledColor: Color.fromARGB(255, 0, 200, 83),
        showBadge: true,
      ),
    );

    // Канал для синхронізації
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _syncChannelId,
        'Синхронізація',
        description: 'Сповіщення про оновлення звітів',
        importance: Importance.defaultImportance,
        enableVibration: false,
      ),
    );

    // Канал для важливих сповіщень
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _alertsChannelId,
        'Важливі сповіщення',
        description: 'Помилки та критичні події',
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
      ),
    );
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('📱 Foreground message: ${message.notification?.title}');
    
    if (message.notification != null) {
      final type = message.data['type'] ?? 'sync';
      _showLocalNotification(message.notification!, type);
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    print('📱 Message opened app: ${message.data}');
    // Тут можна додати навігацію до потрібного екрану
    final type = message.data['type'];
    
    if (type == 'dividend') {
      // TODO: Навігація до екрану дивідендів
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    print('📱 Notification tapped: ${response.payload}');
    // Обробка натискання на локальне сповіщення
  }

  void _showLocalNotification(RemoteNotification notification, String type) {
    String channelId;
    AndroidNotificationDetails androidDetails;

    switch (type) {
      case 'dividend':
        channelId = _dividendsChannelId;
        androidDetails = const AndroidNotificationDetails(
          _dividendsChannelId,
          'Дивіденди',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color.fromARGB(255, 212, 175, 55), // Золотий
          enableVibration: true,
          playSound: true,
          styleInformation: BigTextStyleInformation(''),
        );
        break;
      
      case 'alert':
        channelId = _alertsChannelId;
        androidDetails = const AndroidNotificationDetails(
          _alertsChannelId,
          'Важливі сповіщення',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          color: Color.fromARGB(255, 255, 87, 34), // Червоний
          enableVibration: true,
          playSound: true,
        );
        break;
      
      default:
        channelId = _syncChannelId;
        androidDetails = const AndroidNotificationDetails(
          _syncChannelId,
          'Синхронізація',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
          color: Color.fromARGB(255, 0, 200, 83), // Зелений
        );
    }

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(android: androidDetails),
      payload: type,
    );
  }

  // ============== ПУБЛІЧНІ МЕТОДИ ==============

  /// Показати локальне сповіщення про дивіденди
  Future<void> showDividendNotification({
    required String symbol,
    required double amount,
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '💰 Дивіденд від $symbol!',
      'Ви отримали \$${amount.toStringAsFixed(2)}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _dividendsChannelId,
          'Дивіденди',
          importance: Importance.high,
          priority: Priority.high,
          color: Color.fromARGB(255, 212, 175, 55),
        ),
      ),
      payload: 'dividend:$symbol:$amount',
    );
  }

  /// Показати локальне сповіщення про синхронізацію
  Future<void> showSyncNotification({
    required String reportName,
    required double balance,
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '📊 Звіт оновлено',
      '$reportName: \$${balance.toStringAsFixed(2)}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _syncChannelId,
          'Синхронізація',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          color: Color.fromARGB(255, 0, 200, 83),
        ),
      ),
      payload: 'sync:$reportName',
    );
  }

  /// Показати сповіщення про помилку
  Future<void> showErrorNotification({
    required String title,
    required String message,
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '⚠️ $title',
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _alertsChannelId,
          'Важливі сповіщення',
          importance: Importance.max,
          priority: Priority.max,
          color: Color.fromARGB(255, 255, 87, 34),
        ),
      ),
      payload: 'error',
    );
  }

  /// Отримати історію сповіщень
  Stream<List<Map<String, dynamic>>> getNotificationsStream(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  /// Позначити сповіщення як прочитане
  Future<void> markAsRead(String userId, String notificationId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }

  /// Отримати кількість непрочитаних сповіщень
  Stream<int> getUnreadCountStream(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Вимкнути сповіщення
  Future<void> disableNotifications(String userId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'notificationsEnabled': false,
    });
    await _fcm.deleteToken();
  }

  /// Увімкнути сповіщення
  Future<void> enableNotifications(String userId) async {
    final token = await _fcm.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': token,
        'notificationsEnabled': true,
      });
    }
  }
}
