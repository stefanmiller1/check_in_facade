part of check_in_facade;

@LazySingleton(as: NWatcherFacade)
class NotificationWatcherFacade implements NWatcherFacade {

  final FirebaseFirestore _fireStore;
  final FirebaseAuth _firebaseAuth;

  NotificationWatcherFacade(
      this._fireStore,
      this._firebaseAuth
  );

  @override
  Stream<Either<NotificationValueFailure, List<AccountNotificationItem>>> watchAccountNotificationsByType({required List<AccountNotificationType> type, required UniqueId? reservationId, required bool? isRead}) async* {

    try {

      if (_firebaseAuth.currentUser == null) {
        yield left(const NotificationValueFailure.notificationServerError());
        return;
      }


      var notificationRef = _fireStore.collection('users').doc(_firebaseAuth.currentUser!.uid)
          .collection('notifications')
          .orderBy('receivedAtTimeStamp', descending: true);


      if (type.isNotEmpty) {
        notificationRef = notificationRef.where('notificationType', whereIn: type.map((e) => e.toString()).toList());
      }

      if (isRead != null) {
        notificationRef = notificationRef.where('isRead', isEqualTo: isRead);
      }

      if (reservationId != null) {
        notificationRef = notificationRef.where('reservationId', isEqualTo: reservationId.getOrCrash());
      }

      yield* notificationRef.snapshots().map(
              (event) {
          if (event.docs.isNotEmpty) {
            return right<NotificationValueFailure, List<AccountNotificationItem>>(event.docs.map((e) => AccountNotificationItemDto.fromFireStore(e).toDomain()).toList());
            } else {
            return left(const NotificationValueFailure.notificationServerError(failedValue: 'no notifications'));
          }
        }
      );

      yield left(const NotificationValueFailure.notificationServerError());
    } catch (e) {
      yield left(NotificationValueFailure.notificationServerError(failedValue: e.toString()));
    }
  }
}