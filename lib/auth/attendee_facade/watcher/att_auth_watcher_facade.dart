part of check_in_facade;

abstract class ATTAuthWatcherFacade {

  Stream<Either<AttendeeFormFailure, List<AttendeeItem>>> watchUserProfileAttending();
  Stream<Either<AttendeeFormFailure, List<AttendeeItem>>> watchAllAttendeesByTypeList({required String attendeeType,  required String activityId});
  Stream<Either<AttendeeFormFailure, List<AttendeeItem>>> watchAllAttendees({required String activityId});
  Stream<Either<AttendeeFormFailure, int>> watchAllAttendeesByCount({required String attendeeType, required String activityId});
  Stream<Either<AttendeeFormFailure, AttendeeItem>> watchAttendeeItem({required String activityId, required String attendeeId});
}