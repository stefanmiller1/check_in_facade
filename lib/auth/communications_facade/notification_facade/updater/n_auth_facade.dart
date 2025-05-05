part of check_in_facade;

abstract class NAuthFacade {


  /// masteer notification functions
  /// [ReservationItem] based notificartions  
  /// updates to reservation (sent to facility owner)
  /// updates to reservation (sent to attendees)
  
  // all [ListingManagerForm] based notifications
  Future<Either<ListingFormFailure, Unit>> sendFacilityOwnerNotification({
    required String facilityOwnerId,
    required String reservationId,
    required AccountNotificationType type,
    String? message,
    String? title
  });

  /// all [ReservationItem] based notifications
  Future<Either<ReservationFormFailure, Unit>> sendReservationOwnerNotification({
    required String reservationId,
    required String ownerId,
    required AccountNotificationType type,
    String? message,
    String? title,
  });


  /// all [AttendeeItem] based notifications
  Future<Either<AttendeeFormFailure, Unit>> sendAttendeeNotification({
    required String reservationId,
    required AttendeeItem attendee,
    required AccountNotificationType type,
    String? message,
    String? title
  });

  Future<void> createNotification({
    required AccountNotificationItem notificationItem,
  });

  /// updates & delete functions
  Future<void> updateNotification({
    required String recipientId,
    required String notificationId,
    bool? isRead,
    int? openedAtTimeStamp,
  });

  Future<void> deleteNotificationsAndUnsubscribe({
    required String reservationId,
    required String recipientId,
    required AccountNotificationType type,
    bool shouldUnsubscribe = false,
  });

  /// all [ProfileItem] based notifications
  /// changes made to profile
  /// changes 
  // Future<Either<ProfileFormFailure, Unit>> profileBasedNotification({});
  

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


  /// all [Attendee] based notifications
  Future<Either<AttendeeFormFailure, Unit>> attendeeVendorUpdateNotification({required String reservationId, required String? activityTitle, required AttendeeItem attendee});


}