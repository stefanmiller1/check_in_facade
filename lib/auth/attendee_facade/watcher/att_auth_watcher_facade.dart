part of check_in_facade;

abstract class ATTAuthWatcherFacade {

  Stream<Either<AttendeeFormFailure, List<AttendeeItem>>> watchAllAttendeesList({required String attendeeType,  required String activityId});


}