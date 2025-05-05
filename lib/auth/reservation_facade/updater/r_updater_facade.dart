part of check_in_facade;

abstract class RUpdaterFacade {

  /// create reservation for listing
  Future<Either<ReservationFormFailure, Unit>> createReservationForm({
    required ReservationItem reservationForm,
    required ListingManagerForm? listingForm,
    required ActivityManagerForm? activityForm,
    required String paymentIntentId
});

  /// update/edit reservation
  Future<Either<ReservationFormFailure, Unit>> updateReservationFormRequest({
    required ReservationItem reservationForm,
});


  /// delete reservation
  Future<Either<ReservationFormFailure, Unit>> cancelReservationForm({
  required ReservationCancelRequest cancelRequest,
  required ReservationItem reservationForm,
});

  /// update reservation post
  Future<Either<ReservationFormFailure, Unit>> createReservationPost({
    required Post reservationPost,
    required List<AttendeeItem> attendees
});

  /// reply to existing reservation post
  Future<Either<ReservationFormFailure, Unit>> replyReservationPost({
    required Post replyReservationPost,
});

  /// update existing post with like
  Future<Either<ReservationFormFailure, Unit>> likeReservationPost({
    required Post reservationPost
});

  /// update existing post with bookmark
  Future<Either<ReservationFormFailure, Unit>> bookMarkReservationPost({
    required Post reservationPost
});


  /// update existing with flag
  Future<Either<ReservationFormFailure, Unit>> flagReservationPost({
    required Post reservationPost
});

  /// remove existing post
  Future<Either<ReservationFormFailure, Unit>> removePost({
    required Post reservationPost
});

  /// send invite to reservation link
  Future<Either<ReservationFormFailure, Uri>> createShareLink({
    required ReservationItem reservationItem
});

  /// send invitation to selected list
  Future<Either<AttendeeFormFailure, Unit>> sendInvitationToUsers({
    required String reservationId,
    required ActivityManagerForm? activityForm,
    required List<AttendeeItem> invitations
});

  /// remove invited attendee
  Future<Either<AttendeeFormFailure, Unit>> removeSelectedAttendee({
   required String reservationId,
   required String attendeeId,
});

//   /// join reservation from invite
//   Future<Either<ReservationFormFailure, Unit>> updateReservationAffiliatesList({
//     required String reservationId,
//     required List<ContactDetails> updatedAffiliatesList
// });

}