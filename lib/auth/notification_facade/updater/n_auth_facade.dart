part of check_in_facade;

abstract class NAuthFacade {


  /// all [ReservationItem] based notifications

  // send reservation created notification to facility owners.
  Future<Either<ReservationFormFailure, Unit>> createReservationCreatedNotification({required String facilityOwner});

  /// send reservation request notification
  Future<Either<ReservationFormFailure, Unit>> createReservationRequestNotification({required String facilityOwner});

  /// send invitation notification to invitee
  Future<Either<AttendeeFormFailure, Unit>> createReservationInvitationNotification({required String reservationId, required AttendeeItem attendee});

  /// remove invitation invite
  Future<Either<AttendeeFormFailure, Unit>> deleteReservationInvitationNotification({required String reservationId, required String attendeeUserId});

  /// send request notification to reservation owners
  Future<Either<AttendeeFormFailure, Unit>> createRequestToJoinReservationNotification({required String reservationId, required AttendeeItem attendee});

  /// send notification to reservation owners & attendees that you have joined
  Future<Either<AttendeeFormFailure, Unit>> createJoinedReservationNotification({required String reservationId, required AttendeeItem attendee});

  /// send notification to reservation owners that review was made.
  Future<Either<AttendeeFormFailure, Unit>> createNewReviewNotification({required String reservationId});

  /// send notification to attendee that reservation activity was updated
  Future<Either<AttendeeFormFailure, Unit>> createUpdatedReservationActivityNotification({required String reservationId});

  /// send notification to attendee that new reservation post was created
  Future<Either<AttendeeFormFailure, Unit>> createNewReservationPostNotification({required List<AttendeeItem> attendees, required Post post});

  /// send notification to post author that post was liked
  Future<Either<ReservationFormFailure, Unit>> createDidLikePostNotification({required Post likedPost});

  /// all [Facility] based notifications
  ///

  /// send notification to reservation Owner from facilityOwner
  Future<Either<AttendeeFormFailure, Unit>> createMessageToReservationOwnerNotification({required String facilityOwnerId, required ReservationItem reservation});



}