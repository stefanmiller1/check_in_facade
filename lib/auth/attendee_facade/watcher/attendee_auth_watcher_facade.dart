part of check_in_facade;

@LazySingleton(as: ATTAuthWatcherFacade)
class AttendanceAuthWatcherFacade implements ATTAuthWatcherFacade {

  final FirebaseFirestore _fireStore;

  AttendanceAuthWatcherFacade(this._fireStore);

  @override
  Stream<Either<AttendeeFormFailure, List<AttendeeItem>>> watchAllAttendeesList({required String attendeeType, required String activityId}) async* {
    
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



}