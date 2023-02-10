part of check_in_facade;

@injectable
@LazySingleton(as: LoUnAuthWatcherFacade)
class LocationUnAuthWatcherFacade implements LoUnAuthWatcherFacade {

  final FirebaseFirestore _fireStore;

  LocationUnAuthWatcherFacade(this._fireStore);

  @override
  Stream<Either<FacilityFormFailure, List<LocationModel>>> watchLocationDirectory() async* {
    try {
      // yield* _fireStore.collection('location_directory')
      //     .snapshots()
      //     .map((snapshot) => snapshot. ?
      // right(FacilityLocationDto.fromFireStore(snapshot).toDomain()) :
      // left(const FacilityFormFailure.facilityNotFound())
      // );
      yield left(const FacilityFormFailure.facilityServerError());
    } catch (e) {
      yield left(FacilityFormFailure.facilityServerError(serverResponse: e.toString()));
    }
  }

  @override
  Stream<Either<FacilityFormFailure, LocationModel>> watchLocationItem({required String locationId}) async* {
    try {

      yield* _fireStore.collection('location_directory')
          .doc(locationId)
          .snapshots()
          .map((snapshot) => snapshot.exists ?
      right(LocationModelDto.fromFireStore(snapshot).toDomain()) :
      left(const FacilityFormFailure.facilityNotFound())
      );
      yield left(const FacilityFormFailure.facilityServerError());
    } catch (e) {
      yield left(FacilityFormFailure.facilityServerError(serverResponse: e.toString()));
    }
  }

}