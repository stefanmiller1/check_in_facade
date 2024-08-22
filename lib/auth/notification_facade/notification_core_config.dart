// import 'package:check_in_credentials/check_in_credentials.dart';
// import 'package:check_in_domain/check_in_domain.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
part of check_in_facade;


class LocalNotificationCore {

  static String? lastMessageId = '';
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
    await _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(
        channel);
  }

  static void showFlutterNotificationMobile(RemoteMessage message) {
    print('message got');
    print(message.messageId);
    RemoteNotification? notification = message.notification;
    if (!(kIsWeb)) {
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
          payload: message.data['data'],
        );
      }
    }
  }

  static void showFlutterNotificationWeb(BuildContext context, Color backgroundColor, Color textColor, RemoteMessage message, {required Function(String?) didSelectNotification}) {

    if (message.notification == null) return;
    if (lastMessageId == message.messageId) return;

        lastMessageId = message.messageId;
        final snackBar = SnackBar(
            elevation: 8,
            backgroundColor: backgroundColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)
            ),
            action: SnackBarAction(
                label: 'open',
                onPressed: () {
                  didSelectNotification(message.data['link']);
              }
            ),
            width: 500,
            content: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message.notification?.title ?? 'New Message', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                if (message.notification?.body != null) Text(message.notification!.body!, style: TextStyle(color: textColor.withOpacity(0.7))),
              ],
            )
          );
       ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Initialize the [FlutterLocalNotificationsPlugin] package.
  static Future<void> setupFlutterNotifications(bool isFlutterLocalNotificationsInitialized) async {
    if (isFlutterLocalNotificationsInitialized) {
      return;
    }

    try {
      NotificationSettings settings = await FirebaseMessaging.instance
          .requestPermission(
          alert: true,
          badge: true,
          provisional: false,
          sound: true
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? token;
        final userId = FirebaseAuth.instance.currentUser?.uid;

        if (FirebaseAuth.instance.currentUser != null) {
          if (kIsWeb) {
            token = await FirebaseMessaging.instance.getToken(vapidKey: WEB_PUSH_CERTIFICATE);
            await FirebaseFirestore.instance.collection('users')
                .doc(userId)
                .update({'webToken': token});
          } else {
            token = await FirebaseMessaging.instance.getToken();
            print(token);
            await FirebaseFirestore.instance.collection('users')
                .doc(userId)
                .update({'token': token});
          }
        }

        // print(token);

        if (!(kIsWeb) && userId != null) {
          // create Android Notification Channel.
          LocalNotificationCore.setupChannel();

          // update the iOS foreground notification presentation options to allow headsup notificaiton.
          await FirebaseMessaging.instance
              .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
        }

        isFlutterLocalNotificationsInitialized = true;
      }
    } catch (e) {
      return;
    }
  }

  /// update notification object to read
  static Future<void> updateNotificationToRead(BuildContext context, List<UniqueId> notifications, Color backgroundColor, Color textColor) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      try {
        for (UniqueId notificationId in notifications) {
          await FirebaseFirestore.instance.collection('users').doc(userId)
              .collection('notifications').doc(notificationId.getOrCrash())
              .update({'isRead': true});
        }
      } catch (e) {
        final snackBar = SnackBar(
            backgroundColor: backgroundColor,
            width: 500,
            content: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Something went wrong', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              ],
            )
          );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

}