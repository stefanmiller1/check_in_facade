part of check_in_facade;

abstract class EAuthFacade {

  // all [Email] based notifications
  Future<Either<AttendeeFormFailure, Unit>> createEmailNotification({required List<String>? sendTo, required String? template, required String? button_link, required String? reference_body_title, required Map<String, dynamic>? attachment});


}