part of check_in_facade;

abstract class UAuthFacade {

  /// profile booking count watchers
  Stream<Either<AuthFailure, int>> watchOwnersCurrentFacilityBookingsCount({
    required UniqueId currentOwner,
    required UniqueId bookingId,
    required String facilityType,
  });

  Stream<Either<AuthFailure, int>> watchOwnersCurrentActivitiesBookingsCount({
    required UniqueId currentOwner,
    required UniqueId bookingId,
    required String activityType,
  });

  Stream<Either<AuthFailure, int>> watchOwnersCurrentSessionsBookingsCount({
    required UniqueId currentOwner,
    required UniqueId bookingId,
    required String sessionType,
  });

}