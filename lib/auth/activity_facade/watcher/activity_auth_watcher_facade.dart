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
  Stream<Either<ActivityFormFailure, ActivityManagerForm>> watchActivityCreatorForm({required String activityId}) async* {
    try {

      yield* _fireStore
          .collection('activity_directory')
          .doc(activityId)
          .snapshots().map((snapshot) {
            if (snapshot.exists) {
              return right(ActivityManagerFormDto.fromFireStore(snapshot).toDomain());
            }
          return left(const ActivityFormFailure.activityNotFound());
       });

      yield left(const ActivityFormFailure.activityServerError());
    } catch(e) {
      yield left(const ActivityFormFailure.activityServerError());
    }
  }

  @override
  Stream<Either<ActivityFormFailure, List<ActivityManagerForm>>> watchAllActivityCreatorForms({required bool isReservation, required String? reservationId}) async* {
    try {
      if (_firebaseAuth.currentUser == null ) yield left(const ActivityFormFailure.activityServerError());

      if (isReservation && reservationId != null) {
        yield* _fireStore.collection('activity_directory')
            .where('activityReservation', arrayContains: reservationId)
            .snapshots().map((event) {
              if (event.docs.isNotEmpty) {
                return right<ActivityFormFailure, List<ActivityManagerForm>>(event.docs.map((form) =>
                    ActivityManagerFormDto.fromFireStore(form).toDomain()).toList());
              }
            return left(const ActivityFormFailure.activityServerError());
          }
        );

      } else {
        yield* _fireStore.collection('activity_directory')
            .where('activityOwner', isEqualTo: _firebaseAuth.currentUser!.uid)
            .snapshots().map((event) {
              if (event.docs.isNotEmpty) {
                return right<ActivityFormFailure, List<ActivityManagerForm>>(event.docs.map((form) =>
                    ActivityManagerFormDto.fromFireStore(form).toDomain()).toList());
              }
          return left(const ActivityFormFailure.activityServerError());
        });
      }

      yield left(const ActivityFormFailure.activityServerError());
    } catch(e) {
      yield left(const ActivityFormFailure.activityServerError());
    }
  }

  @override
  Stream<Either<ActivityFormFailure, List<ActivityManagerForm>>> watchAllActivityFormsFromRes({required List<String> reservationIds}) async* {
    try {

      print('FIND THESE ${reservationIds}');
      yield* _fireStore.collection('activity_directory')
              .where('activityFormId', whereIn: reservationIds.toList())
              .snapshots().map((event) {
                print('found ${event.docs}');
                if (event.docs.isNotEmpty) {
                  return right<ActivityFormFailure, List<ActivityManagerForm>>(event.docs.map(
                          (form) => ActivityManagerFormDto.fromFireStore(form).toDomain()).toList());
                  }
                return left(const ActivityFormFailure.activityServerError());
              }
            );

    } catch (e) {
      yield left(const ActivityFormFailure.activityServerError());
    }
  }
}


class ActivitySettingsFacade {

  ActivitySettingsFacade._privateConstructor() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      firebaseUser = user;
    });
  }

  /// Current logged in user in Firebase. Does not update automatically.
  /// Use [FirebaseAuth.authStateChanges] to listen to the state changes.
  User? firebaseUser = FirebaseAuth.instance.currentUser;

  /// Gets proper [FirebaseFirestore] instance.
  FirebaseFirestore getFirebaseFirestore() => FirebaseFirestore.instance;

  /// Singleton instance.
  static final ActivitySettingsFacade instance = ActivitySettingsFacade._privateConstructor();

  Future<ActivityManagerForm> getActivitySettings({
    required String reservationId}) async {
    // if (firebaseUser == null) return Future.error('User does not exist');

    final activitySettings = await getFirebaseFirestore()
        .collection('activity_directory')
        .doc(reservationId).get();

    if (!(activitySettings.exists) || activitySettings.data() == null) {
      return Future.error('cannot find activity');
    }

      return processActivityForm(activitySettings);
  }


  ActivityManagerForm processActivityForm(DocumentSnapshot<Map<String, dynamic>> query) {
    return ActivityManagerFormDto.fromJson(query.data()!).toDomain();
  }


  Future<int> getNumberOfActivityAttendees({
    required String reservationId
}) async {
    final totalAttendees = await getFirebaseFirestore()
        .collection('activity_directory')
        .doc(reservationId)
        .collection('attendees')
        .count().get();

    return totalAttendees.count ?? 0;

  }

  Future<int> getNumberOfChatsInDiscussion({
    required String reservationId
}) async {

    final totalChats = await getFirebaseFirestore()
        .collection('reservation_post')
        .where('reservationId', isEqualTo: reservationId)
        .count().get();

    return totalChats.count ?? 0;
  }

}

