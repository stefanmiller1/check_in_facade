part of check_in_facade;

abstract class AAuthWatcherFacade {

  /// activity items watcher events ///
  // Stream<Either<ActivityFormFailure, ActivityManagerProfile>> watchActivityManagerProfile({required String activityId});
  Stream<Either<ActivityFormFailure, ActivityCreatorForm>> watchActivityCreatorForm({required String activityId});
  Stream<Either<ActivityFormFailure, List<ActivityCreatorForm>>> watchAllActivityCreatorForms({required bool isReservation, required String? reservationId});


}