part of check_in_facade;


abstract class ATTAuthFacade {

  Future<Either<AttendeeFormFailure, Unit>> createNewAttendee({
    required AttendeeItem attendeeItem,
    required ActivityManagerForm? activityForm,
    required String? paymentIntentId
  });

  Future<Either<AttendeeFormFailure, UserProfileModel>> checkVendorLimit({
   required AttendeeItem attendeeItem,
   required ActivityManagerForm activityForm,
   required UserProfileModel currentUser
});

  Future<Either<AttendeeFormFailure, UserProfileModel>> checkTicketLimit({
    required AttendeeItem attendeeItem,
    required ActivityManagerForm activityForm,
    required UserProfileModel currentUser
  });

  Future<Either<AttendeeFormFailure, Unit>> createNewTicket({
    required AttendeeItem attendeeItem,
    required ActivityManagerForm activityForm,
    required bool isOnHold
  });

  Future<Either<AttendeeFormFailure, Unit>> removeTicketsFromAttendee({
    required AttendeeItem attendeeItem,
    required ActivityManagerForm activityForm,
  });

  Future<Either<AttendeeFormFailure, Unit>> deleteAttendee({
    required AttendeeItem attendeeItem,
    required ActivityManagerForm activityForm,
  });

}