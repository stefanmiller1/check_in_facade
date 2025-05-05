part of check_in_facade;

abstract class EAuthFacade {

  // all [Email] based notifications
  Future<Either<AttendeeFormFailure, Unit>> createEmailNotification({required EmailNotificationItem email});


}