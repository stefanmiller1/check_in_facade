part of check_in_facade;

@LazySingleton(as: RAuthWatcherFacade)
class ResWatcherFacade implements RAuthWatcherFacade {

  final FirebaseFirestore _fireStore;
  final FirebaseAuth _firebaseAuth;

  ResWatcherFacade(this._fireStore, this._firebaseAuth);

  @override
  Stream<Either<ReservationFormFailure, List<ReservationItem>>> watchReservationFacilityItem({required List<String> facilityId, required String? activityTypeId, required bool? isPublic, required List<ReservationSlotState>? resState}) async* {

    try {
      var query = _fireStore
          .collection('reservation_directory')
          .where('instanceId', whereIn: facilityId);
      
      if (activityTypeId != null) {
        query.where('');
      }

      if (isPublic != null) {
        query.where('');
      }

      if (resState != null && resState.isNotEmpty) {
        query.where('reservationState', whereNotIn: resState.map((e) => e.toString()).toList());
      }

      // query.limit(2);
      
      yield* query.snapshots().map((event) {
            if (event.docs.isNotEmpty) {
              return right<ReservationFormFailure, List<ReservationItem>>(event.docs.map((form) => ReservationItemDto.fromFireStore(form.data()).toDomain()).toList());
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
  Stream<Either<ReservationFormFailure, List<ReservationItem>>> watchCurrentUserReservationItem({required UserProfileModel currentUser, required bool isResInvitation}) async* {

    try {
      if (isResInvitation) {
        final userItem = StringItemDto(stringItem: currentUser.userId.getOrCrash()).toJson();
        yield* _fireStore
            .collection('reservation_directory')
            // .orderBy('createdAtSTC', descending: true)
            .where('affiliateIds', arrayContainsAny: [userItem]).snapshots().map(
                (event) {
                  if (event.docs.isNotEmpty) {
                    return right<ReservationFormFailure, List<ReservationItem>>(event.docs.map((form) => ReservationItemDto.fromFireStore(form.data()).toDomain()).toList());
                  }
                  return left(const ReservationFormFailure.reservationServerError(failed: 'no reservations found'));
                });
      } else {
        yield* _fireStore
            .collection('reservation_directory')
            // .orderBy('createdAtSTC', descending: true)
            .where('reservationOwnerId', isEqualTo: currentUser.userId.getOrCrash())
            .snapshots().map((event) {
          if (event.docs.isNotEmpty) {
            return right<ReservationFormFailure, List<ReservationItem>>(event.docs.map((form) {
              final data = form.data();
              data['affiliates'] = [];

              return ReservationItemDto.fromFireStore(form.data()).toDomain();
              }
            ).toList());
          }
          return left(const ReservationFormFailure.reservationServerError(failed: 'no reservations found'));
        });
      }
      yield left(const ReservationFormFailure.reservationServerError());
    } catch (e) {
      yield left(const ReservationFormFailure.reservationServerError());
    }
  }

  @override
  Stream<Either<ReservationFormFailure, List<Post>>> watchReservationPostItems({required String? reservationId}) async* {
    try {

      var query = _fireStore
          .collection('reservation_post')
          .where('reservationId', isEqualTo: '$reservationId');
          // .orderBy('createdAtSTC', descending: true);
      
      yield* query.snapshots().map((event) {
         if (event.docs.isNotEmpty) {
           return right<ReservationFormFailure, List<Post>>(event.docs.map((post) => PostDto.fromFireStore(post).toDomain()).toList().where((element) => element.reservationId == reservationId).toList());
         }
         return left(const ReservationFormFailure.reservationServerError(failed: 'no posts found'));
        }
      );
    } catch (e) {
      yield left(ReservationFormFailure.reservationServerError(failed: e.toString()));
    }
  }

  @override
  Stream<Either<ReservationFormFailure, ReservationItem>> watchCurrentReservationItem({required String reservationId}) async* {
    try {

      var query = _fireStore
          .collection('reservation_directory')
          .doc(reservationId);


      yield* query.snapshots().map((event) {
        if (event.data() != null && event.exists) {
          return right<ReservationFormFailure, ReservationItem>(ReservationItemDto.fromFireStore(event.data()!).toDomain());
          }
        return left(const ReservationFormFailure.reservationServerError(failed: 'reservation not found'));
        }
      );
      yield left(const ReservationFormFailure.reservationServerError(failed: 'reservation not found'));
    } catch (e) {
      yield left(ReservationFormFailure.reservationServerError(failed: e.toString()));
    }
  }



}