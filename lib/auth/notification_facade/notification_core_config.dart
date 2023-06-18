import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


class LocalNotificationCore {

  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'high_importance_notification',
      importance: Importance.high,
      enableVibration: true
  );

  @pragma('vm:entry-point')
  static void notificationTapBackground(NotificationResponse notificationResponse) {
    // ignore: avoid_print
    print('notification(${notificationResponse.id}) action tapped: '
        '${notificationResponse.actionId} with'
        ' payload: ${notificationResponse.payload}');
    if (notificationResponse.input?.isNotEmpty ?? false) {
      // ignore: avoid_print
      print('notification action tapped with input: ${notificationResponse.input}');
    }
  }

  static void initialize(BuildContext context) {

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings(
        "@mipmap/ic_launcher");
    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestCriticalPermission: true
    );
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    _notificationsPlugin.initialize(initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) {
        // switch (notificationResponse.notificationResponseType) {
        //   case NotificationResponseType.selectedNotification:
        //     // TODO: Handle this case.
        //     break;
        //   case NotificationResponseType.selectedNotificationAction:
        //     // TODO: Handle this case.
        //     break;
        // },
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  static void setupChannel() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(
        channel);
  }

  static void showFlutterNotification(RemoteMessage message) {

    RemoteNotification? notification = message.notification;
    if (notification != null) {
      _notificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: (notification.android != null) ? AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '',
              importance: Importance.high,
              priority: Priority.high
          ) : null,
        ),
        payload: message.data[''],
      );
    }
  }

  /// Initialize the [FlutterLocalNotificationsPlugin] package.
  static Future<void> setupFlutterNotifications(bool isFlutterLocalNotificationsInitialized) async {
    if (isFlutterLocalNotificationsInitialized) {
      return;
    }

    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        provisional: false,
        sound: true
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      var _token = await FirebaseMessaging.instance.getToken();
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (FirebaseAuth.instance.currentUser != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({'token': _token});
      }

      /// create Android Notification Channel.
      LocalNotificationCore.setupChannel();

      /// update the iOS foreground notification presentation options to allow headsup notificaiton.
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      isFlutterLocalNotificationsInitialized = true;
    }
  }


}