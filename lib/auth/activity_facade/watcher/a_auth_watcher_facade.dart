part of check_in_facade;

abstract class AAuthWatcherFacade {

  /// activity items watcher events ///
  // Stream<Either<ActivityFormFailure, ActivityManagerProfile>> watchActivityManagerProfile({required String activityId});
  Stream<Either<ActivityFormFailure, List<ActivityManagerForm>>> watchAllActivityFormsFromRes({required List<String> reservationIds});
  Stream<Either<ActivityFormFailure, ActivityManagerForm>> watchActivityCreatorForm({required String activityId});
  Stream<Either<ActivityFormFailure, List<ActivityManagerForm>>> watchAllActivityCreatorForms({required bool isReservation, required String? reservationId});


}