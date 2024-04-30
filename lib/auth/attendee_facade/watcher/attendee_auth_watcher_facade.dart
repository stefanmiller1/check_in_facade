part of check_in_facade;

@LazySingleton(as: ATTAuthWatcherFacade)
class AttendanceAuthWatcherFacade implements ATTAuthWatcherFacade {

  final FirebaseFirestore _fireStore;
  final FirebaseAuth _firebaseAuth;

  AttendanceAuthWatcherFacade(
      this._fireStore,
      this._firebaseAuth
    );

  @override
  Stream<Either<AttendeeFormFailure, List<AttendeeItem>>> watchAllAttendeesByTypeList({required String attendeeType, required String activityId}) async* {
    
    try {
      
      yield* _fireStore
          .collection('activity_directory')
          .doc(activityId)
          .collection('attendees')
          .where('attendeeType', isEqualTo: attendeeType)
          .snapshots().map((event) {
            if (event.docs.isNotEmpty) {
              return right<AttendeeFormFailure, List<AttendeeItem>>(event.docs.map((form) => AttendeeItemDto.fromFireStore(form.data()).toDomain()).toList());
            }
          return left(const AttendeeFormFailure.attendeeServerError(failed: 'no attendees were found'));
      });

      yield left(const AttendeeFormFailure.attendeeServerError());
    } catch (e) {
      yield left(AttendeeFormFailure.attendeeServerError(failed: e.toString()));
    }
  }

  @override
  Stream<Either<AttendeeFormFailure, int>> watchAllAttendeesByCount({required String attendeeType, required String activityId}) async* {

    try {
      final attendeeCount = await _fireStore
          .collection('activity_directory')
          .doc(activityId)
          .collection('attendees')
          .where('attendeeType', isEqualTo: attendeeType)
          .count().get();

      yield right(attendeeCount.count ?? 0);
    } catch (e) {
      yield left(AttendeeFormFailure.attendeeServerError(failed: e.toString()));
    }
  }

  @override
  Stream<Either<AttendeeFormFailure, List<AttendeeItem>>> watchUserProfileAttending({required ContactStatus? status, required AttendeeType? attendingType, required int? limit}) async* {

    try {

      final currentUser = _firebaseAuth.currentUser;

      if (currentUser == null) {
        yield left(const AttendeeFormFailure.attendeeServerError(failed: 'not signed in'));
      }

      var attendeeRef = _fireStore.collection('users')
          .doc(currentUser!.uid)
          .collection('attending')
          .orderBy('createdAtSTC', descending: true);

        if (status != null) {
          attendeeRef = attendeeRef.where('contactStatus', isEqualTo: status.toString());
        }

        if (attendingType != null) {
          attendeeRef = attendeeRef.where('attendeeType', isEqualTo: attendingType.toString());
        }

        if (limit != null) {
          attendeeRef = attendeeRef.limit(limit);
        }

          yield* attendeeRef.snapshots().map(
              (event) {
          if (event.docs.isNotEmpty) {
            return right<AttendeeFormFailure, List<AttendeeItem>>(event.docs.map((form) => AttendeeItemDto.fromFireStore(form.data()).toDomain()).toList());
          }
          return left(const AttendeeFormFailure.attendeeServerError(failed: 'not attending any reservations'));
        });

      yield left(const AttendeeFormFailure.attendeeServerError());
    } catch (e) {
      yield left(AttendeeFormFailure.attendeeServerError(failed: e.toString()));
    }
  }


  @override
  Stream<Either<AttendeeFormFailure, List<AttendeeItem>>> watchAllAttendees({required String activityId}) async* {
    try {

      yield* _fireStore
          .collection('activity_directory')
          .doc(activityId)
          .collection('attendees')
          .snapshots().map((event) {



        if (event.docs.isNotEmpty) {
          return right<AttendeeFormFailure, List<AttendeeItem>>(event.docs.map((form) => AttendeeItemDto.fromFireStore(form.data()).toDomain()).toList());
        }
        return left(const AttendeeFormFailure.attendeeServerError(failed: 'no attendees were found'));
      });

      yield left(const AttendeeFormFailure.attendeeServerError());
    } catch (e) {
      yield left(AttendeeFormFailure.attendeeServerError(failed: e.toString()));
    }
  }

  @override
  Stream<Either<AttendeeFormFailure, AttendeeItem>> watchAttendeeItem({required String activityId, required String attendeeId}) async* {

    try {

      yield* _fireStore
          .collection('activity_directory')
          .doc(activityId)
          .collection('attendees')
          .doc(attendeeId)
          .snapshots().map(
              (event) {
                if (event.exists && event.data() != null) {
                  return right<AttendeeFormFailure, AttendeeItem>(AttendeeItemDto.fromFireStore(event.data()!).toDomain());
          }
          return left(const AttendeeFormFailure.attendeeServerError());
        }
      );

      yield left(const AttendeeFormFailure.attendeeServerError());
    } catch (e) {
      yield left(AttendeeFormFailure.attendeeServerError(failed: e.toString()));
    }
  }


  @override
  Stream<Either<AttendeeFormFailure, List<AttendeeItem>>> watchCurrentUsersAttendance({required String userId, required ContactStatus status, required AttendeeType type, required int limit}) async* {

    try {

      yield* _fireStore
          .collection('users')
          .doc(userId)
          .collection('attending')
          .where('attendeeType', isEqualTo: type)
          .limit(limit)
          .snapshots().map((event) {

        if (event.docs.isNotEmpty) {
          return right<AttendeeFormFailure, List<AttendeeItem>>(event.docs.map((form) => AttendeeItemDto.fromFireStore(form.data()).toDomain()).toList());
        }
        return left(const AttendeeFormFailure.attendeeServerError(failed: 'no attendees were found'));
      });

      yield left(AttendeeFormFailure.attendeeServerError(failed: 'not found'));
    } catch (e) {
      yield left(AttendeeFormFailure.attendeeServerError(failed: e.toString()));
    }
  }
}




class AttendeeFacade {

  AttendeeFacade._privateConstructor() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      firebaseUser = user;
    });
  }

  /// Current logged in user in Firebase. Does not update automatically.
  /// Use [FirebaseAuth.authStateChanges] to listen to the state changes.
  User? firebaseUser = FirebaseAuth.instance.currentUser;

  /// Gets proper [FirebaseFirestore] instance.
  FirebaseFirestore getFirebaseFirestore() => FirebaseFirestore.instance;

  static final AttendeeFacade instance = AttendeeFacade._privateConstructor();

  Future<List<AttendeeItem>> getCurrentUserAttending({
    required ContactStatus? status,
    required AttendeeType? attendingType,
    required int? limit}) async {

    if (firebaseUser == null) {
      return Future.error('Not Signed In');
    }

    var query = getFirebaseFirestore().collection('users')
        .doc(firebaseUser!.uid)
        .collection('attending')
        .orderBy('createdAtSTC', descending: true);

    if (status != null) {
      query = query.where('contactStatus', isEqualTo: status.toString());
    }

    if (attendingType != null) {
      query = query.where('attendeeType', isEqualTo: attendingType.toString());
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    final attendingList = await query.get();

    return attendingList.docs.map((e) => processAttendingItem(e)).toList();
  }

  AttendeeItem processAttendingItem(DocumentSnapshot<Map<String, dynamic>> query) {
    return AttendeeItemDto.fromJson(query.data()!).toDomain();
  }

}