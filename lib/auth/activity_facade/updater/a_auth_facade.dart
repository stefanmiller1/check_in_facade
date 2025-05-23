part of check_in_facade;

abstract class AAuthFacade {

  Future<Either<ActivityFormFailure, Unit>> updateActivitySettingsForm({
    required ActivityManagerForm activityForm,
    required UniqueId activityResId,
  });

  // Future<Either<ActivityFormFailure, Unit>> createCompletedActivityForm({
  // required ActivityCreatorForm activityForm,
  // });

  // Future<Either<ActivityFormFailure, Unit>> createActivityManagerProfile({
  //   required ActivityCreatorForm activityForm,
  // });


  /// UPDATER EVENTS ///
  // Future<Either<ActivityFormFailure, Unit>> updateFacilityManagerProfile({
  //   required String activityId,
  //   required ActivityManagerProfile activityForm,
  // });


}