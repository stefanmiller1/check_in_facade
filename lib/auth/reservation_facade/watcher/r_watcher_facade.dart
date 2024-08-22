part of check_in_facade;

abstract class RAuthWatcherFacade {

  /// reservation watcher events
  Stream<Either<ReservationFormFailure, List<ReservationItem>>> watchReservationFacilityItem({required List<String> facilityId, required String? activityTypeId, required bool? isPublic, required List<ReservationSlotState>? resState});
  Stream<Either<ReservationFormFailure, List<ReservationItem>>> watchCurrentUserReservationItem({required List<ReservationSlotState> resState, required UserProfileModel currentUser, required bool isResInvitation, required int? limit, required bool? isActivity});

  Stream<Either<ReservationFormFailure, List<Post>>> watchReservationPostItems({required String? reservationId});
  Stream<Either<ReservationFormFailure, List<ReservationRequestItem>>> watchReservationRequests();
  Stream<Either<ReservationFormFailure, ReservationItem>> watchCurrentReservationItem({required String reservationId});

  Stream<Either<ReservationFormFailure, List<ReservationItem>>> watchDiscoveryReservationItems({required List<ReservationSlotState> resState, required int? hoursTimeAhead, required int? hoursTimeBefore, required bool? isActivity});

}