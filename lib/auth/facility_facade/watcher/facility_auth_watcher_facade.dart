part of check_in_facade;

@LazySingleton(as: FAuthWatcherFacade)
class FacilityWatcherFormFacade implements FAuthWatcherFacade {

  final FirebaseFirestore _fireStore;
  final FirebaseAuth _firebaseAuth;

  FacilityWatcherFormFacade(
      this._fireStore,
      this._firebaseAuth
      );


  @override
  Stream<Either<FacilityFormFailure, FacilityCreatorForm>> watchFacilityCreatorForm({required String facilityId}) async* {
    try {

      yield* _fireStore.collection('facility_directory')
      .doc(facilityId)
      .snapshots()
      .map((snapshot) => snapshot.exists ?
        right(FacilityCreatorFormDto.fromFirestore(snapshot).toDomain()) :
        left(const FacilityFormFailure.facilityNotFound())
      );
      yield left(const FacilityFormFailure.facilityFormServerError());
    }catch(e) {
      yield left(const FacilityFormFailure.facilityFormServerError());
    }
  }


  @override
  Stream<Either<FacilityFormFailure, List<FacilityCreatorForm>>> watchAllFacilityCreatorForms() async* {

    try {

      final currentUser = _firebaseAuth.currentUser?.uid;

      yield* _fireStore.collection('users')
          .doc(currentUser)
          .collection('facility_form').snapshots().map((event) {

      print(event.docs.map((e) => e.data()));

      if (event.docs.isNotEmpty) {
        return right<FacilityFormFailure, List<FacilityCreatorForm>>(event.docs.map((form) =>
            FacilityCreatorFormDto.fromFirestore(form).toDomain()).toList());
      }
      return left(const FacilityFormFailure.facilityFormServerError());
    });

    yield left(const FacilityFormFailure.facilityFormServerError());
  } catch(e) {
    yield left(const FacilityFormFailure.facilityFormServerError());

    }
  }



}