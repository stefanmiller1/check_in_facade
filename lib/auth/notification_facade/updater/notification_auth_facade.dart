part of check_in_facade;

@LazySingleton(as: NAuthFacade)
class NotificationUpdaterFacade implements NAuthFacade {

  final FirebaseAuth _firebaseAuth;
  final FirebaseMessaging _firebaseMessaging;
  final FirebaseFirestore _fireStore;

  NotificationUpdaterFacade(
      this._fireStore,
      this._firebaseMessaging,
      this._firebaseAuth
    );

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

      /// create new notification in users notifications collection
      attendeeProfileDoc.collection('notifications').doc(notificationId.getOrCrash()).set(notificationDto);

      /// send notification to attendee if mobile token exists
      sendPushNotification(
          userInfo.data().toString().contains('token') ? userInfo['token'] : null,
          userInfo.data().toString().contains('webToken') ? userInfo['webToken'] : null,
          <String, dynamic>{
            'reservationId': reservationId,
            'status': 'done',
            'link': '/${DashboardMarker.reservations.name.toString()}/reservation/$reservationId'
          },
        '/${DashboardMarker.reservations.name.toString()}/reservation/$reservationId',
        'New Invitation!',
        'You\'ve been invited to Join a new Reservation!'
      );

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

       final UniqueId notificationId = UniqueId();
       final notificationDto = AccountNotificationItemDto(notificationId: notificationId.getOrCrash(), isRead: false, receivedAtTimeStamp: DateTime.now().millisecondsSinceEpoch, sentFromId: _firebaseAuth.currentUser!.uid, notificationType: AccountNotificationType.joined.toString(), reservationId: reservationId).toJson();

       /// send update to reservation owner
       final reservation = await _fireStore.collection('reservation_directory').doc(reservationId).get();
       final resOwnerId = reservation['reservationOwnerId'];

       /// save notification is users profile
       final resOwnerDoc = _fireStore.collection('users').doc(resOwnerId);
       resOwnerDoc.collection('notifications').doc(notificationId.getOrCrash()).set(notificationDto);


       /// get res owner token for sending notification
       final userInfo = await _fireStore.collection('users').doc(resOwnerId).get();
       /// send notification to attendee if mobile or web token exists
       sendPushNotification(
           userInfo.data().toString().contains('token') ? userInfo['token'] : null,
           userInfo.data().toString().contains('webToken') ? userInfo['webToken'] : null,
           <String, dynamic>{
             'reservationId': reservationId,
             'status': 'done',
             'link': '/${DashboardMarker.reservations.name.toString()}/reservation/$reservationId'
           },
         '/${DashboardMarker.reservations.name.toString()}/reservation/$reservationId',
         'New ${attendee.attendeeType.name} Attendee Joined',
         'Someone new joined your Activity'
       );

       /// subscribe to activity topic
       await _firebaseMessaging.subscribeToTopic(reservationId);


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

       final UniqueId notificationId = UniqueId();
       final notificationDto = AccountNotificationItemDto(notificationId: notificationId.getOrCrash(), isRead: false, receivedAtTimeStamp: DateTime.now().millisecondsSinceEpoch, sentFromId: _firebaseAuth.currentUser!.uid, notificationType: AccountNotificationType.activityPost.toString(), reservationId: post.reservationId).toJson();

       for (AttendeeItem attendee in attendees) {

         /// get all attendees except yourself
         if (attendee.attendeeOwnerId.getOrCrash() != _firebaseAuth.currentUser!.uid) {
           /// save notification in users profile
           final resOwnerDoc = _fireStore.collection('users').doc(attendee.attendeeOwnerId.getOrCrash());
           resOwnerDoc.collection('notifications').doc(notificationId.getOrCrash()).set(notificationDto);

           // /// get res owner token for sending notification
           final userInfo = await _fireStore.collection('users').doc(attendee.attendeeOwnerId.getOrCrash()).get();

           /// send notification to attendee if mobile token exists
           sendPushNotification(
               userInfo.data().toString().contains('token') ? userInfo['token'] : null,
               userInfo.data().toString().contains('webToken') ? userInfo['webToken'] : null,
               <String, dynamic>{
                 'reservationId': post.reservationId,
                 'status': 'done',
                 'link': '/${DashboardMarker.reservations.name.toString()}/reservation/${post.reservationId}'
                },
               '/${DashboardMarker.reservations.name.toString()}/reservation/${post.reservationId}',
               _firebaseAuth.currentUser?.displayName != null ? '${_firebaseAuth.currentUser?.displayName} Sent a New Post!' : 'New Post!',
               post.textPost != null ? '${post.textPost?.text}' : 'see what someone said in an activity you\'re in'
           );
         }
       }


        /// send update to reservation owner...res owners cannot be attendees
        final reservation = await _fireStore.collection('reservation_directory').doc(post.reservationId).get();
        final resOwnerId = reservation['reservationOwnerId'];

        if (_firebaseAuth.currentUser?.uid != resOwnerId) {
          /// save notification is users profile
          final resOwnerDoc = _fireStore.collection('users').doc(resOwnerId);
          resOwnerDoc.collection('notifications').doc(notificationId.getOrCrash()).set(notificationDto);

          final userInfo = await _fireStore.collection('users').doc(resOwnerId).get();

          sendPushNotification(
              userInfo.data().toString().contains('token') ? userInfo['token'] : null,
              userInfo.data().toString().contains('webToken') ? userInfo['webToken'] : null,
              <String, dynamic>{
                'reservationId': post.reservationId,
                'status': 'done',
                'link': '/${DashboardMarker.reservations.name.toString()}/reservation/${post.reservationId}'
              },
              '/${DashboardMarker.reservations.name.toString()}/reservation/${post.reservationId}',
              _firebaseAuth.currentUser?.displayName != null ? '${_firebaseAuth.currentUser?.displayName} Sent a New Post!' : 'New Post!',
              post.textPost != null ? '${post.textPost?.text}' : 'see what someone said in an activity you\'re in'
          );

        }



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

       /// send notification to reservation topic
       await http.post(
           Uri.parse('https://fcm.googleapis.com/fcm/send'),
           headers: <String, String>{
             'Content-Type': 'application/json',
             'Authorization': 'key=$CMF_SERVER_KEY',
           },
           body: jsonEncode(
               <String, dynamic>{
                 'priority': 'high',

                 'data': {
                   'reservationId': reservationId,
                   'status': 'done',
                   'link': '/${DashboardMarker.reservations.name.toString()}/reservation/$reservationId'
                 },
                 'notification': {
                   'title': 'Activity Updated!',
                   'body': 'Changes were made to the activity you\'re in.',
                 },
                 'topic': reservationId,
               }
           )
       );

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

       final UniqueId notificationId = UniqueId();
       final notificationDto = AccountNotificationItemDto(notificationId: notificationId.getOrCrash(), isRead: false, receivedAtTimeStamp: DateTime.now().millisecondsSinceEpoch, sentFromId: _firebaseAuth.currentUser!.uid, notificationType: AccountNotificationType.request.toString(), reservationId: reservationId).toJson();

       /// get reservation owners id
       final reservation = await _fireStore.collection('reservation_directory').doc(attendee.reservationId.getOrCrash()).get();
       final resOwnerId = reservation['reservationOwnerId'];

       /// save notification is users profile
       final resOwnerDoc = _fireStore.collection('users').doc(resOwnerId);
       resOwnerDoc.collection('notifications').doc(notificationId.getOrCrash()).set(notificationDto);


       /// get res owner token for sending notification
       final userInfo = await _fireStore.collection('users').doc(resOwnerId).get();

       /// send notification to attedee if mobile token exists
       sendPushNotification(
           userInfo.data().toString().contains('token') ? userInfo['token'] : null,
           userInfo.data().toString().contains('webToken') ? userInfo['webToken'] : null,
           <String, dynamic>{
             'reservationId': reservationId,
             'status': 'done',
             'link': '/${DashboardMarker.reservations.name.toString()}/reservation/$reservationId'
           },
           '/${DashboardMarker.reservations.name.toString()}/reservation/$reservationId',
           'New Request',
           'Someone has sent you a request for your Reservation'
       );

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

       final UniqueId notificationId = UniqueId();
       final notificationDto = AccountNotificationItemDto(notificationId: notificationId.getOrCrash(), isRead: false, receivedAtTimeStamp: DateTime.now().millisecondsSinceEpoch, sentFromId: _firebaseAuth.currentUser!.uid, notificationType: AccountNotificationType.activityPost.toString(), reservationId: likedPost.reservationId).toJson();

       /// save notification is users profile
       final resOwnerDoc = _fireStore.collection('users').doc(likedPost.authorId.getOrCrash());
       resOwnerDoc.collection('notifications').doc(notificationId.getOrCrash()).set(notificationDto);

       /// get res owner token for sending notification
       final userInfo = await _fireStore.collection('users').doc(likedPost.authorId.getOrCrash()).get();

       /// send notification to attendee if mobile token exists
       sendPushNotification(
           userInfo.data().toString().contains('token') ? userInfo['token'] : null,
           userInfo.data().toString().contains('webToken') ? userInfo['webToken'] : null,
           <String, dynamic>{
             'reservationId': likedPost.reservationId,
             'status': 'done',
             'link': '/${DashboardMarker.reservations.name.toString()}/reservation/${likedPost.reservationId}'
           },
           '/${DashboardMarker.reservations.name.toString()}/reservation/${likedPost.reservationId}',
           'New Like!',
           'Someone Liked your post!'
       );

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

}

Future<void> sendPushNotification(String? mobileToken, String? webToken, Object data, String clickRoute, String title, String body) async {
  if (mobileToken != null) {
    await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=$CMF_SERVER_KEY',
        },
        body: jsonEncode(
            <String, dynamic>{
              'priority': 'high',
              'data': data,
              'notification': {
                'title': title,
                'body': body,
              },
              'to': mobileToken,
            }
        )
    );
  }

  /// send notification to attendee if mobile token exists
  if (webToken != null) {
    await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=$CMF_SERVER_KEY',
        },
        body: jsonEncode(
            <String, dynamic>{
              'priority': 'high',
              'sound': true,
              'data': data,
              'notification': {
                'title': title,
                'body': body,
              },
              'click_action': clickRoute,
              'webpush': {
                'fcm_options': {
                  'link': clickRoute
                },
              },
              'to': webToken,
            }
        )
    );
  }
}