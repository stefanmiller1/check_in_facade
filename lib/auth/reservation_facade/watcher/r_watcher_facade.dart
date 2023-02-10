part of check_in_facade;

abstract class RAuthWatcherFacade {

  /// reservation watcher events
  Stream<Either<ReservationFormFailure, List<ReservationItem>>> watchReservationListingItem({required List<String> listingId});
  Stream<Either<ReservationFormFailure, List<ReservationItem>>> watchCurrentUserReservationItem({required String? currentUser});


  Stream<Either<ReservationFormFailure, List<ReservationRequestItem>>> watchReservationRequests();


}