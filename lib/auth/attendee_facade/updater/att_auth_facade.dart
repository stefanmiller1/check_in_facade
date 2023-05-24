part of check_in_facade;


abstract class ATTAuthFacade {

  Future<Either<AttendeeFormFailure, Unit>> createNewAttendee({
    required AttendeeItem attendeeItem
  });


}