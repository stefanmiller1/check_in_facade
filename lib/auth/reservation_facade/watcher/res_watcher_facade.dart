part of check_in_facade;

@LazySingleton(as: RAuthWatcherFacade)
class ResWatcherFacade implements RAuthWatcherFacade {

  final FirebaseFirestore _fireStore;
  final FirebaseAuth _firebaseAuth;

  ResWatcherFacade(this._fireStore, this._firebaseAuth);

  @override
  Stream<Either<ReservationFormFailure, List<ReservationItem>>> watchReservationListingItem({required List<String> listingId}) async* {

    try {

      yield* _fireStore.
      collection('reservation_directory')
          .snapshots().map((event) {
            if (event.docs.isNotEmpty) {
              return right<ReservationFormFailure, List<ReservationItem>>(event.docs.map((form) => ReservationItemDto.fromFireStore(form).toDomain()).toList().where((element) => element.instanceId.getOrCrash() == listingId.first).toList());
            }
            return left(const ReservationFormFailure.reservationServerError());
      });

      yield left(const ReservationFormFailure.reservationServerError());
    } catch (e) {
      yield left(const ReservationFormFailure.reservationServerError());
    }

  }

  @override
  Stream<Either<ReservationFormFailure, List<ReservationRequestItem>>> watchReservationRequests() async* {

  }

  @override
  Stream<Either<ReservationFormFailure, List<ReservationItem>>> watchCurrentUserReservationItem({required String? currentUser}) async* {

    try {
      yield* _fireStore
          .collection('reservation_directory')
          .snapshots().map((event) {
        if (event.docs.isNotEmpty) {
          return right<ReservationFormFailure, List<ReservationItem>>(event.docs.map((form) => ReservationItemDto.fromFireStore(form).toDomain()).toList().where((element) => element.reservationOwnerId.getOrCrash() == (currentUser ?? _firebaseAuth.currentUser?.uid)).toList());
        }
        return left(const ReservationFormFailure.reservationServerError(failed: 'no reservations found'));
      });

      yield left(const ReservationFormFailure.reservationServerError());
    } catch (e) {
      yield left(const ReservationFormFailure.reservationServerError());
    }
  }

}