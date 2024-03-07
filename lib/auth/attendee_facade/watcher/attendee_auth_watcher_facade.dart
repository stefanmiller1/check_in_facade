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
  Stream<Either<AttendeeFormFailure, List<AttendeeItem>>> watchUserProfileAttending() async* {

    try {

      final currentUser = _firebaseAuth.currentUser;

      if (currentUser == null) {
        yield left(const AttendeeFormFailure.attendeeServerError(failed: 'not signed in'));
      }

      yield* _fireStore.collection('users').doc(currentUser!.uid).collection('attending').snapshots().map(
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
}

