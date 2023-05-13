part of check_in_facade;

@LazySingleton(as: AAuthWatcherFacade)
class ActivityWatcherFacade implements AAuthWatcherFacade {

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _fireStore;

  ActivityWatcherFacade(this._fireStore, this._firebaseAuth);

  // @override
  // Stream<Either<ActivityFormFailure, ActivityManagerProfile>> watchActivityManagerProfile({
  //   required String activityId}) async* {
  //
  //   try {
  //
  //     yield* _fireStore.collection('activity_directory').doc(activityId).snapshots().map(
  //             (snapshot) => snapshot.exists ? right(ActivityManagerProfileDto.fromFirestore(snapshot).toDomain()) :
  //             left(const ActivityFormFailure.activityNotFound()));
  //
  //     yield left(const ActivityFormFailure.serverError());
  //   } catch(e) {
  //     yield left(const ActivityFormFailure.serverError());
  //   }
  // }


  @override
  Stream<Either<ActivityFormFailure, ActivityCreatorForm>> watchActivityCreatorForm({required String activityId}) async* {
    try {

      yield* _fireStore
          .collection('activity_directory')
          .doc(activityId)
          .activityFormDocument
          .doc(activityId)
          .snapshots().map((snapshot) {
            if (snapshot.exists) {
              return right(ActivityCreatorFormDto.fromFireStore(snapshot).toDomain());
            }
          return left(const ActivityFormFailure.activityNotFound());
       });

      yield left(const ActivityFormFailure.activityServerError());
    } catch(e) {

      yield left(const ActivityFormFailure.activityServerError());
    }
  }

  @override
  Stream<Either<ActivityFormFailure, List<ActivityCreatorForm>>> watchAllActivityCreatorForms({required bool isReservation, required String? reservationId}) async* {
    try {
      if (_firebaseAuth.currentUser == null ) yield left(const ActivityFormFailure.activityServerError());

      if (isReservation && reservationId != null) {
        yield* _fireStore.collection('activity_directory')
            .where('activityReservation', arrayContains: reservationId)
            .snapshots().map((event) {
              if (event.docs.isNotEmpty) {
                return right<ActivityFormFailure, List<ActivityCreatorForm>>(event.docs.map((form) =>
                    ActivityCreatorFormDto.fromFireStore(form).toDomain()).toList());
              }
              return left(const ActivityFormFailure.activityServerError());
          }
        );

      } else {
        yield* _fireStore.collection('activity_directory')
            .where('activityOwner', isEqualTo: _firebaseAuth.currentUser!.uid)
            .snapshots().map((event) {
              if (event.docs.isNotEmpty) {
                return right<ActivityFormFailure, List<ActivityCreatorForm>>(event.docs.map((form) =>
                    ActivityCreatorFormDto.fromFireStore(form).toDomain()).toList());
              }
          return left(const ActivityFormFailure.activityServerError());
        });
      }

      yield left(const ActivityFormFailure.activityServerError());
    } catch(e) {
      yield left(const ActivityFormFailure.activityServerError());
    }
  }


}