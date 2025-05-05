part of check_in_facade;

@LazySingleton(as: NAuthFacade)
class NotificationUpdaterFacade implements NAuthFacade {

  final FirebaseAuth _firebaseAuth;
  final FirebaseFunctions _firebaseFunctions;
  final FirebaseMessaging _firebaseMessaging;
  final FirebaseFirestore _fireStore;

  NotificationUpdaterFacade(
      this._fireStore,
      this._firebaseMessaging,
      this._firebaseFunctions,
      this._firebaseAuth
    );

  @override
  Future<void> createNotification({
    required AccountNotificationItem notificationItem,
  }) async {

      if (notificationItem.reservationId == null || notificationItem.recipientId == null){
        return;
      }

      await storeNotification(
        recipientId: notificationItem.recipientId!,
        notificationType: notificationItem.notificationType,
        reservationId: notificationItem.reservationId!,
        title: notificationItem.title,
        body: notificationItem.body,
      );

      await sendPushNotification(
        _fireStore,
        _firebaseFunctions,
        notificationItem.recipientId!,
        <String, dynamic>{
            'reservationId': notificationItem.reservationId,
            'status': 'done',
            'link': '/${DashboardMarker.reservations.name.toString()}/reservation/${notificationItem.reservationId}'
      },
      '/${DashboardMarker.reservations.name.toString()}/reservation/${notificationItem.reservationId}',
      notificationItem.title ?? 'New Notification',
      notificationItem.body ?? 'Check your reservation updates.',
      notificationItem.imageUrl
      );

      /// Only create a topic when the reservation is first created
      if (notificationItem.notificationType == AccountNotificationType.reservation || notificationItem.notificationType == AccountNotificationType.joined) {
          await subscribeUserToTopic(
            _fireStore,
            _firebaseFunctions,
            notificationItem.reservationId!, 
            notificationItem.recipientId!,
            kIsWeb
          );
      }

      if (notificationItem.notificationType == AccountNotificationType.deletedAttendee) {
          await unsubscribeUserFromTopic(
            _fireStore,
            _firebaseFunctions,
            notificationItem.reservationId!, 
            notificationItem.recipientId!,
            kIsWeb
          );
          await FirebaseChatCore.instance.removeUserFromGroupRoom(
            roomId: notificationItem.reservationId!, 
            userId: notificationItem.recipientId!
          );
      }
  }

     @override
  Future<Either<AttendeeFormFailure, Unit>> sendAttendeeNotification({
    required String reservationId, 
    required AttendeeItem attendee, 
    required AccountNotificationType type, 
    String? message, 
    String? title}) async {
    if (_firebaseAuth.currentUser == null) {
    return right(unit);
  }

  try {
    // await storeNotification(
    //   recipientId: attendee.attendeeOwnerId.getOrCrash(),
    //   notificationType: type,
    //   reservationId: reservationId,
    //   title: title,
    //   body: message ?? '',
    // );

    // await sendPushNotification(
    //   _fireStore,
    //   _firebaseFunctions,
    //   attendee.attendeeOwnerId.getOrCrash(),
    //   <String, dynamic>{
    //       'reservationId': reservationId,
    //         'status': 'done',
    //         'link': '/${DashboardMarker.reservations.name.toString()}/reservation/$reservationId'
    //   },
    //   '/${DashboardMarker.reservations.name.toString()}/reservation/$reservationId',
    //   title ?? 'New Notification',
    //   message ?? 'Check your reservation updates.',
    // );


    /// Subscribe attendee only if they are **joining** the reservation
    if (type == AccountNotificationType.joined) {
      await _firebaseMessaging.subscribeToTopic(reservationId);
    }

      return right(unit);
    } catch (e) {
      return left(AttendeeFormFailure.attendeeServerError(failed: e.toString()));
    }
  }
  


  @override
  Future<Either<ListingFormFailure, Unit>> sendFacilityOwnerNotification({required String facilityOwnerId, required String reservationId, required AccountNotificationType type, String? message, String? title}) async {
   if (_firebaseAuth.currentUser == null) {
      return right(unit);
    }

    try {
      // await storeNotification(
      //   recipientId: facilityOwnerId,
      //   notificationType: type,
      //   reservationId: reservationId,
      //   title: title,
      //   body: message,
      // );

      // await sendPushNotification(
      //   _fireStore,
      //   _firebaseFunctions,
      //   facilityOwnerId,
      //   <String, dynamic>{
      //       'reservationId': reservationId,
      //       'status': 'done',
      //       'link': '/${DashboardMarker.reservations.name.toString()}/reservation/$reservationId'
      // },
      // '/${DashboardMarker.reservations.name.toString()}/reservation/$reservationId',
      // title ?? 'New Notification',
      // message ?? 'Check your reservation updates.',
      // );

      // /// Only create a topic when the reservation is first created
      // if (type == AccountNotificationType.reservation) {
      //   await _firebaseMessaging.subscribeToTopic(reservationId);
      // }

      return right(unit);
    } catch (e) {
      return left(ListingFormFailure.listingServerError(failed: e.toString()));
    }
  }
  


  @override
  Future<Either<ReservationFormFailure, Unit>> sendReservationOwnerNotification({
    required String reservationId, 
    required String ownerId, 
    required AccountNotificationType type, 
    String? message, 
    String? title}) async {
    if (_firebaseAuth.currentUser == null) {
      return right(unit);
    }

    try {
      // await storeNotification(
      //   recipientId: ownerId,
      //   notificationType: type,
      //   reservationId: reservationId,
      //   title: title,
      //   body: message,
      // );

      // await sendPushNotification(
      //   _fireStore,
      //   _firebaseFunctions,
      //   ownerId,
      //   <String, dynamic>{
      //     'reservationId': reservationId,
      //       'status': 'done',
      //       'link': '/${DashboardMarker.reservations.name.toString()}/reservation/$reservationId'
      // },
      // '/${DashboardMarker.reservations.name.toString()}/reservation/$reservationId',
      // title ?? 'New Notification',
      // message ?? 'Check your reservation updates.',
      // );

      // /// Only create a topic when the reservation is first created
      // if (type == AccountNotificationType.reservation) {
      //   await _firebaseMessaging.subscribeToTopic(reservationId);
      // }

      return right(unit);
    } catch (e) {
      return left(ReservationFormFailure.reservationServerError(failed: e.toString()));
    }
  }






  @override
  Future<Either<AttendeeFormFailure, Unit>> createReservationInvitationNotification({required String reservationId, required AttendeeItem attendee}) async {

    try {
      if (_firebaseAuth.currentUser == null) {
        return left(const AttendeeFormFailure.attendeeServerError(failed: 'not signed in'));
      }

      final UniqueId notificationId = UniqueId();
      final notificationDto = AccountNotificationItemDto(notificationId: notificationId.getOrCrash(), isRead: false, receivedAtTimeStamp: DateTime.now().millisecondsSinceEpoch, sentFromId: _firebaseAuth.currentUser!.uid, notificationType: AccountNotificationType.invite.toString(), reservationId: reservationId).toJson();
      final userInfo = await _fireStore.collection('users').doc(attendee.attendeeOwnerId.getOrCrash()).get();
      final attendeeProfileDoc = _fireStore.collection('users').doc(attendee.attendeeOwnerId.getOrCrash());

      // /// create new notification in users notifications collection
      // attendeeProfileDoc.collection('notifications').doc(notificationId.getOrCrash()).set(notificationDto);
      //
      // /// send notification to attendee if mobile token exists
      // sendPushNotification(
      //     userInfo.data().toString().contains('token') ? userInfo['token'] : null,
      //     userInfo.data().toString().contains('webToken') ? userInfo['webToken'] : null,
      //     <String, dynamic>{
      //       'reservationId': reservationId,
      //       'status': 'done',
      //       'link': '/${DashboardMarker.reservations.name.toString()}/reservation/$reservationId'
      //     },
      //   '/${DashboardMarker.reservations.name.toString()}/reservation/$reservationId',
      //   'New Invitation!',
      //   'You\'ve been invited to Join a new Reservation!'
      // );

      return right(unit);
    } catch (e) {
      return left(AttendeeFormFailure.attendeeServerError(failed: e.toString()));
    }
  }

  @override
  Future<Either<AttendeeFormFailure, Unit>> deleteReservationInvitationNotification({required String reservationId, required String attendeeUserId}) async {
    try {

      /// get notification sent from you for specific reservation
      if (_firebaseAuth.currentUser == null) {
        return right(unit);
      }

      final attendeeProfileDoc = _fireStore.collection('users').doc(attendeeUserId);
      var resInviteNotification = _fireStore.collection('users').doc(attendeeUserId).collection('notifications')
          .where('reservationId', isEqualTo: reservationId)
          .where('notificationType', isEqualTo: AccountNotificationType.invite.toString());


      /// get first notification if exists
      final notification = await resInviteNotification.get();


      if (notification.docs.isNotEmpty) {
       final accountNotifications = notification.docs.map((e) => AccountNotificationItemDto.fromJson(e.data()).toDomain()).toList();
       if (accountNotifications.isNotEmpty) {
         attendeeProfileDoc.collection('notifications').doc(accountNotifications[0].notificationId.getOrCrash()).delete();
       }
      }

      return right(unit);
    } catch (e) {
      return left(AttendeeFormFailure.attendeeServerError(failed: e.toString()));
    }
  }


  @override
  Future<Either<AttendeeFormFailure, Unit>> createJoinedReservationNotification({required String reservationId, required AttendeeItem attendee}) async {
     try {

       if (_firebaseAuth.currentUser == null) {
         return left(const AttendeeFormFailure.attendeeServerError(failed: 'not signed in'));
       }

      //  final UniqueId notificationId = UniqueId();
      //  final notificationDto = AccountNotificationItemDto(notificationId: notificationId.getOrCrash(), isRead: false, receivedAtTimeStamp: DateTime.now().millisecondsSinceEpoch, sentFromId: _firebaseAuth.currentUser!.uid, notificationType: AccountNotificationType.joined.toString(), reservationId: reservationId).toJson();

      //  /// send update to reservation owner
      //  final reservation = await _fireStore.collection('reservation_directory').doc(reservationId).get();
      //  final resOwnerId = reservation['reservationOwnerId'];

      //  /// save notification in users profile
      //  final resOwnerDoc = _fireStore.collection('users').doc(resOwnerId);
      //  resOwnerDoc.collection('notifications').doc(notificationId.getOrCrash()).set(notificationDto);


      //  /// get res owner token for sending notification
      //  final userInfo = await _fireStore.collection('users').doc(resOwnerId).get();
      //  /// send notification to attendee if mobile or web token exists
      //  sendPushNotification(
      //      userInfo.data().toString().contains('token') ? userInfo['token'] : null,
      //      userInfo.data().toString().contains('webToken') ? userInfo['webToken'] : null,
      //      <String, dynamic>{
      //        'reservationId': reservationId,
      //        'status': 'done',
      //        'link': '/${DashboardMarker.reservations.name.toString()}/reservation/$reservationId'
      //      },
      //    '/${DashboardMarker.reservations.name.toString()}/reservation/$reservationId',
      //    'New ${attendee.attendeeType.name} Attendee Joined',
      //    'Someone new joined your Activity'
      //  );

      //  /// subscribe to activity topic
      //  await _firebaseMessaging.subscribeToTopic(reservationId);


       return right(unit);
     } catch (e) {
       return left(AttendeeFormFailure.attendeeServerError(failed: e.toString()));
     }
  }


  @override
  Future<Either<AttendeeFormFailure, Unit>> createNewReservationPostNotification({required List<AttendeeItem> attendees, required Post post}) async {

    try {

        if (_firebaseAuth.currentUser == null) {
          return right(unit);
        }

      //  final UniqueId notificationId = UniqueId();
      //  final notificationDto = AccountNotificationItemDto(notificationId: notificationId.getOrCrash(), isRead: false, receivedAtTimeStamp: DateTime.now().millisecondsSinceEpoch, sentFromId: _firebaseAuth.currentUser!.uid, notificationType: AccountNotificationType.activityPost.toString(), reservationId: post.reservationId).toJson();

      //  for (AttendeeItem attendee in attendees) {

      //    /// get all attendees except yourself
      //    if (attendee.attendeeOwnerId.getOrCrash() != _firebaseAuth.currentUser!.uid) {
      //      /// save notification in users profile
      //      final resOwnerDoc = _fireStore.collection('users').doc(attendee.attendeeOwnerId.getOrCrash());
      //      resOwnerDoc.collection('notifications').doc(notificationId.getOrCrash()).set(notificationDto);

      //      // /// get res owner token for sending notification
      //      final userInfo = await _fireStore.collection('users').doc(attendee.attendeeOwnerId.getOrCrash()).get();

      //      /// send notification to attendee if mobile token exists
      //      sendPushNotification(
      //          userInfo.data().toString().contains('token') ? userInfo['token'] : null,
      //          userInfo.data().toString().contains('webToken') ? userInfo['webToken'] : null,
      //          <String, dynamic>{
      //            'reservationId': post.reservationId,
      //            'status': 'done',
      //            'link': '/${DashboardMarker.reservations.name.toString()}/reservation/${post.reservationId}'
      //           },
      //          '/${DashboardMarker.reservations.name.toString()}/reservation/${post.reservationId}',
      //          _firebaseAuth.currentUser?.displayName != null ? '${_firebaseAuth.currentUser?.displayName} Sent a New Post!' : 'New Post!',
      //          post.textPost != null ? '${post.textPost?.text}' : 'see what someone said in an activity you\'re in'
      //      );
      //    }
      //  }


      //   /// send update to reservation owner...res owners cannot be attendees
      //   final reservation = await _fireStore.collection('reservation_directory').doc(post.reservationId).get();
      //   final resOwnerId = reservation['reservationOwnerId'];

      //   if (_firebaseAuth.currentUser?.uid != resOwnerId) {
      //     /// save notification is users profile
      //     final resOwnerDoc = _fireStore.collection('users').doc(resOwnerId);
      //     resOwnerDoc.collection('notifications').doc(notificationId.getOrCrash()).set(notificationDto);

      //     final userInfo = await _fireStore.collection('users').doc(resOwnerId).get();

      //     sendPushNotification(
      //         userInfo.data().toString().contains('token') ? userInfo['token'] : null,
      //         userInfo.data().toString().contains('webToken') ? userInfo['webToken'] : null,
      //         <String, dynamic>{
      //           'reservationId': post.reservationId,
      //           'status': 'done',
      //           'link': '/${DashboardMarker.reservations.name.toString()}/reservation/${post.reservationId}'
      //         },
      //         '/${DashboardMarker.reservations.name.toString()}/reservation/${post.reservationId}',
      //         _firebaseAuth.currentUser?.displayName != null ? '${_firebaseAuth.currentUser?.displayName} Sent a New Post!' : 'New Post!',
      //         post.textPost != null ? '${post.textPost?.text}' : 'see what someone said in an activity you\'re in'
      //     );

      //   }

       return right(unit);
     } catch (e) {
       return left(AttendeeFormFailure.attendeeServerError(failed: e.toString()));
     }
  }

  @override
  Future<Either<AttendeeFormFailure, Unit>> createUpdatedReservationActivityNotification({required String reservationId}) async {
     try {

       if (_firebaseAuth.currentUser == null) {
         return right(unit);
       }

      //  /// send notification to reservation topic
      //  await http.post(
      //      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      //      headers: <String, String>{
      //        'Content-Type': 'application/json',
      //        'Authorization': 'key=$CMF_SERVER_KEY',
      //      },
      //      body: jsonEncode(
      //          <String, dynamic>{
      //            'priority': 'high',

      //            'data': {
      //              'reservationId': reservationId,
      //              'status': 'done',
      //              'link': '/${DashboardMarker.reservations.name.toString()}/reservation/$reservationId'
      //            },
      //            'notification': {
      //              'title': 'Activity Updated!',
      //              'body': 'Changes were made to the activity you\'re in.',
      //            },
      //            'topic': reservationId,
      //          }
      //      )
      //  );

       return right(unit);
     } catch (e) {
       return left(AttendeeFormFailure.attendeeServerError(failed: e.toString()));
     }
  }

  @override
  Future<Either<AttendeeFormFailure, Unit>> createRequestToJoinReservationNotification({required String reservationId, required AttendeeItem attendee}) async {
     try {

       if (_firebaseAuth.currentUser == null) {
         return right(unit);
       }

      //  final UniqueId notificationId = UniqueId();
      //  final notificationDto = AccountNotificationItemDto(notificationId: notificationId.getOrCrash(), isRead: false, receivedAtTimeStamp: DateTime.now().millisecondsSinceEpoch, sentFromId: _firebaseAuth.currentUser!.uid, notificationType: AccountNotificationType.request.toString(), reservationId: reservationId).toJson();

      //  /// get reservation owners id
      //  final reservation = await _fireStore.collection('reservation_directory').doc(attendee.reservationId.getOrCrash()).get();
      //  final resOwnerId = reservation['reservationOwnerId'];

      //  /// save notification is users profile
      //  final resOwnerDoc = _fireStore.collection('users').doc(resOwnerId);
      //  resOwnerDoc.collection('notifications').doc(notificationId.getOrCrash()).set(notificationDto);


      //  /// get res owner token for sending notification
      //  final userInfo = await _fireStore.collection('users').doc(resOwnerId).get();

      //  /// send notification to attendee if mobile token exists
      //  sendPushNotification(
      //      userInfo.data().toString().contains('token') ? userInfo['token'] : null,
      //      userInfo.data().toString().contains('webToken') ? userInfo['webToken'] : null,
      //      <String, dynamic>{
      //        'reservationId': reservationId,
      //        'status': 'done',
      //        'link': '/${DashboardMarker.reservations.name.toString()}/reservation/$reservationId'
      //      },
      //      '/${DashboardMarker.reservations.name.toString()}/reservation/$reservationId',
      //      'New Request',
      //      'Someone has sent you a request for your Reservation'
      //  );

       return right(unit);
     } catch (e) {
       return left(AttendeeFormFailure.attendeeServerError(failed: e.toString()));
     }
  }

  @override
  Future<Either<ReservationFormFailure, Unit>> createDidLikePostNotification({required Post likedPost}) async {
     try {

       if (_firebaseAuth.currentUser == null || _firebaseAuth.currentUser?.uid == likedPost.authorId.getOrCrash()) {
         return right(unit);
       }

      //  final UniqueId notificationId = UniqueId();
      //  final notificationDto = AccountNotificationItemDto(notificationId: notificationId.getOrCrash(), isRead: false, receivedAtTimeStamp: DateTime.now().millisecondsSinceEpoch, sentFromId: _firebaseAuth.currentUser!.uid, notificationType: AccountNotificationType.activityPost.toString(), reservationId: likedPost.reservationId).toJson();

      //  /// save notification is users profile
      //  final resOwnerDoc = _fireStore.collection('users').doc(likedPost.authorId.getOrCrash());
      //  resOwnerDoc.collection('notifications').doc(notificationId.getOrCrash()).set(notificationDto);

      //  /// get res owner token for sending notification
      //  final userInfo = await _fireStore.collection('users').doc(likedPost.authorId.getOrCrash()).get();

      //  /// send notification to attendee if mobile token exists
      //  sendPushNotification(
      //      userInfo.data().toString().contains('token') ? userInfo['token'] : null,
      //      userInfo.data().toString().contains('webToken') ? userInfo['webToken'] : null,
      //      <String, dynamic>{
      //        'reservationId': likedPost.reservationId,
      //        'status': 'done',
      //        'link': '/${DashboardMarker.reservations.name.toString()}/reservation/${likedPost.reservationId}'
      //      },
      //      '/${DashboardMarker.reservations.name.toString()}/reservation/${likedPost.reservationId}',
      //      'New Like!',
      //      'Someone Liked your post!'
      //  );

       return right(unit);
     } catch (e) {
       return left (const ReservationFormFailure.reservationServerError());
     }
  }

  @override
  Future<Either<ReservationFormFailure, Unit>> createReservationCreatedNotification({required String facilityOwner}) {
    // TODO: implement createReservationCreatedNotification
    throw UnimplementedError();
  }

  @override
  Future<Either<ReservationFormFailure, Unit>> createReservationRequestNotification({required String facilityOwner}) {
    // TODO: implement createReservationRequestNotification
    throw UnimplementedError();
  }

  @override
  Future<Either<AttendeeFormFailure, Unit>> createNewReviewNotification({required String reservationId}) {
    // TODO: implement createNewReviewNotification
    throw UnimplementedError();
  }

  //// - FACILITY BASED NOTIFICATIONS - ////
  @override
  Future<Either<AttendeeFormFailure, Unit>> createMessageToReservationOwnerNotification({required String facilityOwnerId, required ReservationItem reservation}) {
    // TODO: implement createMessageToReservationOwnerNotification
    throw UnimplementedError();
  }


  @override
  Future<Either<AttendeeFormFailure, Unit>> attendeeVendorUpdateNotification({required String reservationId, required String? activityTitle, required AttendeeItem attendee}) async {
    if (_firebaseAuth.currentUser == null) {
      return right(unit);
    }

    try {

      // final UniqueId notificationId = UniqueId();
      // final notificationDto = AccountNotificationItemDto(
      //   notificationId: notificationId.getOrCrash(), 
      //   isRead: false, 
      //   receivedAtTimeStamp: DateTime.now().millisecondsSinceEpoch, 
      //   sentFromId: _firebaseAuth.currentUser!.uid, 
      //   notificationType: AccountNotificationType.activityAttendee.toString(),
      //   reservationId: reservationId).toJson();


      // /// save notification in users profile
      // final resOwnerDoc = _fireStore.collection('users').doc(attendee.attendeeOwnerId.getOrCrash());
      // resOwnerDoc.collection('notifications').doc(notificationId.getOrCrash()).set(notificationDto);


      // /// get res owner token for sending notification
      // final userInfo = await _fireStore.collection('users').doc(attendee.attendeeOwnerId.getOrCrash()).get();
      // /// send notification to attendee if mobile or web token exists
      // sendPushNotification(
      //     userInfo.data().toString().contains('token') ? userInfo['token'] : null,
      //     userInfo.data().toString().contains('webToken') ? userInfo['webToken'] : null,
      //     <String, dynamic>{
      //       'reservationId': reservationId,
      //       'status': 'done',
      //       'link': '/${DashboardMarker.reservations.name.toString()}/reservation/$reservationId'
      //     },
      //     '/${DashboardMarker.reservations.name.toString()}/reservation/$reservationId',
      //     '${activityTitle} Updated Your Application!',
      //     'Click here to take a look.'
      // );


      return right(unit);
    } catch (e) {
      return left(AttendeeFormFailure.attendeeServerError(failed: e.toString()));
    }
  }

  Future<void> storeNotification({
    required String recipientId,
    required AccountNotificationType notificationType,
    required String reservationId,
    String? title,
    String? body,
      }) async {
      final notificationId = UniqueId();
        final notificationDto = AccountNotificationItemDto(
          notificationId: notificationId.getOrCrash(),
          isRead: false,
          receivedAtTimeStamp: DateTime.now().millisecondsSinceEpoch,
          sentFromId: _firebaseAuth.currentUser!.uid,
          notificationType: notificationType.toString(),
          reservationId: reservationId,
          body: body,
          title: title,
        ).toJson();

      final userDoc = _fireStore.collection('users').doc(recipientId);
      await userDoc.collection('notifications').doc(notificationId.getOrCrash()).set(notificationDto);
    }
    

    @override
    Future<void> deleteNotificationsAndUnsubscribe({required String reservationId, required String recipientId, required AccountNotificationType type, bool shouldUnsubscribe = false}) async {
        final userDoc = _fireStore.collection('users').doc(recipientId);

        /// Get notifications related to this reservation
        final notificationsQuery = userDoc
            .collection('notifications')
            .where('reservationId', isEqualTo: reservationId)
            .where('notificationType', isEqualTo: type.toString());

        final notifications = await notificationsQuery.get();

        if (notifications.docs.isNotEmpty) {
          for (final doc in notifications.docs) {
            await userDoc.collection('notifications').doc(doc.id).delete();
          }
        }

        /// Unsubscribe if necessary
        if (shouldUnsubscribe) {
          await _firebaseMessaging.unsubscribeFromTopic(reservationId);
        }
    }
    
    @override
    Future<void> updateNotification({
      required String recipientId,
      required String notificationId,
      bool? isRead,
      int? openedAtTimeStamp}) async {
      final notificationRef = _fireStore
      .collection('users')
      .doc(recipientId)
      .collection('notifications')
      .doc(notificationId);

    final updates = <String, dynamic>{};

    if (isRead != null) updates['isRead'] = isRead;
    if (openedAtTimeStamp != null) updates['openedAtTimeStamp'] = openedAtTimeStamp;

    await notificationRef.update(updates);
  }
}


Future<void> sendPushNotification(
  FirebaseFirestore fireStore,
  FirebaseFunctions firebaseFunctions,
  String recipientId, 
  Object data, 
  String clickRoute, 
  String title, 
  String body,
  String? imageUrl) async {

    final recipientDoc = await fireStore.collection('users').doc(recipientId).get();
    if (!recipientDoc.exists) {
      print("Recipient user does not exist.");
      return;
    }

    final Map<String, dynamic>? userData = recipientDoc.data();
    final String? mobileToken = userData?['token']; // iOS/Android FCM Token
    final String? webToken = userData?['webToken']; // Web FCM Token

    print(webToken);
    print(mobileToken);

    // Ensure at least one token is available
    if (mobileToken == null && webToken == null) {
      print("No FCM token found for recipient.");
      return;
    }

    // FCM v1 API requires the project ID
    const String projectId = "cico-8298b"; // Replace with your Firebase project ID

    // FCM v1 API endpoint
    final Uri fcmEndpoint = Uri.parse("https://fcm.googleapis.com/v1/projects/$projectId/messages:send");
    final auth.ServiceAccountCredentials serviceAccountCredentials =
        auth.ServiceAccountCredentials.fromJson(SERVICE_ACCOUNT_ADMIN_SDK);

    // Generate OAuth 2.0 access token
    final auth.AccessCredentials accessCredentials = await obtainAccessCredentialsViaServiceAccount(
      serviceAccountCredentials,
      ['https://www.googleapis.com/auth/firebase.messaging'],
      http.Client(),
    );

    final String accessToken = accessCredentials.accessToken.data;

    // FCM server key for authentication
    // const String serverKey = SERVER_KEY_OA2; // Replace with your actual FCM Server Key

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken', // v1 API requires a Bearer token
    };

    // Prepare messages
    final List<Map<String, dynamic>> messages = [];

    if (mobileToken != null) {
      messages.add({
        "message": {
          "token": mobileToken,
          "notification": {
            "title": title,
            "body": body,
          },
          "data": data,
          "android": {
            "priority": "high",
          },
          "apns": {
            "payload": {
              "aps": {
                "category": "NEW_MESSAGE",
                "contentAvailable": true,
              },
            },
          },
        }
      });
    }

    if (webToken != null) {
      messages.add({
        "message": {
          "token": webToken,
          "notification": {
            "title": title,
            "body": body,
            "image": imageUrl
          },
          "data": data,
          "webpush": {
            "notification": {
              "body": body,
              "icon": "https://yourwebsite.com/path-to-icon.png"
            },
            "fcm_options": {
              "link": clickRoute, // Ensures web notifications open the correct page
            },
          },
        }
      });
    }

    // Send each message separately to FCM
    for (final message in messages) {
      final response = await http.post(
        fcmEndpoint,
        headers: headers,
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        print("Notification sent successfully: ${response.body}");
      } else {
        print("Failed to send notification: ${response.body}");
      }
    }
  }
  
Future<void> subscribeUserToTopic(
  FirebaseFirestore fireStore,
  FirebaseFunctions firebaseFunctions,
  String topic,
  String recipientId, 
  bool isWeb) async {
  final recipientDoc = await fireStore.collection('users').doc(recipientId).get();
    if (!recipientDoc.exists) {
      print("Recipient user does not exist.");
      return;
    }

    final Map<String, dynamic>? userData = recipientDoc.data();// iOS/Android FCM Token
    final String? mobileToken = userData?['token'];
    final String? webToken = userData?['webToken'];


    if (isWeb) {
      if (webToken == null) {
        print('web token does not exist');
        return;
      }

    await firebaseFunctions.httpsCallable('httpSubscribeUserToTopic').call({
      'token': webToken,
      'topic': topic,
    });
  }

  if (isWeb == false) {
    if (mobileToken == null) {
      print('mobile token does not exist');
      return;
    }
    await firebaseFunctions.httpsCallable('httpSubscribeUserToTopic').call({
      'token': mobileToken,
      'topic': topic,
    });
  }
}


Future<void> unsubscribeUserFromTopic(
  FirebaseFirestore fireStore,
  FirebaseFunctions firebaseFunctions,
  String topic, 
  String recipientId, 
  bool isWeb) async {
  final recipientDoc = await fireStore.collection('users').doc(recipientId).get();
      if (!recipientDoc.exists) {
        print("Recipient user does not exist.");
        return;
      }

      final Map<String, dynamic>? userData = recipientDoc.data();// iOS/Android FCM Token
      final String? webToken = userData?['webToken'];
      final String? mobileToken = userData?['token'];

      if (isWeb) {
          if (webToken == null) {
            print('web token does not exist');
            return;
          }

        await firebaseFunctions.httpsCallable('httpUnsubscribeUserFromTopic').call({
          'token': webToken,
          'topic': topic,
        });
      }

      if (isWeb == false) {
        if (mobileToken == null) {
            print('web token does not exist');
            return;
          }

        await firebaseFunctions.httpsCallable('httpUnsubscribeUserFromTopic').call({
          'token': mobileToken,
          'topic': topic,
        });
      }
}