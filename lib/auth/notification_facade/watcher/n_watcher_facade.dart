part of check_in_facade;

abstract class NWatcherFacade {

  Stream<Either<NotificationValueFailure, List<AccountNotificationItem>>> watchAccountNotificationsByType({required List<AccountNotificationType> type, required UniqueId? reservationId, required bool? isRead});
}